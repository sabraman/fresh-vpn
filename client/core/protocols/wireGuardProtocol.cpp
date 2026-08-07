#include <QCoreApplication>
#include <QFileInfo>
#include <QNetworkAccessManager>
#include <QNetworkProxy>
#include <QNetworkReply>
#include <QNetworkRequest>
#include <QProcess>
#include <QTcpSocket>
#include <QThread>
#include <QTimer>
#include <QUrl>

#include "wireGuardProtocol.h"
#include "core/utils/networkUtilities.h"
#include "core/utils/constants/configKeys.h"

#include "mozilla/localsocketcontroller.h"

namespace
{
    // Адреса пробы зашиты здесь и НЕ приходят из конфига, подписки или сети.
    // Это важно: конфиг к нам попадает извне, и если брать адрес оттуда, любой,
    // кто подсунет человеку ссылку-подписку, заставит клиент стучаться куда
    // угодно. Оба адреса отвечают пустым 204 - тело читать не нужно, хватает
    // кода ответа. Схема http, а не https: нам нужен факт прохождения пакетов,
    // а не доверенный ответ, и лишнее рукопожатие TLS только тормозит проверку.
    const QStringList &probeUrls()
    {
        static const QStringList urls {
            QStringLiteral("http://connectivitycheck.gstatic.com/generate_204"),
            QStringLiteral("http://cp.cloudflare.com/generate_204")
        };
        return urls;
    }

    // Общий срок пробы. Через живой туннель ответ приходит за доли секунды,
    // так что пять секунд - это уже уверенное "не идёт". Вместе с десятью
    // секундами ожидания рукопожатия худший случай провала укладывается в
    // те же полтора десятка секунд, а не в бесконечность.
    constexpr int kProbeDeadlineMs = 5000;

    // Повторяем запрос, пока не вышел срок: маршруты на Windows встают не
    // мгновенно, и самый первый запрос может уйти мимо ещё не поднятого
    // туннеля. Один промах не должен решать судьбу подключения.
    constexpr int kProbeRetryMs = 2000;

    // Предел на отдельный запрос - чтобы зависшие соединения не копились
    // и не мешали следующему кругу.
    constexpr int kProbeRequestTimeoutMs = 2000;
}

WireguardProtocol::WireguardProtocol(const QJsonObject &configuration, QObject *parent)
    : VpnProtocol(configuration, parent)
{
    m_impl.reset(new LocalSocketController());
    QTimer *statusTimer = new QTimer(this);
    statusTimer->setInterval(1000);
    connect(statusTimer, &QTimer::timeout, this, [this]() { if (m_impl) m_impl->checkStatus(); });
    connect(m_impl.get(), &ControllerImpl::connected, this,
            [this, statusTimer](const QString &pubkey, const QDateTime &connectionTimestamp) {
                Q_UNUSED(pubkey)
                Q_UNUSED(connectionTimestamp)

                statusTimer->start();

                // Рукопожатие прошло - но "Подключено" человеку мы ещё не
                // показываем. Сначала убедимся, что через туннель реально идёт
                // трафик; состояние остаётся "Подключение..." до ответа пробы.
                startTrafficProbe();
            });
    connect(m_impl.get(), &ControllerImpl::statusUpdated, this,
            [this](const QString& serverIpv4Gateway,
                   const QString& deviceIpv4Address, uint64_t txBytes,
                   uint64_t rxBytes) {
                // Feed real tunnel counters into the stats pipeline. setBytesChanged expects
                // cumulative totals (rx, tx) and computes the per-interval diff itself; the
                // daemon status is cumulative, so pass it straight through. Note the arg
                // order is (received, sent) - opposite to this callback's (tx, rx) order.
                setBytesChanged(rxBytes, txBytes);

                const QString previousGateway = m_vpnGateway;
                const QString previousLocal = m_vpnLocalAddress;

                if (!serverIpv4Gateway.isEmpty()) {
                    m_vpnGateway = serverIpv4Gateway;
                }
                if (!deviceIpv4Address.isEmpty()) {
                    m_vpnLocalAddress = deviceIpv4Address;
                }

                if ((!m_vpnGateway.isEmpty() && m_vpnGateway != previousGateway) ||
                    (!m_vpnLocalAddress.isEmpty() && m_vpnLocalAddress != previousLocal)) {
                    emit tunnelAddressesUpdated(m_vpnGateway, m_vpnLocalAddress);
                }
            });

    connect(m_impl.get(), &ControllerImpl::disconnected, this,
            [this, statusTimer]() { statusTimer->stop(); cancelTrafficProbe(); setConnectionState(Vpn::ConnectionState::Disconnected); });

    // Поломка службы теперь доходит до протокола, а не умирает в логе.
    connect(m_impl.get(), &ControllerImpl::backendFailure, this,
            [this](const QString &reason) {
                failConnection(ErrorCode::AmneziaServiceConnectionFailed, reason);
            });

    // У сигнала таймаута раньше не было ни одного получателя. Теперь он гасит
    // пробу: ждать ответа из туннеля, который так и не поднялся, бессмысленно.
    connect(this, &VpnProtocol::timeoutTimerEvent, this, [this]() { cancelTrafficProbe(); });

    m_impl->initialize(nullptr, nullptr);
}

WireguardProtocol::~WireguardProtocol()
{
    WireguardProtocol::stop();
    QThread::msleep(200);
}

void WireguardProtocol::stop()
{
    cancelTrafficProbe();
    stopMzImpl();
    return;
}

ErrorCode WireguardProtocol::startMzImpl()
{
    if (!m_impl) {
        qWarning() << "WireguardProtocol: нет управляющего канала к службе";
        return ErrorCode::AmneziaServiceConnectionFailed;
    }

    QString protocolName = m_rawConfig.value("protocol").toString();
    QJsonObject vpnConfigData = m_rawConfig.value(protocolName + "_config_data").toObject();

    // Имя точки обязано превратиться в адрес ЗДЕСЬ. Раньше результат
    // подставлялся не глядя: не разрешилось имя - в конфиг уезжала пустая
    // строка, служба честно поднимала интерфейс в никуда, а функция возвращала
    // "ошибок нет". Снаружи это выглядело как вечное "Подключение...".
    const QString resolvedHost = NetworkUtilities::getIPAddress(vpnConfigData.value(configKey::hostName).toString());
    if (resolvedHost.isEmpty()) {
        qWarning() << "WireguardProtocol: не удалось определить адрес точки по её имени";
        return ErrorCode::AddressPoolError;
    }
    vpnConfigData[configKey::hostName] = resolvedHost;
    m_rawConfig.insert(protocolName + "_config_data", vpnConfigData);

    const QString resolvedTopLevel = NetworkUtilities::getIPAddress(m_rawConfig[configKey::hostName].toString());
    if (resolvedTopLevel.isEmpty()) {
        qWarning() << "WireguardProtocol: не удалось определить адрес точки по её имени (верхний уровень конфига)";
        return ErrorCode::AddressPoolError;
    }
    m_rawConfig[configKey::hostName] = resolvedTopLevel;

    m_impl->activate(m_rawConfig);
    return ErrorCode::NoError;
}

ErrorCode WireguardProtocol::stopMzImpl()
{
    if (!m_impl) {
        return ErrorCode::NoError;
    }
    m_impl->deactivate();
    return ErrorCode::NoError;
}


ErrorCode WireguardProtocol::start()
{
    // Новая попытка - новое право сообщить о провале.
    m_failureReported = false;

    setConnectionState(Vpn::ConnectionState::Connecting);

    const ErrorCode code = startMzImpl();
    if (code != ErrorCode::NoError) {
        // Не возвращаем ошибку молча: состояние и код должны уйти наверх сразу,
        // иначе человек снова увидит бесконечное "Подключение...".
        failConnection(code, QStringLiteral("не удалось начать подключение"));
    }
    return code;
}

void WireguardProtocol::failConnection(ErrorCode code, const QString &reason)
{
    if (m_failureReported) {
        return;
    }
    m_failureReported = true;

    qWarning().noquote() << "WireguardProtocol: попытка подключения провалилась -" << reason;

    cancelTrafficProbe();

    // Сначала код ошибки и состояние, потом остановка: stopMzImpl() синхронно
    // роняет сигнал disconnected, и если звать его первым, наверх уходит
    // безобидное "отключено" вместо настоящей причины.
    setLastError(code);
    emit protocolError(code);

    stopMzImpl();
}

void WireguardProtocol::startTrafficProbe()
{
    if (m_probeRunning) {
        return;
    }
    m_probeRunning = true;

    // Рукопожатие состоялось, значит своё дело общий таймер ожидания сделал.
    // Дальше сроком распоряжается проба - иначе на медленной сети таймер успел
    // бы прибить подключение, которое на самом деле поднялось.
    stopTimeoutTimer();

    if (!m_probeManager) {
        m_probeManager = new QNetworkAccessManager(this);
        // Мимо системного прокси: нам нужен факт прохождения пакетов именно
        // через туннель, а прокси может ответить и в обход него.
        m_probeManager->setProxy(QNetworkProxy(QNetworkProxy::NoProxy));
        connect(m_probeManager, &QNetworkAccessManager::finished, this, &WireguardProtocol::onProbeFinished);
    }

    if (!m_probeRetry) {
        m_probeRetry = new QTimer(this);
        m_probeRetry->setInterval(kProbeRetryMs);
        connect(m_probeRetry, &QTimer::timeout, this, &WireguardProtocol::sendProbeRound);
    }

    if (!m_probeDeadline) {
        m_probeDeadline = new QTimer(this);
        m_probeDeadline->setSingleShot(true);
        connect(m_probeDeadline, &QTimer::timeout, this, [this]() {
            failConnection(ErrorCode::VpnTunnelDidNotComeUpError,
                           QStringLiteral("рукопожатие прошло, но трафик через туннель не идёт"));
        });
    }

    qInfo() << "WireguardProtocol: рукопожатие прошло, проверяем, идёт ли трафик через туннель";

    m_probeDeadline->start(kProbeDeadlineMs);
    m_probeRetry->start();
    sendProbeRound();
}

void WireguardProtocol::sendProbeRound()
{
    if (!m_probeRunning || !m_probeManager) {
        return;
    }

    const QStringList &urls = probeUrls();
    for (const QString &url : urls) {
        QNetworkRequest request { QUrl(url) };
        // Редиректы не выполняем: ответ, полученный по другому адресу, ничего
        // не доказывает - так отвечают заглушки провайдеров и точки доступа.
        request.setAttribute(QNetworkRequest::RedirectPolicyAttribute,
                             QVariant::fromValue(QNetworkRequest::ManualRedirectPolicy));
        request.setTransferTimeout(kProbeRequestTimeoutMs);
        request.setHeader(QNetworkRequest::UserAgentHeader, QStringLiteral("FreshVPN-probe"));

        QNetworkReply *reply = m_probeManager->get(request);
        m_probeReplies.append(reply);
    }
}

void WireguardProtocol::onProbeFinished(QNetworkReply *reply)
{
    if (!reply) {
        return;
    }

    m_probeReplies.removeAll(reply);
    reply->deleteLater();

    if (!m_probeRunning) {
        return;
    }

    const QVariant statusAttr = reply->attribute(QNetworkRequest::HttpStatusCodeAttribute);
    const int status = statusAttr.isValid() ? statusAttr.toInt() : 0;

    // Засчитываем только пустой 204. Всё остальное - либо ошибка сети, либо
    // чужой ответ (страница-заглушка, перехват провайдером), и подтверждением
    // работающего туннеля это не является.
    if (reply->error() == QNetworkReply::NoError && status == 204) {
        qInfo() << "WireguardProtocol: трафик через туннель идёт, подключение подтверждено";
        cancelTrafficProbe();
        setConnectionState(Vpn::ConnectionState::Connected);
        return;
    }

    qDebug() << "WireguardProtocol: проба не прошла, код ответа" << status << "ошибка" << reply->error();
}

void WireguardProtocol::cancelTrafficProbe()
{
    m_probeRunning = false;

    if (m_probeRetry) {
        m_probeRetry->stop();
    }
    if (m_probeDeadline) {
        m_probeDeadline->stop();
    }

    // Список копируем и чистим ДО обрыва: abort() тут же вызывает обработчик
    // завершения, и он не должен наткнуться на список, по которому мы идём.
    const QVector<QNetworkReply *> pending = m_probeReplies;
    m_probeReplies.clear();
    for (QNetworkReply *reply : pending) {
        if (reply) {
            reply->abort();
        }
    }
}
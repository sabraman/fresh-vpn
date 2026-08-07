#ifndef WIREGUARDPROTOCOL_H
#define WIREGUARDPROTOCOL_H

#include <QObject>
#include <QProcess>
#include <QString>
#include <QTemporaryFile>
#include <QTimer>
#include <QVector>

#include "vpnProtocol.h"

#include "mozilla/controllerimpl.h"

class QNetworkAccessManager;
class QNetworkReply;

class WireguardProtocol : public VpnProtocol
{
    Q_OBJECT

public:
    explicit WireguardProtocol(const QJsonObject& configuration, QObject* parent = nullptr);
    virtual ~WireguardProtocol() override;

    ErrorCode start() override;
    void stop() override;

    ErrorCode startMzImpl();
    ErrorCode stopMzImpl();

private:
    // --- проба реального трафика через туннель ---
    // Для AmneziaWG "интерфейс поднят" не равно "трафик идёт". Служба сообщает
    // о подключении, как только прошло рукопожатие с точкой, но дальше
    // транспортные пакеты вполне могут тонуть в фильтре - и человек смотрит на
    // "Подключено", у которого не открывается ни один сайт. Поэтому между
    // рукопожатием и надписью "Подключено" мы сами дёргаем короткий запрос
    // наружу и ждём пустой ответ. Не дождались - это провал, а не подключение.
    void startTrafficProbe();
    void sendProbeRound();
    void cancelTrafficProbe();
    void onProbeFinished(QNetworkReply *reply);

    // Единая точка "признать попытку провалившейся": кладёт код в lastError,
    // переводит состояние в ошибку, поднимает код наверх сигналом и гасит
    // туннель. Срабатывает один раз на попытку - иначе один провал прилетал бы
    // наверх дважды и съедал сразу две запасные точки из очереди.
    void failConnection(ErrorCode code, const QString &reason);

    QScopedPointer<ControllerImpl> m_impl;

    QNetworkAccessManager *m_probeManager = nullptr;
    QTimer *m_probeRetry = nullptr;
    QTimer *m_probeDeadline = nullptr;
    QVector<QNetworkReply *> m_probeReplies;
    bool m_probeRunning = false;
    bool m_failureReported = false;
};

#endif // WIREGUARDPROTOCOL_H
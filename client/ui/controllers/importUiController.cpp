#include "importUiController.h"

#include <QDebug>
#include <QFile>
#include <QFileInfo>
#include <QMutex>
#include <QJsonDocument>
#include <QEventLoop>
#include <QNetworkAccessManager>
#include <QNetworkReply>
#include <QNetworkRequest>
#include <QRegularExpression>
#include <QTimer>
#include <QUrl>

#include "systemController.h"

#ifdef Q_OS_ANDROID
    #include "platforms/android/android_controller.h"
#endif

#if defined Q_OS_ANDROID
ImportUiController* ImportUiController::mInstance = nullptr;
static QMutex qrDecodeMutex;
#endif

ImportUiController::ImportUiController(ImportController* importController, QObject *parent)
    : QObject(parent),
      m_importController(importController),
      m_isNativeWireGuardConfig(false)
{
#if defined Q_OS_ANDROID
    mInstance = this;
#endif

    connect(m_importController, &ImportController::importFinished, this, &ImportUiController::importFinished);
    connect(m_importController, &ImportController::importErrorOccurred, this, &ImportUiController::importErrorOccurred);
    connect(m_importController, &ImportController::restoreAppConfig, this, &ImportUiController::restoreAppConfig);
}

bool ImportUiController::extractConfigFromFile(const QString &fileName)
{
    QString data;
    if (!SystemController::readFile(fileName, data)) {
        emit importErrorOccurred(ErrorCode::ImportOpenConfigError, false);
        return false;
    }
    
    QString configFileName = QFileInfo(QFile(fileName).fileName()).fileName();
#ifdef Q_OS_ANDROID
    if (configFileName.isEmpty()) {
        configFileName = AndroidController::instance()->getFileName(fileName);
    }
#endif
    
    auto result = m_importController->extractConfigFromData(data, configFileName);
    
    if (result.errorCode != ErrorCode::NoError) {
        emit importErrorOccurred(result.errorCode, false);
        return false;
    }
    
    m_config = result.config;
    m_configFileName = result.configFileName;
    m_maliciousWarningText = result.maliciousWarningText;
    m_isNativeWireGuardConfig = result.isNativeWireGuardConfig;
    
    emit importConfigChanged();
    return true;
}

bool ImportUiController::extractConfigFromData(QString data)
{
    data = data.trimmed();

    // If the user pasted an http(s) subscription link (or a deep-link wrapper that
    // carries one), download the body first, then parse it like any other config.
    const QString url = extractFetchableUrl(data);
    if (!url.isEmpty()) {
        QString fetchError;
        const QString body = fetchSubscriptionBody(url, fetchError);
        if (body.trimmed().isEmpty()) {
            qWarning() << "Subscription fetch failed:" << fetchError;
            emit importErrorOccurred(ErrorCode::ImportInvalidConfigError, false);
            return false;
        }
        data = body.trimmed();
    }

    auto result = m_importController->extractConfigFromData(data);
    
    if (result.errorCode != ErrorCode::NoError) {
        emit importErrorOccurred(result.errorCode, false);
        return false;
    }
    
    m_config = result.config;
    m_configFileName = result.configFileName;
    m_maliciousWarningText = result.maliciousWarningText;
    m_isNativeWireGuardConfig = result.isNativeWireGuardConfig;
    
    emit importConfigChanged();
    return true;
}

bool ImportUiController::extractConfigFromQr(const QByteArray &data)
{
    auto result = m_importController->extractConfigFromQr(data);
    
    if (result.errorCode != ErrorCode::NoError) {
        emit importErrorOccurred(result.errorCode, false);
        return false;
    }
    
    m_config = result.config;
    m_configFileName = result.configFileName;
    m_maliciousWarningText = result.maliciousWarningText;
    m_isNativeWireGuardConfig = result.isNativeWireGuardConfig;
    
    emit importConfigChanged();
    return true;
}

QString ImportUiController::getConfig()
{
    return QJsonDocument(m_config).toJson(QJsonDocument::Indented);
}

QString ImportUiController::getConfigFileName()
{
    return m_configFileName;
}

QString ImportUiController::getMaliciousWarningText()
{
    return m_maliciousWarningText;
}

bool ImportUiController::isNativeWireGuardConfig()
{
    return m_isNativeWireGuardConfig;
}

void ImportUiController::processNativeWireGuardConfig()
{
    m_config = m_importController->processNativeWireGuardConfig(m_config);
    emit importConfigChanged();
}

void ImportUiController::importConfig()
{
    m_importController->importConfig(m_config);
    
    m_config = {};
    m_configFileName.clear();
    m_maliciousWarningText.clear();
    m_isNativeWireGuardConfig = false;
    
    emit importConfigChanged();
}

void ImportUiController::clearConfigFileName()
{
    m_configFileName.clear();
    emit importConfigChanged();
}

#if defined Q_OS_ANDROID || defined Q_OS_IOS
void ImportUiController::startDecodingQr()
{
    m_importController->startDecodingQr();
#if defined Q_OS_ANDROID
    AndroidController::instance()->startQrReaderActivity();
#endif
}

void ImportUiController::stopDecodingQr()
{
    emit qrDecodingFinished();
}

bool ImportUiController::parseQrCodeChunk(const QString &code)
{
    auto parseResult = m_importController->parseQrCodeChunk(code);
    if (parseResult.success) {
        m_config = parseResult.importResult.config;
        m_configFileName = parseResult.importResult.configFileName;
        m_maliciousWarningText = parseResult.importResult.maliciousWarningText;
        m_isNativeWireGuardConfig = parseResult.importResult.isNativeWireGuardConfig;
        emit importConfigChanged();
        stopDecodingQr();
        return true;
    }
    return false;
}

double ImportUiController::getQrCodeScanProgressBarValue()
{
    const int total = m_importController->qrChunksTotal();
    if (total == 0) {
        return 0.0;
    }
    return (1.0 / total) * m_importController->qrChunksReceived();
}

QString ImportUiController::getQrCodeScanProgressString()
{
    return tr("Scanned %1 of %2.").arg(m_importController->qrChunksReceived()).arg(m_importController->qrChunksTotal());
}
#endif

#if defined Q_OS_ANDROID
bool ImportUiController::decodeQrCode(const QString &code)
{
    QMutexLocker lock(&qrDecodeMutex);

    if (!mInstance) {
        return false;
    }

    if (!mInstance->m_importController->isQrDecodingActive()) {
        mInstance->m_importController->startDecodingQr();
    }
    return mInstance->parseQrCodeChunk(code);
}
#endif

QString ImportUiController::readTextFile(const QString &fileName)
{
    QFile file(fileName);
    if (!file.open(QIODevice::ReadOnly | QIODevice::Text)) {
        return {};
    }
    return QString::fromUtf8(file.readAll());
}

QString ImportUiController::extractFetchableUrl(const QString &data) const
{
    const QString trimmed = data.trimmed();

    // A bare http(s) subscription URL (single token, no embedded whitespace).
    if ((trimmed.startsWith("http://", Qt::CaseInsensitive) || trimmed.startsWith("https://", Qt::CaseInsensitive))
        && !trimmed.contains(QRegularExpression("\\s"))) {
        return trimmed;
    }

    // Deep-link wrappers carrying the real subscription URL in a "url=" parameter,
    // e.g. clash://install-config?url=...  sing-box://import-remote-profile?url=...
    //      hiddify://import?url=...  streisand://import?url=...  v2rayng://...?url=...
    if (trimmed.contains("://") && trimmed.contains("url=", Qt::CaseInsensitive)) {
        const int u = trimmed.indexOf("url=", 0, Qt::CaseInsensitive);
        QString inner = trimmed.mid(u + 4);
        const int amp = inner.indexOf('&');
        if (amp >= 0) {
            inner = inner.left(amp);
        }
        inner = QUrl::fromPercentEncoding(inner.toUtf8()).trimmed();
        if (inner.startsWith("http://", Qt::CaseInsensitive) || inner.startsWith("https://", Qt::CaseInsensitive)) {
            return inner;
        }
    }

    return QString();
}

QString ImportUiController::fetchSubscriptionBody(const QString &url, QString &errorString)
{
    QNetworkAccessManager manager;
    QNetworkRequest request{ QUrl(url) };

    // A v2ray-family User-Agent makes most panels (incl. Remnawave) return the
    // base64 share-URI list, which the core parser understands universally.
    request.setHeader(QNetworkRequest::UserAgentHeader, QStringLiteral("v2rayNG/1.8.5 (FreshVPN)"));
    request.setRawHeader("Accept", "*/*");
    request.setAttribute(QNetworkRequest::RedirectPolicyAttribute, QNetworkRequest::NoLessSafeRedirectPolicy);

    QNetworkReply *reply = manager.get(request);

    QEventLoop loop;
    QTimer timeoutTimer;
    timeoutTimer.setSingleShot(true);
    bool timedOut = false;
    QObject::connect(&timeoutTimer, &QTimer::timeout, &loop, [&loop, &timedOut]() {
        timedOut = true;
        loop.quit();
    });
    QObject::connect(reply, &QNetworkReply::finished, &loop, &QEventLoop::quit);

    timeoutTimer.start(15000);
    loop.exec();

    QString body;
    if (timedOut) {
        errorString = QStringLiteral("Request timed out");
        reply->abort();
    } else if (reply->error() != QNetworkReply::NoError) {
        errorString = reply->errorString();
    } else {
        const QByteArray raw = reply->readAll();
        if (raw.size() > 5 * 1024 * 1024) {
            errorString = QStringLiteral("Response too large");
        } else {
            body = QString::fromUtf8(raw);
        }
    }

    reply->deleteLater();
    return body;
}

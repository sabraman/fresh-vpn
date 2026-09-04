#ifndef IMPORTUICONTROLLER_H
#define IMPORTUICONTROLLER_H

#include <QObject>
#include <QList>
#include <QStringList>

#include "core/controllers/selfhosted/importController.h"

QT_BEGIN_NAMESPACE
class QNetworkAccessManager;
class QNetworkReply;
class QTimer;
QT_END_NAMESPACE

class ImportUiController : public QObject
{
    Q_OBJECT

    Q_PROPERTY(QString config READ getConfig NOTIFY importConfigChanged)
    Q_PROPERTY(QString configFileName READ getConfigFileName NOTIFY importConfigChanged)
    Q_PROPERTY(QString maliciousWarningText READ getMaliciousWarningText NOTIFY importConfigChanged)
    Q_PROPERTY(bool isNativeWireGuardConfig READ isNativeWireGuardConfig NOTIFY importConfigChanged)

public:
    explicit ImportUiController(ImportController* importController, QObject *parent = nullptr);

public slots:
    void importConfig();
    void clearConfigFileName();
    bool extractConfigFromFile(const QString &fileName);
    bool extractConfigFromQrImage(const QString &fileName);
    bool extractConfigFromData(QString data);
    // Async variant for UI flows: never blocks; success is reported via
    // configExtracted(), failures via importErrorOccurred().
    void requestConfigFromData(const QString &data);
    bool extractConfigFromQr(const QByteArray &data);
    QString getConfig();
    QString getConfigFileName();
    QString getMaliciousWarningText();
    bool isNativeWireGuardConfig();
    int getConfigsCount();
    void processNativeWireGuardConfig();
    QString readTextFile(const QString &fileName);

#if defined Q_OS_ANDROID || defined Q_OS_IOS
    void startDecodingQr();
    bool parseQrCodeChunk(const QString &code);

    double getQrCodeScanProgressBarValue();
    QString getQrCodeScanProgressString();
#endif

#if defined Q_OS_ANDROID
    static bool decodeQrCode(const QString &code);
#endif

signals:
    void importFinished();
    void importErrorOccurred(ErrorCode errorCode, bool goToPageHome);
    void qrDecodingFinished();
    void restoreAppConfig(const QByteArray &data);
    void importConfigChanged();
    void configExtracted();

private:
#if defined Q_OS_ANDROID || defined Q_OS_IOS
    void stopDecodingQr();
#endif

    // Shared synchronous parse used by both extract paths.
    bool parseFetchedData(const QString &data);
    void fetchHop(const QString &url);
    void abortPendingFetch();
    void onSubscriptionReplyFinished();
    void onSubscriptionHopTimeout();

    QString extractFetchableUrl(const QString &data) const;
    QString extractInnerUrlFromOpenPage(const QString &body) const;
    bool looksLikeHtmlPage(const QString &body) const;
    bool isAllowedHopTarget(const QString &innerUrl) const;
    QString fetchSubscriptionBody(const QString &url, QString &errorString, int timeoutMs = 15000);

    ImportController* m_importController;

    QNetworkAccessManager* m_nam = nullptr;
    QNetworkReply* m_pendingReply = nullptr;
    QTimer* m_hopTimer = nullptr;
    QString m_currentUrl;
    QStringList m_visited;
    int m_hopsLeft = 0;

    QJsonObject m_config;
    QList<QJsonObject> m_configs;
    QString m_configFileName;
    QString m_maliciousWarningText;
    bool m_isNativeWireGuardConfig;

#if defined Q_OS_ANDROID
    static ImportUiController* mInstance;
#endif
};

#endif // IMPORTUICONTROLLER_H

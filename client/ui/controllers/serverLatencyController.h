#ifndef SERVERLATENCYCONTROLLER_H
#define SERVERLATENCYCONTROLLER_H

#include <QElapsedTimer>
#include <QList>
#include <QObject>
#include <QHash>
#include <QString>

#include "ui/models/serversModel.h"

class QNetworkAccessManager;
class QNetworkReply;
class QTimer;

class ServerLatencyController : public QObject
{
    Q_OBJECT
    Q_PROPERTY(double downloadMbps READ downloadMbps NOTIFY speedTestChanged)
    Q_PROPERTY(double uploadMbps READ uploadMbps NOTIFY speedTestChanged)
    Q_PROPERTY(int speedTestState READ speedTestState NOTIFY speedTestChanged)
    Q_PROPERTY(double downloadMB READ downloadMB NOTIFY speedTestChanged)
    Q_PROPERTY(double downloadSecs READ downloadSecs NOTIFY speedTestChanged)
    Q_PROPERTY(double uploadMB READ uploadMB NOTIFY speedTestChanged)
    Q_PROPERTY(double uploadSecs READ uploadSecs NOTIFY speedTestChanged)
public:
    explicit ServerLatencyController(ServersModel* serversModel, QObject* parent = nullptr);

public slots:
    void measureAll();
    int latencyFor(const QString& serverId) const;
    QString bestServerId() const;
    int bestLatency() const;

    // Per-country latency for subscription mode. The subscription body already lists every
    // country's host:port, so the client can probe them directly - no backend change needed.
    void measureCountries(const QString& subscriptionKey);
    int latencyForCountry(const QString& countryCode) const;
    QString bestCountryCode() const;

    // Real download/upload speed test (Cloudflare endpoints).
    void runSpeedTest();
    double downloadMbps() const;
    double uploadMbps() const;
    int speedTestState() const;
    double downloadMB() const;
    double downloadSecs() const;
    double uploadMB() const;
    double uploadSecs() const;

signals:
    void latencyChanged(const QString& serverId, int ms);
    void measurementFinished();
    void countryLatencyChanged(const QString& countryCode, int ms);
    void countryMeasurementFinished();
    void speedTestChanged();

private:
    void measureOne(const QString& serverId, const QString& host, quint16 port);
    void measureCountryOne(const QString& countryCode, const QString& host, quint16 port);
    void parseSubscriptionBody(const QByteArray& body);
    void startSpeedDownload();
    void startSpeedUpload();
    void beginSpeedPhase();
    void abortSpeedReplies();
    void finishSpeedDownload();
    void finishSpeedUpload();

    ServersModel* m_serversModel;
    QHash<QString, int> m_latency;
    QHash<QString, int> m_countryLatency;
    int m_pending = 0;
    int m_countryPending = 0;
    QNetworkAccessManager* m_net = nullptr;
    bool m_countryFetchInFlight = false;
    double m_downloadMbps = 0.0;
    double m_uploadMbps = 0.0;
    double m_downloadMB = 0.0;
    double m_downloadSecs = 0.0;
    double m_uploadMB = 0.0;
    double m_uploadSecs = 0.0;
    QList<QNetworkReply*> m_speedReplies;
    QElapsedTimer m_speedTimer;
    qint64 m_speedBytes = 0;
    bool m_speedStarted = false;
    int m_speedPending = 0;
    QTimer* m_speedCap = nullptr;
    int m_speedTestState = 0; // 0 idle, 1 downloading, 2 uploading, 3 done, -1 error
};

#endif // SERVERLATENCYCONTROLLER_H
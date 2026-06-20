#ifndef LEAKTESTCONTROLLER_H
#define LEAKTESTCONTROLLER_H

#include <QObject>
#include <QString>
#include <QStringList>

class QNetworkAccessManager;

// Leak detector: what IP / geo / DNS the outside world sees while connected.
// Uses public services (ipwho.is, cloudflare trace, bash.ws). No API key, INTL contour.
// WebRTC leak is a browser concept and not applicable to a native client.
class LeakTestController : public QObject
{
    Q_OBJECT
public:
    Q_PROPERTY(QString exitIp READ exitIp NOTIFY resultChanged)
    Q_PROPERTY(QString exitCountry READ exitCountry NOTIFY resultChanged)
    Q_PROPERTY(QString exitCity READ exitCity NOTIFY resultChanged)
    Q_PROPERTY(QString isp READ isp NOTIFY resultChanged)
    Q_PROPERTY(QStringList dnsServers READ dnsServers NOTIFY resultChanged)
    Q_PROPERTY(int dnsLeak READ dnsLeak NOTIFY resultChanged) // -1 unknown, 0 no leak, 1 leak
    Q_PROPERTY(int state READ state NOTIFY stateChanged)      // 0 idle, 1 ip, 2 dns, 3 done, 4 error

    explicit LeakTestController(QObject* parent = nullptr);

    QString exitIp() const { return m_exitIp; }
    QString exitCountry() const { return m_exitCountry; }
    QString exitCity() const { return m_exitCity; }
    QString isp() const { return m_isp; }
    QStringList dnsServers() const { return m_dnsServers; }
    int dnsLeak() const { return m_dnsLeak; }
    int state() const { return m_state; }

public slots:
    void runTest();

signals:
    void resultChanged();
    void stateChanged();

private:
    void fetchIp();
    void fetchIpFallback();
    void startDnsTest();
    void resolveDnsProbes(const QString& id);
    void fetchDnsResults(const QString& id);
    void setState(int s);

    QNetworkAccessManager* m_nam;
    QString m_exitIp;
    QString m_exitCountry;
    QString m_exitCity;
    QString m_isp;
    QStringList m_dnsServers;
    int m_dnsLeak = -1;
    bool m_exitCountryIsName = false; // true => m_exitCountry holds a full country name (comparable to bash.ws)
    int m_state = 0;
};

#endif // LEAKTESTCONTROLLER_H
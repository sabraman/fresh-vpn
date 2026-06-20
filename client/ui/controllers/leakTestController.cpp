#include "leakTestController.h"

#include <QHostInfo>
#include <QJsonArray>
#include <QJsonDocument>
#include <QJsonObject>
#include <QJsonParseError>
#include <QJsonValue>
#include <QNetworkAccessManager>
#include <QNetworkReply>
#include <QNetworkRequest>
#include <QTimer>
#include <QUrl>

LeakTestController::LeakTestController(QObject* parent)
    : QObject(parent), m_nam(new QNetworkAccessManager(this))
{
}

void LeakTestController::setState(int s)
{
    if (m_state != s) {
        m_state = s;
        emit stateChanged();
    }
}

void LeakTestController::runTest()
{
    if (m_state == 1 || m_state == 2) {
        return;
    }
    m_exitIp.clear();
    m_exitCountry.clear();
    m_exitCity.clear();
    m_isp.clear();
    m_dnsServers.clear();
    m_dnsLeak = -1;
    m_exitCountryIsName = false;
    emit resultChanged();
    fetchIp();
}

void LeakTestController::fetchIp()
{
    setState(1);
    QNetworkRequest req(QUrl(QStringLiteral("https://ipwho.is/")));
    QNetworkReply* reply = m_nam->get(req);
    connect(reply, &QNetworkReply::finished, this, [this, reply]() {
        const QByteArray body = reply->readAll();
        const bool ok = (reply->error() == QNetworkReply::NoError);
        reply->deleteLater();

        bool parsed = false;
        if (ok) {
            QJsonParseError pe;
            const QJsonDocument doc = QJsonDocument::fromJson(body, &pe);
            if (pe.error == QJsonParseError::NoError && doc.isObject()) {
                const QJsonObject o = doc.object();
                if (o.value(QStringLiteral("success")).toBool(true)) {
                    m_exitIp = o.value(QStringLiteral("ip")).toString();
                    m_exitCountry = o.value(QStringLiteral("country")).toString();
                    m_exitCity = o.value(QStringLiteral("city")).toString();
                    const QJsonObject conn = o.value(QStringLiteral("connection")).toObject();
                    m_isp = conn.value(QStringLiteral("isp")).toString();
                    m_exitCountryIsName = !m_exitCountry.isEmpty();
                    parsed = !m_exitIp.isEmpty();
                }
            }
        }
        emit resultChanged();
        if (parsed) {
            startDnsTest();
        } else {
            fetchIpFallback();
        }
    });
}

void LeakTestController::fetchIpFallback()
{
    QNetworkRequest req(QUrl(QStringLiteral("https://www.cloudflare.com/cdn-cgi/trace")));
    QNetworkReply* reply = m_nam->get(req);
    connect(reply, &QNetworkReply::finished, this, [this, reply]() {
        const QByteArray body = reply->readAll();
        const bool ok = (reply->error() == QNetworkReply::NoError);
        reply->deleteLater();
        if (ok) {
            const QList<QByteArray> lines = body.split('\n');
            for (const QByteArray& line : lines) {
                const int eq = line.indexOf('=');
                if (eq <= 0) {
                    continue;
                }
                const QString key = QString::fromUtf8(line.left(eq));
                const QString val = QString::fromUtf8(line.mid(eq + 1)).trimmed();
                if (key == QLatin1String("ip")) {
                    m_exitIp = val;
                } else if (key == QLatin1String("loc")) {
                    m_exitCountry = val; // 2-letter code, not comparable to bash.ws country names
                    m_exitCountryIsName = false;
                }
            }
        }
        emit resultChanged();
        if (!m_exitIp.isEmpty()) {
            startDnsTest();
        } else {
            setState(4);
            emit resultChanged();
        }
    });
}

void LeakTestController::startDnsTest()
{
    setState(2);
    QNetworkRequest req(QUrl(QStringLiteral("https://bash.ws/id")));
    QNetworkReply* reply = m_nam->get(req);
    connect(reply, &QNetworkReply::finished, this, [this, reply]() {
        const QString id = QString::fromUtf8(reply->readAll()).trimmed();
        const bool ok = (reply->error() == QNetworkReply::NoError);
        reply->deleteLater();
        if (!ok || id.isEmpty()) {
            // DNS check unavailable; keep IP/geo result, leave dnsLeak unknown.
            setState(3);
            emit resultChanged();
            return;
        }
        resolveDnsProbes(id);
    });
}

void LeakTestController::resolveDnsProbes(const QString& id)
{
    // Each probe forces a DNS resolution through whatever resolver the tunnel uses;
    // bash.ws authoritative NS records which resolver IPs queried it.
    for (int i = 1; i <= 8; ++i) {
        const QString host = QStringLiteral("%1.%2.bash.ws").arg(i).arg(id);
        QHostInfo::lookupHost(host, this, [](const QHostInfo&) { /* result ignored on purpose */ });
    }
    QTimer::singleShot(3500, this, [this, id]() { fetchDnsResults(id); });
}

void LeakTestController::fetchDnsResults(const QString& id)
{
    QNetworkRequest req(QUrl(QStringLiteral("https://bash.ws/dnsleak/test/%1?json").arg(id)));
    QNetworkReply* reply = m_nam->get(req);
    connect(reply, &QNetworkReply::finished, this, [this, reply]() {
        const QByteArray body = reply->readAll();
        const bool ok = (reply->error() == QNetworkReply::NoError);
        reply->deleteLater();

        QStringList servers;
        int leak = -1;
        if (ok) {
            const QJsonDocument doc = QJsonDocument::fromJson(body);
            if (doc.isArray()) {
                bool anyDns = false;
                bool mismatch = false;
                const QJsonArray arr = doc.array();
                for (const QJsonValue& v : arr) {
                    const QJsonObject o = v.toObject();
                    if (o.value(QStringLiteral("type")).toString() != QLatin1String("dns")) {
                        continue;
                    }
                    anyDns = true;
                    const QString ip = o.value(QStringLiteral("ip")).toString();
                    const QString country = o.value(QStringLiteral("country_name")).toString();
                    QString label = ip;
                    if (!country.isEmpty()) {
                        label += QStringLiteral(" · ") + country;
                    }
                    servers << label;
                    if (m_exitCountryIsName && !m_exitCountry.isEmpty() && !country.isEmpty()
                        && country.compare(m_exitCountry, Qt::CaseInsensitive) != 0) {
                        mismatch = true;
                    }
                }
                if (anyDns) {
                    leak = m_exitCountryIsName ? (mismatch ? 1 : 0) : -1;
                }
            }
        }
        m_dnsServers = servers;
        m_dnsLeak = leak;
        setState(3);
        emit resultChanged();
    });
}
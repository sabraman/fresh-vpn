#include "connectionHealthController.h"

#include <QTcpSocket>
#include <QElapsedTimer>
#include <QSharedPointer>

ConnectionHealthController::ConnectionHealthController(ConnectionController* connectionController, ServersModel* serversModel, QObject* parent)
    : QObject(parent), m_connectionController(connectionController), m_serversModel(serversModel)
{
    m_timer.setInterval(3000);
    connect(&m_timer, &QTimer::timeout, this, &ConnectionHealthController::onTick);
    connect(m_connectionController, &ConnectionController::connectionStateChanged, this, &ConnectionHealthController::onConnectionStateChanged);
}

int ConnectionHealthController::latencyMs() const { return m_latencyMs; }
int ConnectionHealthController::jitterMs() const { return m_jitterMs; }
int ConnectionHealthController::healthState() const { return m_healthState; }

void ConnectionHealthController::onConnectionStateChanged()
{
    if (m_connectionController->isConnected()) {
        m_samples.clear();
        m_latencyMs = -1;
        m_jitterMs = -1;
        m_healthState = 3;
        emit healthChanged();
        m_timer.start();
        measure();
    } else {
        m_timer.stop();
        m_samples.clear();
        m_latencyMs = -1;
        m_jitterMs = -1;
        m_healthState = 0;
        emit healthChanged();
    }
}

void ConnectionHealthController::onTick()
{
    if (m_connectionController->isConnected()) {
        measure();
    } else {
        m_timer.stop();
    }
}

QString ConnectionHealthController::currentHost() const
{
    if (!m_serversModel) {
        return QString();
    }
    const int rows = m_serversModel->rowCount();
    for (int i = 0; i < rows; ++i) {
        if (m_serversModel->data(i, ServersModel::IsDefaultRole).toBool()) {
            return m_serversModel->data(i, ServersModel::HostNameRole).toString();
        }
    }
    return QString();
}

void ConnectionHealthController::measure()
{
    const QString host = currentHost();
    if (host.isEmpty()) {
        return;
    }

    QTcpSocket* sock = new QTcpSocket(this);
    auto timer = QSharedPointer<QElapsedTimer>::create();
    auto done = QSharedPointer<bool>::create(false);
    timer->start();

    auto finish = [this, sock, timer, done](int ms) {
        if (*done) {
            return;
        }
        *done = true;
        sock->deleteLater();

        if (ms >= 0) {
            m_latencyMs = ms;
            m_samples.append(ms);
            while (m_samples.size() > 6) {
                m_samples.removeFirst();
            }
            int mn = m_samples.first();
            int mx = m_samples.first();
            for (int v : m_samples) {
                if (v < mn) mn = v;
                if (v > mx) mx = v;
            }
            m_jitterMs = mx - mn;
            m_healthState = (ms < 150) ? 1 : 2;
        } else {
            m_latencyMs = -1;
            m_healthState = 2;
        }
        emit healthChanged();
    };

    connect(sock, &QTcpSocket::connected, this, [finish, timer]() {
        finish(static_cast<int>(timer->elapsed()));
    });
    connect(sock, &QAbstractSocket::errorOccurred, this, [finish]() {
        finish(-1);
    });
    QTimer::singleShot(2500, this, [finish]() {
        finish(-1);
    });

    sock->connectToHost(host, 443);
}
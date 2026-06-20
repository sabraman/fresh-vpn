#include "serverLatencyController.h"

#include <QTcpSocket>
#include <QElapsedTimer>
#include <QTimer>
#include <QSharedPointer>

ServerLatencyController::ServerLatencyController(ServersModel* serversModel, QObject* parent)
    : QObject(parent), m_serversModel(serversModel)
{
}

void ServerLatencyController::measureAll()
{
    if (!m_serversModel) {
        return;
    }

    const int rows = m_serversModel->rowCount();
    for (int i = 0; i < rows; ++i) {
        const QString serverId = m_serversModel->data(i, ServersModel::ServerIdRole).toString();
        const QString host = m_serversModel->data(i, ServersModel::HostNameRole).toString();
        if (serverId.isEmpty() || host.isEmpty()) {
            continue;
        }
        m_latency[serverId] = -3; // measuring
        emit latencyChanged(serverId, -3);
        measureOne(serverId, host, 443);
    }
}

void ServerLatencyController::measureOne(const QString& serverId, const QString& host, quint16 port)
{
    QTcpSocket* sock = new QTcpSocket(this);
    auto timer = QSharedPointer<QElapsedTimer>::create();
    auto done = QSharedPointer<bool>::create(false);
    timer->start();
    m_pending++;

    auto finish = [this, sock, timer, done, serverId](int ms) {
        if (*done) {
            return;
        }
        *done = true;
        m_latency[serverId] = ms;
        emit latencyChanged(serverId, ms);
        if (--m_pending <= 0) {
            emit measurementFinished();
        }
        sock->deleteLater();
    };

    connect(sock, &QTcpSocket::connected, this, [finish, timer]() {
        finish(static_cast<int>(timer->elapsed()));
    });
    connect(sock, &QAbstractSocket::errorOccurred, this, [finish]() {
        finish(-2);
    });
    QTimer::singleShot(3000, this, [finish]() {
        finish(-2);
    });

    sock->connectToHost(host, port);
}

int ServerLatencyController::latencyFor(const QString& serverId) const
{
    return m_latency.value(serverId, -1);
}

int ServerLatencyController::bestLatency() const
{
    int best = -1;
    for (auto it = m_latency.constBegin(); it != m_latency.constEnd(); ++it) {
        if (it.value() > 0 && (best < 0 || it.value() < best)) {
            best = it.value();
        }
    }
    return best;
}

QString ServerLatencyController::bestServerId() const
{
    QString bestId;
    int best = -1;
    for (auto it = m_latency.constBegin(); it != m_latency.constEnd(); ++it) {
        if (it.value() > 0 && (best < 0 || it.value() < best)) {
            best = it.value();
            bestId = it.key();
        }
    }
    return bestId;
}
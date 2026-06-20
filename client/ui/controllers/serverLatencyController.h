#ifndef SERVERLATENCYCONTROLLER_H
#define SERVERLATENCYCONTROLLER_H

#include <QObject>
#include <QHash>
#include <QString>

#include "ui/models/serversModel.h"

class ServerLatencyController : public QObject
{
    Q_OBJECT
public:
    explicit ServerLatencyController(ServersModel* serversModel, QObject* parent = nullptr);

public slots:
    void measureAll();
    int latencyFor(const QString& serverId) const;
    QString bestServerId() const;
    int bestLatency() const;

signals:
    void latencyChanged(const QString& serverId, int ms);
    void measurementFinished();

private:
    void measureOne(const QString& serverId, const QString& host, quint16 port);

    ServersModel* m_serversModel;
    QHash<QString, int> m_latency;
    int m_pending = 0;
};

#endif // SERVERLATENCYCONTROLLER_H
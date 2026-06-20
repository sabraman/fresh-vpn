#ifndef CONNECTIONHEALTHCONTROLLER_H
#define CONNECTIONHEALTHCONTROLLER_H

#include <QObject>
#include <QTimer>
#include <QVector>
#include <QString>

#include "core/controllers/connectionController.h"
#include "ui/models/serversModel.h"

class ConnectionHealthController : public QObject
{
    Q_OBJECT
public:
    Q_PROPERTY(int latencyMs READ latencyMs NOTIFY healthChanged)
    Q_PROPERTY(int jitterMs READ jitterMs NOTIFY healthChanged)
    Q_PROPERTY(int healthState READ healthState NOTIFY healthChanged)

    ConnectionHealthController(ConnectionController* connectionController, ServersModel* serversModel, QObject* parent = nullptr);

    int latencyMs() const;
    int jitterMs() const;
    int healthState() const;

signals:
    void healthChanged();

private slots:
    void onConnectionStateChanged();
    void onTick();

private:
    void measure();
    QString currentHost() const;

    ConnectionController* m_connectionController;
    ServersModel* m_serversModel;
    QTimer m_timer;
    QVector<int> m_samples;
    int m_latencyMs = -1;
    int m_jitterMs = -1;
    int m_healthState = 0;
};

#endif // CONNECTIONHEALTHCONTROLLER_H
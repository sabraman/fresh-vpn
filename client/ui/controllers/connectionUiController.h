#ifndef CONNECTIONUICONTROLLER_H
#define CONNECTIONUICONTROLLER_H

#include <QObject>
#include <QElapsedTimer>

#include "core/controllers/connectionController.h"
#include "core/utils/errorCodes.h"
#include "core/utils/routeModes.h"
#include "core/utils/commonStructs.h"
#include "core/protocols/vpnProtocol.h"
#include "core/controllers/serversController.h"

class ConnectionUiController : public QObject
{
    Q_OBJECT

public:
    Q_PROPERTY(bool isConnected READ isConnected NOTIFY connectionStateChanged)
    Q_PROPERTY(bool isConnectionInProgress READ isConnectionInProgress NOTIFY connectionStateChanged)
    Q_PROPERTY(QString connectionStateText READ connectionStateText NOTIFY connectionStateChanged)
    Q_PROPERTY(double rxSpeedMbps READ rxSpeedMbps NOTIFY trafficChanged)
    Q_PROPERTY(double txSpeedMbps READ txSpeedMbps NOTIFY trafficChanged)
    Q_PROPERTY(double rxTotalBytes READ rxTotalBytes NOTIFY trafficChanged)
    Q_PROPERTY(double txTotalBytes READ txTotalBytes NOTIFY trafficChanged)

    explicit ConnectionUiController(ConnectionController* connectionController,
                                    ServersController* serversController,
                                    QObject *parent = nullptr);

    ~ConnectionUiController() = default;

    bool isConnected() const;
    bool isConnectionInProgress() const;
    QString connectionStateText() const;
    double rxSpeedMbps() const;
    double txSpeedMbps() const;
    double rxTotalBytes() const;
    double txTotalBytes() const;

public slots:
    void toggleConnection();

    void openConnection();
    void closeConnection();

    bool isRevokeBlockedDuringActiveConnection(const QString &serverId, int containerIndex, const QString &clientId) const;

    ErrorCode getLastConnectionError();
    void onConnectionStateChanged(Vpn::ConnectionState state);
    void onBytesChanged(quint64 receivedBytes, quint64 sentBytes);

    void onTranslationsUpdated();

signals:
    void connectionStateChanged();
    void trafficChanged();

    void connectionErrorOccurred(ErrorCode errorCode);

    void connectButtonClicked();
    void preparingConfig();
    void prepareConfig();
    void unsupportedConnectDrawerRequested();
    void noInstalledContainers();

private:
    Vpn::ConnectionState getCurrentConnectionState();
    void notifyConnectionBlocked(ErrorCode errorCode);

    ConnectionController* m_connectionController;
    ServersController* m_serversController;

    bool m_isConnected = false;
    bool m_isConnectionInProgress = false;
    QString m_connectionStateText = tr("Connect");

    Vpn::ConnectionState m_state;

    double m_rxSpeedMbps = 0.0;
    double m_txSpeedMbps = 0.0;
    quint64 m_sessionRx = 0;
    quint64 m_sessionTx = 0;
    QElapsedTimer m_speedTimer;
};

#endif

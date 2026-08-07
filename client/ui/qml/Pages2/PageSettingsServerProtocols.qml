import QtQuick
import QtQuick.Controls
import QtQuick.Layouts

import SortFilterProxyModel 0.2

import PageEnum 1.0
import ContainerProps 1.0
import ContainersModelFilters 1.0
import Style 1.0

import "./"
import "../Controls2"
import "../Controls2/TextTypes"
import "../Config"
import "../Components"

PageType {
    id: root

    property var installedProtocolsCount

    readonly property bool isApi: ServersUiController.isServerFromApi(ServersUiController.processedServerId)
    property bool vlessActive: true

    function refreshProto() {
        root.vlessActive = SubscriptionUiController.isVlessProtocol(ServersUiController.processedServerId)
    }
    Component.onCompleted: refreshProto()
    Connections {
        target: ApiAccountInfoModel
        function onModelReset() { root.refreshProto() }
    }
    Connections {
        target: ServersUiController
        function onProcessedServerIdChanged() { root.refreshProto() }
    }

    // Applies the gateway protocol switch. Assumes a clean network path (VPN off),
    // otherwise a stuck tunnel routes the request into itself and it times out.
    function applyProtoSwitch(useVless) {
        var prevVless = root.vlessActive
        if (SubscriptionUiController.updateServiceFromGateway(ServersUiController.processedServerId, "", "", true)) {
            ServersUiController.updateModel()
            root.vlessActive = useVless
        } else {
            SubscriptionUiController.setCurrentProtocol(ServersUiController.processedServerId, prevVless ? "vless" : "awg")
            root.vlessActive = prevVless
            PageController.showNotificationMessage(qsTr("Failed to switch protocol. Disconnect from VPN and try again."))
        }
        PageController.showBusyIndicator(false)
    }

    Timer {
        id: switchTimer
        interval: 1600; repeat: false
        property bool useVless: true
        property bool reconnectAfter: false
        onTriggered: {
            root.applyProtoSwitch(switchTimer.useVless)
            if (switchTimer.reconnectAfter)
                ConnectionController.reconnect()
        }
    }

    function switchProto(useVless) {
        var wasConnected = ConnectionController.isConnected || ConnectionController.isConnectionInProgress
        PageController.showBusyIndicator(true)
        SubscriptionUiController.setCurrentProtocol(ServersUiController.processedServerId, useVless ? "vless" : "awg")
        if (wasConnected) {
            // Disconnect first so the gateway request goes over a clean path, then reconnect on the new protocol.
            ConnectionController.closeConnection()
            switchTimer.useVless = useVless
            switchTimer.reconnectAfter = true
            switchTimer.restart()
        } else {
            root.applyProtoSwitch(useVless)
        }
    }
    function confirmProto(useVless) {
        if (useVless === root.vlessActive)
            return
        showQuestionDrawer(qsTr("Change the connection protocol?"),
            qsTr("The connection will be reconfigured to %1. If the current protocol works unstably on the network, another one often works better. The active connection may briefly drop.").arg(useVless ? "XRay (VLESS)" : "AmneziaWG"),
            qsTr("Switch"), qsTr("Cancel"),
            function() { root.switchProto(useVless) }, function() {})
    }

    function resetView() {
        settingsContainersListView.positionViewAtBeginning()
    }

    Column {
        id: protoBox
        visible: root.isApi
        anchors.top: parent.top
        anchors.left: parent.left
        anchors.right: parent.right
        anchors.topMargin: 14
        anchors.leftMargin: 16
        anchors.rightMargin: 16
        spacing: 8

        Text {
            text: qsTr("Connection protocol")
            color: AmneziaStyle.fresh.dim
            font.pixelSize: 12; font.weight: 700
        }
        Row {
            width: parent.width
            spacing: 10
            Repeater {
                model: [ { nm: "AmneziaWG", vless: false }, { nm: "XRay (REALITY)", vless: true } ]
                delegate: Rectangle {
                    property bool sel: modelData.vless === root.vlessActive
                    width: (protoBox.width - 10) / 2
                    height: 62
                    radius: 12
                    color: sel ? Qt.rgba(184/255,230/255,65/255,0.12) : AmneziaStyle.fresh.bg2
                    border.color: sel ? AmneziaStyle.fresh.limeStrong : AmneziaStyle.fresh.line
                    border.width: sel ? 2 : 1
                    Column {
                        anchors.centerIn: parent
                        width: parent.width - 16
                        spacing: 2
                        Text {
                            width: parent.width; horizontalAlignment: Text.AlignHCenter; elide: Text.ElideRight
                            text: modelData.nm
                            color: sel ? AmneziaStyle.fresh.limeStrong : AmneziaStyle.fresh.fg
                            font.pixelSize: 14; font.weight: 800
                        }
                        Text {
                            width: parent.width; horizontalAlignment: Text.AlignHCenter
                            text: sel ? qsTr("Active") : qsTr("Enable")
                            color: AmneziaStyle.fresh.mute
                            font.pixelSize: 11
                        }
                    }
                    MouseArea {
                        anchors.fill: parent
                        cursorShape: Qt.PointingHandCursor
                        onClicked: root.confirmProto(modelData.vless)
                    }
                }
            }
        }
        Text {
            width: parent.width
            wrapMode: Text.WordWrap
            text: qsTr("Protocols available for this subscription. If one doesn't work, switch to another.")
            color: AmneziaStyle.fresh.dim
            font.pixelSize: 11
        }
    }

    SettingsContainersListView {
        id: settingsContainersListView

        anchors.top: root.isApi ? protoBox.bottom : parent.top
        anchors.topMargin: root.isApi ? 16 : 0
        anchors.left: parent.left
        anchors.right: parent.right
        anchors.bottom: parent.bottom

        Connections {
            target: ServersUiController

            function onProcessedServerIdChanged() {
                settingsContainersListView.updateContainersModelFilters()
            }
        }

        function updateContainersModelFilters() {
            if (ServersUiController.isProcessedServerHasWriteAccess()) {
                proxyContainersModel.filters = ContainersModelFilters.getWriteAccessProtocolsListFilters()
            } else {
                proxyContainersModel.filters = ContainersModelFilters.getReadAccessProtocolsListFilters()
            }
            root.installedProtocolsCount = proxyContainersModel.count
        }

        model: SortFilterProxyModel {
            id: proxyContainersModel
            sourceModel: ContainersModel
            sorters: [
                RoleSorter { roleName: "isInstalled"; sortOrder: Qt.DescendingOrder },
                RoleSorter { roleName: "installPageOrder"; sortOrder: Qt.AscendingOrder }
            ]
        }

        Component.onCompleted: {
            settingsContainersListView.isFocusable = true
            settingsContainersListView.interactive = true
            updateContainersModelFilters()
        }
    }
}
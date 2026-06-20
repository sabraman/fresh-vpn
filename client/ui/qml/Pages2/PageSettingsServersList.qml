import QtQuick
import QtQuick.Controls
import QtQuick.Layouts

import SortFilterProxyModel 0.2

import PageEnum 1.0
import ContainerProps 1.0
import Style 1.0

import "./"
import "../Controls2"
import "../Controls2/TextTypes"
import "../Config"
import "../Components"

PageType {
    id: root

    function latColor(ms){
        if(ms < 0) return "#878B91"
        if(ms < 100) return "#C8F050"
        if(ms < 250) return "#FBB26A"
        return "#E5484D"
    }
    function latText(ms){
        if(ms === -3) return "•••"
        if(ms < 0) return "—"
        return ms + " мс"
    }

    Component.onCompleted: ServerLatencyController.measureAll()

    Connections {
        target: ServerLatencyController
        function onMeasurementFinished(){
            var ms = ServerLatencyController.bestLatency()
            if(ms > 0){
                PageController.showNotificationMessage(qsTr("Быстрейший сервер: ") + ms + qsTr(" мс"))
            }
        }
    }

    ColumnLayout {
        id: header

        anchors.top: parent.top
        anchors.left: parent.left
        anchors.right: parent.right

        anchors.topMargin: 20 + PageController.safeAreaTopMargin

        BackButtonType {
            id: backButton
        }

        BaseHeaderType {
            Layout.fillWidth: true
            Layout.leftMargin: 16
            Layout.rightMargin: 16

            headerText: qsTr("Servers")
        }

        BasicButtonType {
            id: autoButton
            Layout.fillWidth: true
            Layout.topMargin: 10
            Layout.leftMargin: 16
            Layout.rightMargin: 16
            implicitHeight: 40

            defaultColor: "#C8F050"
            hoveredColor: "#D4F571"
            pressedColor: "#9FC72E"
            textColor: "#0E0E11"

            text: qsTr("Авто — выбрать быстрейший")

            clickedFunc: function() {
                ServerLatencyController.measureAll()
                PageController.showNotificationMessage(qsTr("Замеряю пинг серверов…"))
            }
        }
    }

    ListViewType {
        id: servers
        objectName: "servers"

        width: parent.width
        anchors.top: header.bottom
        anchors.topMargin: 16
        anchors.bottom: parent.bottom
        anchors.left: parent.left
        anchors.right: parent.right

        model: ServersModel

        delegate: Item {
            id: delegateItem
            implicitWidth: servers.width
            implicitHeight: delegateContent.implicitHeight

            property int lat: ServerLatencyController.latencyFor(serverId)

            Connections {
                target: ServerLatencyController
                function onLatencyChanged(sid, ms){
                    if(sid === serverId) delegateItem.lat = ms
                }
            }

            ColumnLayout {
                id: delegateContent

                anchors.top: parent.top
                anchors.left: parent.left
                anchors.right: parent.right

                LabelWithButtonType {
                    id: server
                    Layout.fillWidth: true

                    text: name

                    descriptionText: {
                        var servicesNameString = ""
                        var servicesName = ServersUiController.getAllInstalledServicesName(index)
                        for (var i = 0; i < servicesName.length; i++) {
                            servicesNameString += servicesName[i] + " · "
                        }

                        if (ServersUiController.isServerFromApi(serverId)) {
                            return servicesNameString + serverDescription
                        } else {
                            return servicesNameString + hostName
                        }
                    }
                    rightImageSource: "qrc:/images/controls/chevron-right.svg"

                    clickedFunction: function() {
                        ServersUiController.setProcessedServerId(serverId)

                        if (ServersUiController.isServerFromApi(ServersUiController.processedServerId)) {
                            PageController.showBusyIndicator(true)
                            let result = SubscriptionUiController.getAccountInfo(ServersUiController.processedServerId, false)
                            PageController.showBusyIndicator(false)
                            if (!result) {
                                return
                            }

                            PageController.goToPage(PageEnum.PageSettingsApiServerInfo)
                        } else {
                            PageController.goToPage(PageEnum.PageSettingsServerInfo)
                        }
                    }
                }

                DividerType {}
            }

            Rectangle {
                anchors.right: delegateContent.right
                anchors.rightMargin: 46
                anchors.verticalCenter: delegateContent.verticalCenter
                height: 22
                width: latBadge.implicitWidth + 18
                radius: 11
                color: Qt.rgba(1,1,1,0.05)
                border.width: 1
                border.color: Qt.rgba(1,1,1,0.09)

                Text {
                    id: latBadge
                    anchors.centerIn: parent
                    text: root.latText(delegateItem.lat)
                    color: root.latColor(delegateItem.lat)
                    font.pixelSize: 12
                    font.weight: 700
                }
            }
        }
    }
}
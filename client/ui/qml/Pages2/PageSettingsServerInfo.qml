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

    readonly property int pageSettingsServerProtocols: 0
    readonly property int pageSettingsServerServices: 1
    readonly property int pageSettingsServerData: 2
    readonly property int pageSettingsServerAdvanced: 3

    property var processedServer

    function cleanName(s) {
        var raw = "" + s
        try { raw = decodeURIComponent(raw) } catch (e) {}
        while (raw.length >= 2 && raw.charCodeAt(0) === 0xD83C && raw.charCodeAt(1) >= 0xDDE6 && raw.charCodeAt(1) <= 0xDDFF) { raw = raw.substring(2) }
        var cut = raw.indexOf("|") >= 0 ? raw.substring(0, raw.indexOf("|")) : raw
        if (cut.length > 3 && cut[0] >= "A" && cut[0] <= "Z" && cut[1] >= "A" && cut[1] <= "Z" && cut[2] === " ")
            cut = cut.substring(3)
        cut = cut.split("  ").join(" ").split("  ").join(" ").trim()
        return cut.length > 0 ? cut : ("" + s)
    }

    Connections {
        target: PageController

        function onGoToPageSettingsServerServices() {
            tabBar.setCurrentIndex(root.pageSettingsServerServices)
        }
    }

    Connections {
        target: ServersUiController

        function onProcessedServerIdChanged() {
            root.processedServer = proxyServersModel.get(0)
        }
    }

    Connections {
        target: ServersModel

        function onModelReset() {
            root.processedServer = proxyServersModel.get(0)
        }
    }

    SortFilterProxyModel {
        id: proxyServersModel
        objectName: "proxyServersModel"

        sourceModel: ServersModel
        filters: [
            ValueFilter {
                roleName: "serverId"
                value: ServersUiController.processedServerId
            }
        ]

        Component.onCompleted: {
            root.processedServer = proxyServersModel.get(0)
        }
    }

    ColumnLayout {
        objectName: "mainLayout"

        anchors.fill: parent
        anchors.topMargin: 20 + PageController.safeAreaTopMargin

        spacing: 4

        BackButtonType {
            id: backButton
            objectName: "backButton"
        }

        HeaderTypeWithButton {
            id: headerContent
            objectName: "headerContent"

            Layout.fillWidth: true
            Layout.leftMargin: 16
            Layout.rightMargin: 16
            Layout.bottomMargin: 10

            actionButtonImage: ""  // Fresh: rename via click on the name (below), no separate pencil

            headerText: root.processedServer != null ? cleanName(root.processedServer.name) : ""
            descriptionText: {
                if (root.processedServer == null) {
                    return ""
                }
                if (ServersUiController.isServerFromApi(ServersUiController.processedServerId)) {
                    return root.processedServer.serverDescription
                } else if (ServersUiController.isProcessedServerHasWriteAccess()) {
                    return root.processedServer.credentialsLogin + " · " + root.processedServer.hostName
                } else {
                    return root.processedServer.hostName
                }
            }

            actionButtonFunction: function() {
                serverNameEditDrawer.openTriggered()
            }

            // Fresh: rename by clicking the server name itself (hover shows it is editable)
            MouseArea {
                anchors.fill: parent
                hoverEnabled: true
                cursorShape: Qt.PointingHandCursor
                onClicked: serverNameEditDrawer.openTriggered()
            }
        }

        RenameServerDrawer {
            id: serverNameEditDrawer

            parent: root

            anchors.fill: parent
            expandedHeight: root.height * 0.35

            serverNameText: root.processedServer != null ? root.processedServer.name : ""
        }

        TabBar {
            id: tabBar

            Layout.fillWidth: true

            currentIndex: (ServersUiController.isServerFromApi(ServersUiController.processedServerId)
                           && !ServersUiController.serverHasInstalledContainers(ServersUiController.processedServerId)) ?
                              root.pageSettingsServerData : root.pageSettingsServerProtocols

            background: Rectangle {
                color: AmneziaStyle.color.transparent
            }


            TabButtonType {
                id: protocolsTab
                visible: protocolsPage.installedProtocolsCount
                width: protocolsPage.installedProtocolsCount ? undefined : 0
                isSelected: TabBar.tabBar.currentIndex === root.pageSettingsServerProtocols
                text: qsTr("Protocols")

                Keys.onReturnPressed: TabBar.tabBar.setCurrentIndex(root.pageSettingsServerProtocols)
                Keys.onEnterPressed: TabBar.tabBar.setCurrentIndex(root.pageSettingsServerProtocols)
            }

            TabButtonType {
                id: servicesTab
                visible: servicesPage.installedServicesCount
                width: servicesPage.installedServicesCount ? undefined : 0
                isSelected: TabBar.tabBar.currentIndex === root.pageSettingsServerServices
                text: qsTr("Services")

                Keys.onReturnPressed: TabBar.tabBar.setCurrentIndex(root.pageSettingsServerServices)
                Keys.onEnterPressed: TabBar.tabBar.setCurrentIndex(root.pageSettingsServerServices)
            }

            TabButtonType {
                id: dataTab
                isSelected: tabBar.currentIndex === root.pageSettingsServerData
                text: qsTr("Management")

                Keys.onReturnPressed: TabBar.tabBar.setCurrentIndex(root.pageSettingsServerData)
                Keys.onEnterPressed: TabBar.tabBar.setCurrentIndex(root.pageSettingsServerData)
            }

            TabButtonType {
                id: advancedTab
                isSelected: tabBar.currentIndex === root.pageSettingsServerAdvanced
                text: qsTr("Advanced")

                Keys.onReturnPressed: TabBar.tabBar.setCurrentIndex(root.pageSettingsServerAdvanced)
                Keys.onEnterPressed: TabBar.tabBar.setCurrentIndex(root.pageSettingsServerAdvanced)
            }
        }

        StackLayout {
            id: nestedStackView

            Layout.fillWidth: true

            currentIndex: tabBar.currentIndex

            PageSettingsServerProtocols {
                id: protocolsPage
                stackView: root.stackView
            }

            PageSettingsServerServices {
                id: servicesPage
                stackView: root.stackView
            }

            PageSettingsServerData {
                id: dataPage
                stackView: root.stackView
            }

            PageSettingsServerAdvanced {
                id: advancedPage
                stackView: root.stackView
            }
        }
    }
}

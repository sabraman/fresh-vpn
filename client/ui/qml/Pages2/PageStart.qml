import QtQuick
import QtQuick.Controls
import QtQuick.Layouts
import QtQuick.Shapes

import PageEnum 1.0
import Style 1.0

import "./"
import "../Controls2"
import "../Controls2/TextTypes"
import "../Config"
import "../Components"

PageType {
    id: root

    property bool isControlsDisabled: false
    property bool isTabBarDisabled: false

    Connections {
        objectName: "pageControllerConnection"

        target: PageController

        function onGoToPageHome() {
            if (PageController.isStartPageVisible()) {
                tabBar.visible = false
                tabBarStackView.goToTabBarPage(PageEnum.PageSetupWizardStart)
            } else {
                tabBar.visible = true
                tabBar.setCurrentIndex(0)
                tabBarStackView.goToTabBarPage(PageEnum.PageHome)
            }
        }

        function onGoToPageSettings() {
            tabBar.setCurrentIndex(2)
            tabBarStackView.goToTabBarPage(PageEnum.PageSettings)
        }

        function onGoToPageViewConfig() {
            var pagePath = PageController.getPagePath(PageEnum.PageSetupWizardViewConfig)
            tabBarStackView.push(pagePath, { "objectName" : pagePath }, StackView.PushTransition)
        }

        function onGoToShareConnectionPage(headerText, configContentHeaderText, configCaption, configExtension, configFileName) {
            var pagePath = PageController.getPagePath(PageEnum.PageShareConnection)
            tabBarStackView.push(pagePath,
                                 { "objectName" : pagePath,
                                     "headerText" : headerText,
                                     "configContentHeaderText" : configContentHeaderText,
                                     "configCaption" : configCaption,
                                     "configExtension" : configExtension,
                                     "configFileName" : configFileName
                                 },
                                 StackView.PushTransition)
        }

        function onDisableControls(disabled) {
            isControlsDisabled = disabled
        }

        function onDisableTabBar(disabled) {
            isTabBarDisabled = disabled
        }

        function onClosePage() {
            if (tabBarStackView.depth <= 1) {
                PageController.hideWindow()
                return
            }
            tabBarStackView.pop()
        }

        function onGoToPage(page, slide) {
            var pagePath = PageController.getPagePath(page)

            if (slide) {
                tabBarStackView.push(pagePath, { "objectName" : pagePath }, StackView.PushTransition)
            } else {
                tabBarStackView.push(pagePath, { "objectName" : pagePath }, StackView.Immediate)
            }
        }

        function onGoToStartPage() {
            while (tabBarStackView.depth > 1) {
                tabBarStackView.pop()
            }
        }

        function onEscapePressed() {
            if (root.isControlsDisabled || root.isTabBarDisabled) {
                return
            }

            var pageName = tabBarStackView.currentItem.objectName
            if ((pageName === PageController.getPagePath(PageEnum.PageShare)) ||
                    (pageName === PageController.getPagePath(PageEnum.PageSettings)) ||
                    (pageName === PageController.getPagePath(PageEnum.PageSetupWizardConfigSource))) {
                PageController.goToPageHome()
            } else {
                PageController.closePage()
            }
        }
    }

    Connections {
        objectName: "connectionControllerConnections"

        target: ConnectionController

        function onNoInstalledContainers() {
            PageController.setTriggeredByConnectButton(true)

            ServersUiController.setProcessedServerId(ServersUiController.defaultServerId)
            PageController.goToPage(PageEnum.PageSetupWizardEasy)
        }
    }

    Connections {
        objectName: "installControllerConnections"

        target: InstallController

        function onInstallationErrorOccurred(error) {
            PageController.showBusyIndicator(false)

            PageController.showErrorMessage(error)

            var needCloseCurrentPage = false
            var currentPageName = tabBarStackView.currentItem.objectName

            if (currentPageName === PageController.getPagePath(PageEnum.PageSetupWizardInstalling)) {
                needCloseCurrentPage = true
            } else if (currentPageName === PageController.getPagePath(PageEnum.PageDeinstalling)) {
                needCloseCurrentPage = true
            }
            if (needCloseCurrentPage) {
                PageController.closePage()
            }
        }

        function onWrongInstallationUser(message) {
            onInstallationErrorOccurred(message)
        }

        function onUpdateContainerFinished(message, closePage) {
            PageController.showNotificationMessage(message)
            if (closePage) {
                PageController.closePage()
            }
        }

        function onCachedProfileCleared(message) {
            PageController.showNotificationMessage(message)
        }

        function onRemoveServerFinished(finishedMessage) {
            if (!ServersUiController.getServersCount()) {
                PageController.goToPageHome()
            } else {
                PageController.goToStartPage()
                PageController.goToPage(PageEnum.PageSettingsServersList)
            }
            PageController.showNotificationMessage(finishedMessage)
        }

        function onRemoveAllContainersFinished(finishedMessage) {
            if (tabBarStackView.currentItem.objectName === PageController.getPagePath(PageEnum.PageDeinstalling)) {
                PageController.closePage()
            }
            PageController.showNotificationMessage(finishedMessage)
        }

        function onRemoveContainerFinished(finishedMessage) {
            if (tabBarStackView.currentItem.objectName === PageController.getPagePath(PageEnum.PageDeinstalling)) {
                PageController.closePage()
            }
            PageController.closePage()
            PageController.showNotificationMessage(finishedMessage)
        }
    }

    Connections {
        objectName: "importControllerConnections"

        target: ImportController

        function onImportErrorOccurred(error, goToPageHome) {
            PageController.showErrorMessage(error)
        }

        function onRestoreAppConfig(data) {
            PageController.showBusyIndicator(true)
            SettingsController.restoreAppConfigFromData(data)
            PageController.showBusyIndicator(false)
        }
    }

    Connections {
        objectName: "settingsControllerConnections"

        target: SettingsController

        function onLoggingDisableByWatcher() {
            PageController.showNotificationMessage(qsTr("Logging was disabled after 14 days, log files were deleted"))
        }

        function onRestoreBackupFinished() {
            PageController.showNotificationMessage(qsTr("Settings restored from backup file"))
            PageController.goToPageHome()
        }

        function onLoggingStateChanged() {
            if (SettingsController.isLoggingEnabled) {
                var message = qsTr("Logging is enabled. Note that logs will be automatically" +
                                   "disabled after 14 days, and all log files will be deleted.")
                PageController.showNotificationMessage(message)
            }
        }
    }

    Connections {
        target: SubscriptionUiController

        function onErrorOccurred(error) {
            PageController.showErrorMessage(error)
        }
    }

    Connections {
        target: SubscriptionUiController

        function onApiConfigRemoved(message) {
            PageController.showNotificationMessage(message)
        }

        function onApiServerRemoved(message) {
            if (!ServersUiController.getServersCount()) {
                PageController.goToPageHome()
            } else {
                PageController.goToStartPage()
                PageController.goToPage(PageEnum.PageSettingsServersList)
            }
            PageController.showNotificationMessage(message)
        }

        function onInstallServerFromApiFinished(message, preferredDefaultIndex) {
            PageController.goToPageHome()
            PageController.showNotificationMessage(message)
        }

        function onChangeApiCountryFinished(message) {
            PageController.goToPageHome()
            PageController.showNotificationMessage(message)
        }

        function onReloadServerFromApiFinished(message) {
            PageController.goToPageHome()
            PageController.showNotificationMessage(message)
        }
    }

    StackViewType {
        id: tabBarStackView
        objectName: "tabBarStackView"

        anchors.top: parent.top
        anchors.right: parent.right
        anchors.left: parent.left
        anchors.bottom: tabBar.top

        enabled: !root.isControlsDisabled

        function goToTabBarPage(page) {
            var pagePath = PageController.getPagePath(page)
            tabBarStackView.clear(StackView.Immediate)
            tabBarStackView.replace(pagePath, { "objectName" : pagePath }, StackView.Immediate)
        }

        Component.onCompleted: {
            var pagePath
            if (PageController.isStartPageVisible()) {
                tabBar.visible = false
                pagePath = PageController.getPagePath(PageEnum.PageSetupWizardStart)
            } else {
                tabBar.visible = true
                pagePath = PageController.getPagePath(PageEnum.PageHome)
                ServersUiController.setProcessedServerId(ServersUiController.defaultServerId)
            }

            tabBarStackView.push(pagePath, { "objectName" : pagePath })
        }

        Keys.onPressed: function(event) {
            switch (event.key) {
            case Qt.Key_Tab:
            case Qt.Key_Down:
            case Qt.Key_Right:
                FocusController.nextKeyTabItem()
                break
            case Qt.Key_Backtab:
            case Qt.Key_Up:
            case Qt.Key_Left:
                FocusController.previousKeyTabItem()
                break
            default:
                PageController.keyPressEvent(event.key)
                event.accepted = true
            }
        }
    }

    Item {
        id: tabBar
        objectName: "tabBar"

        anchors.right: parent.right
        anchors.left: parent.left
        anchors.bottom: parent.bottom
        anchors.bottomMargin: PageController.imeHeight

        property int currentIndex: 0
        function setCurrentIndex(i) { currentIndex = i }

        enabled: !root.isControlsDisabled && !root.isTabBarDisabled
        height: visible ? 60 + PageController.safeAreaBottomMargin : 0

        function navTo(i) {
            tabBar.currentIndex = i
            if (i === 0) {
                tabBarStackView.goToTabBarPage(PageEnum.PageHome)
                ServersUiController.setProcessedServerId(ServersUiController.defaultServerId)
            } else if (i === 1) {
                tabBarStackView.goToTabBarPage(PageEnum.PageSettingsServersList)
            } else if (i === 2) {
                tabBarStackView.goToTabBarPage(PageEnum.PageStatistics)
            } else if (i === 3) {
                ServersUiController.setProcessedServerId(ServersUiController.defaultServerId)
                tabBarStackView.goToTabBarPage(PageEnum.PageProfile)
            }
        }

        Rectangle {
            anchors.fill: parent
            color: AmneziaStyle.color.onyxBlack
            Rectangle { width: parent.width; height: 1; color: Qt.rgba(1,1,1,0.06); anchors.top: parent.top }
        }

        Row {
            anchors.top: parent.top
            anchors.topMargin: 8
            anchors.left: parent.left
            anchors.right: parent.right
            height: 52

            Repeater {
                model: [
                    { lbl: qsTr("Главная"),    t: "house" },
                    { lbl: qsTr("Серверы"),    t: "globe" },
                    { lbl: qsTr("Статистика"), t: "chart" },
                    { lbl: qsTr("Профиль"),    t: "user" }
                ]
                delegate: Item {
                    width: tabBar.width / 4
                    height: 52
                    property bool sel: tabBar.currentIndex === index
                    property color c: sel ? AmneziaStyle.color.goldenApricotStrong : AmneziaStyle.color.mutedGray

                    Rectangle {
                        visible: parent.sel
                        width: 20; height: 3; radius: 2
                        color: AmneziaStyle.color.goldenApricotStrong
                        anchors.horizontalCenter: parent.horizontalCenter
                        y: 0
                    }

                    Canvas {
                        width: 24; height: 24
                        anchors.horizontalCenter: parent.horizontalCenter
                        y: 6
                        property color col: parent.c
                        property string tp: modelData.t
                        onColChanged: requestPaint()
                        onPaint: {
                            var c = getContext("2d"); c.reset()
                            c.strokeStyle = col; c.fillStyle = col; c.lineWidth = 1.8; c.lineCap = "round"; c.lineJoin = "round"
                            if (tp === "house") { c.beginPath(); c.moveTo(12,3); c.lineTo(21,11); c.lineTo(19,11); c.lineTo(19,21); c.lineTo(5,21); c.lineTo(5,11); c.lineTo(3,11); c.closePath(); c.stroke() }
                            else if (tp === "globe") { c.beginPath(); c.arc(12,12,9,0,2*Math.PI); c.stroke(); c.beginPath(); c.moveTo(3,12); c.lineTo(21,12); c.stroke(); c.beginPath(); c.moveTo(12,3); c.bezierCurveTo(6,7,6,17,12,21); c.stroke(); c.beginPath(); c.moveTo(12,3); c.bezierCurveTo(18,7,18,17,12,21); c.stroke() }
                            else if (tp === "chart") { c.beginPath(); c.moveTo(4,4); c.lineTo(4,20); c.lineTo(21,20); c.stroke(); c.beginPath(); c.moveTo(7,15); c.lineTo(11,10); c.lineTo(14,13); c.lineTo(20,6); c.stroke() }
                            else if (tp === "user") { c.beginPath(); c.arc(12,12,9,0,2*Math.PI); c.stroke(); c.beginPath(); c.arc(12,10,3.2,0,2*Math.PI); c.stroke(); c.beginPath(); c.arc(12,21,6,Math.PI*1.15,Math.PI*1.85,false); c.stroke() }
                        }
                    }

                    Text {
                        text: modelData.lbl
                        color: parent.c
                        font.pixelSize: 10
                        font.weight: parent.sel ? 700 : 600
                        anchors.horizontalCenter: parent.horizontalCenter
                        y: 33
                    }

                    MouseArea {
                        anchors.fill: parent
                        cursorShape: Qt.PointingHandCursor
                        onClicked: tabBar.navTo(index)
                    }
                }
            }
        }
    }
}

import QtQuick
import QtQuick.Controls
import QtQuick.Layouts

import SortFilterProxyModel 0.2

import PageEnum 1.0
import Style 1.0

import "./"
import "../Controls2"
import "../Config"
import "../Components"

PageType {
    id: root

    property color bg: AmneziaStyle.fresh.bg
    property color card: AmneziaStyle.fresh.card
    property color bg2: AmneziaStyle.fresh.bg2
    property color line: AmneziaStyle.fresh.line
    property color fg: AmneziaStyle.fresh.fg
    property color mute: AmneziaStyle.fresh.mute
    property color dim: AmneziaStyle.fresh.dim
    property color limeStrong: AmneziaStyle.fresh.limeStrong
    property color warn: AmneziaStyle.fresh.warn
    property color danger: AmneziaStyle.fresh.danger

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

    property var processedServer

    property bool isSubscriptionExpired: false
    property bool isSubscriptionExpiringSoon: false
    property bool isSubscriptionRenewalAvailable: false
    property bool isInAppPurchase: false
    property bool vlessActive: false
    property bool protoSelectable: false
    property bool amneziaFree: false
    property string svcDesc: ""

    readonly property bool protoSwitchBlocked: ServersUiController.isDefaultServerCurrentlyProcessed() && ConnectionController.isConnected

    function updateSubscriptionState() {
        root.isSubscriptionExpired = ApiAccountInfoModel.data("isSubscriptionExpired")
        root.isSubscriptionExpiringSoon = ApiAccountInfoModel.data("isSubscriptionExpiringSoon")
        root.isSubscriptionRenewalAvailable = ApiAccountInfoModel.data("isSubscriptionRenewalAvailable")
        root.isInAppPurchase = ApiAccountInfoModel.data("isInAppPurchase")
        root.protoSelectable = ApiAccountInfoModel.data("isProtocolSelectionSupported")
        root.amneziaFree = ApiAccountInfoModel.data("isComponentVisible")
        root.svcDesc = ApiAccountInfoModel.data("serviceDescription")
        root.vlessActive = SubscriptionUiController.isVlessProtocol(ServersUiController.processedServerId)
    }

    function setProtocol(useVless) {
        if (root.protoSwitchBlocked) {
            PageController.showNotificationMessage(qsTr("Cannot change protocol during active connection"))
            return
        }
        PageController.showBusyIndicator(true)
        SubscriptionUiController.setCurrentProtocol(ServersUiController.processedServerId, useVless ? "vless" : "awg")
        SubscriptionUiController.updateServiceFromGateway(ServersUiController.processedServerId, "", "", true)
        ServersUiController.updateModel()
        root.vlessActive = useVless
        PageController.showBusyIndicator(false)
    }

    function confirmSetProtocol(useVless) {
        if (useVless === root.vlessActive)
            return
        showQuestionDrawer(
            qsTr("Change connection protocol?"),
            qsTr("The connection will be reconfigured to %1. If the current protocol works unstably on your network, another one often gives a better connection. The active connection may briefly drop.").arg(useVless ? "VLESS" : "AmneziaWG"),
            qsTr("Switch"),
            qsTr("Cancel"),
            function() { root.setProtocol(useVless) },
            function() {}
        )
    }

    Component.onCompleted: root.updateSubscriptionState()

    Connections {
        target: ApiAccountInfoModel
        function onModelReset() { root.updateSubscriptionState() }
    }
    Connections {
        target: ServersUiController
        function onProcessedServerIdChanged() {
            root.processedServer = proxyServersModel.get(0)
            root.updateSubscriptionState()
        }
    }
    Connections {
        target: ServersModel
        function onModelReset() { root.processedServer = proxyServersModel.get(0) }
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
        Component.onCompleted: root.processedServer = proxyServersModel.get(0)
    }

    Rectangle { anchors.fill: parent; color: root.bg }

    component NavRow: Rectangle {
        property string nm: ""
        property string ds: ""
        property color tint: root.fg
        signal activated()
        width: parent ? parent.width : 0
        height: 60; radius: 14; color: root.card; border.color: root.line; border.width: 1
        Row {
            anchors.left: parent.left; anchors.leftMargin: 16; anchors.right: parent.right; anchors.rightMargin: 14
            anchors.verticalCenter: parent.verticalCenter; spacing: 12
            Column {
                width: parent.width - 24; anchors.verticalCenter: parent.verticalCenter; spacing: 2
                Text { width: parent.width; elide: Text.ElideRight; text: nm; color: tint; font.pixelSize: 14; font.weight: 600 }
                Text { width: parent.width; elide: Text.ElideRight; text: ds; color: root.mute; font.pixelSize: 12; visible: ds.length > 0 }
            }
            Image { source: "qrc:/images/controls/chevron-right.svg"; width: 18; height: 18; opacity: 0.5; anchors.verticalCenter: parent.verticalCenter }
        }
        MouseArea { anchors.fill: parent; cursorShape: Qt.PointingHandCursor; onClicked: activated() }
    }

    BackButtonType {
        id: backButton
        objectName: "backButton"
        anchors.top: parent.top
        anchors.left: parent.left
        anchors.right: parent.right
        anchors.topMargin: 16 + PageController.safeAreaTopMargin
        z: 50
    }

    Flickable {
        anchors.top: backButton.bottom
        anchors.left: parent.left
        anchors.right: parent.right
        anchors.bottom: parent.bottom
        anchors.topMargin: 6
        contentHeight: wrap.height + 40
        clip: true
        boundsBehavior: Flickable.StopAtBounds

        Item {
            id: wrap
            width: Math.min(640, root.width - 56)
            x: (root.width - width) / 2
            height: col.implicitHeight

            Column {
                id: col
                width: parent.width
                spacing: 16

                Item {
                    width: parent.width
                    height: Math.max(nameCol.implicitHeight, 40)
                    Column {
                        id: nameCol
                        anchors.left: parent.left; anchors.right: editBtn.left; anchors.rightMargin: 12
                        anchors.verticalCenter: parent.verticalCenter; spacing: 4
                        Text {
                            width: parent.width; elide: Text.ElideRight
                            text: root.processedServer != null ? cleanName(root.processedServer.name) : ""
                            color: root.fg; font.pixelSize: 26; font.weight: 800
                        }
                        Text {
                            width: parent.width; wrapMode: Text.WordWrap
                            visible: root.svcDesc !== ""
                            text: root.svcDesc
                            color: root.mute; font.pixelSize: 13
                        }
                    }
                    Rectangle {
                        id: editBtn
                        width: 36; height: 36; radius: 10
                        anchors.right: parent.right; anchors.top: parent.top
                        color: edM.containsMouse ? root.card : "transparent"
                        border.color: root.line; border.width: 1
                        Image { anchors.centerIn: parent; width: 18; height: 18; source: "qrc:/images/controls/edit-3.svg"; opacity: 0.75 }
                        MouseArea { id: edM; anchors.fill: parent; hoverEnabled: true; cursorShape: Qt.PointingHandCursor; onClicked: serverNameEditDrawer.openTriggered() }
                    }
                }

                Rectangle {
                    width: parent.width
                    visible: root.isSubscriptionExpired || root.isSubscriptionExpiringSoon
                    radius: 14; color: root.card
                    border.color: root.isSubscriptionExpired ? root.danger : root.warn; border.width: 1
                    height: expCol.implicitHeight + 28
                    Column {
                        id: expCol
                        anchors.left: parent.left; anchors.right: parent.right; anchors.margins: 16
                        anchors.verticalCenter: parent.verticalCenter; spacing: 10
                        Text {
                            width: parent.width; wrapMode: Text.WordWrap
                            text: root.isSubscriptionExpired ? qsTr("Subscription expired") : qsTr("Subscription expiring soon")
                            color: root.isSubscriptionExpired ? root.danger : root.warn; font.pixelSize: 14; font.weight: 700
                        }
                        Rectangle {
                            visible: root.isSubscriptionRenewalAvailable && !root.isInAppPurchase
                            width: parent.width; height: 42; radius: 11; color: root.limeStrong
                            Text { anchors.centerIn: parent; text: qsTr("Renew subscription"); color: "#0E0E11"; font.pixelSize: 14; font.weight: 700 }
                            MouseArea { anchors.fill: parent; cursorShape: Qt.PointingHandCursor; onClicked: SubscriptionUiController.getRenewalLink(ServersUiController.processedServerId) }
                        }
                    }
                }

                Column {
                    width: parent.width; spacing: 10
                    Text { text: qsTr("SUBSCRIPTION"); color: root.dim; font.pixelSize: 11; font.weight: 800; leftPadding: 4 }
                    Rectangle {
                        width: parent.width; radius: 14; color: root.card; border.color: root.line; border.width: 1
                        height: stCol.implicitHeight + 24
                        Column {
                            id: stCol
                            anchors.left: parent.left; anchors.right: parent.right; anchors.margins: 16
                            anchors.verticalCenter: parent.verticalCenter; spacing: 12
                            Repeater {
                                model: [
                                    { l: qsTr("Subscription Status"), k: "subscriptionStatus", rich: true },
                                    { l: qsTr("Valid Until"), k: "endDate", rich: false },
                                    { l: qsTr("Active Connections"), k: "connectedDevices", rich: false }
                                ]
                                delegate: RowLayout {
                                    width: stCol.width
                                    spacing: 10
                                    property string val: ApiAccountInfoModel.data(modelData.k)
                                    Connections {
                                        target: ApiAccountInfoModel
                                        function onModelReset() { val = ApiAccountInfoModel.data(modelData.k) }
                                    }
                                    visible: val !== ""
                                    Text { text: modelData.l; color: root.mute; font.pixelSize: 13; Layout.fillWidth: true }
                                    Text {
                                        text: val
                                        textFormat: modelData.rich ? Text.RichText : Text.PlainText
                                        color: root.fg; font.pixelSize: 13; font.weight: 600
                                        horizontalAlignment: Text.AlignRight
                                    }
                                }
                            }
                        }
                    }
                }

                Column {
                    width: parent.width; spacing: 10
                    visible: root.protoSelectable
                    Text { text: qsTr("CONNECTION PROTOCOL"); color: root.dim; font.pixelSize: 11; font.weight: 800; leftPadding: 4 }
                    Rectangle {
                        width: parent.width; radius: 16; color: root.card; border.color: root.line; border.width: 1
                        height: pCol.implicitHeight + 28
                        opacity: root.protoSwitchBlocked ? 0.5 : 1.0
                        Column {
                            id: pCol
                            anchors.left: parent.left; anchors.right: parent.right; anchors.margins: 14
                            anchors.verticalCenter: parent.verticalCenter; spacing: 12
                            Row {
                                width: parent.width; spacing: 10
                                Repeater {
                                    model: [ { nm: "AmneziaWG", vless: false }, { nm: "VLESS", vless: true } ]
                                    delegate: Rectangle {
                                        property bool sel: modelData.vless === root.vlessActive
                                        width: (pCol.width - 10) / 2; height: 64; radius: 12
                                        color: sel ? Qt.rgba(184/255,230/255,65/255,0.12) : root.bg2
                                        border.color: sel ? root.limeStrong : root.line; border.width: sel ? 2 : 1
                                        Column {
                                            anchors.centerIn: parent; spacing: 3; width: parent.width - 20
                                            Text { width: parent.width; horizontalAlignment: Text.AlignHCenter; text: modelData.nm; color: sel ? root.limeStrong : root.fg; font.pixelSize: 15; font.weight: 800 }
                                            Text { width: parent.width; horizontalAlignment: Text.AlignHCenter; text: sel ? qsTr("Active") : qsTr("Tap to switch"); color: root.mute; font.pixelSize: 11; wrapMode: Text.WordWrap }
                                        }
                                        MouseArea { anchors.fill: parent; enabled: !root.protoSwitchBlocked; cursorShape: Qt.PointingHandCursor; onClicked: root.confirmSetProtocol(modelData.vless) }
                                    }
                                }
                            }
                            Text {
                                width: parent.width; wrapMode: Text.WordWrap
                                text: root.protoSwitchBlocked
                                    ? qsTr("Disconnect the VPN to change the protocol.")
                                    : qsTr("If the current protocol works unstably on your network, switch to another.")
                                color: root.dim; font.pixelSize: 11
                            }
                        }
                    }
                }

                Rectangle {
                    width: parent.width
                    visible: {
                        var n = ApiCountryModel.count
                        for (var i = 0; i < n; ++i) {
                            if (ApiCountryModel.get(i).isWorkerExpired)
                                return true
                        }
                        return false
                    }
                    radius: 14; color: Qt.rgba(230/255,160/255,60/255,0.12); border.color: root.warn; border.width: 1
                    height: wTxt.implicitHeight + 28
                    Text {
                        id: wTxt
                        anchors.left: parent.left; anchors.right: parent.right; anchors.margins: 16
                        anchors.verticalCenter: parent.verticalCenter; wrapMode: Text.WordWrap
                        text: qsTr("Configurations have been updated for some countries. Download and install the updated configuration files")
                        color: root.warn; font.pixelSize: 12
                    }
                }

                Column {
                    width: parent.width; spacing: 10
                    visible: root.amneziaFree
                    Text { text: qsTr("MANAGEMENT"); color: root.dim; font.pixelSize: 11; font.weight: 800; leftPadding: 4 }
                    NavRow {
                        nm: qsTr("Subscription Key")
                        onActivated: {
                            PageController.goToPage(PageEnum.PageSettingsApiSubscriptionKey)
                            PageController.showBusyIndicator(true)
                            SubscriptionUiController.prepareVpnKeyExport(ServersUiController.processedServerId)
                            PageController.showBusyIndicator(false)
                        }
                    }
                    NavRow {
                        nm: qsTr("Configuration Files")
                        ds: qsTr("Manage configuration files")
                        onActivated: {
                            SubscriptionUiController.updateApiCountryModel()
                            PageController.goToPage(PageEnum.PageSettingsApiNativeConfigs)
                        }
                    }
                    NavRow {
                        nm: qsTr("Active Devices")
                        ds: qsTr("Manage currently connected devices")
                        onActivated: {
                            SubscriptionUiController.updateApiDevicesModel()
                            PageController.goToPage(PageEnum.PageSettingsApiDevices)
                        }
                    }
                }

                Column {
                    width: parent.width; spacing: 10
                    Text { text: qsTr("HELP"); color: root.dim; font.pixelSize: 11; font.weight: 800; leftPadding: 4 }
                    NavRow {
                        nm: qsTr("Support")
                        onActivated: PageController.goToPage(PageEnum.PageSettingsApiSupport)
                    }
                    NavRow {
                        visible: root.amneziaFree
                        nm: qsTr("How to connect on another device")
                        onActivated: PageController.goToPage(PageEnum.PageSettingsApiInstructions)
                    }
                }

                Column {
                    width: parent.width; spacing: 10
                    Text { text: qsTr("ACTIONS"); color: root.dim; font.pixelSize: 11; font.weight: 800; leftPadding: 4 }
                    NavRow {
                        nm: qsTr("Reload API config")
                        tint: root.danger
                        onActivated: {
                            showQuestionDrawer(qsTr("Reload API config?"), "", qsTr("Continue"), qsTr("Cancel"),
                                function() {
                                    if (root.protoSwitchBlocked) {
                                        PageController.showNotificationMessage(qsTr("Cannot reload API config during active connection"))
                                    } else {
                                        PageController.showBusyIndicator(true)
                                        SubscriptionUiController.updateServiceFromGateway(ServersUiController.processedServerId, "", "", true)
                                        PageController.showBusyIndicator(false)
                                    }
                                }, function() {})
                        }
                    }
                    NavRow {
                        visible: root.amneziaFree
                        nm: qsTr("Unlink this device")
                        tint: root.danger
                        onActivated: {
                            showQuestionDrawer(qsTr("Are you sure you want to unlink this device?"),
                                qsTr("This will unlink the device from your subscription. You can reconnect it anytime by pressing \"Reload API config\" in subscription settings on device."),
                                qsTr("Continue"), qsTr("Cancel"),
                                function() {
                                    if (root.protoSwitchBlocked) {
                                        PageController.showNotificationMessage(qsTr("Cannot unlink device during active connection"))
                                    } else {
                                        PageController.showBusyIndicator(true)
                                        if (SubscriptionUiController.deactivateDevice(ServersUiController.processedServerId)) {
                                            SubscriptionUiController.getAccountInfo(ServersUiController.processedServerId, true)
                                        }
                                        PageController.showBusyIndicator(false)
                                    }
                                }, function() {})
                        }
                    }
                    NavRow {
                        nm: qsTr("Remove from application")
                        tint: root.danger
                        onActivated: {
                            showQuestionDrawer(qsTr("Remove from application?"), "", qsTr("Continue"), qsTr("Cancel"),
                                function() {
                                    if (root.protoSwitchBlocked) {
                                        PageController.showNotificationMessage(qsTr("Cannot remove server during active connection"))
                                    } else {
                                        PageController.showBusyIndicator(true)
                                        SubscriptionUiController.removeServer(ServersUiController.processedServerId)
                                        PageController.showBusyIndicator(false)
                                    }
                                }, function() {})
                        }
                    }
                }

                Item { width: 1; height: 8 }
            }
        }
    }

    RenameServerDrawer {
        id: serverNameEditDrawer
        anchors.fill: parent
        expandedHeight: parent.height * 0.35
        serverNameText: root.processedServer != null ? root.processedServer.name : ""
    }

    Item {
        id: themeToggleBtn
        width: 36; height: 36; z: 200
        anchors.top: parent.top; anchors.right: parent.right
        anchors.topMargin: 14 + PageController.safeAreaTopMargin
        anchors.rightMargin: 16
        Rectangle { anchors.fill: parent; radius: 10; color: thM.containsMouse ? root.card : "transparent"; border.color: root.line; border.width: 1 }
        Canvas {
            id: thIcon
            anchors.centerIn: parent; width: 20; height: 20
            property bool dark: AmneziaStyle.isDark
            property color col: root.fg
            onDarkChanged: requestPaint()
            onColChanged: requestPaint()
            onPaint: {
                var c = getContext("2d"); c.reset(); c.clearRect(0,0,width,height)
                c.strokeStyle = col; c.fillStyle = col; c.lineWidth = 1.6; c.lineCap = "round"; c.lineJoin = "round"
                var cx = 10, cy = 10
                if (dark) {
                    c.beginPath(); c.arc(cx, cy, 6.4, 0, 2*Math.PI); c.fill()
                    c.globalCompositeOperation = "destination-out"
                    c.beginPath(); c.arc(cx + 3.6, cy - 2.2, 6.0, 0, 2*Math.PI); c.fill()
                    c.globalCompositeOperation = "source-over"
                } else {
                    c.beginPath(); c.arc(cx, cy, 3.4, 0, 2*Math.PI); c.fill()
                    for (var i = 0; i < 8; i++) {
                        var a = i*Math.PI/4
                        c.beginPath()
                        c.moveTo(cx + Math.cos(a)*5.6, cy + Math.sin(a)*5.6)
                        c.lineTo(cx + Math.cos(a)*8.0, cy + Math.sin(a)*8.0)
                        c.stroke()
                    }
                }
            }
        }
        MouseArea {
            id: thM
            anchors.fill: parent; hoverEnabled: true; cursorShape: Qt.PointingHandCursor
            onClicked: AmneziaStyle.isDark = !AmneziaStyle.isDark
        }
    }
}
import QtQuick
import QtQuick.Controls
import QtQuick.Layouts

import PageEnum 1.0
import Style 1.0

import "./"
import "../Controls2"
import "../Config"
import "../Components"

PageType {
    id: root

    property color bg: AmneziaStyle.fresh.bg; property color card: AmneziaStyle.fresh.card; property color line: AmneziaStyle.fresh.line
    property color fg: AmneziaStyle.fresh.fg; property color mute: AmneziaStyle.fresh.mute; property color dim: AmneziaStyle.fresh.dim
    property color lime: AmneziaStyle.fresh.lime; property color limeStrong: AmneziaStyle.fresh.limeStrong
    property color limeSoft: AmneziaStyle.fresh.limeSoft; property color limeLine: AmneziaStyle.fresh.limeLine
    property color bg3: AmneziaStyle.fresh.bg3; property color danger: AmneziaStyle.fresh.danger

    property bool maskOn: false
    property bool autoPickOn: true
    property bool autoConnectOn: false
    property bool newsOn: false
    property bool autoUpdateOn: false
    Component.onCompleted: {
        autoConnectOn = SettingsController.isAutoConnectEnabled()
        newsOn = SettingsController.isNewsNotificationsEnabled()
        autoUpdateOn = SettingsController.isAutoUpdateEnabled()
    }

    function goP(p) { PageController.goToPage(p) }

    Rectangle { anchors.fill: parent; color: root.bg }

    component ToggleRow: Rectangle {
        property string nm: ""
        property string ds: ""
        property bool on: false
        property bool rowEnabled: true
        signal switched()
        width: parent ? parent.width : 0
        height: Math.max(66, rowTxt.implicitHeight + 28)
        radius: 14; color: root.card; border.color: root.line; border.width: 1
        opacity: rowEnabled ? 1.0 : 0.45
        Row {
            anchors.left: parent.left; anchors.right: parent.right
            anchors.leftMargin: 16; anchors.rightMargin: 16
            anchors.verticalCenter: parent.verticalCenter; spacing: 12
            Column {
                id: rowTxt
                width: parent.width - 46 - 12
                anchors.verticalCenter: parent.verticalCenter; spacing: 3
                Text { width: parent.width; elide: Text.ElideRight; text: nm; color: root.fg; font.pixelSize: 14; font.weight: 700 }
                Text { width: parent.width; wrapMode: Text.WordWrap; text: ds; color: root.mute; font.pixelSize: 12 }
            }
            Rectangle {
                width: 46; height: 26; radius: 13; anchors.verticalCenter: parent.verticalCenter
                color: on ? root.limeStrong : Qt.rgba(1,1,1,0.12)
                Behavior on color { ColorAnimation { duration: 150 } }
                Rectangle { width: 20; height: 20; radius: 10; y: 3; color: "#FFFFFF"; x: on ? 23 : 3
                    Behavior on x { NumberAnimation { duration: 160; easing.type: Easing.OutCubic } } }
            }
        }
        MouseArea { anchors.fill: parent; enabled: rowEnabled; cursorShape: rowEnabled ? Qt.PointingHandCursor : Qt.ArrowCursor; onClicked: switched() }
    }

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

    Flickable {
        anchors.fill: parent
        anchors.topMargin: 18 + PageController.safeAreaTopMargin
        id: flk
        contentHeight: wrap.phone ? Math.max(flk.height, col.implicitHeight * wrap.k + 8) : (wrap.height + 40)
        clip: true
        boundsBehavior: Flickable.StopAtBounds

        Item {
            id: wrap
            property bool phone: Qt.platform.os === "android" || Qt.platform.os === "ios"
            property real avail: flk.height - 24
            property real k: (phone && col.implicitHeight > avail && col.implicitHeight > 0) ? Math.max(0.80, avail / col.implicitHeight) : 1.0
            width: Math.min(640, root.width - 56)
            x: (root.width - width) / 2
            y: phone ? Math.max(0, (flk.height - col.implicitHeight * k) / 2 - 6) : 0
            height: col.implicitHeight
            scale: k
            transformOrigin: Item.Top

            Column {
                id: col
                width: parent.width
                spacing: 16

                Column {
                    width: parent.width; spacing: 4
                    Text { text: qsTr("Settings"); color: root.fg; font.pixelSize: 26; font.weight: 800 }
                    Text { text: qsTr("Application and account settings"); color: root.mute; font.pixelSize: 13 }
                }

                Column {
                    width: parent.width; spacing: 10
                    visible: !GC.isMobile() || ServersUiController.hasServersFromGatewayApi
                    Text { text: qsTr("APPLICATION"); color: root.dim; font.pixelSize: 11; font.weight: 800; leftPadding: 4 }
                    ToggleRow {
                        visible: !GC.isMobile()
                        nm: qsTr("Autostart")
                        ds: qsTr("Launch Fresh VPN when the computer starts")
                        on: SettingsController.autoStartEnabled
                        onSwitched: SettingsController.toggleAutoStart(!SettingsController.autoStartEnabled)
                    }
                    ToggleRow {
                        visible: !GC.isMobile()
                        nm: qsTr("Start minimized")
                        ds: qsTr("Open in the tray without a window (autostart required)")
                        rowEnabled: SettingsController.autoStartEnabled
                        on: SettingsController.autoStartEnabled && SettingsController.startMinimized
                        onSwitched: SettingsController.toggleStartMinimized(!SettingsController.startMinimized)
                    }
                    ToggleRow {
                        visible: ServersUiController.hasServersFromGatewayApi
                        nm: qsTr("News notifications")
                        ds: qsTr("Badge for unread service news")
                        on: root.newsOn
                        onSwitched: { root.newsOn = !root.newsOn; SettingsController.toggleNewsNotificationsEnabled(root.newsOn) }
                    }
                }
                Column {
                    width: parent.width; spacing: 10
                    Text { text: qsTr("CONNECTION & PROTECTION"); color: root.dim; font.pixelSize: 11; font.weight: 800; leftPadding: 4 }
                    NavRow {
                        nm: qsTr("Ad & tracker blocking")
                        ds: qsTr("DNS filtering of ads and trackers")
                        onActivated: root.goP(PageEnum.PageSettingsDns)
                    }
                    NavRow {
                        nm: qsTr("Russian services direct")
                        ds: qsTr("Route RU services outside the VPN tunnel")
                        onActivated: root.goP(PageEnum.PageSettingsSplitTunneling)
                    }
                }

                Column {
                    width: parent.width; spacing: 10
                    Text { text: qsTr("OTHER"); color: root.dim; font.pixelSize: 11; font.weight: 800; leftPadding: 4 }
                    NavRow {
                        nm: qsTr("Language")
                        ds: LanguageUiController.currentLanguageName
                        onActivated: selectLanguageDrawer.openTriggered()
                    }
                    NavRow {
                        nm: qsTr("Event log")
                        ds: SettingsController.isLoggingEnabled ? qsTr("Enabled") : qsTr("Disabled")
                        onActivated: root.goP(PageEnum.PageSettingsLogging)
                    }
                    NavRow {
                        nm: qsTr("Reset settings")
                        ds: qsTr("Reset to defaults, subscription is kept")
                        tint: root.danger
                        onActivated: {
                            var h = qsTr("Reset all settings to default?")
                            var d = qsTr("All settings will return to their default values. Your subscription and connected servers will be kept.")
                            var yes = qsTr("Continue")
                            var no = qsTr("Cancel")
                            var yesFn = function() {
                                if (ServersUiController.isDefaultServerCurrentlyProcessed() && ConnectionController.isConnected) {
                                    PageController.showNotificationMessage(qsTr("Cannot reset settings during active connection"))
                                } else {
                                    SettingsController.resetSettingsKeepServers()
                                    PageController.goToPageHome()
                                }
                            }
                            var noFn = function() {}
                            showQuestionDrawer(h, d, yes, no, yesFn, noFn)
                        }
                    }
                }

                Column {
                    width: parent.width; spacing: 10
                    Text { text: qsTr("ABOUT"); color: root.dim; font.pixelSize: 11; font.weight: 800; leftPadding: 4 }
                    ToggleRow {
                        nm: qsTr("Auto-update")
                        ds: qsTr("Install new versions automatically on launch")
                        on: root.autoUpdateOn
                        onSwitched: { root.autoUpdateOn = !root.autoUpdateOn; SettingsController.setAutoUpdateEnabled(root.autoUpdateOn) }
                    }
                    NavRow {
                        nm: qsTr("Check for updates")
                        ds: qsTr("Look for a new version now")
                        onActivated: {
                            PageController.showNotificationMessage(qsTr("Checking for updates..."))
                            UpdateController.checkForUpdates()
                        }
                    }
                    NavRow {
                        nm: qsTr("About")
                        ds: qsTr("Version %1").arg(SettingsController.getAppVersion())
                        onActivated: root.goP(PageEnum.PageSettingsAbout)
                    }
                }
                Item { width: 1; height: 8 }
            }
        }
    }

    SelectLanguageDrawer {
        id: selectLanguageDrawer
        width: root.width
        height: root.height
    }

    // ===== Theme toggle (day/night) =====
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

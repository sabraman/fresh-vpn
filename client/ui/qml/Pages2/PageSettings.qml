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

    property color bg: "#0E0E11"; property color card: "#16171A"; property color line: Qt.rgba(1,1,1,0.08)
    property color fg: "#F5F4EF"; property color mute: "#878B91"; property color dim: "#5A5D63"
    property color lime: "#B8E641"; property color limeStrong: "#C8F050"
    property color limeSoft: Qt.rgba(184/255,230/255,65/255,0.10); property color limeLine: Qt.rgba(184/255,230/255,65/255,0.30)
    property color bg3: "#25262B"; property color danger: "#E5715A"

    property bool maskOn: false
    property bool autoPickOn: true
    property bool autoConnectOn: false
    property bool newsOn: false
    Component.onCompleted: {
        autoConnectOn = SettingsController.isAutoConnectEnabled()
        newsOn = SettingsController.isNewsNotificationsEnabled()
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

                Column {
                    width: parent.width; spacing: 4
                    Text { text: "Настройки"; color: root.fg; font.pixelSize: 26; font.weight: 800 }
                    Text { text: "Главные переключатели под рукой"; color: root.mute; font.pixelSize: 13 }
                }

                Grid {
                    id: grid
                    width: parent.width
                    columns: 2
                    rowSpacing: 12; columnSpacing: 12
                    property real cw: (width - 12) / 2

                    Repeater {
                        model: [
                            { ic: "shield",  nm: "Аварийный стоп",     ds: "Обрыв VPN — интернет сразу блокируется", kind: "ks" },
                            { ic: "refresh", nm: "Авто-подключение",   ds: "VPN включается сам при запуске",         kind: "ac" },
                            { ic: "mask",    nm: "Маскировка трафика",  ds: "Прячет VPN под обычный трафик",          kind: "mask" },
                            { ic: "server",  nm: "Авто-выбор сервера",  ds: "Сам подбирает самый быстрый узел",       kind: "auto" }
                        ]
                        delegate: Rectangle {
                            id: tg
                            width: grid.cw; height: 104; radius: 16
                            property bool on: modelData.kind === "ks"   ? SettingsController.isKillSwitchEnabled
                                            : modelData.kind === "ac"   ? root.autoConnectOn
                                            : modelData.kind === "mask" ? root.maskOn
                                            : root.autoPickOn
                            color: root.card
                            border.color: root.line; border.width: 1
                            scale: tgM.pressed ? 0.985 : 1.0
                            Behavior on scale { NumberAnimation { duration: 90 } }

                            Row {
                                anchors.fill: parent; anchors.leftMargin: 16; anchors.rightMargin: 16
                                spacing: 12
                                Rectangle {
                                    width: 38; height: 38; radius: 11; anchors.verticalCenter: parent.verticalCenter
                                    color: tg.on ? Qt.rgba(184/255,230/255,65/255,0.14) : Qt.rgba(1,1,1,0.05)
                                    Canvas {
                                        anchors.centerIn: parent; width: 22; height: 22
                                        property color col: tg.on ? root.limeStrong : root.mute
                                        property string ic: modelData.ic
                                        onColChanged: requestPaint()
                                        onPaint: {
                                            var c = getContext("2d"); c.reset()
                                            c.strokeStyle = col; c.fillStyle = col; c.lineWidth = 1.8; c.lineCap = "round"; c.lineJoin = "round"
                                            if (ic === "shield") { c.beginPath(); c.moveTo(11,2); c.lineTo(19,5); c.lineTo(19,11); c.bezierCurveTo(19,17,15,20,11,21); c.bezierCurveTo(7,20,3,17,3,11); c.lineTo(3,5); c.closePath(); c.stroke() }
                                            else if (ic === "refresh") { c.beginPath(); c.arc(11,11,7,0.6,2*Math.PI); c.stroke(); c.beginPath(); c.moveTo(17,4); c.lineTo(18.5,8.5); c.lineTo(14,8); c.stroke() }
                                            else if (ic === "mask") { c.beginPath(); c.moveTo(3,7); c.lineTo(19,7); c.stroke(); c.beginPath(); c.moveTo(3,11); c.lineTo(19,11); c.stroke(); c.beginPath(); c.moveTo(3,15); c.lineTo(13,15); c.stroke() }
                                            else { c.strokeRect(4,3,14,6); c.strokeRect(4,13,14,6); c.beginPath(); c.arc(8,6,0.6,0,2*Math.PI); c.fill(); c.beginPath(); c.arc(8,16,0.6,0,2*Math.PI); c.fill() }
                                        }
                                    }
                                }
                                Column {
                                    width: parent.width - 38 - 46 - 24; anchors.verticalCenter: parent.verticalCenter; spacing: 3
                                    Text { width: parent.width; elide: Text.ElideRight; text: modelData.nm; color: root.fg; font.pixelSize: 14; font.weight: 700 }
                                    Text { width: parent.width; wrapMode: Text.WordWrap; maximumLineCount: 2; elide: Text.ElideRight; text: modelData.ds; color: root.mute; font.pixelSize: 11 }
                                }
                                Rectangle {
                                    width: 46; height: 26; radius: 13; anchors.verticalCenter: parent.verticalCenter
                                    color: tg.on ? root.limeStrong : Qt.rgba(1,1,1,0.12)
                                    Behavior on color { ColorAnimation { duration: 150 } }
                                    Rectangle { width: 20; height: 20; radius: 10; y: 3; color: "#FFFFFF"; x: tg.on ? 23 : 3
                                        Behavior on x { NumberAnimation { duration: 160; easing.type: Easing.OutCubic } } }
                                }
                            }
                            MouseArea {
                                id: tgM; anchors.fill: parent; cursorShape: Qt.PointingHandCursor
                                onClicked: {
                                    if (modelData.kind === "ks") SettingsController.isKillSwitchEnabled = !SettingsController.isKillSwitchEnabled
                                    else if (modelData.kind === "ac") { root.autoConnectOn = !root.autoConnectOn; SettingsController.toggleAutoConnect(root.autoConnectOn) }
                                    else if (modelData.kind === "mask") root.maskOn = !root.maskOn
                                    else root.autoPickOn = !root.autoPickOn
                                }
                            }
                        }
                    }
                }

                Column {
                    width: parent.width; spacing: 10
                    visible: !GC.isMobile() || ServersUiController.hasServersFromGatewayApi
                    Text { text: "ПРИЛОЖЕНИЕ"; color: root.dim; font.pixelSize: 11; font.weight: 800; leftPadding: 4 }
                    ToggleRow {
                        visible: !GC.isMobile()
                        nm: "Автозапуск"
                        ds: "Запускать Fresh VPN при включении компьютера"
                        on: SettingsController.autoStartEnabled
                        onSwitched: SettingsController.toggleAutoStart(!SettingsController.autoStartEnabled)
                    }
                    ToggleRow {
                        visible: !GC.isMobile()
                        nm: "Запуск свёрнутым"
                        ds: "Открываться в трее без окна (нужен автозапуск)"
                        rowEnabled: SettingsController.autoStartEnabled
                        on: SettingsController.autoStartEnabled && SettingsController.startMinimized
                        onSwitched: SettingsController.toggleStartMinimized(!SettingsController.startMinimized)
                    }
                    ToggleRow {
                        visible: ServersUiController.hasServersFromGatewayApi
                        nm: "Уведомления о новостях"
                        ds: "Значок при непрочитанных новостях сервиса"
                        on: root.newsOn
                        onSwitched: { root.newsOn = !root.newsOn; SettingsController.toggleNewsNotificationsEnabled(root.newsOn) }
                    }
                }

                Column {
                    width: parent.width; spacing: 10
                    Text { text: "ПРОЧЕЕ"; color: root.dim; font.pixelSize: 11; font.weight: 800; leftPadding: 4 }
                    NavRow {
                        nm: "Язык"
                        ds: LanguageUiController.currentLanguageName
                        onActivated: selectLanguageDrawer.openTriggered()
                    }
                    NavRow {
                        nm: "Журнал событий"
                        ds: SettingsController.isLoggingEnabled ? "Включён" : "Выключен"
                        onActivated: root.goP(PageEnum.PageSettingsLogging)
                    }
                    NavRow {
                        nm: "Сбросить настройки"
                        ds: "Удалить все данные приложения"
                        tint: root.danger
                        onActivated: {
                            var h = qsTr("Reset settings and remove all data from the application?")
                            var d = qsTr("All settings will be reset to default. All installed Fresh VPN services will still remain on the server.")
                            var yes = qsTr("Continue")
                            var no = qsTr("Cancel")
                            var yesFn = function() {
                                if (ServersUiController.isDefaultServerCurrentlyProcessed() && ConnectionController.isConnected) {
                                    PageController.showNotificationMessage(qsTr("Cannot reset settings during active connection"))
                                } else {
                                    SettingsController.clearSettings()
                                    PageController.goToPageHome()
                                }
                            }
                            var noFn = function() {}
                            showQuestionDrawer(h, d, yes, no, yesFn, noFn)
                        }
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
}
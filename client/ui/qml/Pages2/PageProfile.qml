import QtQuick
import PageEnum 1.0
import Style 1.0
import "../Controls2"

PageType {
    id: root

    property color bg: AmneziaStyle.fresh.bg; property color card: AmneziaStyle.fresh.card; property color bg3: AmneziaStyle.fresh.bg3
    property color line: AmneziaStyle.fresh.line; property color fg: AmneziaStyle.fresh.fg; property color mute: AmneziaStyle.fresh.mute; property color dim: AmneziaStyle.fresh.dim
    property color lime: AmneziaStyle.fresh.lime; property color limeStrong: AmneziaStyle.fresh.limeStrong
    property color limeSoft: AmneziaStyle.fresh.limeSoft; property color limeLine: AmneziaStyle.fresh.limeLine
    property color ok: AmneziaStyle.fresh.ok

    // ---- visual mockup state (UI only, no billing backend wired yet) ----
    property int selectedPlan: 1
    property bool autopayOn: true
    property var plans: [
        { id: 0, nm: qsTr("1 month"),    price: "299 ₽",   per: qsTr("299 ₽/mo"), save: "" },
        { id: 1, nm: qsTr("12 months"), price: "1 990 ₽", per: qsTr("166 ₽/mo"), save: "−44%" },
        { id: 2, nm: qsTr("24 months"),  price: "2 990 ₽", per: qsTr("125 ₽/mo"), save: "−58%" }
    ]
    property var history: []

    // The OS used to be hardcoded to "Windows", which reads as a plain lie on
    // a phone. Qt.platform.os is the real thing.
    property string thisOsName: {
        switch (Qt.platform.os) {
        case "windows": return "Windows"
        case "android": return "Android"
        case "ios":     return "iOS"
        case "osx":     return "macOS"
        case "linux":   return "Linux"
        default:         return Qt.platform.os
        }
    }

    function goP(p){ PageController.goToPage(p) }
    function stub(){ PageController.showNotificationMessage(qsTr("Payment will be connected on the next step")) }
    function payText(){ return qsTr("Pay · ") + root.plans[root.selectedPlan].price }

    Rectangle { anchors.fill: parent; color: root.bg }

    component IconBox: Rectangle {
        property string tp: "monitor"
        width: 36; height: 36; radius: 10; color: root.bg3
        Canvas {
            anchors.centerIn: parent; width: 20; height: 20
            Component.onCompleted: requestPaint()
            onPaint: {
                var c = getContext("2d"); c.reset()
                c.strokeStyle = "#C8F050"; c.fillStyle = "#C8F050"; c.lineWidth = 1.7; c.lineCap = "round"; c.lineJoin = "round"
                if (tp === "monitor"){ c.strokeRect(2,3,16,11); c.beginPath(); c.moveTo(7,17); c.lineTo(13,17); c.stroke(); c.beginPath(); c.moveTo(10,14); c.lineTo(10,17); c.stroke() }
                else if (tp === "qr"){ c.strokeRect(3,3,5,5); c.strokeRect(12,3,5,5); c.strokeRect(3,12,5,5); c.strokeRect(12,12,2,2); c.strokeRect(15,15,2,2) }
                else { c.beginPath(); c.arc(10,10,8,0,2*Math.PI); c.stroke(); c.beginPath(); c.arc(10,8,2.6,Math.PI*0.9,Math.PI*2.2,false); c.stroke(); c.beginPath(); c.moveTo(10,11); c.lineTo(10,12.5); c.stroke(); c.beginPath(); c.arc(10,15,0.9,0,2*Math.PI); c.fill() }
            }
        }
    }

    component RowCard: Rectangle {
        property string nm: ""
        property string ds: ""
        property string icon: "monitor"
        property bool clickable: true
        signal activated()
        width: parent ? parent.width : 0
        height: 60; radius: 14; color: root.card; border.color: root.line; border.width: 1
        Row {
            anchors.left: parent.left; anchors.leftMargin: 14; anchors.verticalCenter: parent.verticalCenter; spacing: 13
            IconBox { tp: icon; anchors.verticalCenter: parent.verticalCenter }
            Column {
                anchors.verticalCenter: parent.verticalCenter; spacing: 2
                Text { text: nm; color: root.fg; font.pixelSize: 14; font.weight: 600 }
                Text { text: ds; color: root.mute; font.pixelSize: 12 }
            }
        }
        MouseArea { anchors.fill: parent; enabled: clickable; cursorShape: clickable ? Qt.PointingHandCursor : Qt.ArrowCursor; onClicked: activated() }
    }

    Flickable {
        anchors.fill: parent
        anchors.topMargin: 18 + PageController.safeAreaTopMargin
        contentHeight: wrap.height + 40
        clip: true
        boundsBehavior: Flickable.StopAtBounds

        Item {
            id: wrap
            width: Math.min(620, root.width - 56)
            x: (root.width - width) / 2
            height: col.implicitHeight

            Column {
                id: col
                width: parent.width
                spacing: 16

                Column {
                    width: parent.width; spacing: 4
                    Text { text: qsTr("Profile"); color: root.fg; font.pixelSize: 26; font.weight: 800 }
                    Text { text: qsTr("Subscription, payment and devices"); color: root.mute; font.pixelSize: 13 }
                }

                // ===== Subscription hero =====
                Rectangle {
                    width: parent.width; radius: 18; color: root.card; border.color: root.line; border.width: 1
                    height: heroCol.implicitHeight + 40
                    Column {
                        id: heroCol
                        anchors.left: parent.left; anchors.right: parent.right; anchors.top: parent.top
                        anchors.leftMargin: 20; anchors.rightMargin: 20; anchors.topMargin: 20
                        spacing: 10
                        Text { text: "Fresh VPN"; color: root.fg; font.pixelSize: 22; font.weight: 800 }
                        Text { width: parent.width; wrapMode: Text.WordWrap
                               text: qsTr("Choose a plan below to activate or extend your subscription"); color: root.mute; font.pixelSize: 13 }
                        Rectangle { height: 42; radius: 11; width: renT.implicitWidth + 34; color: root.limeStrong
                            Text { id: renT; anchors.centerIn: parent; text: qsTr("Renew"); color: "#0E0E11"; font.pixelSize: 13; font.weight: 800 }
                            MouseArea { anchors.fill: parent; cursorShape: Qt.PointingHandCursor; onClicked: root.stub() } }
                    }
                }

                // ===== Tariffs =====
                Column {
                    width: parent.width; spacing: 10
                    Text { text: qsTr("PLAN"); color: root.dim; font.pixelSize: 11; font.weight: 800; leftPadding: 4 }
                    Grid {
                        id: plansGrid
                        width: parent.width; columns: 3; rowSpacing: 12; columnSpacing: 12
                        property real cw: (width - 24) / 3
                        Repeater {
                            model: root.plans
                            delegate: Rectangle {
                                width: plansGrid.cw; height: 116; radius: 14
                                property bool sel: root.selectedPlan === modelData.id
                                color: sel ? root.limeSoft : root.card
                                border.color: sel ? root.limeLine : root.line; border.width: sel ? 2 : 1
                                Rectangle {
                                    visible: modelData.save.length > 0
                                    anchors.top: parent.top; anchors.right: parent.right; anchors.topMargin: 12; anchors.rightMargin: 12
                                    height: 18; radius: 9; width: svT.implicitWidth + 14; color: root.limeStrong
                                    Text { id: svT; anchors.centerIn: parent; text: modelData.save; color: "#0E0E11"; font.pixelSize: 10; font.weight: 800 }
                                }
                                Column {
                                    anchors.left: parent.left; anchors.right: parent.right; anchors.bottom: parent.bottom
                                    anchors.leftMargin: 14; anchors.rightMargin: 14; anchors.bottomMargin: 14; spacing: 4
                                    Text { width: parent.width; elide: Text.ElideRight; text: modelData.nm; color: root.mute; font.pixelSize: 12; font.weight: 600 }
                                    Text { text: modelData.price; color: sel ? root.limeStrong : root.fg; font.pixelSize: 19; font.weight: 800 }
                                    Text { text: modelData.per; color: root.dim; font.pixelSize: 11 }
                                }
                                MouseArea { anchors.fill: parent; cursorShape: Qt.PointingHandCursor; onClicked: root.selectedPlan = modelData.id }
                            }
                        }
                    }
                }

                // ===== Pay button =====
                Rectangle {
                    width: parent.width; height: 52; radius: 14; color: root.limeStrong
                    scale: payM.pressed ? 0.99 : 1.0
                    Behavior on scale { NumberAnimation { duration: 90 } }
                    Text { anchors.centerIn: parent; text: root.payText(); color: "#0E0E11"; font.pixelSize: 15; font.weight: 800 }
                    MouseArea { id: payM; anchors.fill: parent; cursorShape: Qt.PointingHandCursor; onClicked: root.stub() }
                }

                // ===== Autopay =====
                Rectangle {
                    width: parent.width; height: 66; radius: 14; color: root.card; border.color: root.line; border.width: 1
                    Row {
                        anchors.left: parent.left; anchors.right: parent.right; anchors.leftMargin: 16; anchors.rightMargin: 16
                        anchors.verticalCenter: parent.verticalCenter; spacing: 12
                        Column {
                            width: parent.width - 46 - 12; anchors.verticalCenter: parent.verticalCenter; spacing: 3
                            Text { text: qsTr("Auto-renewal"); color: root.fg; font.pixelSize: 14; font.weight: 700 }
                            Text { width: parent.width; wrapMode: Text.WordWrap; text: qsTr("Renew the subscription automatically before it expires"); color: root.mute; font.pixelSize: 12 }
                        }
                        Rectangle {
                            width: 46; height: 26; radius: 13; anchors.verticalCenter: parent.verticalCenter
                            color: root.autopayOn ? root.limeStrong : Qt.rgba(1,1,1,0.12)
                            Behavior on color { ColorAnimation { duration: 150 } }
                            Rectangle { width: 20; height: 20; radius: 10; y: 3; color: "#FFFFFF"; x: root.autopayOn ? 23 : 3
                                Behavior on x { NumberAnimation { duration: 160; easing.type: Easing.OutCubic } } }
                        }
                    }
                    MouseArea { anchors.fill: parent; cursorShape: Qt.PointingHandCursor; onClicked: root.autopayOn = !root.autopayOn }
                }

                // ===== Payment history =====
                Column {
                    visible: root.history.length > 0
                    width: parent.width; spacing: 10
                    Text { text: qsTr("PAYMENT HISTORY"); color: root.dim; font.pixelSize: 11; font.weight: 800; leftPadding: 4 }
                    Column {
                        width: parent.width; spacing: 8
                        Repeater {
                            model: root.history
                            delegate: Rectangle {
                                width: parent.width; height: 58; radius: 12; color: root.card; border.color: root.line; border.width: 1
                                Row {
                                    anchors.left: parent.left; anchors.right: parent.right; anchors.leftMargin: 16; anchors.rightMargin: 16
                                    anchors.verticalCenter: parent.verticalCenter; spacing: 12
                                    Column {
                                        width: parent.width - 108; anchors.verticalCenter: parent.verticalCenter; spacing: 2
                                        Text { width: parent.width; elide: Text.ElideRight; text: modelData.nm; color: root.fg; font.pixelSize: 13; font.weight: 600 }
                                        Text { text: modelData.d; color: root.mute; font.pixelSize: 11 }
                                    }
                                    Column {
                                        width: 96; anchors.verticalCenter: parent.verticalCenter; spacing: 2
                                        Text { width: parent.width; horizontalAlignment: Text.AlignRight; text: modelData.a; color: root.fg; font.pixelSize: 13; font.weight: 700 }
                                        Text { width: parent.width; horizontalAlignment: Text.AlignRight; text: qsTr("Paid"); color: root.ok; font.pixelSize: 10; font.weight: 700 }
                                    }
                                }
                            }
                        }
                    }
                }

                // ===== Devices =====
                Column {
                    width: parent.width; spacing: 10
                    Text { text: qsTr("DEVICES"); color: root.dim; font.pixelSize: 11; font.weight: 800; leftPadding: 4 }
                    RowCard { nm: qsTr("This device · %1").arg(root.thisOsName); ds: qsTr("connected now"); icon: "monitor"; clickable: false }
                    RowCard { nm: qsTr("Add device"); ds: qsTr("via QR or subscription key"); icon: "qr"; onActivated: root.goP(PageEnum.PageSetupWizardConfigSource) }
                    RowCard { nm: qsTr("Manage servers"); ds: qsTr("node list and settings"); icon: "monitor"; onActivated: root.goP(PageEnum.PageSettingsServersList) }
                    RowCard { nm: qsTr("Support"); ds: qsTr("we will reply in Telegram"); icon: "help"; onActivated: root.goP(PageEnum.PageSettingsApiSupport) }
                }

                Item { width: 1; height: 8 }
            }
        }
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
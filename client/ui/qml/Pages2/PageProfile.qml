import QtQuick
import PageEnum 1.0
import "../Controls2"

PageType {
    id: root

    property color bg: "#0E0E11"; property color card: "#16171A"; property color bg3: "#25262B"
    property color line: Qt.rgba(1,1,1,0.08); property color fg: "#F5F4EF"; property color mute: "#878B91"; property color dim: "#5A5D63"
    property color lime: "#B8E641"; property color limeStrong: "#C8F050"
    property color limeSoft: Qt.rgba(184/255,230/255,65/255,0.10); property color limeLine: Qt.rgba(184/255,230/255,65/255,0.30)
    property color ok: "#5FD08A"

    // ---- visual mockup state (UI only, no billing backend wired yet) ----
    property int selectedPlan: 1
    property bool autopayOn: true
    property var plans: [
        { id: 0, nm: "1 месяц",    price: "299 ₽",   per: "299 ₽/мес", save: "" },
        { id: 1, nm: "12 месяцев", price: "1 990 ₽", per: "166 ₽/мес", save: "−44%" },
        { id: 2, nm: "24 месяца",  price: "2 990 ₽", per: "125 ₽/мес", save: "−58%" }
    ]
    property var history: [
        { d: "23 мая 2026", nm: "Fresh Premium · 12 мес", a: "1 990 ₽" },
        { d: "19 мая 2025", nm: "Fresh Premium · 12 мес", a: "1 790 ₽" },
        { d: "02 фев 2025", nm: "Fresh Premium · 1 мес",  a: "299 ₽" }
    ]

    function goP(p){ PageController.goToPage(p) }
    function stub(){ PageController.showNotificationMessage("Оплата подключится на следующем шаге") }
    function payText(){ return "Оплатить · " + root.plans[root.selectedPlan].price }

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
                    Text { text: "Профиль"; color: root.fg; font.pixelSize: 26; font.weight: 800 }
                    Text { text: "Подписка, оплата и устройства"; color: root.mute; font.pixelSize: 13 }
                }

                // ===== Subscription hero =====
                Rectangle {
                    width: parent.width; height: 190; radius: 18; color: root.card; border.color: root.line; border.width: 1
                    Column {
                        anchors.left: parent.left; anchors.right: parent.right; anchors.top: parent.top
                        anchors.leftMargin: 20; anchors.rightMargin: 20; anchors.topMargin: 18
                        spacing: 9
                        Row {
                            spacing: 8
                            Rectangle { height: 20; radius: 10; width: badgeT.implicitWidth + 18; anchors.verticalCenter: parent.verticalCenter; color: root.limeStrong
                                Text { id: badgeT; anchors.centerIn: parent; text: "PREMIUM"; color: "#0E0E11"; font.pixelSize: 10; font.weight: 800 } }
                            Text { anchors.verticalCenter: parent.verticalCenter; text: "Активна"; color: root.ok; font.pixelSize: 12; font.weight: 700 }
                        }
                        Text { text: "Fresh Premium"; color: root.fg; font.pixelSize: 22; font.weight: 800 }
                        Text { text: "Действует до 23 июля 2026 · осталось 30 дней"; color: root.mute; font.pixelSize: 13 }
                        Rectangle {
                            width: parent.width; height: 6; radius: 3; color: root.bg3
                            Rectangle { width: parent.width * 0.7; height: parent.height; radius: 3; color: root.limeStrong }
                        }
                        Row {
                            spacing: 10
                            Rectangle { height: 38; radius: 11; width: renT.implicitWidth + 32; color: root.limeStrong
                                Text { id: renT; anchors.centerIn: parent; text: "Продлить"; color: "#0E0E11"; font.pixelSize: 13; font.weight: 800 }
                                MouseArea { anchors.fill: parent; cursorShape: Qt.PointingHandCursor; onClicked: root.stub() } }
                            Rectangle { height: 38; radius: 11; width: chgT.implicitWidth + 32; color: "transparent"; border.width: 1; border.color: root.line
                                Text { id: chgT; anchors.centerIn: parent; text: "Сменить тариф"; color: root.fg; font.pixelSize: 13; font.weight: 600 }
                                MouseArea { anchors.fill: parent; cursorShape: Qt.PointingHandCursor; onClicked: root.stub() } }
                        }
                    }
                }

                // ===== Tariffs =====
                Column {
                    width: parent.width; spacing: 10
                    Text { text: "ТАРИФ"; color: root.dim; font.pixelSize: 11; font.weight: 800; leftPadding: 4 }
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
                            Text { text: "Автопродление"; color: root.fg; font.pixelSize: 14; font.weight: 700 }
                            Text { width: parent.width; wrapMode: Text.WordWrap; text: "Продлевать подписку автоматически перед окончанием срока"; color: root.mute; font.pixelSize: 12 }
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
                    width: parent.width; spacing: 10
                    Text { text: "ИСТОРИЯ ОПЛАТ"; color: root.dim; font.pixelSize: 11; font.weight: 800; leftPadding: 4 }
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
                                        Text { width: parent.width; horizontalAlignment: Text.AlignRight; text: "Оплачено"; color: root.ok; font.pixelSize: 10; font.weight: 700 }
                                    }
                                }
                            }
                        }
                    }
                }

                // ===== Devices =====
                Column {
                    width: parent.width; spacing: 10
                    Text { text: "УСТРОЙСТВА"; color: root.dim; font.pixelSize: 11; font.weight: 800; leftPadding: 4 }
                    RowCard { nm: "Это устройство · Windows"; ds: "подключено сейчас"; icon: "monitor"; clickable: false }
                    RowCard { nm: "Добавить устройство"; ds: "по QR или ключу подписки"; icon: "qr"; onActivated: root.goP(PageEnum.PageSetupWizardConfigSource) }
                    RowCard { nm: "Управлять серверами"; ds: "список и настройки узлов"; icon: "monitor"; onActivated: root.goP(PageEnum.PageSettingsServersList) }
                    RowCard { nm: "Поддержка"; ds: "ответим в Telegram"; icon: "help"; onActivated: root.goP(PageEnum.PageSettingsAbout) }
                }

                Item { width: 1; height: 8 }
            }
        }
    }
}
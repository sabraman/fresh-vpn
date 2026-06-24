import QtQuick
import QtQuick.Controls
import QtQuick.Layouts

import PageEnum 1.0
import Style 1.0

import "./"
import "../Controls2"
import "../Components"

PageType {
    id: root

    property color bg: "#0E0E11"; property color card: "#16171A"; property color bg2: "#1C1D21"
    property color line: Qt.rgba(1,1,1,0.08); property color fg: "#F5F4EF"; property color mute: "#878B91"; property color dim: "#5A5D63"
    property color lime: "#B8E641"; property color limeStrong: "#C8F050"
    property color limeSoft: Qt.rgba(184/255,230/255,65/255,0.10); property color limeLine: Qt.rgba(184/255,230/255,65/255,0.30)
    property color warn: "#FBB26A"; property color bad: "#E5484D"

    property bool conn: ConnectionController.isConnected
    property string serverName: ServersUiController.defaultServerName
    property bool autoPick: true

    property string statusUrl: "http://94.156.232.206:8088/node-status.json"
    property var loadByCountry: ({})
    property bool feedKnown: false
    property bool allServersOk: false
    property int nodeCount: 0
    property double feedUpdated: 0

    property double connStart: 0
    property int connElapsed: 0

    property var ru: ({
        "FI":"Финляндия","DE":"Германия","NL":"Нидерланды","SE":"Швеция","FR":"Франция",
        "GB":"Великобритания","US":"США","PL":"Польша","LT":"Литва","LV":"Латвия",
        "EE":"Эстония","CH":"Швейцария","AT":"Австрия","ES":"Испания","IT":"Италия",
        "NO":"Норвегия","DK":"Дания","CZ":"Чехия","RO":"Румыния","BG":"Болгария",
        "TR":"Турция","UA":"Украина","KZ":"Казахстан","AM":"Армения","GE":"Грузия",
        "RS":"Сербия","MD":"Молдова","HU":"Венгрия","IE":"Ирландия","PT":"Португалия",
        "BE":"Бельгия","LU":"Люксембург","JP":"Япония","SG":"Сингапур","HK":"Гонконг",
        "CA":"Канада","AE":"ОАЭ","IL":"Израиль","IN":"Индия","AU":"Австралия","ZA":"ЮАР",
        "BR":"Бразилия","KR":"Южная Корея","CY":"Кипр","MT":"Мальта","IS":"Исландия","RU":"Россия"
    })

    function decode(s){ try { return decodeURIComponent(s) } catch(e){ return s } }
    function emojiCode(s){
        var out = ""
        for(var i=0;i<s.length;i++){
            var cp = s.codePointAt(i)
            if(cp>=0x1F1E6 && cp<=0x1F1FF){ out += String.fromCharCode(0x41 + cp - 0x1F1E6); i++ }
            if(out.length===2) break
        }
        return out
    }
    function srvCode(){
        var p = "" + ServersUiController.defaultServerImagePathCollapsed
        var m = p.match(/([A-Za-z]{2})\.svg$/); if(m) return m[1].toUpperCase()
        var raw = "" + root.serverName
        var ec = emojiCode(raw); if(ec.length===2 && root.ru[ec]) return ec
        var n = decode(raw).toUpperCase()
        var mm = n.match(/\b([A-Z]{2})\b/); if(mm && root.ru[mm[1]]) return mm[1]
        return ""
    }
    function cleanName(){
        var raw = decode("" + root.serverName)
        raw = raw.replace(/[\uD83C][\uDDE6-\uDDFF]/g, "")
        raw = raw.replace(/[☀-➿‍️]/g, "")
        var cut = raw.split("|")[0]
        cut = cut.replace(/%[0-9A-Fa-f]{2}/g, " ")
        cut = cut.replace(/\s+/g, " ").trim()
        return cut
    }
    function srvCountry(){ var c = srvCode(); return (c.length>0 && root.ru[c]) ? root.ru[c] : "" }
    function srvTitle(){
        if(root.serverName.length===0) return "Выбрать сервер"
        var t = cleanName(); if(t.length>0) return t
        var c = srvCountry(); if(c.length>0) return c
        return "Сервер"
    }
    function flagSrc(){ var c = srvCode(); return c.length>0 ? ("qrc:/countriesFlags/images/flagKit/" + c + ".svg") : "" }
    function pingMs(){
        if(root.conn && ConnectionHealth.latencyMs>=0) return ConnectionHealth.latencyMs
        return ServerLatencyController.latencyFor(ServersUiController.defaultServerId)
    }
    function latColor(ms){ if(ms<0) return root.mute; if(ms<100) return root.limeStrong; if(ms<250) return root.warn; return root.bad }
    function latText(ms){ if(ms===-3) return "•••"; if(ms<0) return "нет"; return ms + " мс" }
    function fmtB(b){ if(b>=1073741824) return (b/1073741824).toFixed(2)+" ГБ"; if(b>=1048576) return (b/1048576).toFixed(1)+" МБ"; if(b>=1024) return (b/1024).toFixed(0)+" КБ"; return Math.round(b)+" Б" }

    function srvLoad(){ var c = srvCode(); if(root.feedKnown && root.loadByCountry[c] !== undefined) return root.loadByCountry[c]; return -1 }
    function loadColor(p){ if(p<0) return root.mute; if(p<60) return root.limeStrong; if(p<85) return root.warn; return root.bad }
    function loadText(p){ return p<0 ? "—" : (p + "%") }
    function fmtUptime(s){ if(!root.conn || s<=0) return "—"; var h=Math.floor(s/3600), m=Math.floor((s%3600)/60), ss=s%60; return h>0 ? (h+"ч "+m+"м") : (m+"м "+ss+"с") }
    function locWord(n){ var a=n%10, b=n%100; if(a===1 && b!==11) return "локация"; if(a>=2 && a<=4 && (b<12||b>14)) return "локации"; return "локаций" }
    function fmtFresh(){
        if(root.feedUpdated<=0) return "обновляется"
        var diff = Math.floor(Date.now()/1000 - root.feedUpdated)
        if(diff<180) return "обновлено только что"
        if(diff<3600) return "обновлено " + Math.floor(diff/60) + " мин назад"
        return "обновлено " + Math.floor(diff/3600) + " ч назад"
    }
    function pollStatus(){
        var xhr = new XMLHttpRequest()
        xhr.onreadystatechange = function(){
            if(xhr.readyState === XMLHttpRequest.DONE && xhr.status === 200){
                try {
                    var d = JSON.parse(xhr.responseText)
                    var arr = d.nodes ? d.nodes : [d]
                    var mp = {}; var allUp = true
                    for(var i=0;i<arr.length;i++){
                        var cc = ("" + arr[i].country).toUpperCase()
                        mp[cc] = arr[i].loadPct
                        if(arr[i].online === false) allUp = false
                    }
                    root.loadByCountry = mp
                    root.nodeCount = arr.length
                    root.feedUpdated = (d.updated !== undefined) ? d.updated : 0
                    root.allServersOk = (d.allOk !== undefined) ? d.allOk : allUp
                    root.feedKnown = true
                } catch(e){}
            }
        }
        try { xhr.open("GET", root.statusUrl); xhr.send() } catch(e){}
    }

    onConnChanged: { if(conn){ root.connStart = Date.now() } else { root.connStart = 0; root.connElapsed = 0 } }
    Component.onCompleted: root.pollStatus()
    Timer { interval: 120000; running: true; repeat: true; onTriggered: root.pollStatus() }
    Timer { interval: 1000; running: root.conn; repeat: true; onTriggered: root.connElapsed = root.connStart>0 ? Math.floor((Date.now()-root.connStart)/1000) : 0 }

    Connections { objectName: "pageControllerConnections"; target: PageController; function onRestorePageHomeState(isContainerInstalled) { } }
    Connections {
        target: ServerLatencyController
        function onMeasurementFinished(){
            if(!root.autoPick || root.conn) return
            var b = ServerLatencyController.bestServerId()
            if(b && b.length>0 && b !== ServersUiController.defaultServerId)
                ServersUiController.setDefaultServer(b)
        }
    }

    Rectangle { anchors.fill: parent; color: root.bg }

    Flickable {
        anchors.fill: parent
        anchors.topMargin: 14 + PageController.safeAreaTopMargin
        contentHeight: wrap.height + 48
        clip: true
        boundsBehavior: Flickable.StopAtBounds

        Item {
            id: wrap
            width: Math.min(460, root.width - 56)
            x: (root.width - width) / 2
            height: col.implicitHeight

            Column {
                id: col
                width: parent.width
                spacing: 16

                Item { width: 1; height: 6 }

                // ===== Reactive shield =====
                Item {
                    width: parent.width; height: 196
                    Canvas {
                        id: shieldCv
                        anchors.centerIn: parent
                        width: 172; height: 182
                        transformOrigin: Item.Center
                        property bool on: root.conn
                        property bool busy: ConnectionController.isConnectionInProgress
                        onOnChanged: requestPaint()
                        onBusyChanged: { requestPaint(); if (!busy) scale = 1 }
                        Component.onCompleted: requestPaint()
                        onPaint: {
                            var c = getContext("2d"); c.reset()
                            var w = width, h = height
                            c.lineCap = "round"; c.lineJoin = "round"
                            if (on) {
                                c.beginPath()
                                c.moveTo(w*0.5, h*0.03)
                                c.lineTo(w*0.87, h*0.17)
                                c.lineTo(w*0.87, h*0.50)
                                c.bezierCurveTo(w*0.87, h*0.79, w*0.71, h*0.93, w*0.5, h*0.99)
                                c.bezierCurveTo(w*0.29, h*0.93, w*0.13, h*0.79, w*0.13, h*0.50)
                                c.lineTo(w*0.13, h*0.17)
                                c.closePath()
                                var g = c.createLinearGradient(0, 0, 0, h)
                                g.addColorStop(0, "#C8F050"); g.addColorStop(1, "#74B62B")
                                c.fillStyle = g; c.fill()
                                c.strokeStyle = "#11140A"; c.lineWidth = 10
                                c.beginPath(); c.moveTo(w*0.35, h*0.52); c.lineTo(w*0.46, h*0.63); c.lineTo(w*0.67, h*0.39); c.stroke()
                            } else {
                                var gp = w*0.045
                                c.strokeStyle = busy ? "#C8F050" : "#B8E641"; c.lineWidth = 5
                                c.fillStyle = "rgba(184,230,65,0.05)"
                                c.beginPath()
                                c.moveTo(w*0.5 - gp, h*0.05)
                                c.lineTo(w*0.13 - gp, h*0.17)
                                c.lineTo(w*0.13 - gp, h*0.50)
                                c.bezierCurveTo(w*0.13 - gp, h*0.79, w*0.29 - gp, h*0.93, w*0.5 - gp, h*0.985)
                                c.lineTo(w*0.5 - gp, h*0.05)
                                c.closePath(); c.fill(); c.stroke()
                                c.beginPath()
                                c.moveTo(w*0.5 + gp, h*0.05)
                                c.lineTo(w*0.87 + gp, h*0.17)
                                c.lineTo(w*0.87 + gp, h*0.50)
                                c.bezierCurveTo(w*0.87 + gp, h*0.79, w*0.71 + gp, h*0.93, w*0.5 + gp, h*0.985)
                                c.lineTo(w*0.5 + gp, h*0.05)
                                c.closePath(); c.fill(); c.stroke()
                            }
                        }
                        SequentialAnimation on scale {
                            running: shieldCv.busy
                            loops: Animation.Infinite
                            NumberAnimation { from: 0.97; to: 1.05; duration: 620; easing.type: Easing.InOutSine }
                            NumberAnimation { from: 1.05; to: 0.97; duration: 620; easing.type: Easing.InOutSine }
                        }
                    }
                }

                // ===== Status line =====
                Column {
                    width: parent.width; spacing: 5
                    Text {
                        anchors.horizontalCenter: parent.horizontalCenter
                        text: root.conn ? "Подключено" : (ConnectionController.isConnectionInProgress ? "Подключение…" : "Отключено")
                        color: root.fg; font.pixelSize: 22; font.weight: 800; font.family: "Bricolage Grotesque"
                    }
                    Row {
                        anchors.horizontalCenter: parent.horizontalCenter; spacing: 7
                        Rectangle { width: 7; height: 7; radius: 4; anchors.verticalCenter: parent.verticalCenter; color: root.conn ? root.limeStrong : root.dim }
                        Text {
                            anchors.verticalCenter: parent.verticalCenter
                            text: root.conn ? ((root.srvCountry().length>0 ? root.srvCountry() : root.srvTitle()) + (ConnectionHealth.latencyMs>=0 ? (" · " + ConnectionHealth.latencyMs + " мс") : "")) : "Нажми, чтобы подключиться"
                            color: root.mute; font.pixelSize: 12; font.weight: 600
                        }
                    }
                }

                // ===== Connect button =====
                Item {
                    width: parent.width; height: 60
                    Rectangle {
                        id: cbtn
                        anchors.centerIn: parent
                        height: 54; radius: 999
                        width: root.conn ? 200 : 248
                        color: root.conn ? "transparent" : root.limeStrong
                        border.width: root.conn ? 1 : 0
                        border.color: root.limeLine
                        scale: cbtnM.pressed ? 0.97 : 1.0
                        Behavior on scale { NumberAnimation { duration: 90; easing.type: Easing.OutQuad } }
                        Row {
                            id: cbtnRow
                            anchors.centerIn: parent; spacing: 9
                            Canvas {
                                width: 17; height: 17; anchors.verticalCenter: parent.verticalCenter
                                property color col: root.conn ? root.limeStrong : "#11140A"
                                onColChanged: requestPaint()
                                onPaint: {
                                    var c = getContext("2d"); c.reset()
                                    c.strokeStyle = col; c.lineWidth = 2.4; c.lineCap = "round"
                                    c.beginPath(); c.arc(8.5, 9, 6, -Math.PI/2 + 0.5, -Math.PI/2 - 0.5 + 2*Math.PI, false); c.stroke()
                                    c.beginPath(); c.moveTo(8.5, 1.5); c.lineTo(8.5, 8); c.stroke()
                                }
                            }
                            Text {
                                anchors.verticalCenter: parent.verticalCenter
                                text: root.conn ? "Отключиться" : (ConnectionController.isConnectionInProgress ? "Подключение…" : "Подключиться")
                                color: root.conn ? root.limeStrong : "#11140A"; font.pixelSize: 15; font.weight: 800
                            }
                        }
                        MouseArea { id: cbtnM; anchors.fill: parent; cursorShape: Qt.PointingHandCursor; onClicked: ConnectionController.connectButtonClicked() }
                    }
                }

                // ===== Server chip =====
                Rectangle {
                    width: parent.width; height: 64; radius: 16; color: root.card; border.color: root.line; border.width: 1
                    scale: chipM.pressed ? 0.99 : 1.0
                    Behavior on scale { NumberAnimation { duration: 90 } }
                    MouseArea { id: chipM; anchors.fill: parent; cursorShape: Qt.PointingHandCursor; onClicked: PageController.goToPage(PageEnum.PageSettingsServersList) }
                    RowLayout {
                        anchors.fill: parent; anchors.leftMargin: 14; anchors.rightMargin: 14; spacing: 11
                        Image { Layout.preferredWidth: 30; Layout.preferredHeight: 21; Layout.alignment: Qt.AlignVCenter; source: root.flagSrc(); visible: root.flagSrc().length>0; fillMode: Image.PreserveAspectFit }
                        Rectangle { Layout.preferredWidth: 18; Layout.preferredHeight: 12; radius: 2; color: root.limeStrong; Layout.alignment: Qt.AlignVCenter; visible: root.flagSrc().length===0 }
                        ColumnLayout {
                            Layout.fillWidth: true; spacing: 2
                            Text { Layout.fillWidth: true; elide: Text.ElideRight; text: root.srvCountry().length>0 ? root.srvCountry() : root.srvTitle(); color: root.fg; font.pixelSize: 14; font.weight: 700 }
                            Text { Layout.fillWidth: true; elide: Text.ElideRight; text: ServersUiController.defaultServerDefaultContainerName.length>0 ? ServersUiController.defaultServerDefaultContainerName : "сервер"; color: root.mute; font.pixelSize: 11 }
                        }
                        Rectangle { Layout.alignment: Qt.AlignVCenter; implicitHeight: 22; implicitWidth: latTxt.implicitWidth + 16; radius: 11; color: Qt.rgba(1,1,1,0.05); border.width: 1; border.color: root.line
                            Text { id: latTxt; anchors.centerIn: parent; text: root.latText(root.pingMs()); color: root.latColor(root.pingMs()); font.pixelSize: 12; font.weight: 700 } }
                        Rectangle { Layout.alignment: Qt.AlignVCenter; implicitHeight: 22; implicitWidth: loadTxt.implicitWidth + 16; radius: 11; color: Qt.rgba(1,1,1,0.05); border.width: 1; border.color: root.line
                            Text { id: loadTxt; anchors.centerIn: parent; text: root.loadText(root.srvLoad()); color: root.loadColor(root.srvLoad()); font.pixelSize: 12; font.weight: 700 } }
                        Image { source: "qrc:/images/controls/chevron-right.svg"; Layout.preferredWidth: 16; Layout.preferredHeight: 16; Layout.alignment: Qt.AlignVCenter; opacity: 0.5 }
                    }
                }

                // ===== Add subscription =====
                Rectangle {
                    width: parent.width; height: 48; radius: 14
                    color: addM.pressed ? root.limeSoft : "transparent"
                    border.color: root.limeLine; border.width: 1
                    Behavior on color { ColorAnimation { duration: 120 } }
                    Row {
                        anchors.centerIn: parent; spacing: 8
                        Text { anchors.verticalCenter: parent.verticalCenter; text: "+"; color: root.limeStrong; font.pixelSize: 18; font.weight: 800 }
                        Text { anchors.verticalCenter: parent.verticalCenter; text: "Добавить подписку"; color: root.limeStrong; font.pixelSize: 14; font.weight: 700 }
                    }
                    MouseArea { id: addM; anchors.fill: parent; cursorShape: Qt.PointingHandCursor; onClicked: PageController.goToStartPage() }
                }
                // ===== Minigrid =====
                Row {
                    id: mg
                    width: parent.width; spacing: 10
                    property real cw: (width - 20) / 3
                    Repeater {
                        model: [
                            { l: "Скорость", v: root.conn ? (ConnectionController.rxSpeedMbps.toFixed(1) + " Мбит") : "—", acc: true },
                            { l: "Пинг",     v: (root.conn && ConnectionHealth.latencyMs>=0) ? (ConnectionHealth.latencyMs + " мс") : "—", acc: false },
                            { l: "Сессия",   v: root.fmtUptime(root.connElapsed), acc: false }
                        ]
                        delegate: Rectangle {
                            width: mg.cw; height: 62; radius: 12; color: root.card; border.color: root.line; border.width: 1
                            Column {
                                anchors.centerIn: parent; spacing: 4; width: parent.width - 12
                                Text { width: parent.width; horizontalAlignment: Text.AlignHCenter; text: modelData.l; color: root.dim; font.pixelSize: 9; font.weight: 700 }
                                Text { width: parent.width; horizontalAlignment: Text.AlignHCenter; text: modelData.v; color: modelData.acc ? root.limeStrong : root.fg; font.pixelSize: 14; font.weight: 800; font.family: "Bricolage Grotesque" }
                            }
                        }
                    }
                }

                Item { width: 1; height: 10 }
            }
        }
    }
}
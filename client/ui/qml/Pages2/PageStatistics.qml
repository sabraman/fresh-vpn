import QtQuick
import QtQuick.Layouts
import "../Controls2"

PageType {
    id: root

    property color bg: "#0E0E11"; property color card: "#16171A"; property color bg2: "#1C1D21"; property color bg3: "#25262B"
    property color line: Qt.rgba(1,1,1,0.08); property color fg: "#F5F4EF"; property color mute: "#878B91"; property color dim: "#5A5D63"
    property color lime: "#B8E641"; property color limeStrong: "#C8F050"
    property color limeSoft: Qt.rgba(184/255,230/255,65/255,0.10); property color limeLine: Qt.rgba(184/255,230/255,65/255,0.30)
    property color warn: "#FBB26A"; property color ok: "#5FD08A"; property color bad: "#E5484D"

    property bool conn: ConnectionController.isConnected
    property var samples: []
    property int period: 0
    property double connStart: 0
    property int connElapsed: 0

    function fmtB(b){
        if(b>=1073741824) return (b/1073741824).toFixed(2)+" ГБ"
        if(b>=1048576) return (b/1048576).toFixed(1)+" МБ"
        if(b>=1024) return (b/1024).toFixed(0)+" КБ"
        return Math.round(b)+" Б"
    }
    function fmtUptime(s){ if(!root.conn || s<=0) return "—"; var h=Math.floor(s/3600), m=Math.floor((s%3600)/60), ss=s%60; return h>0 ? (h+"ч "+m+"м") : (m+"м "+ss+"с") }
    function healthWord(s){ return s===1 ? "Стабильно" : s===2 ? "Нестабильно" : s===3 ? "Измерение…" : "Ожидание" }

    onConnChanged: { if(conn){ root.connStart = Date.now() } else { root.connStart = 0; root.connElapsed = 0 } }

    Connections {
        target: ConnectionController
        function onTrafficChanged(){
            if(root.conn){
                var a = root.samples.slice()
                a.push(ConnectionController.rxSpeedMbps)
                if(a.length>48) a.shift()
                root.samples = a
                spark.requestPaint()
            }
        }
        function onConnectionStateChanged(){
            if(!ConnectionController.isConnected){ root.samples=[]; spark.requestPaint() }
        }
    }
    Timer { interval: 1000; running: root.conn; repeat: true; onTriggered: root.connElapsed = root.connStart>0 ? Math.floor((Date.now()-root.connStart)/1000) : 0 }

    Rectangle { anchors.fill: parent; color: root.bg }

    Flickable {
        anchors.fill: parent
        anchors.topMargin: 18 + PageController.safeAreaTopMargin
        contentHeight: wrap.height + 40
        clip: true
        boundsBehavior: Flickable.StopAtBounds

        Item {
            id: wrap
            width: Math.min(680, root.width - 56)
            x: (root.width - width) / 2
            height: col.implicitHeight

            Column {
                id: col
                width: parent.width
                spacing: 16

                Column {
                    width: parent.width; spacing: 4
                    Text { text: "Статистика"; color: root.fg; font.pixelSize: 26; font.weight: 800 }
                    Text { text: "Трафик и здоровье соединения"; color: root.mute; font.pixelSize: 13 }
                }

                Rectangle {
                    width: segRow.implicitWidth + 8; height: 36; radius: 12; color: root.bg2; border.color: root.line; border.width: 1
                    Row {
                        id: segRow
                        anchors.centerIn: parent; spacing: 0
                        Repeater {
                            model: ["Сессия", "День", "Неделя"]
                            delegate: Rectangle {
                                width: 84; height: 28; radius: 9
                                color: root.period === index ? root.limeStrong : "transparent"
                                Text { anchors.centerIn: parent; text: modelData; color: root.period === index ? "#0E0E11" : root.mute; font.pixelSize: 12; font.weight: 700 }
                                MouseArea { anchors.fill: parent; cursorShape: Qt.PointingHandCursor; onClicked: root.period = index }
                            }
                        }
                    }
                }

                Rectangle {
                    width: parent.width; height: 150; radius: 16; color: root.card; border.color: root.line; border.width: 1
                    Column {
                        anchors.fill: parent; anchors.margins: 16; spacing: 10
                        RowLayout {
                            width: parent.width
                            Text { text: "СКОРОСТЬ КАНАЛА"; color: root.dim; font.pixelSize: 11; font.weight: 700; Layout.fillWidth: true }
                            Text { text: (root.conn ? ConnectionController.rxSpeedMbps.toFixed(1) : "0.0") + " Мбит/с"; color: root.limeStrong; font.pixelSize: 14; font.weight: 700 }
                        }
                        Canvas {
                            id: spark
                            width: parent.width; height: 82
                            onPaint: {
                                var c = getContext("2d"); c.reset()
                                var s = root.samples, n = s.length, w = width, h = height
                                c.strokeStyle = "rgba(255,255,255,0.06)"; c.lineWidth = 1
                                c.beginPath(); c.moveTo(0, h-1); c.lineTo(w, h-1); c.stroke()
                                if (root.period !== 0) {
                                    c.fillStyle = "#5A5D63"; c.font = "12px sans-serif"; c.textAlign = "center"
                                    c.fillText("История — скоро", w/2, h/2)
                                    return
                                }
                                if (n < 2) return
                                var mx = 0.3; for (var i=0;i<n;i++){ if (s[i] > mx) mx = s[i] }
                                c.strokeStyle = "#C8F050"; c.lineWidth = 2; c.lineJoin = "round"; c.lineCap = "round"
                                c.beginPath()
                                for (var j=0;j<n;j++){ var x=(j/(n-1))*w, y=h-(s[j]/mx)*(h-8)-4; if(j===0) c.moveTo(x,y); else c.lineTo(x,y) }
                                c.stroke()
                                c.lineTo(w, h); c.lineTo(0, h); c.closePath(); c.fillStyle = "rgba(184,230,65,0.10)"; c.fill()
                            }
                        }
                    }
                }

                Grid {
                    id: sg
                    width: parent.width; columns: 2; rowSpacing: 12; columnSpacing: 12
                    property real cw: (width - 12) / 2
                    Repeater {
                        model: [
                            { l: "Скачано",    k: "rx" },
                            { l: "Отдано",     k: "tx" },
                            { l: "Пинг",       k: "ping" },
                            { l: "Джиттер",    k: "jitter" },
                            { l: "Соединение", k: "health" },
                            { l: "Сессия",     k: "uptime" }
                        ]
                        delegate: Rectangle {
                            width: sg.cw; height: 78; radius: 14; color: root.card; border.color: root.line; border.width: 1
                            Column {
                                anchors.left: parent.left; anchors.leftMargin: 16; anchors.verticalCenter: parent.verticalCenter; spacing: 6
                                Text { text: modelData.l; color: root.dim; font.pixelSize: 10; font.weight: 700 }
                                Text {
                                    text: modelData.k === "rx" ? (root.conn ? root.fmtB(ConnectionController.rxTotalBytes) : "—")
                                        : modelData.k === "tx" ? (root.conn ? root.fmtB(ConnectionController.txTotalBytes) : "—")
                                        : modelData.k === "ping" ? ((root.conn && ConnectionHealth.latencyMs>=0) ? (ConnectionHealth.latencyMs + " мс") : "—")
                                        : modelData.k === "jitter" ? ((root.conn && ConnectionHealth.jitterMs>=0) ? (ConnectionHealth.jitterMs + " мс") : "—")
                                        : modelData.k === "uptime" ? root.fmtUptime(root.connElapsed)
                                        : (root.conn ? root.healthWord(ConnectionHealth.healthState) : "—")
                                    color: (modelData.k === "rx" || modelData.k === "ping") ? root.limeStrong
                                        : modelData.k === "health" ? (root.conn ? (ConnectionHealth.healthState === 2 ? root.warn : ConnectionHealth.healthState === 1 ? root.ok : root.mute) : root.mute)
                                        : root.fg
                                    font.pixelSize: 20; font.weight: 800
                                }
                            }
                        }
                    }
                }

                Text {
                    visible: !root.conn
                    width: parent.width; wrapMode: Text.WordWrap
                    text: "Здесь живой трафик, скорость, пинг, джиттер и здоровье текущего подключения. История за день и неделю появится, когда подключим хранение на сервере."
                    color: root.dim; font.pixelSize: 11
                }

                Item { width: 1; height: 8 }
            }
        }
    }
}
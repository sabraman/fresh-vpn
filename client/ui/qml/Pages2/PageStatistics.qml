import QtQuick
import QtQuick.Layouts
import Style 1.0
import "../Controls2"

PageType {
    id: root

    property color bg: AmneziaStyle.fresh.bg; property color card: AmneziaStyle.fresh.card; property color bg2: AmneziaStyle.fresh.bg2; property color bg3: AmneziaStyle.fresh.bg3
    property color line: AmneziaStyle.fresh.line; property color fg: AmneziaStyle.fresh.fg; property color mute: AmneziaStyle.fresh.mute; property color dim: AmneziaStyle.fresh.dim
    property color lime: AmneziaStyle.fresh.lime; property color limeStrong: AmneziaStyle.fresh.limeStrong
    property color limeSoft: AmneziaStyle.fresh.limeSoft; property color limeLine: AmneziaStyle.fresh.limeLine
    property color warn: AmneziaStyle.fresh.warn; property color ok: AmneziaStyle.fresh.ok; property color bad: AmneziaStyle.fresh.bad

    property bool conn: ConnectionController.isConnected
    property var samples: []
    property int period: 0
    property double connStart: 0
    property int connElapsed: 0

    function fmtB(b){
        if(b>=1073741824) return (b/1073741824).toFixed(2)+qsTr(" GB")
        if(b>=1048576) return (b/1048576).toFixed(1)+qsTr(" MB")
        if(b>=1024) return (b/1024).toFixed(0)+qsTr(" KB")
        return Math.round(b)+qsTr(" B")
    }
    function fmtUptime(s){ if(!root.conn || s<=0) return "—"; var h=Math.floor(s/3600), m=Math.floor((s%3600)/60), ss=s%60; return h>0 ? (h+qsTr("h ")+m+qsTr("m")) : (m+qsTr("m ")+ss+qsTr("s")) }
    function healthWord(s){ return s===1 ? qsTr("Stable") : s===2 ? qsTr("Unstable") : s===3 ? qsTr("Measuring…") : qsTr("Waiting") }

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
                    Text { text: qsTr("Statistics"); color: root.fg; font.pixelSize: 26; font.weight: 800 }
                    Text { text: qsTr("Traffic and connection health"); color: root.mute; font.pixelSize: 13 }
                }


                Rectangle {
                    width: parent.width; height: 150; radius: 16; color: root.card; border.color: root.line; border.width: 1
                    Column {
                        anchors.fill: parent; anchors.margins: 16; spacing: 10
                        RowLayout {
                            width: parent.width
                            Text { text: qsTr("CHANNEL SPEED"); color: root.dim; font.pixelSize: 11; font.weight: 700; Layout.fillWidth: true }
                            Text { text: (root.conn ? ConnectionController.rxSpeedMbps.toFixed(1) : "0.0") + qsTr(" Mbps"); color: root.limeStrong; font.pixelSize: 14; font.weight: 700 }
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
                                    c.fillText(qsTr("History — soon"), w/2, h/2)
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

                // ===== Internet speed test (#5) =====
                Rectangle {
                    id: stCard
                    width: parent.width; radius: 16; color: root.card; border.color: root.limeLine; border.width: 1
                    height: stCol.implicitHeight + 32
                    property int st: ServerLatencyController.speedTestState
                    property bool running: stCard.st===1 || stCard.st===2
                    Column {
                        id: stCol
                        anchors.left: parent.left; anchors.right: parent.right; anchors.top: parent.top
                        anchors.topMargin: 16; anchors.leftMargin: 16; anchors.rightMargin: 16; spacing: 12
                        RowLayout {
                            width: parent.width
                            Text { text: qsTr("SPEED TEST"); color: root.dim; font.pixelSize: 11; font.weight: 700; Layout.fillWidth: true }
                            Text { text: stCard.st===1 ? qsTr("Download…") : stCard.st===2 ? qsTr("Upload…") : stCard.st===-1 ? qsTr("Failed, try again") : ""; color: root.mute; font.pixelSize: 12; font.weight: 600 }
                        }
                        Row {
                            width: parent.width; spacing: 12
                            Rectangle {
                                width: (parent.width-12)/2; height: 66; radius: 12; color: root.bg2; border.color: root.line; border.width: 1
                                Column { anchors.centerIn: parent; spacing: 3
                                    Text { anchors.horizontalCenter: parent.horizontalCenter; text: qsTr("Download"); color: root.dim; font.pixelSize: 10; font.weight: 700 }
                                    Text { anchors.horizontalCenter: parent.horizontalCenter; text: ServerLatencyController.downloadMbps>0 ? (ServerLatencyController.downloadMbps.toFixed(1) + qsTr(" Mbps")) : "—"; color: root.limeStrong; font.pixelSize: 20; font.weight: 800; font.family: "Bricolage Grotesque" }
                                }
                            }
                            Rectangle {
                                width: (parent.width-12)/2; height: 66; radius: 12; color: root.bg2; border.color: root.line; border.width: 1
                                Column { anchors.centerIn: parent; spacing: 3
                                    Text { anchors.horizontalCenter: parent.horizontalCenter; text: qsTr("Upload"); color: root.dim; font.pixelSize: 10; font.weight: 700 }
                                    Text { anchors.horizontalCenter: parent.horizontalCenter; text: ServerLatencyController.uploadMbps>0 ? (ServerLatencyController.uploadMbps.toFixed(1) + qsTr(" Mbps")) : "—"; color: root.fg; font.pixelSize: 20; font.weight: 800; font.family: "Bricolage Grotesque" }
                                }
                            }
                        }
                        Text {
                            width: parent.width
                            visible: ServerLatencyController.downloadMB > 0 || ServerLatencyController.uploadMB > 0
                            horizontalAlignment: Text.AlignHCenter
                            wrapMode: Text.WordWrap
                            color: root.mute
                            font.pixelSize: 11
                            text: qsTr("Real transfer: %1 MB in %2 s down, %3 MB in %4 s up")
                                    .arg(ServerLatencyController.downloadMB.toFixed(0))
                                    .arg(ServerLatencyController.downloadSecs.toFixed(1))
                                    .arg(ServerLatencyController.uploadMB.toFixed(0))
                                    .arg(ServerLatencyController.uploadSecs.toFixed(1))
                        }
                        Rectangle {
                            width: parent.width; height: 44; radius: 12
                            color: stCard.running ? "transparent" : (stM.pressed ? root.limeSoft : root.limeStrong)
                            scale: (stM.pressed && !stCard.running) ? 0.97 : 1.0
                            Behavior on scale { NumberAnimation { duration: 90; easing.type: Easing.OutQuad } }
                            border.color: root.limeLine; border.width: stCard.running ? 1 : 0
                            Text { anchors.centerIn: parent; text: stCard.running ? qsTr("Testing…") : qsTr("Check speed"); color: stCard.running ? root.limeStrong : "#11140A"; font.pixelSize: 14; font.weight: 800 }
                            MouseArea { id: stM; anchors.fill: parent; enabled: !stCard.running; cursorShape: Qt.PointingHandCursor; onClicked: ServerLatencyController.runSpeedTest() }
                        }
                    }
                }

                Grid {
                    id: sg
                    width: parent.width; columns: 2; rowSpacing: 12; columnSpacing: 12
                    property real cw: (width - 12) / 2
                    Repeater {
                        model: [
                            { l: qsTr("Downloaded"),    k: "rx" },
                            { l: qsTr("Uploaded"),     k: "tx" },
                            { l: qsTr("Ping"),       k: "ping" },
                            { l: qsTr("Jitter"),    k: "jitter" },
                            { l: qsTr("Connection"), k: "health" },
                            { l: qsTr("Session"),     k: "uptime" }
                        ]
                        delegate: Rectangle {
                            width: sg.cw; height: 78; radius: 14; color: root.card; border.color: root.line; border.width: 1
                            Column {
                                anchors.left: parent.left; anchors.leftMargin: 16; anchors.verticalCenter: parent.verticalCenter; spacing: 6
                                Text { text: modelData.l; color: root.dim; font.pixelSize: 10; font.weight: 700 }
                                Text {
                                    text: modelData.k === "rx" ? (root.conn ? root.fmtB(ConnectionController.rxTotalBytes) : "—")
                                        : modelData.k === "tx" ? (root.conn ? root.fmtB(ConnectionController.txTotalBytes) : "—")
                                        : modelData.k === "ping" ? ((root.conn && ConnectionHealth.latencyMs>=0) ? (ConnectionHealth.latencyMs + qsTr(" ms")) : "—")
                                        : modelData.k === "jitter" ? ((root.conn && ConnectionHealth.jitterMs>=0) ? (ConnectionHealth.jitterMs + qsTr(" ms")) : "—")
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
                    text: qsTr("Here you'll see live traffic, speed, ping, jitter and the state of the current connection in real time.")
                    color: root.dim; font.pixelSize: 11
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
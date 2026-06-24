import QtQuick
import QtQuick.Controls
import SortFilterProxyModel 0.2
import PageEnum 1.0
import "../Controls2"
import "../Components"

PageType {
    id: root

    property color bg: "#0E0E11"; property color card: "#16171A"; property color bg2: "#1C1D21"; property color bg3: "#25262B"
    property color line: Qt.rgba(1,1,1,0.08); property color fg: "#F5F4EF"; property color mute: "#878B91"; property color dim: "#5A5D63"
    property color lime: "#B8E641"; property color limeStrong: "#C8F050"
    property color limeSoft: Qt.rgba(184/255,230/255,65/255,0.10); property color limeLine: Qt.rgba(184/255,230/255,65/255,0.30)
    property color warn: "#FBB26A"; property color bad: "#E5484D"

    property string selServerId: ""
    property string selName: ""
    property real selLat: 51
    property real selLon: 9
    property bool hasSel: false

    property real yaw: 0.0
    property real targetYaw: 0.0
    property real tilt: -0.30
    property var dots: []

    property var geo: ({
        "DE":[51,9],"FI":[64,26],"NL":[52,5],"SE":[60,18],"FR":[47,2],"GB":[54,-2],"US":[39,-98],"PL":[52,19],
        "LT":[55,24],"LV":[57,24],"EE":[59,25],"CH":[47,8],"AT":[47,14],"ES":[40,-4],"IT":[42,12],"NO":[61,8],
        "DK":[56,9],"CZ":[50,15],"RO":[46,25],"BG":[43,25],"TR":[39,35],"UA":[49,32],"KZ":[48,67],"AM":[40,45],
        "GE":[42,43],"RS":[44,21],"MD":[47,28],"HU":[47,19],"IE":[53,-8],"PT":[39,-8],"BE":[50,4],"LU":[49,6],
        "JP":[36,138],"SG":[1,103],"HK":[22,114],"CA":[56,-106],"AE":[24,54],"IL":[31,35],"IN":[22,79],"AU":[-25,133],
        "KR":[37,128],"CY":[35,33],"IS":[65,-18]
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
    function ccFrom(s){
        var c = emojiCode("" + s); if(c.length===2) return c
        var n = decode("" + s).toUpperCase(); var m = n.match(/\b([A-Z]{2})\b/); return (m && root.geo[m[1]]) ? m[1] : ""
    }
    function cleanSrv(s){
        var raw = decode("" + s)
        raw = raw.replace(/[\uD83C][\uDDE6-\uDDFF]/g, "")
        raw = raw.replace(/[☀-➿️]/g, "")
        var cut = raw.split("|")[0].replace(/%[0-9A-Fa-f]{2}/g, " ").replace(/\s+/g, " ").trim()
        return cut.length>0 ? cut : decode("" + s)
    }
    function flagFrom(s){ var c = ccFrom(s); return c.length===2 ? ("qrc:/countriesFlags/images/flagKit/" + c + ".svg") : "" }
    function latText(ms){ if(ms===-3) return "•••"; if(ms<0) return "нет"; return ms + " мс" }
    function latColor(ms){ if(ms<0) return root.mute; if(ms<100) return root.limeStrong; if(ms<250) return root.warn; return root.bad }

    function rotP(p, yaw, tilt){
        var cw=Math.cos(yaw), sw=Math.sin(yaw)
        var x=p[0]*cw+p[2]*sw, z=-p[0]*sw+p[2]*cw, y=p[1]
        var ct=Math.cos(tilt), st=Math.sin(tilt)
        return [x, y*ct-z*st, y*st+z*ct]
    }
    function ll(lat, lon){ var a=lat*Math.PI/180, o=lon*Math.PI/180; return [Math.cos(a)*Math.sin(o), Math.sin(a), Math.cos(a)*Math.cos(o)] }

    function selectSrv(sid, name){
        root.selServerId = "" + sid
        root.selName = "" + name
        root.hasSel = true
        var cc = ccFrom(name)
        if(cc.length===2 && root.geo[cc]){ root.selLat = root.geo[cc][0]; root.selLon = root.geo[cc][1] }
        ServersUiController.setProcessedServerId(sid)
        root.targetYaw = -root.selLon * Math.PI / 180
        globeCv.requestPaint()
    }

    Component.onCompleted: {
        var arr = []
        for(var la=-78; la<=78; la+=6){
            var r = Math.cos(la*Math.PI/180); var n = Math.max(1, Math.round(40*r))
            for(var k=0;k<n;k++){ arr.push(ll(la, k/n*360-180)) }
        }
        root.dots = arr
        ServerLatencyController.measureAll()
    }

    Timer { interval: 40; running: true; repeat: true; onTriggered: {
        var d = root.targetYaw - root.yaw
        d = d - 2*Math.PI*Math.floor((d + Math.PI) / (2*Math.PI))
        if(Math.abs(d) > 0.002){
            root.yaw += d * 0.12
            var n = globeArea.fcount
            var f = Math.round((((root.yaw % (2*Math.PI)) + 2*Math.PI) % (2*Math.PI)) / (2*Math.PI) * n) % n
            earthImg.fidx = f
            globeCv.requestPaint()
        }
    } }

    Rectangle { anchors.fill: parent; color: root.bg }

    Item {
        anchors.fill: parent
        anchors.topMargin: 18 + PageController.safeAreaTopMargin
        anchors.leftMargin: 28; anchors.rightMargin: 28; anchors.bottomMargin: 16

        Column {
            id: head
            anchors.top: parent.top; anchors.left: parent.left; anchors.right: parent.right
            spacing: 4
            Text { text: "Серверы"; color: root.fg; font.pixelSize: 26; font.weight: 800 }
            Text { text: "Выберите страну, и она засветится на планете"; color: root.mute; font.pixelSize: 13 }
        }

        Row {
            anchors.top: head.bottom; anchors.topMargin: 18
            anchors.left: parent.left; anchors.right: parent.right; anchors.bottom: parent.bottom
            spacing: 22

            // ===== Globe =====
            Item {
                id: globeArea
                width: parent.width - 360 - 22
                height: parent.height

                property int fcount: 48
                property int fcols: 8
                property int fsize: 280
                property real gR: Math.min(Math.min(width, height) * 0.40, 180)

                // atmosphere glow (behind the planet)
                Canvas {
                    id: atmoCv
                    anchors.fill: parent
                    Component.onCompleted: requestPaint()
                    Connections {
                        target: globeArea
                        function onWidthChanged(){ atmoCv.requestPaint() }
                        function onHeightChanged(){ atmoCv.requestPaint() }
                    }
                    onPaint: {
                        var c = getContext("2d"); c.reset()
                        c.clearRect(0,0,width,height)
                        var R = globeArea.gR, cx = width/2, cy = height/2
                        var ga = c.createRadialGradient(cx,cy,R*0.86,cx,cy,R*1.34)
                        ga.addColorStop(0,"rgba(96,150,235,0.20)"); ga.addColorStop(1,"rgba(0,0,0,0)")
                        c.fillStyle = ga; c.beginPath(); c.arc(cx,cy,R*1.34,0,7); c.fill()
                    }
                }

                // real Earth — current rotation frame from the sprite sheet
                Image {
                    id: earthImg
                    anchors.centerIn: parent
                    width: globeArea.gR * 2
                    height: globeArea.gR * 2
                    smooth: true
                    cache: true
                    source: "qrc:/images/earth_sheet.png"
                    fillMode: Image.Stretch
                    property int fidx: 0
                    sourceClipRect: Qt.rect((fidx % globeArea.fcols) * globeArea.fsize,
                                            Math.floor(fidx / globeArea.fcols) * globeArea.fsize,
                                            globeArea.fsize, globeArea.fsize)
                }

                // selected-country marker (on top of the planet)
                Canvas {
                    id: globeCv
                    anchors.fill: parent
                    onPaint: {
                        var c = getContext("2d"); c.reset()
                        c.clearRect(0,0,width,height)
                        var R = globeArea.gR, cx = width/2, cy = height/2
                        var yaw = root.yaw, tilt = 0.89
                        if(root.hasSel){
                            var sp = root.rotP(root.ll(root.selLat, root.selLon), yaw, tilt)
                            if(sp[2] > -0.10){
                                var spx = cx+R*sp[0], spy = cy-R*sp[1]
                                c.beginPath(); c.arc(spx,spy,5,0,7); c.fillStyle = "#C8F050"; c.shadowColor = "#C8F050"; c.shadowBlur = 14; c.fill(); c.shadowBlur = 0
                                c.beginPath(); c.arc(spx,spy,10,0,7); c.strokeStyle = "rgba(200,240,80,0.5)"; c.lineWidth = 1; c.stroke()
                            }
                        }
                    }
                }
                // cap
                Rectangle {
                    visible: root.hasSel
                    anchors.bottom: parent.bottom; anchors.horizontalCenter: parent.horizontalCenter
                    height: 36; radius: 18; width: capRow.implicitWidth + 28
                    color: root.bg2; border.color: root.line; border.width: 1
                    Row {
                        id: capRow
                        anchors.centerIn: parent; spacing: 9
                        Image { width: 22; height: 15; anchors.verticalCenter: parent.verticalCenter; source: root.flagFrom(root.selName); visible: root.flagFrom(root.selName).length>0; fillMode: Image.PreserveAspectFit }
                        Text { anchors.verticalCenter: parent.verticalCenter; text: root.cleanSrv(root.selName); color: root.fg; font.pixelSize: 13; font.weight: 700 }
                    }
                }
            }

            // ===== Side: list + connect =====
            Column {
                width: 360
                height: parent.height
                spacing: 12

                Text { text: "ЛОКАЦИИ"; color: root.dim; font.pixelSize: 11; font.weight: 700 }

                ListView {
                    id: srvList
                    width: parent.width
                    height: parent.height - 11 - 12 - 12 - 48
                    clip: true
                    spacing: 8
                    model: ServersModel
                    boundsBehavior: Flickable.StopAtBounds

                    delegate: Rectangle {
                        width: srvList.width; height: 58; radius: 14
                        property bool sel: root.selServerId === ("" + serverId)
                        color: sel ? root.limeSoft : (dMouse.containsMouse ? root.bg2 : root.card)
                        border.color: sel ? root.limeLine : root.line; border.width: 1
                        Behavior on color { ColorAnimation { duration: 120 } }
                        property int lat: ServerLatencyController.latencyFor(serverId)
                        Connections { target: ServerLatencyController; function onLatencyChanged(sid, ms){ if(sid === serverId) lat = ms } }
                        Row {
                            anchors.left: parent.left; anchors.leftMargin: 14; anchors.verticalCenter: parent.verticalCenter; spacing: 12
                            Rectangle { width: 30; height: 30; radius: 8; color: root.bg2; anchors.verticalCenter: parent.verticalCenter; clip: true
                                Image { anchors.centerIn: parent; width: 22; height: 15; source: root.flagFrom(name); visible: root.flagFrom(name).length>0; fillMode: Image.PreserveAspectFit }
                                Rectangle { anchors.centerIn: parent; width: 12; height: 8; radius: 2; color: root.limeStrong; visible: root.flagFrom(name).length===0 } }
                            Column { anchors.verticalCenter: parent.verticalCenter; spacing: 2
                                Text { text: root.cleanSrv(name); color: root.fg; font.pixelSize: 14; font.weight: 600; elide: Text.ElideRight; width: 200 } }
                        }
                        Rectangle { anchors.right: parent.right; anchors.rightMargin: 14; anchors.verticalCenter: parent.verticalCenter
                            height: 22; width: msT.implicitWidth + 16; radius: 11; color: Qt.rgba(1,1,1,0.05); border.width: 1; border.color: root.line
                            Text { id: msT; anchors.centerIn: parent; text: root.latText(parent.parent.lat); color: root.latColor(parent.parent.lat); font.pixelSize: 12; font.weight: 700 } }
                        MouseArea { id: dMouse; anchors.fill: parent; hoverEnabled: true; cursorShape: Qt.PointingHandCursor; onClicked: root.selectSrv(serverId, name) }
                    }
                }

                Rectangle {
                    width: parent.width; height: 48; radius: 13; color: root.hasSel ? root.limeStrong : root.bg2
                    scale: connM.pressed ? 0.98 : 1.0; Behavior on scale { NumberAnimation { duration: 90 } }
                    Text { anchors.centerIn: parent; text: "Подключиться"; color: root.hasSel ? "#0E0E11" : root.mute; font.pixelSize: 15; font.weight: 800 }
                    MouseArea { id: connM; anchors.fill: parent; enabled: root.hasSel; cursorShape: Qt.PointingHandCursor
                        onClicked: {
                            ServersUiController.setProcessedServerId(root.selServerId)
                            ServersUiController.setDefaultServer(root.selServerId)
                            PageController.goToPageHome()
                            ConnectionController.connectButtonClicked()
                        }
                    }
                }
            }
        }
    }
}

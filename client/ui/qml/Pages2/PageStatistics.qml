import QtQuick
import SortFilterProxyModel 0.2
import "../Controls2"

PageType {
  id: root
  property color bg:"#0E0E11"; property color card:"#16171A"; property color bg2:"#1C1D21"; property color bg3:"#25262B"
  property color line: Qt.rgba(1,1,1,0.08); property color fg:"#F5F4EF"; property color mute:"#878B91"; property color dim:"#5A5D63"
  property color lime:"#B8E641"; property color limeStrong:"#C8F050"
  property color limeSoft: Qt.rgba(184/255,230/255,65/255,0.10); property color limeLine: Qt.rgba(184/255,230/255,65/255,0.30)

  property bool conn: ConnectionController.isConnected
  property var samples: []
  property int upSec: 0
  property string serverName: ""

  function fmtB(b){
    if(b>=1073741824) return (b/1073741824).toFixed(2)+" ГБ"
    if(b>=1048576) return (b/1048576).toFixed(1)+" МБ"
    if(b>=1024) return (b/1024).toFixed(0)+" КБ"
    return Math.round(b)+" Б"
  }
  function fmtUp(s){ var h=Math.floor(s/3600), m=Math.floor((s%3600)/60), ss=s%60; return (h>0?(h+":"):"")+("0"+m).slice(-2)+":"+("0"+ss).slice(-2) }
  function refreshServerName(){ var s=proxyServersModel.get(0); root.serverName=(s&&s.name)?s.name:"" }

  SortFilterProxyModel {
    id: proxyServersModel
    sourceModel: ServersModel
    filters: ValueFilter { roleName: "serverId"; value: ServersUiController.processedServerId }
    Component.onCompleted: root.refreshServerName()
  }
  Connections { target: ServersUiController; function onProcessedServerIdChanged(){ root.refreshServerName() } }
  Connections { target: ServersModel; function onModelReset(){ root.refreshServerName() } }

  Connections {
    target: ConnectionController
    function onTrafficChanged(){
      if(root.conn){
        var a = root.samples.slice()
        a.push(ConnectionController.rxSpeedMbps)
        if(a.length>40) a.shift()
        root.samples = a
        spark.requestPaint()
      }
    }
    function onConnectionStateChanged(){
      if(!ConnectionController.isConnected){ root.samples=[]; root.upSec=0; spark.requestPaint() }
      else { root.upSec=0 }
    }
  }

  Timer { interval:1000; repeat:true; running: root.conn; onTriggered: root.upSec++ }

  Component.onCompleted: root.refreshServerName()

  Rectangle { anchors.fill: parent; color: root.bg }

  Flickable {
    anchors.fill: parent
    anchors.topMargin: 10 + PageController.safeAreaTopMargin
    contentHeight: col.implicitHeight + 28
    clip: true
    boundsBehavior: Flickable.StopAtBounds

    Column {
      id: col
      width: root.width
      spacing: 14

      Item { width: parent.width; height: 34
        Text { x:20; anchors.verticalCenter: parent.verticalCenter; text:"Статистика"; color: root.fg; font.pixelSize:24; font.weight:800 } }

      // status card
      Rectangle { x:16; width: root.width-32; height:72; radius:14; color: root.card; border.color: root.line; border.width:1
        Row { anchors.left: parent.left; anchors.leftMargin:16; anchors.verticalCenter: parent.verticalCenter; spacing:12
          Rectangle { width:12; height:12; radius:6; anchors.verticalCenter: parent.verticalCenter
            color: root.conn ? root.limeStrong : root.dim }
          Column { anchors.verticalCenter: parent.verticalCenter; spacing:3; width: root.width-150
            Text { width: parent.width; elide: Text.ElideRight
              text: root.conn ? ("Подключено" + (root.serverName.length>0 ? (" · " + root.serverName) : "")) : "Отключено"
              color: root.fg; font.pixelSize:15; font.weight:700 }
            Text { text: root.conn ? ("в сети " + root.fmtUp(root.upSec)) : "трафик появится после подключения"; color: root.mute; font.pixelSize:12 } } } }

      // live speed card
      Rectangle { x:16; width: root.width-32; height:150; radius:14; color: root.card; border.color: root.line; border.width:1
        Text { x:16; y:14; text:"СКОРОСТЬ"; color: root.dim; font.pixelSize:10; font.weight:700 }
        Row { x:16; y:30; spacing:26
          Column { spacing:2
            Row { spacing:5
              Text { text:"↓"; color: root.limeStrong; font.pixelSize:16; font.weight:800; anchors.bottom: parent.bottom; anchors.bottomMargin:5 }
              Text { text: ConnectionController.rxSpeedMbps.toFixed(2); color: root.fg; font.pixelSize:26; font.weight:800 }
              Text { text:"Mbps"; color: root.mute; font.pixelSize:11; font.weight:600; anchors.bottom: parent.bottom; anchors.bottomMargin:5 } } }
          Column { spacing:2
            Row { spacing:5
              Text { text:"↑"; color: root.mute; font.pixelSize:16; font.weight:800; anchors.bottom: parent.bottom; anchors.bottomMargin:5 }
              Text { text: ConnectionController.txSpeedMbps.toFixed(2); color: root.fg; font.pixelSize:26; font.weight:800 }
              Text { text:"Mbps"; color: root.mute; font.pixelSize:11; font.weight:600; anchors.bottom: parent.bottom; anchors.bottomMargin:5 } } } }
        Canvas { id: spark; x:14; y:78; width: parent.width-28; height:60
          onPaint:{
            var c=getContext("2d"); c.reset();
            var s=root.samples; var n=s.length;
            c.strokeStyle="rgba(255,255,255,0.06)"; c.lineWidth=1; c.beginPath(); c.moveTo(0,height-0.5); c.lineTo(width,height-0.5); c.stroke();
            if(n<2) return;
            var mx=0.3; for(var i=0;i<n;i++){ if(s[i]>mx) mx=s[i]; }
            c.strokeStyle="#C8F050"; c.lineWidth=2; c.lineJoin="round"; c.lineCap="round"; c.beginPath();
            for(var j=0;j<n;j++){ var x=(j/(n-1))*width; var y=height-(s[j]/mx)*(height-6)-3; if(j===0) c.moveTo(x,y); else c.lineTo(x,y); }
            c.stroke();
            c.lineTo(width,height); c.lineTo(0,height); c.closePath(); c.fillStyle="rgba(184,230,65,0.12)"; c.fill();
          } } }

      // session totals
      Item { width: parent.width; height: 2 }
      Text { x:20; text:"ТРАФИК СЕССИИ"; color: root.dim; font.pixelSize:10; font.weight:700 }
      Grid { x:16; columns:2; rowSpacing:8; columnSpacing:8
        Repeater { model:[ {cap:"СКАЧАНО",dl:true},{cap:"ОТДАНО",dl:false} ]
          delegate: Rectangle { width:(root.width-32-8)/2; height:74; radius:12; color: root.card; border.color: root.line; border.width:1
            Column { anchors.left: parent.left; anchors.leftMargin:14; anchors.verticalCenter: parent.verticalCenter; spacing:5
              Text { text: modelData.cap; color: root.dim; font.pixelSize:9; font.weight:700 }
              Text { text: root.fmtB(modelData.dl ? ConnectionController.rxTotalBytes : ConnectionController.txTotalBytes)
                color: modelData.dl ? root.limeStrong : root.fg; font.pixelSize:22; font.weight:800 } } } } }

      Item { width: parent.width; height: 4 }
      Text { visible: !root.conn; x:20; width: root.width-40; wrapMode: Text.WordWrap
        text:"Здесь — живой трафик и скорость текущего подключения. История за день/неделю появится, когда подключим хранение на сервере."
        color: root.dim; font.pixelSize:11 }
    }
  }
}
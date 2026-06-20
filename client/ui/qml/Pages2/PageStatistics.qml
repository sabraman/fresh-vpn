import QtQuick
import SortFilterProxyModel 0.2
import "../Controls2"

PageType {
  id: root
  property color bg:"#0E0E11"; property color card:"#16171A"; property color bg2:"#1C1D21"; property color bg3:"#25262B"
  property color line: Qt.rgba(1,1,1,0.08); property color fg:"#F5F4EF"; property color mute:"#878B91"; property color dim:"#5A5D63"
  property color lime:"#B8E641"; property color limeStrong:"#C8F050"
  property color limeSoft: Qt.rgba(184/255,230/255,65/255,0.10); property color limeLine: Qt.rgba(184/255,230/255,65/255,0.30)
  property color warn:"#FBB26A"

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
  function healthText(){
    var s=ConnectionHealth.healthState
    var st = s===1?"Стабильно":(s===2?"Нестабильно":"проверка…")
    var lat = ConnectionHealth.latencyMs>=0 ? (ConnectionHealth.latencyMs+" мс") : "—"
    var jit = ConnectionHealth.jitterMs>=0 ? (" · джиттер "+ConnectionHealth.jitterMs+" мс") : ""
    return "пинг " + lat + jit + " · " + st
  }

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

      // status + health card
      Rectangle { x:16; width: root.width-32; height: root.conn ? 98 : 72; radius:14; color: root.card; border.color: root.line; border.width:1
        Row { anchors.left: parent.left; anchors.leftMargin:16; anchors.verticalCenter: parent.verticalCenter; spacing:12
          Rectangle { width:12; height:12; radius:6; anchors.verticalCenter: parent.verticalCenter
            color: !root.conn ? root.dim : (ConnectionHealth.healthState===2 ? root.warn : root.limeStrong) }
          Column { anchors.verticalCenter: parent.verticalCenter; spacing:3; width: root.width-150
            Text { width: parent.width; elide: Text.ElideRight
              text: root.conn ? ("Подключено" + (root.serverName.length>0 ? (" · " + root.serverName) : "")) : "Отключено"
              color: root.fg; font.pixelSize:15; font.weight:700 }
            Text { width: parent.width; elide: Text.ElideRight
              text: root.conn ? ("в сети " + root.fmtUp(root.upSec) + (ServersUiController.defaultServerDefaultContainerName.length>0 ? (" · " + ServersUiController.defaultServerDefaultContainerName) : "")) : "трафик появится после подключения"
              color: root.mute; font.pixelSize:12 }
            Text { visible: root.conn; width: parent.width; elide: Text.ElideRight
              text: root.healthText()
              color: ConnectionHealth.healthState===2 ? root.warn : root.limeStrong; font.pixelSize:12; font.weight:600 } } } }

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

      // speed test card
      Rectangle { x:16; width: root.width-32; height:96; radius:14; color: root.card; border.color: root.line; border.width:1
        Text { x:16; y:14; text:"СПИД-ТЕСТ"; color: root.dim; font.pixelSize:10; font.weight:700 }
        Text { x:16; y:36; width: parent.width-130; elide: Text.ElideRight
          text: {
            var s=SpeedTest.state
            if(s===1) return "Загрузка… " + SpeedTest.progress + "%"
            if(s===2) return "Отдача… " + SpeedTest.progress + "%"
            if(s===4) return "Не удалось замерить"
            if(s===3 || SpeedTest.downloadMbps>0) return "↓ " + SpeedTest.downloadMbps.toFixed(1) + "   ↑ " + SpeedTest.uploadMbps.toFixed(1) + " Mbps"
            return "Замерь реальную скорость через VPN"
          }
          color: SpeedTest.state===4 ? root.warn : root.fg; font.pixelSize:16; font.weight:700 }
        Rectangle { anchors.right: parent.right; anchors.rightMargin:14; anchors.verticalCenter: parent.verticalCenter
          width:104; height:40; radius:10
          color: (SpeedTest.state===1||SpeedTest.state===2) ? root.bg3 : root.limeStrong
          Text { anchors.centerIn: parent; text: (SpeedTest.state===1||SpeedTest.state===2) ? "…" : "Запустить"; color:"#0E0E11"; font.pixelSize:13; font.weight:800 }
          MouseArea { anchors.fill: parent; enabled: !(SpeedTest.state===1||SpeedTest.state===2); onClicked: SpeedTest.runTest() } } }

      // session totals      Item { width: parent.width; height: 2 }
      Text { x:20; text:"ТРАФИК СЕССИИ"; color: root.dim; font.pixelSize:10; font.weight:700 }
      Grid { x:16; columns:2; rowSpacing:8; columnSpacing:8
        Repeater { model:[ {cap:"СКАЧАНО",dl:true},{cap:"ОТДАНО",dl:false} ]
          delegate: Rectangle { width:(root.width-32-8)/2; height:74; radius:12; color: root.card; border.color: root.line; border.width:1
            Column { anchors.left: parent.left; anchors.leftMargin:14; anchors.verticalCenter: parent.verticalCenter; spacing:5
              Text { text: modelData.cap; color: root.dim; font.pixelSize:9; font.weight:700 }
              Text { text: root.fmtB(modelData.dl ? ConnectionController.rxTotalBytes : ConnectionController.txTotalBytes)
                color: modelData.dl ? root.limeStrong : root.fg; font.pixelSize:22; font.weight:800 } } } } }

      // leak detector card
      Rectangle { x:16; width: root.width-32; height: 58 + leakBody.implicitHeight; radius:14; color: root.card; border.color: root.line; border.width:1
        Text { x:16; y:14; text:"ПРОВЕРКА УТЕЧЕК"; color: root.dim; font.pixelSize:10; font.weight:700 }
        Rectangle { anchors.right: parent.right; anchors.rightMargin:14; y:8; width:104; height:36; radius:10
          color: (LeakTest.state===1||LeakTest.state===2) ? root.bg3 : root.limeStrong
          Text { anchors.centerIn: parent; text:(LeakTest.state===1||LeakTest.state===2)?"…":"Проверить"; color:"#0E0E11"; font.pixelSize:13; font.weight:800 }
          MouseArea { anchors.fill: parent; enabled: !(LeakTest.state===1||LeakTest.state===2); onClicked: LeakTest.runTest() } }
        Column { id: leakBody; x:16; y:44; width: parent.width-32; spacing:6
          Text { width: parent.width; elide: Text.ElideRight
            text: LeakTest.exitIp.length>0 ? ("IP: " + LeakTest.exitIp) : "Покажу IP, гео и DNS, которые видит внешний мир"
            color: root.fg; font.pixelSize:14; font.weight:700 }
          Text { visible: LeakTest.exitCountry.length>0; width: parent.width; elide: Text.ElideRight
            text: "Гео: " + LeakTest.exitCity + ((LeakTest.exitCity.length>0 && LeakTest.exitCountry.length>0) ? ", " : "") + LeakTest.exitCountry + (LeakTest.isp.length>0 ? (" · " + LeakTest.isp) : "")
            color: root.mute; font.pixelSize:12 }
          Text { visible: LeakTest.state===2 || LeakTest.dnsServers.length>0 || LeakTest.dnsLeak>=0
            width: parent.width; wrapMode: Text.WordWrap
            text: {
              if(LeakTest.state===2) return "DNS: проверяю…"
              if(LeakTest.dnsLeak===0) return "DNS: без утечек · " + LeakTest.dnsServers.length + " сервер(ов)"
              if(LeakTest.dnsLeak===1) return "DNS: возможна утечка — " + LeakTest.dnsServers.join(", ")
              if(LeakTest.dnsServers.length>0) return "DNS: " + LeakTest.dnsServers.join(", ")
              return ""
            }
            color: LeakTest.dnsLeak===1 ? root.warn : (LeakTest.dnsLeak===0 ? root.limeStrong : root.mute); font.pixelSize:12; font.weight:600 }
          Text { visible: LeakTest.state===4; width: parent.width; text:"Не удалось проверить"; color: root.warn; font.pixelSize:12 } } }

      Item { width: parent.width; height: 4 }
      Text { visible: !root.conn; x:20; width: root.width-40; wrapMode: Text.WordWrap
        text:"Здесь — живой трафик, скорость и пинг текущего подключения. История за день/неделю появится, когда подключим хранение на сервере."
        color: root.dim; font.pixelSize:11 }
    }
  }
}
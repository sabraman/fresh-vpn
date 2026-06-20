import QtQuick
import SortFilterProxyModel 0.2
import PageEnum 1.0
import "../Controls2"

PageType {
  id: root
  property color bg:"#0E0E11"; property color card:"#16171A"; property color bg2:"#1C1D21"; property color bg3:"#25262B"
  property color line: Qt.rgba(1,1,1,0.08); property color fg:"#F5F4EF"; property color mute:"#878B91"; property color dim:"#5A5D63"
  property color lime:"#B8E641"; property color limeStrong:"#C8F050"
  property color limeSoft: Qt.rgba(184/255,230/255,65/255,0.10); property color limeLine: Qt.rgba(184/255,230/255,65/255,0.30)
  property color warn:"#FBB26A"; property color bad:"#E5484D"

  // --- real account/subscription state (from engine ApiAccountInfoModel) ---
  property bool acctVisible: false
  property string acctPlan: ""
  property string acctEnd: ""
  property string acctDevices: ""
  property bool subExpired: false
  property bool subSoon: false
  property bool renewAvail: false
  property bool inApp: false
  property string serverName: "Fresh VPN"
  property var menuModel: []

  function fmt(v){ return (v === undefined || v === null) ? "" : ("" + v) }

  function buildMenu(){
    return [
      { t:"server", nm:"Серверы",        ds:"Список и добавление",       vis:true,             act:function(){ root.goP(PageEnum.PageSettingsServersList) } },
      { t:"radio",  nm:"Соединение",      ds:"Kill Switch · туннель · DNS", vis:true,           act:function(){ root.goP(PageEnum.PageSettingsConnection) } },
      { t:"app",    nm:"Приложение",      ds:"Язык · автозапуск · тема",  vis:true,             act:function(){ root.goP(PageEnum.PageSettingsApplication) } },
      { t:"device", nm:"Мои устройства",  ds:root.acctDevices,            vis:root.acctVisible, act:function(){ SubscriptionUiController.updateApiDevicesModel(); root.goP(PageEnum.PageSettingsApiDevices) } },
      { t:"save",   nm:"Резервная копия", ds:"",                          vis:true,             act:function(){ root.goP(PageEnum.PageSettingsBackup) } },
      { t:"help",   nm:"О приложении",    ds:"",                          vis:true,             act:function(){ root.goP(PageEnum.PageSettingsAbout) } }
    ]
  }

  function updateAccount(){
    root.acctVisible = ApiAccountInfoModel.data("isComponentVisible") === true
    root.acctPlan    = root.fmt(ApiAccountInfoModel.data("serviceDescription"))
    root.acctEnd     = root.fmt(ApiAccountInfoModel.data("endDate"))
    root.acctDevices = root.fmt(ApiAccountInfoModel.data("connectedDevices"))
    root.subExpired  = ApiAccountInfoModel.data("isSubscriptionExpired") === true
    root.subSoon     = ApiAccountInfoModel.data("isSubscriptionExpiringSoon") === true
    root.renewAvail  = ApiAccountInfoModel.data("isSubscriptionRenewalAvailable") === true
    root.inApp       = ApiAccountInfoModel.data("isInAppPurchase") === true
    root.menuModel   = root.buildMenu()
  }

  function refreshServerName(){
    var s = proxyServersModel.get(0)
    root.serverName = (s && s.name) ? s.name : "Fresh VPN"
  }

  function goP(p){ PageController.goToPage(p) }

  Component.onCompleted: { root.updateAccount(); root.refreshServerName() }

  Connections { target: ApiAccountInfoModel; function onModelReset(){ root.updateAccount() } }
  Connections { target: ServersModel; function onModelReset(){ root.refreshServerName() } }
  Connections { target: ServersUiController; function onProcessedServerIdChanged(){ root.refreshServerName() } }

  SortFilterProxyModel {
    id: proxyServersModel
    sourceModel: ServersModel
    filters: ValueFilter { roleName: "serverId"; value: ServersUiController.processedServerId }
    Component.onCompleted: root.refreshServerName()
  }

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
      spacing: 12

      Item { width: parent.width; height: 34
        Text { x:20; anchors.verticalCenter: parent.verticalCenter; text:"Профиль"; color: root.fg; font.pixelSize:24; font.weight:800 } }

      // account card (real)
      Rectangle { x:16; width: root.width-32; height:84; radius:14; color: root.card; border.color: root.line; border.width:1
        Row { anchors.left: parent.left; anchors.leftMargin:16; anchors.verticalCenter: parent.verticalCenter; spacing:14
          Rectangle { width:54; height:54; radius:27; anchors.verticalCenter: parent.verticalCenter
            gradient: Gradient { GradientStop{position:0;color: root.limeStrong} GradientStop{position:1;color:"#1F7A3A"} }
            Text { anchors.centerIn: parent; text: (root.acctVisible && root.acctPlan.length>0) ? root.acctPlan.charAt(0).toUpperCase() : (root.serverName.length>0 ? root.serverName.charAt(0).toUpperCase() : "F"); color:"#0E0E11"; font.pixelSize:24; font.weight:800 } }
          Column { anchors.verticalCenter: parent.verticalCenter; spacing:4; width: root.width-180
            Text { width: parent.width; elide: Text.ElideRight; text: root.acctVisible ? (root.acctPlan.length>0 ? root.acctPlan : "Подписка Fresh") : root.serverName; color: root.fg; font.pixelSize:17; font.weight:700 }
            Text { width: parent.width; elide: Text.ElideRight; text: root.acctVisible ? (root.acctEnd.length>0 ? ("активна до " + root.acctEnd) : "подписка активна") : "самостоятельный сервер"; color: root.mute; font.pixelSize:12 } } }
        Rectangle { anchors.right: parent.right; anchors.rightMargin:16; anchors.verticalCenter: parent.verticalCenter; height:24; radius:12; width: pb.width+20
          color: root.subExpired ? Qt.rgba(229/255,72/255,77/255,0.12) : root.limeSoft
          border.color: root.subExpired ? Qt.rgba(229/255,72/255,77/255,0.30) : root.limeLine; border.width:1
          Text { id:pb; anchors.centerIn: parent
            text: root.acctVisible ? (root.subExpired ? "ИСТЕКЛА" : (root.subSoon ? "ИСТЕКАЕТ" : "АКТИВНА")) : "СВОЙ СЕРВЕР"
            color: root.subExpired ? root.bad : root.limeStrong; font.pixelSize:10; font.weight:800 } } }

      // subscription card (gateway accounts only — real renewal)
      Rectangle { visible: root.acctVisible; x:16; width: root.width-32; height: renewBtn.visible ? 100 : 64; radius:14; color: root.card; border.color: root.line; border.width:1
        Column { x:16; y:14; spacing:3; width: parent.width-120
          Text { text:"Подписка"; color: root.fg; font.pixelSize:15; font.weight:700 }
          Text { width: parent.width; elide: Text.ElideRight
            text: root.subExpired ? "истекла" : (root.subSoon ? ("истекает скоро · до " + root.acctEnd) : (root.acctEnd.length>0 ? ("действует до " + root.acctEnd) : "активна"))
            color: root.subExpired ? root.bad : (root.subSoon ? root.warn : root.mute); font.pixelSize:12 }
          Text { visible: root.acctDevices.length>0; text:"устройства: " + root.acctDevices; color: root.mute; font.pixelSize:12 } }
        Rectangle { id: renewBtn; visible: root.renewAvail && !root.inApp; anchors.right: parent.right; anchors.rightMargin:16; y:58; width:108; height:30; radius:9; color: root.limeStrong
          Text { anchors.centerIn: parent; text:"Продлить"; color:"#0E0E11"; font.pixelSize:13; font.weight:700 }
          MouseArea { anchors.fill: parent; cursorShape: Qt.PointingHandCursor; onClicked: SubscriptionUiController.getRenewalLink(ServersUiController.processedServerId) } } }

      Item { width: parent.width; height: 6 }
      Text { x:20; text:"НАСТРОЙКИ"; color: root.dim; font.pixelSize:10; font.weight:700 }
      Column { x:16; width: root.width-32; spacing:8
        Repeater { model: root.menuModel
          delegate: Rectangle { visible: modelData.vis; width: parent.width; height:52; radius:12; color: root.card; border.color: root.line; border.width:1
            Row { anchors.left: parent.left; anchors.leftMargin:12; anchors.verticalCenter: parent.verticalCenter; spacing:12
              Rectangle { width:32; height:32; radius:9; color: root.bg3; anchors.verticalCenter: parent.verticalCenter
                Canvas { anchors.centerIn: parent; width:18; height:18; property string tp: modelData.t
                  onPaint:{ var c=getContext("2d"); c.reset(); c.strokeStyle="#C8F050"; c.fillStyle="#C8F050"; c.lineWidth=1.6; c.lineCap="round"; c.lineJoin="round";
                    if(tp==="server"){ c.strokeRect(3,3,12,4.5); c.strokeRect(3,10.5,12,4.5); c.beginPath(); c.arc(5.5,5.2,0.7,0,2*Math.PI); c.fill(); c.beginPath(); c.arc(5.5,12.7,0.7,0,2*Math.PI); c.fill(); }
                    else if(tp==="radio"){ c.beginPath(); c.arc(9,12,1.5,0,2*Math.PI); c.fill(); c.beginPath(); c.arc(9,12,4.5,Math.PI*1.15,Math.PI*1.85,false); c.stroke(); c.beginPath(); c.arc(9,12,7,Math.PI*1.1,Math.PI*1.9,false); c.stroke(); }
                    else if(tp==="app"){ c.strokeRect(3,3,5,5); c.strokeRect(10,3,5,5); c.strokeRect(3,10,5,5); c.strokeRect(10,10,5,5); }
                    else if(tp==="device"){ c.strokeRect(5,2,8,14); c.beginPath(); c.moveTo(8,13.5); c.lineTo(10,13.5); c.stroke(); }
                    else if(tp==="save"){ c.beginPath(); c.moveTo(3,3); c.lineTo(12,3); c.lineTo(15,6); c.lineTo(15,15); c.lineTo(3,15); c.closePath(); c.stroke(); c.strokeRect(6,10,6,5); }
                    else if(tp==="help"){ c.beginPath(); c.arc(9,9,7,0,2*Math.PI); c.stroke(); c.beginPath(); c.arc(9,7.5,2.4,Math.PI*0.9,Math.PI*2.2,false); c.stroke(); c.beginPath(); c.moveTo(9,10); c.lineTo(9,11.5); c.stroke(); c.beginPath(); c.arc(9,13.6,0.8,0,2*Math.PI); c.fill(); } } } }
              Column { anchors.verticalCenter: parent.verticalCenter; spacing:1
                Text { text: modelData.nm; color: root.fg; font.pixelSize:14; font.weight:600 }
                Text { visible: ("" + modelData.ds).length>0; text: modelData.ds; color: root.mute; font.pixelSize:11 } } }
            Canvas { anchors.right: parent.right; anchors.rightMargin:14; anchors.verticalCenter: parent.verticalCenter; width:8; height:14
              onPaint:{ var c=getContext("2d"); c.reset(); c.strokeStyle="#5A5D63"; c.lineWidth=1.6; c.lineCap="round"; c.lineJoin="round"; c.beginPath(); c.moveTo(1,1); c.lineTo(7,7); c.lineTo(1,13); c.stroke(); } }
            MouseArea { anchors.fill: parent; cursorShape: Qt.PointingHandCursor; onClicked: modelData.act() } } } }

      // add server CTA (real)
      Rectangle { x:16; width: root.width-32; height:58; radius:14; color: root.limeSoft; border.color: root.limeLine; border.width:1
        MouseArea { anchors.fill: parent; cursorShape: Qt.PointingHandCursor; onClicked: root.goP(PageEnum.PageSetupWizardConfigSource) }
        Row { anchors.left: parent.left; anchors.leftMargin:14; anchors.verticalCenter: parent.verticalCenter; spacing:12
          Rectangle { width:34; height:34; radius:10; color: Qt.rgba(184/255,230/255,65/255,0.16); anchors.verticalCenter: parent.verticalCenter
            Text { anchors.centerIn: parent; text:"+"; color: root.limeStrong; font.pixelSize:22; font.weight:700 } }
          Column { anchors.verticalCenter: parent.verticalCenter; spacing:2
            Text { text:"Добавить сервер"; color: root.fg; font.pixelSize:14; font.weight:700 }
            Text { text:"импорт ключа, QR или файла"; color: root.mute; font.pixelSize:11 } } } }
    }
  }
}
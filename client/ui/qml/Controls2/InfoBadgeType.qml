import QtQuick
import QtQuick.Controls

import Style 1.0

Rectangle {
    id: badge

    property string tipText: ""
    property int tipWidth: 228

    width: 16
    height: 16
    radius: 8
    color: AmneziaStyle.fresh.bg3
    border.color: AmneziaStyle.fresh.line
    border.width: 1

    Text {
        anchors.centerIn: parent
        text: "?"
        color: AmneziaStyle.fresh.mute
        font.pixelSize: 10
        font.weight: 800
    }

    MouseArea {
        id: badgeMouse
        anchors.fill: parent
        hoverEnabled: true
    }

    FreshToolTipType {
        id: badgeTip
        parent: badge
        visible: badgeMouse.containsMouse && badge.tipText !== ""
        text: badge.tipText
        tipWidth: badge.tipWidth
        x: badge.width - width
        y: -badgeTip.implicitHeight - 8
    }
}
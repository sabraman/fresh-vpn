import QtQuick
import QtQuick.Controls

import Style 1.0

ToolTip {
    id: control

    property int tipWidth: 228

    delay: 200
    width: control.tipWidth
    padding: 0

    background: Rectangle {
        color: AmneziaStyle.fresh.bg2
        radius: 10
        border.color: AmneziaStyle.fresh.limeLine
        border.width: 1
    }

    contentItem: Text {
        text: control.text
        width: control.tipWidth
        wrapMode: Text.WordWrap
        color: AmneziaStyle.fresh.fg
        font.pixelSize: 12
        leftPadding: 12
        rightPadding: 12
        topPadding: 9
        bottomPadding: 9
    }
}
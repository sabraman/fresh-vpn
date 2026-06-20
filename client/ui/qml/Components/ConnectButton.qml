import QtQuick
import QtQuick.Controls
import QtQuick.Layouts
import QtQuick.Shapes
import Qt5Compat.GraphicalEffects

import ConnectionState 1.0
import PageEnum 1.0
import Style 1.0

Button {
    id: root

    property bool buttonActiveFocus: activeFocus && (Qt.platform.os !== "android" || SettingsController.isOnTv())
    property bool isFocusable: true

    readonly property bool isOn: ConnectionController.isConnected
    readonly property bool isBusy: ConnectionController.isConnectionInProgress

    Keys.onTabPressed: { FocusController.nextKeyTabItem() }
    Keys.onBacktabPressed: { FocusController.previousKeyTabItem() }
    Keys.onUpPressed: { FocusController.nextKeyUpItem() }
    Keys.onDownPressed: { FocusController.nextKeyDownItem() }
    Keys.onLeftPressed: { FocusController.nextKeyLeftItem() }
    Keys.onRightPressed: { FocusController.nextKeyRightItem() }

    implicitWidth: 190
    implicitHeight: 190

    // оставлено для доступности (screen-reader), визуально текст НЕ показывается
    text: ConnectionController.connectionStateText

    Connections {
        target: ConnectionController
        function onPreparingConfig() {
            PageController.showNotificationMessage(qsTr("Unable to disconnect during configuration preparation"))
        }
    }

    background: Item {
        implicitWidth: parent.width
        implicitHeight: parent.height

        Rectangle {
            anchors.centerIn: parent
            width: 190; height: 190; radius: 95
            color: AmneziaStyle.color.transparent
            border.width: 1.5
            border.color: root.isOn ? Qt.rgba(184/255, 230/255, 65/255, 0.12) : AmneziaStyle.color.translucentWhite
        }
        Rectangle {
            anchors.centerIn: parent
            width: 166; height: 166; radius: 83
            color: AmneziaStyle.color.transparent
            border.width: 1.5
            border.color: root.isOn ? Qt.rgba(184/255, 230/255, 65/255, 0.22) : AmneziaStyle.color.sheerWhite
        }

        Rectangle {
            id: coreBase
            anchors.centerIn: parent
            width: 150; height: 150; radius: 75
            color: AmneziaStyle.color.onyxBlack
            border.width: 1.5
            border.color: root.isOn ? AmneziaStyle.color.transparent : AmneziaStyle.color.charcoalGray
        }

        Rectangle {
            id: coreOn
            anchors.centerIn: parent
            width: 150; height: 150; radius: 75
            visible: root.isOn
            gradient: Gradient {
                GradientStop { position: 0.0; color: AmneziaStyle.color.goldenApricotStrong }
                GradientStop { position: 1.0; color: "#5FA524" }
            }
            layer.enabled: true
            layer.effect: DropShadow {
                horizontalOffset: 0; verticalOffset: 0
                radius: 28; samples: 43
                color: Qt.rgba(184/255, 230/255, 65/255, 0.55)
                source: coreOn
            }
        }

        Shape {
            id: spinner
            anchors.centerIn: parent
            width: 150; height: 150
            visible: root.isBusy
            layer.enabled: true
            layer.samples: 4

            ShapePath {
                fillColor: AmneziaStyle.color.transparent
                strokeColor: AmneziaStyle.color.goldenApricot
                strokeWidth: 3
                capStyle: ShapePath.RoundCap

                PathAngleArc {
                    centerX: spinner.width / 2
                    centerY: spinner.height / 2
                    radiusX: 80; radiusY: 80
                    startAngle: 245; sweepAngle: -150
                }
            }

            RotationAnimator {
                target: spinner
                running: root.isBusy
                from: 0
                to: 360
                loops: Animation.Infinite
                duration: 1000
            }
        }
    }

    contentItem: Item {
        Canvas {
            id: powerIcon
            anchors.centerIn: parent
            width: 58; height: 58
            property color col: root.isOn ? AmneziaStyle.color.midnightBlack : AmneziaStyle.color.mutedGray
            onColChanged: requestPaint()
            onPaint: {
                var c = getContext("2d")
                c.reset()
                c.strokeStyle = col
                c.lineWidth = 5
                c.lineCap = "round"
                c.lineJoin = "round"
                var cx = 29, cy = 31, r = 16
                c.beginPath()
                c.arc(cx, cy, r, -Math.PI / 2 + 0.55, -Math.PI / 2 - 0.55 + 2 * Math.PI, false)
                c.stroke()
                c.beginPath()
                c.moveTo(cx, cy - r - 4)
                c.lineTo(cx, cy - 1)
                c.stroke()
            }
        }
    }

    onClicked: {
        ConnectionController.connectButtonClicked()
    }

    Keys.onEnterPressed: this.clicked()
    Keys.onReturnPressed: this.clicked()
}
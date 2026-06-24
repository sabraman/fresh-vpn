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

    // Fresh VPN: лайм-орб. Кольцо-индикатор состояния сохранено (idle / progress / connected),
    // добавлены — заполненный тёмный орб, мягкое лайм-свечение, «дыхание» в покое,
    // лайм-подсветка изнутри при подключении. Логика клика/состояния НЕ изменена.
    property string defaultButtonColor: AmneziaStyle.color.goldenApricot
    property string progressButtonColor: AmneziaStyle.color.paleGray
    property string connectedButtonColor: AmneziaStyle.color.goldenApricot
    property bool buttonActiveFocus: activeFocus && (Qt.platform.os !== "android" || SettingsController.isOnTv())

    property bool isFocusable: true

    Keys.onTabPressed: {
        FocusController.nextKeyTabItem()
    }

    Keys.onBacktabPressed: {
        FocusController.previousKeyTabItem()
    }

    Keys.onUpPressed: {
        FocusController.nextKeyUpItem()
    }

    Keys.onDownPressed: {
        FocusController.nextKeyDownItem()
    }

    Keys.onLeftPressed: {
        FocusController.nextKeyLeftItem()
    }

    Keys.onRightPressed: {
        FocusController.nextKeyRightItem()
    }

    implicitWidth: 190
    implicitHeight: 190

    text: ConnectionController.connectionStateText

    Connections {
        target: ConnectionController

        function onPreparingConfig() {
            PageController.showNotificationMessage(qsTr("Unable to disconnect during configuration preparation"))
        }
    }

//    enabled: !ConnectionController.isConnectionInProgress

    background: Item {
        id: orbBackground
        implicitWidth: parent.width
        implicitHeight: parent.height
        transformOrigin: Item.Center

        // «Дыхание» орба в покое (как в мини-аппе/превью); останавливается при подключении,
        // чтобы не мешать вращающейся дуге прогресса.
        SequentialAnimation on scale {
            running: !ConnectionController.isConnectionInProgress
            loops: Animation.Infinite
            NumberAnimation { from: 1.0; to: 1.035; duration: 1500; easing.type: Easing.InOutQuad }
            NumberAnimation { from: 1.035; to: 1.0; duration: 1500; easing.type: Easing.InOutQuad }
        }

        // Заполненный тёмный орб (читается как объёмная кнопка поверх матрицы)
        Rectangle {
            id: orbFill
            anchors.centerIn: parent
            width: 178
            height: 178
            radius: width / 2
            color: AmneziaStyle.color.midnightBlack

            // Лайм-подсветка изнутри при активном подключении
            Rectangle {
                anchors.fill: parent
                radius: parent.radius
                color: AmneziaStyle.color.softGoldenApricot
                opacity: ConnectionController.isConnected ? 1 : 0
                Behavior on opacity {
                    PropertyAnimation { duration: 400 }
                }
            }
        }

        Shape {
            id: backgroundCircle
            width: parent.implicitWidth
            height: parent.implicitHeight
            anchors.bottom: parent.bottom
            anchors.right: parent.right
            layer.enabled: true
            layer.samples: 4
            layer.smooth: true
            layer.effect: DropShadow {
                anchors.fill: backgroundCircle
                horizontalOffset: 0
                verticalOffset: 0
                radius: 16
                samples: 25
                color: root.buttonActiveFocus ? AmneziaStyle.color.paleGray : AmneziaStyle.color.goldenApricot
                source: backgroundCircle
            }

            ShapePath {
                fillColor: AmneziaStyle.color.transparent
                strokeColor: AmneziaStyle.color.paleGray
                strokeWidth: root.buttonActiveFocus ? 1 : 0
                capStyle: ShapePath.RoundCap

                PathAngleArc {
                    centerX: backgroundCircle.width / 2
                    centerY: backgroundCircle.height / 2
                    radiusX: 94
                    radiusY: 94
                    startAngle: 0
                    sweepAngle: 360
                }
            }

            ShapePath {
                fillColor: AmneziaStyle.color.transparent
                strokeColor: {
                    if (ConnectionController.isConnectionInProgress) {
                        return AmneziaStyle.color.darkCharcoal
                    } else if (ConnectionController.isConnected) {
                        return connectedButtonColor
                    } else {
                        return defaultButtonColor
                    }
                }
                strokeWidth: root.buttonActiveFocus ? 2 : 3
                capStyle: ShapePath.RoundCap

                PathAngleArc {
                    centerX: backgroundCircle.width / 2
                    centerY: backgroundCircle.height / 2
                    radiusX: 93 - (root.buttonActiveFocus ? 2 : 0)
                    radiusY: 93 - (root.buttonActiveFocus ? 2 : 0)
                    startAngle: 0
                    sweepAngle: 360
                }
            }

            MouseArea {
                anchors.fill: parent

                cursorShape: Qt.PointingHandCursor
                enabled: false
            }
        }

        Shape {
            id: shape
            width: parent.implicitWidth
            height: parent.implicitHeight
            anchors.bottom: parent.bottom
            anchors.right: parent.right
            layer.enabled: true
            layer.samples: 4

            visible: ConnectionController.isConnectionInProgress

            ShapePath {
                fillColor: AmneziaStyle.color.transparent
                strokeColor: AmneziaStyle.color.paleGray
                strokeWidth: 3
                capStyle: ShapePath.RoundCap

                PathAngleArc {
                    centerX: shape.width / 2
                    centerY: shape.height / 2
                    radiusX: 93
                    radiusY: 93
                    startAngle: 245
                    sweepAngle: -180
                }
            }

            RotationAnimator {
                target: shape
                running: ConnectionController.isConnectionInProgress
                from: 0
                to: 360
                loops: Animation.Infinite
                duration: 1000
            }
        }
    }

    contentItem: Text {
        height: 24

        font.family: "PT Root UI VF"
        font.weight: 700
        font.pixelSize: 20

        color: ConnectionController.isConnected ? connectedButtonColor : defaultButtonColor
        text: root.text

        horizontalAlignment: Text.AlignHCenter
        verticalAlignment: Text.AlignVCenter
    }

    onClicked: {
        ConnectionController.connectButtonClicked()
    }

    Keys.onEnterPressed: this.clicked()
    Keys.onReturnPressed: this.clicked()
}

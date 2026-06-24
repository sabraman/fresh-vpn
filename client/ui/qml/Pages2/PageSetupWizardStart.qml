import QtQuick
import QtQuick.Controls
import QtQuick.Layouts

import PageEnum 1.0
import Style 1.0

import "./"
import "../Controls2"
import "../Config"
import "../Controls2/TextTypes"
import "../Components"

PageType {
    id: root
    enableTimer: (SettingsController.isOnTv()) ? false : true

    property color bg: "#0E0E11"; property color fg: "#F5F4EF"; property color mute: "#878B91"

    Rectangle { anchors.fill: parent; color: root.bg }

    ColumnLayout {
        id: content
        anchors.fill: parent
        anchors.leftMargin: 24
        anchors.rightMargin: 24
        spacing: 0

        Item { Layout.fillHeight: true; Layout.fillWidth: true }

        Canvas {
            id: keyIcon
            Layout.alignment: Qt.AlignHCenter
            Layout.preferredWidth: 132
            Layout.preferredHeight: 144
            Component.onCompleted: requestPaint()
            onPaint: {
                var c = getContext("2d"); c.reset()
                c.lineCap = "round"; c.lineJoin = "round"
                // bow
                c.strokeStyle = "#74B62B"; c.lineWidth = 13
                c.beginPath(); c.arc(66, 36, 24, 0, 2*Math.PI); c.stroke()
                c.fillStyle = "#0E0E11"; c.beginPath(); c.arc(66, 36, 8, 0, 2*Math.PI); c.fill()
                // shaft + teeth
                c.fillStyle = "#74B62B"
                c.fillRect(60, 58, 13, 64)
                c.fillRect(73, 96, 17, 10)
                c.fillRect(73, 113, 12, 10)
            }
        }

        Text {
            Layout.alignment: Qt.AlignHCenter
            Layout.topMargin: 26
            text: "Подключись за минуту"
            color: root.fg; font.pixelSize: 26; font.weight: 800
            horizontalAlignment: Text.AlignHCenter
        }

        Text {
            Layout.alignment: Qt.AlignHCenter
            Layout.topMargin: 10
            Layout.maximumWidth: 420
            text: "Вставь ключ подписки или отсканируй QR-код — остальное Fresh VPN сделает сам."
            color: root.mute; font.pixelSize: 14
            horizontalAlignment: Text.AlignHCenter
            wrapMode: Text.WordWrap
        }

        Item { Layout.fillHeight: true; Layout.fillWidth: true }

        BasicButtonType {
            id: startButton
            Layout.fillWidth: true
            Layout.maximumWidth: 440
            Layout.alignment: Qt.AlignHCenter
            Layout.bottomMargin: 48 + PageController.safeAreaBottomMargin
            implicitHeight: 48

            defaultColor: "#C8F050"
            hoveredColor: "#D4F571"
            pressedColor: "#9FC72E"
            textColor: "#0E0E11"

            text: qsTr("Начать")

            clickedFunc: function() {
                PageController.goToPage(PageEnum.PageSetupWizardConfigSource)
            }
        }
    }

    Timer {
        interval: 250
        running: SettingsController.isOnTv()
        repeat: true
        onTriggered: {
            startButton.forceActiveFocus()
            if (startButton.activeFocus) {
                running = false
            }
        }
    }

    onVisibleChanged: {
        if (visible && SettingsController.isOnTv()) {
            startButton.forceActiveFocus()
        }
    }
}

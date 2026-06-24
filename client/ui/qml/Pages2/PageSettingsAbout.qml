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

    BackButtonType {
        id: backButton

        anchors.top: parent.top
        anchors.left: parent.left
        anchors.right: parent.right
        anchors.topMargin: 20 + PageController.safeAreaTopMargin

        onActiveFocusChanged: {
            if(backButton.enabled && backButton.activeFocus) {
                listView.positionViewAtBeginning()
            }
        }
    }

    ListViewType {
        id: listView

        anchors.top: backButton.bottom
        anchors.bottom: parent.bottom
        anchors.right: parent.right
        anchors.left: parent.left

        header: ColumnLayout {
            width: listView.width

            // Fresh VPN brand lockup (lime mark + wordmark) - no external image asset
            Rectangle {
                id: logoMark
                Layout.alignment: Qt.AlignCenter
                Layout.topMargin: 40
                Layout.preferredWidth: 96
                Layout.preferredHeight: 96
                radius: 26
                gradient: Gradient {
                    GradientStop { position: 0.0; color: "#C8F050" }
                    GradientStop { position: 1.0; color: "#3E8E2B" }
                }

                Text {
                    anchors.centerIn: parent
                    text: "F"
                    color: "#0E1206"
                    font.pixelSize: 56
                    font.bold: true
                    font.family: "Bricolage Grotesque"
                }
            }

            Header2TextType {
                Layout.fillWidth: true
                Layout.topMargin: 16
                Layout.leftMargin: 16
                Layout.rightMargin: 16

                text: qsTr("Fresh VPN")
                horizontalAlignment: Text.AlignHCenter
            }

            ParagraphTextType {
                Layout.fillWidth: true
                Layout.topMargin: 8
                Layout.leftMargin: 16
                Layout.rightMargin: 16

                horizontalAlignment: Text.AlignHCenter

                font.pixelSize: 14

                text: qsTr("Fast and private VPN. Connect in one tap.")
                color: AmneziaStyle.color.paleGray
            }
        }

        model: 0
        delegate: Item {}

        footer: ColumnLayout {
            width: listView.width

            CaptionTextType {
                Layout.fillWidth: true
                Layout.topMargin: 48

                horizontalAlignment: Text.AlignHCenter

                text: qsTr("Software version: %1").arg(SettingsController.getAppVersion())
                color: AmneziaStyle.color.mutedGray

                MouseArea {
                    property int clickCount: 0
                    anchors.fill: parent
                    onClicked: {
                        if (clickCount > 10) {
                            SettingsController.enableDevMode()
                        } else {
                            clickCount++
                        }
                    }
                }
            }
        }
    }
}
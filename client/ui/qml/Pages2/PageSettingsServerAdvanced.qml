import QtQuick
import QtQuick.Controls
import QtQuick.Layouts

import Style 1.0

import "../Controls2"
import "../Controls2/TextTypes"
import "../Components"
import "../Config"

PageType {
    id: root

    property string srvId: ServersUiController.processedServerId
    property bool supportsDns: ServersUiController.serverSupportsCustomDns(root.srvId)
    property bool hasAwg: ServersUiController.serverHasAwg(root.srvId)

    ListViewType {
        id: listView

        anchors.fill: parent


        header: ColumnLayout {
            width: listView.width
            spacing: 8

            RowLayout {
                Layout.fillWidth: true
                Layout.leftMargin: 16
                Layout.rightMargin: 16
                spacing: 8

                ListItemTitleType {
                    Layout.fillWidth: true
                    text: qsTr("DNS for this server")
                }

                InfoBadgeType {
                    Layout.alignment: Qt.AlignVCenter
                    tipText: qsTr("DNS turns site names into addresses. It applies to THIS server only. The default blocks ads and trackers. Change it if a site does not open or you want a faster resolver.")
                }
            }

            ParagraphTextType {
                Layout.fillWidth: true
                Layout.leftMargin: 16
                Layout.rightMargin: 16

                text: root.supportsDns
                      ? qsTr("Leave empty to use the app default (AdGuard, blocks ads).")
                      : qsTr("This server type does not support a custom DNS.")
            }
        }

        model: 1

        delegate: ColumnLayout {
            id: dnsRow

            width: listView.width
            spacing: 16

            function reloadDns() {
                dns1Field.textField.text = ServersUiController.serverDns1(root.srvId)
                dns2Field.textField.text = ServersUiController.serverDns2(root.srvId)
                mtuField.textField.text = ServersUiController.serverMtu(root.srvId)
            }

            Component.onCompleted: dnsRow.reloadDns()
            ListView.onReused: dnsRow.reloadDns()

            Connections {
                target: root
                function onSrvIdChanged() { dnsRow.reloadDns() }
            }

            TextFieldWithHeaderType {
                id: dns1Field

                Layout.fillWidth: true
                Layout.topMargin: 16
                Layout.leftMargin: 16
                Layout.rightMargin: 16

                headerText: qsTr("Primary DNS")
                textField.placeholderText: "94.140.14.14"
                textField.validator: RegularExpressionValidator {
                    regularExpression: InstallController.ipAddressRegExp()
                }
            }

            TextFieldWithHeaderType {
                id: dns2Field

                Layout.fillWidth: true
                Layout.leftMargin: 16
                Layout.rightMargin: 16

                headerText: qsTr("Backup DNS")
                textField.placeholderText: "94.140.15.15"
                textField.validator: RegularExpressionValidator {
                    regularExpression: InstallController.ipAddressRegExp()
                }
            }

            DividerType { Layout.topMargin: 8 }

            RowLayout {
                Layout.fillWidth: true
                Layout.topMargin: 8
                Layout.leftMargin: 16
                Layout.rightMargin: 16
                spacing: 8

                ListItemTitleType {
                    Layout.fillWidth: true
                    text: qsTr("Packet size (MTU)")
                }

                InfoBadgeType {
                    Layout.alignment: Qt.AlignVCenter
                    tipText: qsTr("The size of one packet. If pages do not load on mobile internet, lower it to 1280. Applies to this server only.")
                }
            }

            ParagraphTextType {
                Layout.fillWidth: true
                Layout.leftMargin: 16
                Layout.rightMargin: 16
                visible: !root.hasAwg
                text: qsTr("This server has no AmneziaWG, so MTU does not apply.")
            }

            RowLayout {
                Layout.fillWidth: true
                Layout.topMargin: 8
                Layout.leftMargin: 16
                Layout.rightMargin: 16
                spacing: 8
                visible: root.hasAwg

                Repeater {
                    model: [
                        { lbl: qsTr("Mobile"), v: "1280" },
                        { lbl: qsTr("Default"), v: "1376" },
                        { lbl: qsTr("Maximum"), v: "1420" }
                    ]
                    delegate: Rectangle {
                        Layout.fillWidth: true
                        height: 36
                        radius: 10
                        property bool sel: mtuField.textField.text === modelData.v
                        color: sel ? AmneziaStyle.fresh.limeStrong : AmneziaStyle.fresh.bg2
                        border.color: sel ? AmneziaStyle.fresh.limeLine : AmneziaStyle.fresh.line
                        border.width: 1
                        scale: presetM.pressed ? 0.95 : 1.0
                        Behavior on scale { NumberAnimation { duration: 90; easing.type: Easing.OutQuad } }
                        Text {
                            anchors.centerIn: parent
                            text: modelData.lbl + " " + modelData.v
                            color: parent.sel ? "#11140A" : AmneziaStyle.fresh.mute
                            font.pixelSize: 12
                            font.weight: 700
                        }
                        MouseArea {
                            id: presetM
                            anchors.fill: parent
                            cursorShape: Qt.PointingHandCursor
                            onClicked: mtuField.textField.text = modelData.v
                        }
                    }
                }
            }

            TextFieldWithHeaderType {
                id: mtuField

                Layout.fillWidth: true
                Layout.topMargin: 8
                Layout.leftMargin: 16
                Layout.rightMargin: 16
                visible: root.hasAwg

                headerText: qsTr("MTU")
                textField.placeholderText: "1376"
                textField.validator: IntValidator { bottom: 576; top: 65535 }
            }

            BasicButtonType {
                Layout.fillWidth: true
                Layout.leftMargin: 16
                Layout.rightMargin: 16
                visible: root.hasAwg

                text: qsTr("Save MTU")

                clickedFunc: function() {
                    ServersUiController.setServerMtu(root.srvId, mtuField.textField.text)
                }
            }
            BasicButtonType {
                Layout.fillWidth: true
                Layout.leftMargin: 16
                Layout.rightMargin: 16

                text: qsTr("Save")

                clickedFunc: function() {
                    ServersUiController.setServerDns(root.srvId, dns1Field.textField.text, dns2Field.textField.text)
                }
            }

            BasicButtonType {
                Layout.fillWidth: true
                Layout.leftMargin: 16
                Layout.rightMargin: 16
                Layout.bottomMargin: 16

                defaultColor: AmneziaStyle.color.transparent
                hoveredColor: AmneziaStyle.color.translucentWhite
                pressedColor: AmneziaStyle.color.sheerWhite
                textColor: AmneziaStyle.color.paleGray
                borderWidth: 1
                text: qsTr("Use app default")

                clickedFunc: function() {
                    dns1Field.textField.text = ""
                    dns2Field.textField.text = ""
                    ServersUiController.setServerDns(root.srvId, "", "")
                }
            }
        }
    }
}
import QtQuick 2.15
import QtQuick.Controls 2.15
import QtQuick.Layouts 1.15

Rectangle {
    id: trackHeader
    color: "#202020"
    border.color: "#0A0A0A"
    border.width: 1

    signal addTrackClicked()
    signal toolsClicked()

    RowLayout {
        anchors.fill: parent
        anchors.margins: 4
        spacing: 8

        // Add Track Button
        Rectangle {
            width: 80
            height: 20
            color: addTrackMouse.containsMouse ? "#252525" : "#151515"
            border.color: "#0A0A0A"

            RowLayout {
                anchors.centerIn: parent
                spacing: 4

                Image {
                    source: "qrc:/icons/plus.svg"
                    width: 10
                    height: 10
                }

                Text {
                    text: "Add Track"
                    color: "#808080"
                    font.pixelSize: 11
                    font.family: "Inter Display"
                }
            }

            MouseArea {
                id: addTrackMouse
                anchors.fill: parent
                hoverEnabled: true
                cursorShape: Qt.PointingHandCursor
                onClicked: trackHeader.addTrackClicked()
            }
        }

        Item { Layout.fillWidth: true }

        // Tools Button
        Rectangle {
            width: 60
            height: 20
            color: toolsMouse.containsMouse ? "#252525" : "#151515"
            border.color: "#0A0A0A"

            Text {
                anchors.centerIn: parent
                text: "Tools"
                color: "#808080"
                font.pixelSize: 11
                font.family: "Inter Display"
            }

            MouseArea {
                id: toolsMouse
                anchors.fill: parent
                hoverEnabled: true
                cursorShape: Qt.PointingHandCursor
                onClicked: trackHeader.toolsClicked()
            }
        }
    }
}

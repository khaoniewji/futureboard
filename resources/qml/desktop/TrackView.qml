// TrackView.qml
import QtQuick 2.15
import QtQuick.Controls 2.15
import QtQuick.Layouts 1.15

Rectangle {
    id: trackView
    color: "#2D2D2D"

    property alias trackListModel: trackModel  // Changed from trackModel to trackListModel

    ListModel {
        id: trackModel
        ListElement {
            name: "Audio 1"
            type: "audio"
            color: "#297ACC"
        }
        ListElement {
            name: "MIDI 1"
            type: "midi"
            color: "#7AC929"
        }
        ListElement {
            name: "Automation"
            type: "automation"
            color: "#C92929"
        }
    }

    ColumnLayout {
        anchors.fill: parent
        spacing: 1

        Rectangle {
            width: parent.width
            height: 33
            color: "#3A3A3A"

            Text {
                anchors.verticalCenter: parent.verticalCenter
                anchors.left: parent.left
                anchors.leftMargin: 10
                anchors.right: parent.right
                anchors.rightMargin: 10
                text: "Add Track"
                color: "#FFFFFF"
                font.pixelSize: 11
                font.family: "Inter Display"
            }

            MouseArea {
                anchors.fill: parent
                onClicked: {
                    trackModel.append({
                        name: "New Track",
                        type: "audio",
                        color: "#297ACC"
                    })
                }
            }
        }

        ListView {
            id: trackList
            Layout.fillWidth: true
            Layout.fillHeight: true
            model: trackModel
            spacing: 1
            clip: true

            delegate: TrackWidget {
                width: trackList.width
            }
        }
    }

    Menu {
        id: trackContextMenu
        MenuItem { text: "Add Audio Track" }
        MenuItem { text: "Add MIDI Track" }
        MenuItem { text: "Add Automation Track" }
        MenuSeparator {}
        MenuItem { text: "Remove Track" }
    }
}

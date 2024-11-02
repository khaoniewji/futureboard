// TrackView.qml
import QtQuick 2.15
import QtQuick.Controls 2.15
import QtQuick.Layouts 1.15
import "." as Local

Rectangle {
    id: trackView
    color: "#2D2D2D"

    property var trackModel: ListModel {
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
            height: 32
            color: "#3A3A3A"

            // Padding for the text
            Text {
                anchors.verticalCenter: parent.verticalCenter
                anchors.left: parent.left
                anchors.leftMargin: 10  // Padding on the left
                anchors.right: parent.right
                anchors.rightMargin: 10 // Padding on the right
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


        // Track list
        ListView {
            id: trackList
            Layout.fillWidth: true
            Layout.fillHeight: true
            model: trackModel
            spacing: 1
            clip: true

            delegate: Local.TrackWidget {
                width: trackList.width
                // trackColor: model.color
                // Other track-specific properties
            }
        }
    }

    // Context menu for track operations
    Menu {
        id: trackContextMenu
        MenuItem { text: "Add Audio Track" }
        MenuItem { text: "Add MIDI Track" }
        MenuItem { text: "Add Automation Track" }
        MenuSeparator {}
        MenuItem { text: "Remove Track" }
    }
}

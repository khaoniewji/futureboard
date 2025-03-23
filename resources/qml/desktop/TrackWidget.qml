import QtQuick 2.15
import QtQuick.Controls 2.15
import QtQuick.Layouts 1.15

Rectangle {
    id: trackWidget
    width: 272
    height: 42
    color: selected ? "#202020" : "#151515"
    border.color: "#0A0A0A"
    border.width: 1

    property bool selected: false
    property real volume: 0.75
    property real pan: 0.0
    property string trackName: "Audio Track"
    property int trackNumber: 1
    property bool isAudioTrack: true

    RowLayout {
        anchors.fill: parent
        anchors.margins: 1
        spacing: -1

        // Track Number
        Rectangle {
            width: 28
            Layout.fillHeight: true
            color: "#202020"
            border.color: "#0A0A0A"

            Text {
                anchors.centerIn: parent
                text: trackNumber
                color: "#808080"
                font.pixelSize: 10
                font.family: "Inter Display"
            }
        }

        // Main Controls
        ColumnLayout {
            Layout.fillWidth: true
            Layout.fillHeight: true
            spacing: 1

            // Track Name
            Rectangle {
                Layout.fillWidth: true
                Layout.preferredHeight: parent.height * 0.6
                color: "transparent"  // Changed from "#202020" to "transparent"
                border.color: "#0A0A0A"

                Rectangle {
                    anchors.right: parent.right
                    width: parent.width * volume
                    height: parent.height
                    color: volume > 0.8 ? "#FF4040" : "#40FF40"
                    opacity: 0.2
                }

                TextInput {
                    anchors.fill: parent
                    anchors.margins: 4
                    text: trackName
                    color: "#B0B0B0"
                    font.pixelSize: 11
                    font.family: "Inter Display"
                    verticalAlignment: Text.AlignVCenter

                    MouseArea {
                        anchors.fill: parent
                        property bool isDragging: false
                        property real startY: 0
                        
                        onPressed: {
                            isDragging = false
                            startY = mouseY
                        }
                        
                        onMouseYChanged: {
                            if (pressed) {
                                if (Math.abs(mouseY - startY) > 5) {  // Reduced threshold
                                    isDragging = true
                                }
                                if (isDragging) {
                                    var delta = (startY - mouseY) / 100
                                    var newVolume = Math.max(0, Math.min(1, volume + delta))
                                    volume = newVolume
                                    startY = mouseY  // Update startY for continuous movement
                                }
                            }
                        }
                        
                        onDoubleClicked: parent.forceActiveFocus()
                        onReleased: isDragging = false
                    }

                    onTextChanged: {
                        trackName = text  // This will trigger the NOTIFY signal automatically
                    }
                }
            }

            // Track Controls
            Rectangle {
                Layout.fillWidth: true
                Layout.fillHeight: true
                color: "#202020"
                border.color: "#0A0A0A"

                Row {
                    anchors.centerIn: parent
                    spacing: 1

                    Repeater {
                        model: ["M", "S", "R", isAudioTrack ? "STEREO" : "EDIT"]

                        Rectangle {
                            width: modelData.length > 1 ? 42 : 20
                            height: 16
                            color: "#151515"
                            border.color: "#0A0A0A"

                            Text {
                                anchors.centerIn: parent
                                text: modelData
                                color: "#808080"
                                font.pixelSize: 9
                                font.family: "Inter Display"
                            }

                            MouseArea {
                                anchors.fill: parent
                                onClicked: {
                                    if (modelData === "EDIT") {
                                        // TODO: Open plugin editor
                                    }
                                }
                            }
                        }
                    }
                }
            }
        }

        // Volume/Pan
        Rectangle {
            width: 42
            Layout.fillHeight: true
            color: "#202020"
            border.color: "#0A0A0A"

            ColumnLayout {
                anchors.fill: parent
                anchors.margins: 1
                spacing: 1

                Rectangle {
                    Layout.fillWidth: true
                    Layout.fillHeight: true
                    color: "#151515"
                    
                    // Pan indicator
                    Rectangle {
                        width: 1
                        height: parent.height * 0.7
                        color: "#606060"
                        anchors.centerIn: parent
                        rotation: -45 + (pan * 90)
                    }

                    MouseArea {
                        anchors.fill: parent
                        property bool isDragging: false
                        property real startX: 0
                        
                        onPressed: {
                            isDragging = false
                            startX = mouseX
                        }
                        
                        onMouseXChanged: {
                            if (pressed) {
                                if (Math.abs(mouseX - startX) > 10) {
                                    isDragging = true
                                }
                                if (isDragging) {
                                    pan = Math.max(-1, Math.min(1, (mouseX / width * 2) - 1))
                                }
                            }
                        }
                    }
                }

                Rectangle {
                    Layout.fillWidth: true
                    Layout.fillHeight: true
                    color: "#151515"
                }
            }
        }
    }
}

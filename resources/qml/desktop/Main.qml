import QtQuick 2.15
import QtQuick.Controls 2.15
import QtQuick.Layouts 1.15

import "." as Local
import "MenuItems" as Menu

Rectangle {
    width: 1280
    height: 720
    color: "#2D2D2D"

    // Custom value slider component
    component ValueSlider: Rectangle {
        id: valueSlider
        height: 60
        width: parent.width
        color: "transparent"
        property real value: 0.7
        property real minValue: 0
        property real maxValue: 1
        property string valueLabel: "0.0 dB"
        property color activeColor: "#297ACC"

        Rectangle {
            id: track
            width: 4
            height: parent.height - 20
            color: "#404040"
            anchors.centerIn: parent

            Rectangle {
                width: parent.width
                height: parent.height * valueSlider.value
                color: valueSlider.activeColor
                anchors.bottom: parent.bottom
            }
        }

        Rectangle {
            id: handle
            width: 16
            height: 8
            radius: 2
            color: valueSlider.activeColor
            y: (parent.height - 20) * (1 - valueSlider.value) + 10
            anchors.horizontalCenter: track.horizontalCenter

            MouseArea {
                anchors.fill: parent
                drag.target: parent
                drag.axis: Drag.YAxis
                drag.minimumY: 10
                drag.maximumY: valueSlider.height - 20
                onPositionChanged: {
                    if (drag.active) {
                        valueSlider.value = 1 - ((parent.y - 10) / (valueSlider.height - 30))
                        valueSlider.valueLabel = (20 * Math.log10(valueSlider.value)).toFixed(1) + " dB"
                    }
                }
            }
        }

        Text {
            text: valueSlider.valueLabel
            color: "#FFFFFF"
            font.pixelSize: 10
            anchors.horizontalCenter: parent.horizontalCenter
            anchors.bottom: parent.bottom
        }
    }

    Local.Transport {
        id: transportBar
        anchors.left: parent.left
        anchors.right: parent.right
        property int currentBpm: 120
        property string timeSignature: "4/4"
        property bool isPlaying: false
        property real playbackPosition: 0

        function onPlayPause() {
            isPlaying = !isPlaying
        }

        function onStop() {
            isPlaying = false
            playbackPosition = 0
        }

        function onRecord() {
            // Implement record logic
        }
    }

    // Main content area with zoom controls
    Rectangle {
        id: mainContent
        anchors {
            top: transportBar.bottom
            left: parent.left
            right: parent.right
            bottom: statusBar.top
        }
        color: "#1E1E1E"

        Rectangle {
            id: trackListPanel
            width: 300
            anchors {
                top: parent.top
                bottom: parent.bottom
                left: parent.left
            }
            color: "#2D2D2D"
            z: 1

            property alias trackListModel: trackView.trackListModel  // Add this property

            Local.TrackView {
                id: trackView
                anchors.fill: parent
            }
        }

        Rectangle {
            id: contentArea
            anchors {
                top: parent.top
                bottom: parent.bottom
                left: trackListPanel.right
                right: parent.right
            }
            color: "#252525"

            SplitView {
                anchors.fill: parent
                orientation: Qt.Vertical

                Local.Timeline {
                    id: timeline
                    SplitView.preferredHeight: 32
                    SplitView.minimumHeight: 32
                    SplitView.maximumHeight: 32
                    SplitView.fillWidth: true

                    onPositionChanged: function(position) {
                        // Handle timeline position changes
                        // For example, update playhead position
                        transportBar.playbackPosition = position
                    }

                    onZoomChanged: function(level) {
                        // Handle zoom level changes
                        // Update grid or other elements if needed
                        gridArea.updateGrid()
                    }
                }

                Rectangle {
                    id: gridArea
                    SplitView.fillHeight: true
                    SplitView.fillWidth: true
                    color: "#202020"
                    clip: true

                    // Flickable to sync with timeline
                    Flickable {
                        id: gridFlickable
                        anchors.fill: parent
                        contentWidth: timeline.contentWidth
                        contentHeight: trackRepeater.count * 42  // Match TrackWidget height
                        boundsBehavior: Flickable.StopAtBounds
                        clip: true

                        // Sync horizontal scrolling with timeline
                        Connections {
                            target: timeline
                            function onScrollPositionChanged() {
                                gridFlickable.contentX = timeline.scrollPosition
                            }
                        }

                        // Background grid
                        Item {
                            width: parent.width
                            height: parent.height

                            // Vertical grid lines
                            Repeater {
                                model: initialBars + extraBars
                                Rectangle {
                                    x: index * timeline.barInterval
                                    width: 1
                                    height: parent.height
                                    color: index % 4 === 0 ? "#3A3A3A" : "#2A2A2A"
                                }
                            }

                            // Beat lines
                            Repeater {
                                model: (initialBars + extraBars) * 4
                                Rectangle {
                                    x: index * timeline.beatInterval
                                    width: 1
                                    height: parent.height
                                    color: "#2A2A2A"
                                    visible: index % 4 !== 0  // Don't show on bar lines
                                    opacity: 0.5
                                }
                            }
                        }

                        // Track content area
                        Column {
                            id: trackContentColumn
                            width: parent.width

                            Repeater {
                                id: trackRepeater
                                model: trackListPanel.trackListModel

                                Rectangle {
                                    id: trackContent
                                    width: gridFlickable.contentWidth
                                    height: 43  // Match TrackWidget height
                                    color: "transparent"

                                    // Track content background
                                    Rectangle {
                                        anchors.fill: parent
                                        color: index % 2 === 0 ? "#1A1A1A" : "#1E1E1E"
                                        opacity: 0.5
                                    }

                                    // // Clip area for this track
                                    // Row {
                                    //     anchors.fill: parent
                                    //     spacing: 0

                                    //     // Add your clip components here
                                    //     // Example placeholder for clips:
                                    //     Repeater {
                                    //         model: 3  // Example: 3 clips per track
                                    //         Rectangle {
                                    //             width: timeline.barInterval * 2  // 2 bars per clip
                                    //             height: parent.height - 8
                                    //             anchors.verticalCenter: parent.verticalCenter
                                    //             color: model.color || "#297ACC"
                                    //             opacity: 0.6
                                    //             radius: 4
                                    //             x: index * timeline.barInterval * 3  // Space them out

                                    //             // Clip label
                                    //             Text {
                                    //                 anchors.centerIn: parent
                                    //                 text: "Clip " + (index + 1)
                                    //                 color: "#FFFFFF"
                                    //                 font.pixelSize: 10
                                    //             }
                                    //         }
                                    //     }
                                    // }
                                }
                            }
                        }
                    }

                    // Playhead
                    Rectangle {
                        id: playhead
                        width: 2
                        height: parent.height
                        color: "#297ACC"
                        x: transportBar.playbackPosition * timeline.barInterval - gridFlickable.contentX
                        visible: true
                        z: 1000
                    }


                }
            }
        }

        ScrollBar {
            id: verticalScrollBar
            anchors {
                top: contentArea.top
                bottom: horizontalScrollBar.top
                right: parent.right
            }
            active: true
            orientation: Qt.Vertical
            width: 8
            background: Rectangle {
                color: "#1A1A1A"
            }
            contentItem: Rectangle {
                color: verticalScrollBar.pressed ? "#297ACC" : "#4A4A4A"
            }
        }

        ScrollBar {
            id: horizontalScrollBar
            anchors {
                left: contentArea.left
                right: parent.right
                bottom: parent.bottom
            }
            active: true
            orientation: Qt.Horizontal
            height: 8
            background: Rectangle {
                color: "#1A1A1A"
            }
            contentItem: Rectangle {
                color: horizontalScrollBar.pressed ? "#297ACC" : "#4A4A4A"
            }
        }
    }

    Rectangle {
        id: statusBar
        height: 25
        width: parent.width
        anchors.bottom: parent.bottom
        color: "#383838"

        Label {
            anchors.left: parent.left
            anchors.leftMargin: 10
            anchors.verticalCenter: parent.verticalCenter
            font.family: "IBM Plex Sans"
            text: "Current Project: Untitled.ftbp / A = 440hz / Sample Rate: 480000 / ASIO: FlexASIO 256smp 4.04 ms"
            color: "white"
        }

        Row {
            anchors.right: parent.right
            anchors.rightMargin: 10
            anchors.verticalCenter: parent.verticalCenter
            spacing: 15

            Text {
                text: transportBar.currentBpm + " BPM"
                color: "white"
                font.family: "IBM Plex Sans"
            }

            Text {
                text: transportBar.timeSignature
                color: "white"
                font.family: "IBM Plex Sans"
            }
        }
    }

    Local.CommandPallette {
        id: commandPalette
        anchors.fill: parent
        visible: false

        // Convert menu items to commands
        Component.onCompleted: {
            var commands = [];
            Menu.Items.menuItems.forEach(function(menuGroup) {
                menuGroup.items.forEach(function(item) {
                    commands.push({
                        label: item.name,
                        shortcut: item.shortcut || "",
                        category: menuGroup.menu
                    });
                });
            });
            applicationCommands = commands;
        }


        onCommandExecuted: function(command) {
            switch(command.label) {
                case "Play/Pause":
                    transportBar.onPlayPause()
                    break
                case "Stop":
                    transportBar.onStop()
                    break
                case "Toggle Record":
                    transportBar.onRecord()
                    break
                case "Zoom In":
                    timeline.zoomIn()
                    break
                case "Zoom Out":
                    timeline.zoomOut()
                    break
                default:
                    console.log("Executing command:", command.label)
            }
        }
    }
    Connections {
        target: commandPalette
        function onVisibleChanged() {
            if (commandPalette.visible) {
                commandPalette.forceActiveFocus()
            }
        }
    }

    Shortcut {
        sequences: ["Ctrl+Shift+P", "Ctrl+P"]
        context: Qt.ApplicationShortcut
        onActivated: commandPalette.show()
    }
}

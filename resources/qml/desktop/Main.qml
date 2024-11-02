import QtQuick 2.15
import QtQuick.Controls 2.15
import QtQuick.Layouts 1.15

import "." as Local

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

        // Add transport controls integration
        function onPlayPause() {
            isPlaying = !isPlaying
            // Implement play/pause logic
        }

        function onStop() {
            isPlaying = false
            playbackPosition = 0
            // Implement stop logic
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

        // Track list panel
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

            Local.TrackView {
                anchors.fill: parent
            }
        }

        // Content area with enhanced grid
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

                    property real zoomLevel: 1.0
                    function zoomIn() {
                        zoomLevel = Math.min(zoomLevel * 1.2, 4.0)
                        barInterval = baseBarInterval * zoomLevel
                    }
                    function zoomOut() {
                        zoomLevel = Math.max(zoomLevel / 1.2, 0.25)
                        barInterval = baseBarInterval * zoomLevel
                    }
                }

                // Enhanced grid area
                Rectangle {
                    id: gridArea
                    SplitView.fillHeight: true
                    SplitView.fillWidth: true
                    color: "#202020"
                    clip: true

                    // Vertical grid lines
                    Grid {
                        id: verticalGrid
                        anchors.fill: parent
                        spacing: timeline.barInterval - 1
                        columns: timeline.bars
                        rows: 1

                        Repeater {
                            model: timeline.bars
                            Rectangle {
                                width: 1
                                height: parent.height
                                color: index % 4 === 0 ? "#3A3A3A" : "#2A2A2A"
                            }
                        }
                    }

                    // Playhead
                    Rectangle {
                        id: playhead
                        width: 2
                        height: parent.height
                        color: "#297ACC"
                        x: transportBar.playbackPosition * timeline.barInterval
                        visible: true
                    }
                }
            }
        }

        // Enhanced scrollbars
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

        // Additional status indicators
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
}

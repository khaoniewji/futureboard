import QtQuick 2.15
import QtQuick.Controls 2.15
import QtQuick.Layouts 1.15

import "." as Local

Rectangle {
    width: Screen.width
    height: Screen.height
    color: "#2D2D2D"

    component ValueSlider: Rectangle {
        id: valueSlider
        height: 80
        width: parent.width
        color: "transparent"
        property real value: 0.7
        property real minValue: 0
        property real maxValue: 1
        property string valueLabel: "0.0 dB"
        property color activeColor: "#297ACC"

        Rectangle {
            id: track
            width: 6
            height: parent.height - 24
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
            width: 24
            height: 12
            radius: 3
            color: valueSlider.activeColor
            y: (parent.height - 24) * (1 - valueSlider.value) + 12
            anchors.horizontalCenter: track.horizontalCenter

            MouseArea {
                anchors.fill: parent
                anchors.margins: -12
                drag.target: parent
                drag.axis: Drag.YAxis
                drag.minimumY: 12
                drag.maximumY: valueSlider.height - 24
                onPositionChanged: {
                    if (drag.active) {
                        valueSlider.value = 1 - ((parent.y - 12) / (valueSlider.height - 36))
                        valueSlider.valueLabel = (20 * Math.log10(valueSlider.value)).toFixed(1) + " dB"
                    }
                }
            }
        }

        Text {
            text: valueSlider.valueLabel
            color: "#FFFFFF"
            font.pixelSize: 12
            anchors.horizontalCenter: parent.horizontalCenter
            anchors.bottom: parent.bottom
        }
    }

    Local.Transport {
        id: transportBar
        height: 48
        anchors.left: parent.left
        anchors.right: parent.right
        property int currentBpm: 120
        property string timeSignature: "4/4"
        property bool isPlaying: false
        property real playbackPosition: 0

        function onPlayPause() { isPlaying = !isPlaying }
        function onStop() {
            isPlaying = false
            playbackPosition = 0
        }
        function onRecord() { /* Implement record logic */ }
    }

    Rectangle {
        id: mainContent
        anchors {
            top: transportBar.bottom
            left: parent.left
            right: parent.right
            bottom: parent.bottom
        }
        color: "#1E1E1E"

        Rectangle {
            id: trackListPanel
            width: parent.width * 0.3
            anchors {
                top: parent.top
                bottom: parent.bottom
                left: parent.left
            }
            color: "#2D2D2D"
            z: 1

            property alias trackListModel: trackView.trackListModel

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
                    SplitView.preferredHeight: 40
                    SplitView.minimumHeight: 40
                    SplitView.maximumHeight: 40
                    SplitView.fillWidth: true
                }

                Rectangle {
                    id: gridArea
                    SplitView.fillHeight: true
                    SplitView.fillWidth: true
                    color: "#202020"
                    clip: true

                    Flickable {
                        id: gridFlickable
                        anchors.fill: parent
                        contentWidth: timeline.contentWidth
                        contentHeight: trackRepeater.count * 42
                        boundsBehavior: Flickable.StopAtBounds
                        clip: true

                        Connections {
                            target: timeline
                            function onScrollPositionChanged() {
                                gridFlickable.contentX = timeline.scrollPosition
                            }
                        }

                        Item {
                            width: parent.width
                            height: parent.height

                            Repeater {
                                model: initialBars + extraBars
                                Rectangle {
                                    x: index * timeline.barInterval
                                    width: 1
                                    height: parent.height
                                    color: index % 4 === 0 ? "#3A3A3A" : "#2A2A2A"
                                }
                            }

                            Repeater {
                                model: (initialBars + extraBars) * 4
                                Rectangle {
                                    x: index * timeline.beatInterval
                                    width: 1
                                    height: parent.height
                                    color: "#2A2A2A"
                                    visible: index % 4 !== 0
                                    opacity: 0.5
                                }
                            }
                        }

                        Column {
                            id: trackContentColumn
                            width: parent.width

                            Repeater {
                                id: trackRepeater
                                model: trackListPanel.trackListModel

                                Rectangle {
                                    id: trackContent
                                    width: gridFlickable.contentWidth
                                    height: 43
                                    color: "transparent"

                                    Rectangle {
                                        anchors.fill: parent
                                        color: index % 2 === 0 ? "#1A1A1A" : "#1E1E1E"
                                        opacity: 0.5
                                    }
                                }
                            }
                        }
                    }

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
            width: 12
            background: Rectangle { color: "#1A1A1A" }
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
            height: 12
            background: Rectangle { color: "#1A1A1A" }
            contentItem: Rectangle {
                color: horizontalScrollBar.pressed ? "#297ACC" : "#4A4A4A"
            }
        }
    }
}

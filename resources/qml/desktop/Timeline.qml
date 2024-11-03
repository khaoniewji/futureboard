// Timeline.qml
import QtQuick 2.15
import QtQuick.Controls 2.15
import QtQuick.Layouts 1.15

Rectangle {
    id: timeline
    property int baseBarInterval: 80  // Base width of each bar
    property int barInterval: baseBarInterval  // Actual width (affected by zoom)
    property int beatInterval: barInterval / 4
    property int tickInterval: beatInterval / 4
    property int initialBars: 16
    property int extraBars: 100
    property real zoomLevel: 1.0
    property bool showGrid: true
    property real scrollPosition: timelineFlickable.contentX
    property alias contentWidth: timelineFlickable.contentWidth
    property alias contentX: timelineFlickable.contentX

    // Colors
    property color accentColor: "#297ACC"
    property color backgroundColor: "#2D2D2D"
    property color primaryTextColor: "#FFFFFF"
    property color secondaryTextColor: "#B0B0B0"
    property color gridColor: "#3A3A3A"
    property color barLineColor: "#505050"
    property color beatLineColor: "#404040"

    // Signals
    signal positionChanged(real position)
    signal zoomChanged(real level)

    width: parent.width
    height: 32
    color: backgroundColor

    // Zoom functions
    function zoomIn(center) {
        const oldZoom = zoomLevel
        zoomLevel = Math.min(zoomLevel * 1.2, 4.0)
        barInterval = baseBarInterval * zoomLevel
        if (center !== undefined) {
            maintainZoomCenter(oldZoom, zoomLevel, center)
        }
        zoomChanged(zoomLevel)
    }

    function zoomOut(center) {
        const oldZoom = zoomLevel
        zoomLevel = Math.max(zoomLevel / 1.2, 0.25)
        barInterval = baseBarInterval * zoomLevel
        if (center !== undefined) {
            maintainZoomCenter(oldZoom, zoomLevel, center)
        }
        zoomChanged(zoomLevel)
    }

    function maintainZoomCenter(oldZoom, newZoom, center) {
        const mouseX = center - timelineFlickable.contentX
        const ratio = newZoom / oldZoom
        const newX = center * ratio - mouseX
        timelineFlickable.contentX = newX
    }

    Flickable {
        id: timelineFlickable
        anchors.fill: parent
        contentWidth: (initialBars + extraBars) * barInterval
        contentHeight: height
        boundsBehavior: Flickable.StopAtBounds
        clip: true

        onContentXChanged: {
            positionChanged(contentX / barInterval)
        }

        // Bar and beat markers
        Row {
            Repeater {
                model: initialBars + extraBars
                Item {
                    width: timeline.barInterval
                    height: timeline.height

                    // Bar number label
                    Text {
                        text: (index + 1).toString()
                        font.family: "Inter Display"
                        font.pixelSize: 11
                        font.bold: true
                        color: primaryTextColor
                        y: 4
                        x: 4
                        opacity: 0.9
                    }

                    // Main bar line
                    Rectangle {
                        width: 1
                        height: parent.height
                        color: barLineColor
                        opacity: 0.8
                    }

                    // Beat markers
                    Repeater {
                        model: 4
                        Rectangle {
                            width: timeline.beatInterval
                            height: parent.height
                            x: index * timeline.beatInterval
                            color: "transparent"

                            Rectangle {
                                width: 1
                                height: parent.height * 0.7
                                anchors.bottom: parent.bottom
                                color: beatLineColor
                                opacity: 0.6
                                visible: index > 0
                            }

                            Text {
                                visible: index > 0
                                text: (index + 1).toString()
                                font.family: "Inter Display"
                                font.pixelSize: 9
                                color: secondaryTextColor
                                y: 6
                                x: 3
                                opacity: 0.7
                            }

                            // Tick markers
                            Repeater {
                                model: 4
                                Rectangle {
                                    visible: showGrid && index > 0
                                    width: 1
                                    height: parent.height * 0.4
                                    x: index * timeline.tickInterval
                                    anchors.bottom: parent.bottom
                                    color: gridColor
                                    opacity: 0.3
                                }
                            }
                        }
                    }
                }
            }
        }
    }

    // Mouse interaction area
    MouseArea {
        anchors.fill: parent
        acceptedButtons: Qt.LeftButton | Qt.MiddleButton
        hoverEnabled: true
        property int hoveredBar: -1

        onMouseXChanged: {
            hoveredBar = Math.floor((mouseX + timelineFlickable.contentX) / timeline.barInterval)
        }

        onWheel: function(wheel) {
            if (wheel.modifiers & Qt.ControlModifier) {
                // Zoom with Ctrl+Wheel
                const zoomCenter = wheel.x + timelineFlickable.contentX
                if (wheel.angleDelta.y > 0) {
                    zoomIn(zoomCenter)
                } else {
                    zoomOut(zoomCenter)
                }
                wheel.accepted = true
            } else {
                // Horizontal scroll with wheel
                timelineFlickable.contentX += wheel.angleDelta.y < 0 ? 100 : -100
                wheel.accepted = true
            }
        }

        onPressed: function(mouse) {
            if (mouse.button === Qt.MiddleButton) {
                // Middle mouse button drag to scroll
                timelineFlickable.interactive = false
                mouse.accepted = true
            }
        }

        onReleased: function(mouse) {
            if (mouse.button === Qt.MiddleButton) {
                timelineFlickable.interactive = true
            }
        }

        onPositionChanged: function(mouse) {
            if (pressed && mouse.buttons === Qt.MiddleButton) {
                // Handle middle mouse button drag scrolling
                timelineFlickable.contentX -= mouse.x - mouse.lastX
            }
        }

        // Hover highlight effect
        Rectangle {
            visible: parent.hoveredBar >= 0
            x: (parent.hoveredBar * timeline.barInterval) - timelineFlickable.contentX
            width: timeline.barInterval
            height: parent.height
            color: accentColor
            opacity: 0.1
        }
    }

    // Keyboard shortcuts
    Shortcut {
        sequence: "Ctrl+="
        onActivated: timeline.zoomIn()
    }

    Shortcut {
        sequence: "Ctrl+-"
        onActivated: timeline.zoomOut()
    }
}

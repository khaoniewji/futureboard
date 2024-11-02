// timeline.qml
import QtQuick 2.15
import QtQuick.Controls 2.15
import QtQuick.Layouts 1.15

Rectangle {
    id: timeline
    property int barInterval: 80
    property int beatInterval: 20
    property int tickInterval: 5
    property int initialBars: 16
    property int extraBars: 100  // Set a large count to simulate unlimited bars
    property bool showGrid: true
    property color accentColor: "#297ACC"
    property color backgroundColor: "#2D2D2D"
    property color primaryTextColor: "#FFFFFF"
    property color secondaryTextColor: "#B0B0B0"
    property color gridColor: "#3A3A3A"
    property color barLineColor: "#505050"
    property color beatLineColor: "#404040"

    width: parent.width
    height: 32
    color: backgroundColor

    Flickable {
        anchors.fill: parent
        contentWidth: (initialBars + extraBars) * barInterval  // Total width based on bars
        contentHeight: height
        clip: true

        // Bar and beat markers
        Repeater {
            model: initialBars + extraBars
            Item {
                width: timeline.barInterval
                height: timeline.height
                x: index * timeline.barInterval

                // Bar number label
                Text {
                    id: barLabel
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

                        // Beat line
                        Rectangle {
                            width: 1
                            height: parent.height * 0.7
                            anchors.bottom: parent.bottom
                            color: beatLineColor
                            opacity: 0.6
                            visible: index > 0
                        }

                        // Small beat number
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

    // Mouseover highlight effect
    MouseArea {
        anchors.fill: parent
        hoverEnabled: true
        property int hoveredBar: -1

        onMouseXChanged: {
            hoveredBar = Math.floor(mouseX / timeline.barInterval)
        }

        Rectangle {
            visible: parent.hoveredBar >= 0
            x: parent.hoveredBar * timeline.barInterval
            width: timeline.barInterval
            height: parent.height
            color: accentColor
            opacity: 0.1
        }
    }
}

import QtQuick 2.15
import QtQuick.Controls 2.15
import QtQuick.Layouts 1.15

Rectangle {
    id: trackWidget
    width: parent.width
    height: 42
    color: "#242424"  // Ableton dark gray
    radius: 0  // Ableton uses sharp corners

    property bool expanded: true
    property bool selected: false
    property real volume: 0.75
    property string trackColor: "#FF764D"  // Ableton orange

    // Track selection highlight
    Rectangle {
        anchors.fill: parent
        color: "#FF764D"
        opacity: selected ? 0.1 : 0
    }

    RowLayout {
        anchors.fill: parent
        anchors.margins: 6
        spacing: 8

        // Track Expand/Collapse
        Rectangle {
            id: expandButton
            width: 16
            height: 16
            color: "transparent"

            Image {
                anchors.centerIn: parent
                source: expanded ? "qrc:/icons/arrow-down.svg" : "qrc:/icons/arrow-right.svg"
                width: 9  // Adjust size as needed
                height: 9 // Adjust size as needed
                sourceSize: Qt.size(9, 9)
                antialiasing: true
            }

            MouseArea {
                id: expandButtonMouse
                anchors.fill: parent
                hoverEnabled: true
                onClicked: expanded = !expanded
            }
        }

        // Color Bar (Ableton style)
        Rectangle {
            width: 4
            height: parent.height - 8
            color: trackColor
            opacity: 0.9
        }

        // Track Name (Ableton style font and input)
        Rectangle {
            height: 22
            Layout.fillWidth: true
            color: trackNameInput.activeFocus ? "#3F3F3F" : "transparent"

            TextInput {
                id: trackNameInput
                anchors.verticalCenter: parent.verticalCenter
                width: parent.width
                text: "Audio Track"
                color: "#DBDBDB"
                font.pixelSize: 12
                font.family: "Inter Display"  // Ableton uses Inter Display
                font.weight: Font.DemiBold
                selectByMouse: true
                selectedTextColor: "#FFFFFF"
                selectionColor: "#0086FF"  // Ableton blue selection
                leftPadding: 4
            }
        }

        // Track Controls
        RowLayout {
            spacing: 4

            // Ableton-style button group
            Row {
                spacing: 1  // Minimal spacing for connected feel

                Repeater {
                    model: [
                        { label: "R", active: false },
                        { label: "M", active: false },
                        { label: "S", active: false }
                    ]

                    Rectangle {
                        id: controlButton
                        width: 20
                        height: 20
                        color: buttonMouse.containsMouse ? "transparent" :
                               modelData.active ? "#FF764D" : "#2F2F2F"

                        property bool isHovered: false

                        Text {
                            anchors.centerIn: parent
                            text: modelData.label
                            color: modelData.active ? "#000000" : "#B4B4B4"
                            font.pixelSize: 11
                            font.family: "Inter Display"
                        }

                        MouseArea {
                            id: buttonMouse
                            anchors.fill: parent
                            hoverEnabled: true
                            onClicked: modelData.active = !modelData.active
                            onEntered: controlButton.isHovered = true
                            onExited: controlButton.isHovered = false
                        }
                    }
                }
            }
        }

        // Volume Control (Ableton style) with outer border
        Rectangle {
            id: volumeControlBorder
            width: 64  // Increased to accommodate inner control + border
            height: 20 // Increased to accommodate inner control + border
            color: "#1A1A1A" // Border color

            Rectangle {
                id: volumeControl
                anchors.centerIn: parent
                width: 60
                height: 16
                color: "#2F2F2F"

                Rectangle {
                    width: parent.width * volume
                    height: parent.height
                    color: trackColor
                    opacity: 0.9
                }
                // Volume value in dB
                Text {
                    anchors.centerIn: parent
                    text: {
                        // Convert percentage (0-1) to dB
                        // Using 20 * log10(volume) with -60dB minimum
                        const dB = volume > 0 ? Math.max(-60, 20 * Math.log10(volume)) : -60
                        return Math.round(dB) + "dB"
                    }
                    color: "#DBDBDB"
                    font.pixelSize: 10
                    font.family: "Inter Display"
                    font.weight: Font.DemiBold
                }
                MouseArea {
                    anchors.fill: parent
                    onMouseXChanged: {
                        if (pressed) {
                            volume = Math.max(0, Math.min(1, mouseX / width))
                        }
                    }
                    onClicked: {
                        volume = Math.max(0, Math.min(1, mouseX / width))
                    }
                }
            }
        }
    }

    // Track selection mouse area
    MouseArea {
        anchors.fill: parent
        z: -1
        onClicked: selected = !selected
    }
}

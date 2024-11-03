import QtQuick 2.15
import QtQuick.Controls 2.15
import QtQuick.Layouts 1.15

Rectangle {
    id: root
    width: 600
    height: 400
    color: "#00000000"  // Transparent background
    signal commandExecuted(var command)

    property var applicationCommands: []
    property var filteredCommands: applicationCommands

    focus: visible
    activeFocusOnTab: true

    function show() {
        visible = true
        searchField.clear()
        searchField.forceActiveFocus()
        filteredCommands = applicationCommands
    }

    // Constants for styling
    QtObject {
        id: style
        readonly property color backgroundColor: "#282828"
        readonly property color searchBarColor: "#383838"
        readonly property color textColor: "#FFFFFF"
        readonly property color highlightColor: "#FF764D"
        readonly property color borderColor: "#1E1E1E"
        readonly property int radius: 6
        readonly property font defaultFont: Qt.font({
            family: "Inter Display",
            pixelSize: 13,
            weight: Font.Normal
        })
    }

    function filterCommands(searchText) {
        if (!searchText) {
            filteredCommands = applicationCommands
            return
        }

        filteredCommands = applicationCommands.filter(cmd => {
            const searchLower = searchText.toLowerCase()
            return cmd.label.toLowerCase().includes(searchLower) ||
                   (cmd.category && cmd.category.toLowerCase().includes(searchLower))
        })
    }

    Rectangle {
        id: overlay
        anchors.fill: parent
        color: "#000000"
        opacity: 0.5
        visible: root.visible

        MouseArea {
            anchors.fill: parent
            onClicked: root.visible = false
        }
    }

    Rectangle {
        id: commandPalette
        width: 600
        height: Math.min(500, filteredCommands.length * 40 + 50)
        x: (parent.width - width) / 2
        y: 100
        color: style.backgroundColor
        radius: style.radius
        border.color: style.borderColor
        border.width: 1
        visible: root.visible
        opacity: root.visible ? 1 : 0

        Behavior on opacity {
            NumberAnimation { duration: 150 }
        }

        ColumnLayout {
            anchors.fill: parent
            spacing: 0

            // Search field
            Rectangle {
                Layout.fillWidth: true
                Layout.preferredHeight: 50
                color: style.searchBarColor
                radius: style.radius

                Rectangle {
                    anchors.bottom: parent.bottom
                    width: parent.width
                    height: style.radius
                    color: parent.color
                }

                RowLayout {
                    anchors.fill: parent
                    anchors.margins: 12
                    spacing: 8

                    TextField {
                        id: searchField
                        Layout.fillWidth: true
                        placeholderText: "Type a command..."
                        color: "#FFFFFF"
                        placeholderTextColor: "#808080"
                        font: style.defaultFont
                        selectByMouse: true
                        focus: true

                        background: Rectangle {
                            color: "transparent"
                        }

                        onTextChanged: {
                            filterCommands(text)
                        }
                    }

                    Text {
                        text: "ESC to close"
                        font: style.defaultFont
                        color: "#FFFFFF"
                        opacity: 0.5
                    }
                }
            }

            ListView {
                id: commandList
                Layout.fillWidth: true
                Layout.fillHeight: true
                clip: true
                model: filteredCommands
                spacing: 1
                currentIndex: 0
                focus: true

                delegate: Rectangle {
                    width: commandList.width
                    height: 40
                    color: mouseArea.containsMouse || ListView.isCurrentItem ? Qt.darker(style.searchBarColor, 1.2) : "transparent"

                    RowLayout {
                        anchors.fill: parent
                        anchors.leftMargin: 16
                        anchors.rightMargin: 16
                        spacing: 12

                        Text {
                            text: modelData.label
                            font: style.defaultFont
                            color: "#FFFFFF"
                            opacity: mouseArea.containsMouse || ListView.isCurrentItem ? 1 : 0.8
                            Layout.fillWidth: true
                        }

                        Text {
                            text: modelData.category || ""
                            font: style.defaultFont
                            color: "#FFFFFF"
                            opacity: 0.5
                        }

                        Text {
                            text: modelData.shortcut || ""
                            font: style.defaultFont
                            color: "#FFFFFF"
                            opacity: 0.5
                        }
                    }

                    MouseArea {
                        id: mouseArea
                        anchors.fill: parent
                        hoverEnabled: true
                        cursorShape: Qt.PointingHandCursor

                        onClicked: {
                            root.commandExecuted(modelData)
                            root.visible = false
                        }
                    }

                    Rectangle {
                        anchors.bottom: parent.bottom
                        width: parent.width
                        height: 1
                        color: style.borderColor
                        visible: index !== commandList.count - 1
                    }
                }

                ScrollBar.vertical: ScrollBar {
                    active: true
                    policy: ScrollBar.AsNeeded

                    contentItem: Rectangle {
                        implicitWidth: 6
                        radius: 3
                        color: "#FFFFFF"
                        opacity: 0.3
                    }

                    background: Rectangle {
                        color: "transparent"
                    }
                }
            }
        }
    }

    Keys.onPressed: function(event) {
        if (event.key === Qt.Key_Escape) {
            root.visible = false
            event.accepted = true
        } else if (event.key === Qt.Key_Return || event.key === Qt.Key_Enter) {
            if (commandList.currentItem) {
                root.commandExecuted(filteredCommands[commandList.currentIndex])
                root.visible = false
            }
            event.accepted = true
        } else if (event.key === Qt.Key_Up) {
            commandList.decrementCurrentIndex()
            event.accepted = true
        } else if (event.key === Qt.Key_Down) {
            commandList.incrementCurrentIndex()
            event.accepted = true
        }
    }

    Behavior on visible {
        SequentialAnimation {
            NumberAnimation {
                target: commandPalette
                property: "scale"
                from: 0.95
                to: 1
                duration: 150
                easing.type: Easing.OutQuad
            }
        }
    }
}

import QtQuick
import QtQuick.Window
import QtQuick.Controls
import QtQuick.Layouts
import Qt5Compat.GraphicalEffects

Window {
    id: mainWindow
    width: 800
    height: 600
    visible: true
    flags: Qt.Window | Qt.FramelessWindowHint
    color: "transparent"

    // Dark theme colors
    property var colors: {
        "bg": "#1e1e1e",
        "titleBar": "#252525",
        "hover": "#3d3d3d",
        "text": "#ffffff",
        "border": "#323232",
        "accent": "#007acc",
        "control": "#2d2d2d"
    }

    // Main container with shadow
    Rectangle {
        id: container
        anchors.fill: parent
        color: "transparent"

        // Window shadow
        DropShadow {
            anchors.fill: mainContent
            horizontalOffset: 0
            verticalOffset: 2
            radius: 8.0
            samples: 17
            color: "#40000000"
            source: mainContent
        }

        Rectangle {
            id: mainContent
            anchors.fill: parent
            color: colors.bg
            border.color: colors.border
            border.width: 1

            // Custom titlebar
            Rectangle {
                id: titleBar
                width: parent.width
                height: 32
                color: colors.titleBar

                RowLayout {
                    anchors.fill: parent
                    spacing: 8

                    // Plugin title
                    Text {
                        id: pluginTitle
                        text: "Plugin Name"
                        Layout.leftMargin: 12
                        font.family: "Inter Display"
                        font.pixelSize: 12
                        font.weight: Font.Medium
                        color: colors.text
                    }

                    // Preset ComboBox
                    ComboBox {
                        id: presetCombo
                        model: ["Default", "Preset 1", "Preset 2", "Preset 3"]
                        Layout.preferredWidth: 200
                        Layout.preferredHeight: 24
                        Layout.alignment: Qt.AlignVCenter
                        font.family: "Inter Display"
                        font.pixelSize: 11

                        background: Rectangle {
                            color: colors.control
                            border.color: colors.border
                            radius: 3
                        }

                        contentItem: Text {
                            text: presetCombo.displayText
                            font: presetCombo.font
                            color: colors.text
                            verticalAlignment: Text.AlignVCenter
                            leftPadding: 8
                        }
                    }

                    Item { Layout.fillWidth: true } // Spacer

                    // Window controls
                    Row {
                        id: windowControls
                        Layout.alignment: Qt.AlignRight
                        spacing: 0

                        // Minimize button
                        Rectangle {
                            width: 46
                            height: titleBar.height
                            color: minimizeBtn.containsMouse ? colors.hover : "transparent"

                            Text {
                                text: "\uE921"
                                anchors.centerIn: parent
                                font.family: "Segoe Fluent Icons"
                                font.pixelSize: 10
                                color: colors.text
                            }

                            MouseArea {
                                id: minimizeBtn
                                anchors.fill: parent
                                hoverEnabled: true
                                onClicked: mainWindow.showMinimized()
                            }
                        }

                        // Close button
                        Rectangle {
                            width: 46
                            height: titleBar.height
                            color: closeBtn.containsMouse ? "#c42b1c" : "transparent"

                            Text {
                                text: "\uE8BB"
                                anchors.centerIn: parent
                                font.family: "Segoe Fluent Icons"
                                font.pixelSize: 10
                                color: closeBtn.containsMouse ? "#ffffff" : colors.text
                            }

                            MouseArea {
                                id: closeBtn
                                anchors.fill: parent
                                hoverEnabled: true
                                onClicked: Qt.quit()
                            }
                        }
                    }
                }

                // Window dragging
                MouseArea {
                    anchors.fill: parent
                    anchors.rightMargin: 92
                    property point lastMousePos
                    onPressed: lastMousePos = Qt.point(mouseX, mouseY)
                    onPositionChanged: {
                        if (pressed) {
                            var dx = mouseX - lastMousePos.x
                            var dy = mouseY - lastMousePos.y
                            mainWindow.x += dx
                            mainWindow.y += dy
                        }
                    }
                }
            }

            // Header toolbar
            Rectangle {
                id: headerToolbar
                anchors.top: titleBar.bottom
                width: parent.width
                height: 40
                color: colors.titleBar
                border.color: colors.border
                border.width: 1

                RowLayout {
                    anchors.fill: parent
                    anchors.leftMargin: 8
                    anchors.rightMargin: 8
                    spacing: 8

                    // Bypass Button
                    Button {
                        id: bypassButton
                        width: 32
                        height: 28
                        font.family: "Segoe Fluent Icons"
                        font.pixelSize: 14
                        checkable: true
                        ToolTip.visible: hovered
                        ToolTip.text: "Bypass"

                        background: Rectangle {
                            color: bypassButton.checked ? colors.accent :
                                   bypassButton.hovered ? colors.hover : colors.control
                            border.color: colors.border
                            radius: 3
                        }

                        contentItem: Text {
                            text: "\uE7BA"  // Power icon
                            font: bypassButton.font
                            color: bypassButton.checked ? "#ffffff" : colors.text
                            horizontalAlignment: Text.AlignHCenter
                            verticalAlignment: Text.AlignVCenter
                        }
                    }

                    // Edit, Save, Load buttons
                    Repeater {
                        model: [
                            {text: "Edit", icon: "\uE70F"},   // Edit icon
                            {text: "Save", icon: "\uE74E"},   // Save icon
                            {text: "Load", icon: "\uE8E5"}    // Load icon
                        ]
                        delegate: Button {
                            width: 32
                            height: 28
                            font.family: "Segoe Fluent Icons"
                            font.pixelSize: 14
                            ToolTip.visible: hovered
                            ToolTip.text: modelData.text

                            background: Rectangle {
                                color: parent.hovered ? colors.hover : colors.control
                                border.color: colors.border
                                radius: 3
                            }

                            contentItem: Text {
                                text: modelData.icon
                                font: parent.font
                                color: colors.text
                                horizontalAlignment: Text.AlignHCenter
                                verticalAlignment: Text.AlignVCenter
                            }
                        }
                    }

                    Item { Layout.fillWidth: true }
                }
            }

            // VST Plugin Render Area
            Rectangle {
                id: vstRenderArea
                anchors.top: headerToolbar.bottom
                anchors.left: parent.left
                anchors.right: parent.right
                anchors.bottom: parent.bottom
                color: colors.bg

                // Placeholder for VST plugin UI
                Text {
                    anchors.centerIn: parent
                    text: "VST Plugin UI Render Area"
                    font.family: "Inter Display"
                    font.pixelSize: 14
                    color: colors.text
                }
            }
        }

        // Window resize handles
        MouseArea {
            id: leftResize
            width: 5
            anchors.left: parent.left
            anchors.top: parent.top
            anchors.bottom: parent.bottom
            cursorShape: Qt.SizeHorCursor
            onPressed: { startResize(1); }
            onReleased: stopResize()
            onPositionChanged: if (pressed) performResize(mouse)
        }

        MouseArea {
            id: rightResize
            width: 5
            anchors.right: parent.right
            anchors.top: parent.top
            anchors.bottom: parent.bottom
            cursorShape: Qt.SizeHorCursor
            onPressed: { startResize(2); }
            onReleased: stopResize()
            onPositionChanged: if (pressed) performResize(mouse)
        }

        MouseArea {
            id: bottomResize
            height: 5
            anchors.bottom: parent.bottom
            anchors.left: parent.left
            anchors.right: parent.right
            cursorShape: Qt.SizeVerCursor
            onPressed: { startResize(4); }
            onReleased: stopResize()
            onPositionChanged: if (pressed) performResize(mouse)
        }
    }

    // Resize handling functions
    property bool isResizing: false
    property int resizeEdge: 0
    property point lastMousePos

    function startResize(edge) {
        isResizing = true;
        resizeEdge = edge;
        lastMousePos = Qt.point(mouseX, mouseY);
    }

    function stopResize() {
        isResizing = false;
        resizeEdge = 0;
    }

    function performResize(mouse) {
        if (!isResizing) return;

        var delta = Qt.point(mouse.x - lastMousePos.x, mouse.y - lastMousePos.y);
        var minWidth = 400;
        var minHeight = 300;

        switch (resizeEdge) {
            case 1: // Left
                var newWidth = Math.max(minWidth, width - delta.x);
                var deltaWidth = width - newWidth;
                if (newWidth > minWidth) {
                    x += deltaWidth;
                    width = newWidth;
                }
                break;
            case 2: // Right
                width = Math.max(minWidth, width + delta.x);
                break;
            case 4: // Bottom
                height = Math.max(minHeight, height + delta.y);
                break;
        }
        lastMousePos = Qt.point(mouse.x, mouse.y);
    }
}

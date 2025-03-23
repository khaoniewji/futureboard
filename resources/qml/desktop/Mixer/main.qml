import QtQuick
import QtQuick.Controls
import QtQuick.Controls.Basic
import QtQuick.Layouts
import QtQuick.Window
import com.futureboard.core 1.0
import com.futureboard.audio 1.0
import "." as Local

ApplicationWindow {
    id: mainWindow
    width: 1280
    height: 720
    visible: true
    title: "Mixer View"
    color: "#1B1B1B"  // Direct color value
    // flags: Qt.Window | Qt.WindowStaysOnTopHint

    // Set window minimum size
    minimumWidth: 800
    minimumHeight: 600

    // Set window position to center of screen
    Component.onCompleted: {
        x = Screen.width / 2 - width / 2
        y = Screen.height / 2 - height / 2
    }

    // Top Toolbar
    Rectangle {
        id: topToolbar
        width: parent.width
        height: 32
        color: "#252525"
        border.color: "#121212"
        z: 2

        RowLayout {
            anchors.fill: parent
            anchors.margins: 4
            spacing: 8

            // Left Section
            Row {
                spacing: 4
                Layout.alignment: Qt.AlignLeft

                Button {
                    text: "Racks"
                    height: 24
                    width: 60
                    background: Rectangle {
                        color: parent.pressed ? 
                              "#346AB2" : 
                              "#2D2D2D"
                        radius: 2
                    }
                    contentItem: Text {
                        text: parent.text
                        color: "#FFFFFF"
                        font.family: "Inter"
                        horizontalAlignment: Text.AlignHCenter
                        verticalAlignment: Text.AlignVCenter
                    }
                }

                Button {
                    text: "Pictures"
                    height: 24
                    width: 60
                    background: Rectangle {
                        color: parent.pressed ? 
                              "#346AB2" : 
                              "#2D2D2D"
                        radius: 2
                    }
                    contentItem: Text {
                        text: parent.text
                        color: "#FFFFFF"
                        font.family: "Inter"
                        horizontalAlignment: Text.AlignHCenter
                        verticalAlignment: Text.AlignVCenter
                    }
                }
            }

            // Center Section
            Row {
                spacing: 4
                Layout.alignment: Qt.AlignCenter

                ComboBox {
                    width: 120
                    height: 24
                    model: ["All Channels", "Audio Tracks", "MIDI Tracks", "Groups"]
                    font.family: "Inter"
                    background: Rectangle {
                        color: "#353B41"
                        radius: 2
                    }
                }

                TextField {
                    width: 120
                    height: 24
                    placeholderText: "Filter..."
                    background: Rectangle {
                        color: "#353B41"
                        radius: 2
                    }
                    color: "white"
                    font.family: "Inter"
                }
            }

            // Right Section
            Row {
                spacing: 4
                Layout.alignment: Qt.AlignRight

                Button {
                    text: "A"
                    height: 24
                    width: 24
                    background: Rectangle {
                        color: parent.pressed ? 
                              "#346AB2" : 
                              "#2D2D2D"
                        radius: 2
                    }
                    contentItem: Text {
                        text: parent.text
                        color: "#FFFFFF"
                        font.family: "Inter"
                        horizontalAlignment: Text.AlignHCenter
                        verticalAlignment: Text.AlignVCenter
                    }
                }

                Button {
                    text: "B"
                    height: 24
                    width: 24
                    background: Rectangle {
                        color: parent.pressed ? 
                              "#346AB2" : 
                              "#2D2D2D"
                        radius: 2
                    }
                    contentItem: Text {
                        text: parent.text
                        color: "#FFFFFF"
                        font.family: "Inter"
                        horizontalAlignment: Text.AlignHCenter
                        verticalAlignment: Text.AlignVCenter
                    }
                }
            }
        }
    }

    // Channel Types Bar
    Rectangle {
        id: channelTypesBar
        width: parent.width
        height: 24
        anchors.top: topToolbar.bottom
        color: "#252525"
        border.color: "#121212"

        Row {
            anchors.fill: parent
            anchors.margins: 4
            spacing: 8

            Repeater {
                model: ["Input", "Audio", "MIDI", "FX", "Group", "Output"]
                delegate: Text {
                    text: modelData
                    color: "#566470"
                    font.family: "Inter"
                    font.pixelSize: 11
                    anchors.verticalCenter: parent.verticalCenter
                }
            }
        }
    }

    // Mixer View Container
    Rectangle {
        id: mixerContainer
        anchors {
            top: channelTypesBar.bottom
            bottom: statusBar.top
            left: parent.left
            right: parent.right
        }
        color: "#1A1D21"

        // Scrollable Mixer View
        ScrollView {
            id: mixerScrollView
            anchors {
                fill: parent
                right: masterContainer.left
            }
            ScrollBar.vertical.policy: ScrollBar.AlwaysOff
            clip: true

            Item {
                // Ensure content is larger than view
                width: mixerChannels.width + 30  // Add extra width for the + button
                height: parent.height

                Row {
                    id: mixerChannels
                    spacing: 1
                    height: parent.height

                    // Regular Channels
                    Repeater {
                        id: channelRepeater
                        model: TrackManager ? TrackManager.trackModel : null  // Add null check
                        Rectangle {
                            width: 129
                            height: parent.height
                            color: "#141618"
                            border.color: "#090909"

                            Loader {
                                source: "MixerRack.qml"
                                anchors.fill: parent
                                onLoaded: {
                                    if (item && model) {  // Add null checks
                                        item.nameInput.text = model.name || ""
                                    }
                                }
                            }
                        }
                    }
                }

                // Add track button at the end of mixerChannels
                Rectangle {
                    id: addTrackButton
                    width: 30
                    height: parent.height
                    color: "#141618"
                    anchors.left: mixerChannels.right

                    Rectangle {
                        width: 24
                        height: 24
                        radius: 12
                        color: "#353B41"
                        anchors.horizontalCenter: parent.horizontalCenter
                        anchors.top: parent.top
                        anchors.topMargin: 10

                        Text {
                            text: "+"
                            color: "white"
                            font.family: "Inter"
                            font.pixelSize: 16
                            anchors.centerIn: parent
                        }

                        MouseArea {
                            anchors.fill: parent
                            onClicked: {
                                TrackManager.trackModel.addTrack(
                                    "Track " + (channelRepeater.count + 1), 
                                    "audio",
                                    "#297ACC"
                                )
                            }
                        }
                    }
                }
            }
        }

        // Custom Horizontal ScrollBar
        ScrollBar {
            id: horizontalScrollBar
            height: 8
            anchors {
                left: mixerScrollView.left
                right: mixerScrollView.right
                bottom: mixerScrollView.bottom
            }
            active: true
            policy: ScrollBar.AlwaysOn
            orientation: Qt.Horizontal
            position: mixerScrollView.ScrollBar.horizontal.position
            size: mixerScrollView.ScrollBar.horizontal.size
            
            contentItem: Rectangle {
                implicitHeight: 8
                radius: height / 2
                color: parent.pressed ? "#81B1FF" : "#353B41"
            }

            background: Rectangle {
                implicitHeight: 8
                color: "#141618"
                radius: 4
            }
        }

        // Master Track Container
        Rectangle {
            id: masterContainer
            width: 130
            anchors {
                top: parent.top
                bottom: parent.bottom
                right: parent.right
            }
            color: "#141618"
            border.color: "#090909"

            Loader {
                source: "MasterTrack.qml"
                anchors.fill: parent
            }
        }
    }

    // Status Bar
    Rectangle {
        id: statusBar
        height: 24
        color: "#141618"
        border.color: "#090909"
        anchors {
            left: parent.left
            right: parent.right
            bottom: parent.bottom
        }

        RowLayout {
            anchors.fill: parent
            anchors.margins: 4
            spacing: 8

            Text {
                text: "48kHz | 24bit | Buffer: 256"
                color: "#566470"
                font.family: "Inter"
                font.pixelSize: 11
                Layout.alignment: Qt.AlignLeft
            }

            Item { Layout.fillWidth: true }

            Text {
                text: "CPU: 12% | RAM: 4.2GB"
                color: "#566470"
                font.family: "Inter"
                font.pixelSize: 11
                Layout.alignment: Qt.AlignRight
            }
        }
    }

    // Keyboard shortcuts
    Shortcut {
        sequence: StandardKey.MoveToNextChar
        onActivated: mixerScrollView.ScrollBar.horizontal.position += 0.1
    }

    Shortcut {
        sequence: StandardKey.MoveToPreviousChar
        onActivated: mixerScrollView.ScrollBar.horizontal.position -= 0.1
    }
}
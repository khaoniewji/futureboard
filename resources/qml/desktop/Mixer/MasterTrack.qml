import QtQuick
import QtQuick.Controls
import QtQuick.Layouts
import QtQuick.Dialogs
import com.futureboard.audio 1.0

Rectangle {
    id: masterTrack
    width: 130
    color: "transparent"

    Component {
        id: masterVuMeterComponent
        Rectangle {
            id: vuMeter
            property real leftLevel: 0
            property real rightLevel: 0
            property real leftPeak: 0
            property real rightPeak: 0
            color: "transparent"
            
            Rectangle {
                id: leftChannel
                width: 6
                height: parent.height - 22
                color: "#272C32"
                anchors.right: parent.horizontalCenter
                anchors.rightMargin: 1
                anchors.top: parent.top

                Item {
                    width: parent.width
                    height: parent.height * leftLevel
                    anchors.bottom: parent.bottom
                    clip: true

                    Rectangle {
                        width: parent.width
                        height: parent.parent.height
                        gradient: Gradient {
                            GradientStop { position: 0.0; color: "#FF4444" }
                            GradientStop { position: 0.15; color: "#FF4444" }
                            GradientStop { position: 0.3; color: "#FFAA00" }
                            GradientStop { position: 0.5; color: "#FFAA00" }
                            GradientStop { position: 0.7; color: "#00FF66" }
                            GradientStop { position: 1.0; color: "#00FF66" }
                        }
                    }
                }

                Rectangle {
                    width: parent.width
                    height: 2
                    color: "#FFFFFF"
                    opacity: 0.8
                    y: parent.height * (1 - leftPeak)
                }
            }

            Rectangle {
                id: rightChannel
                width: 6
                height: parent.height - 22
                color: "#272C32"
                anchors.left: parent.horizontalCenter
                anchors.leftMargin: 1
                anchors.top: parent.top

                Item {
                    width: parent.width
                    height: parent.height * rightLevel
                    anchors.bottom: parent.bottom
                    clip: true

                    Rectangle {
                        width: parent.width
                        height: parent.parent.height
                        gradient: Gradient {
                            GradientStop { position: 0.0; color: "#FF4444" }
                            GradientStop { position: 0.15; color: "#FF4444" }
                            GradientStop { position: 0.3; color: "#FFAA00" }
                            GradientStop { position: 0.5; color: "#FFAA00" }
                            GradientStop { position: 0.7; color: "#00FF66" }
                            GradientStop { position: 1.0; color: "#00FF66" }
                        }
                    }
                }

                Rectangle {
                    width: parent.width
                    height: 2
                    color: "#FFFFFF"
                    opacity: 0.8
                    y: parent.height * (1 - rightPeak)
                }
            }

            Timer {
                interval: 50
                running: true
                repeat: true
                onTriggered: {
                    AudioEngine.updateLevels()
                    leftPeak = Math.max(leftPeak * 0.995, leftLevel)
                    rightPeak = Math.max(rightPeak * 0.995, rightLevel)
                }
            }
        }
    }

    Component {
        id: masterFaderComponent
        Rectangle {
            id: faderBackground
            color: "transparent"
            property real value: 0.7

            Rectangle {
                id: faderTrack
                width: 10  // Wider track for master
                height: parent.height - 20
                color: "#191D21"
                anchors.centerIn: parent
                radius: 4

                Rectangle {
                    id: faderHandle
                    width: 50  // Wider handle for master
                    height: 20
                    radius: 4
                    color: "#CC3636"  // Master color
                    border.color: "#0A0B08"
                    x: (faderTrack.width - width) / 2
                    y: (parent.height - height) * (1 - value)

                    MouseArea {
                        anchors.fill: parent
                        drag.target: parent
                        drag.axis: Drag.YAxis
                        drag.minimumY: -height/2
                        drag.maximumY: faderTrack.height - height/2

                        onPositionChanged: {
                            if (drag.active) {
                                value = 1 - (faderHandle.y + height/2) / faderTrack.height
                                updateLevel()
                            }
                        }
                    }
                }
            }

            function updateLevel() {
                let db = value <= 0 ? -Infinity : 20 * Math.log10(value)
                if (db > 12) db = 12
                masterLevelText.text = db.toFixed(1) + " dB"
            }
        }
    }

    ColumnLayout {
        anchors.fill: parent
        spacing: 0

        // Master Header
        Rectangle {
            Layout.fillWidth: true
            Layout.leftMargin: 0
            Layout.rightMargin: 0
            Layout.minimumWidth: 130
            height: 21
            z: 6
            color: "#CC3636"
            border.color: "#0A0B08"

            Text {
                anchors.centerIn: parent
                text: "MASTER"
                color: "white"
                font.family: "Inter"
                font.weight: Font.Bold
            }
        }

        // Master Inserts
        Rectangle {
            id: masterEfxRack
            Layout.fillWidth: true
            Layout.leftMargin: 0
            Layout.rightMargin: 0
            Layout.minimumWidth: 130
            height: 292
            color: "#191D21"
            border.color: "#0A0B08"
            z: 4

            ListModel {
                id: masterEfxModel
                ListElement { name: "Limiter" }
                ListElement { name: "Compressor" }
            }

            ListView {
                anchors.fill: parent
                model: masterEfxModel
                delegate: Rectangle {
                    width: parent.width
                    height: 30
                    color: "#1B1F24"
                    border.color: "#0A0B08"

                    RowLayout {
                        anchors.fill: parent
                        anchors.margins: 4
                        spacing: 4

                        Rectangle {
                            width: 1
                            height: 10
                            color: "#CC3636"
                            Layout.alignment: Qt.AlignVCenter
                        }

                        Text {
                            text: name
                            color: "white"
                            font.family: "Inter"
                            Layout.fillWidth: true
                        }

                        Text {
                            text: "\uE2B4"
                            color: "white"
                            font.family: "Segoe Fluent Icons"
                            MouseArea {
                                anchors.fill: parent
                                onClicked: {
                                    // Open plugin window
                                }
                            }
                        }
                    }
                }
            }
        }

        // Master Output Section
        Rectangle {
            Layout.fillWidth: true
            Layout.fillHeight: true
            color: "#272C32"
            border.color: "#0A0B08"
            z: 1

            Loader {
                id: masterVuMeterLoader
                sourceComponent: masterVuMeterComponent
                anchors.fill: parent
                z: 1

                Connections {
                    target: AudioEngine
                    function onLevelsChanged(left, right) {
                        if (masterVuMeterLoader.item) {
                            masterVuMeterLoader.item.leftLevel = left
                            masterVuMeterLoader.item.rightLevel = right
                        }
                    }
                }
            }

            ColumnLayout {
                anchors.fill: parent
                anchors.margins: 4
                spacing: 4
                z: 2

                Loader {
                    id: masterFaderLoader
                    sourceComponent: masterFaderComponent
                    Layout.fillWidth: true
                    Layout.fillHeight: true
                }

                Text {
                    id: masterLevelText
                    text: "0.0 dB"
                    color: "white"
                    font.family: "Inter"
                    Layout.alignment: Qt.AlignHCenter
                }
            }
        }

        // Master Controls
        Rectangle {
            Layout.fillWidth: true
            height: 40
            color: "#272C32"
            border.color: "#0A0B08"

            Row {
                anchors.centerIn: parent
                spacing: 4

                Button {
                    width: 40
                    height: 30
                    text: "A/B"
                    font.family: "Inter"
                    background: Rectangle {
                        color: parent.pressed ? "#CC3636" : "#353B41"
                        radius: 2
                    }
                    contentItem: Text {
                        text: parent.text
                        color: "white"
                        font.family: "Inter"
                        horizontalAlignment: Text.AlignHCenter
                        verticalAlignment: Text.AlignVCenter
                    }
                }

                Button {
                    width: 40
                    height: 30
                    text: "MONO"
                    font.family: "Inter"
                    background: Rectangle {
                        color: parent.pressed ? "#CC3636" : "#353B41"
                        radius: 2
                    }
                    contentItem: Text {
                        text: parent.text
                        color: "white"
                        font.family: "Inter"
                        horizontalAlignment: Text.AlignHCenter
                        verticalAlignment: Text.AlignVCenter
                    }
                }
            }
        }
    }

    FileDialog {
        id: savePresetDialog
        title: "Save Master Preset"
        nameFilters: ["XML files (*.xml)"]
        fileMode: FileDialog.SaveFile
        onAccepted: {
            audioEngine.save_preset(selectedFile)
        }
    }
}

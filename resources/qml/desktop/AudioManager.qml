import QtQuick
import QtQuick.Controls
import QtQuick.Layouts
import com.futureboard.audio 1.0
import com.futureboard.core 1.0

Window {
    id: root
    title: "Audio Settings"
    width: 500
    height: 600
    modality: Qt.ApplicationModal
    flags: Qt.Dialog

    ColumnLayout {
        anchors.fill: parent
        spacing: 1

        // Header
        Rectangle {
            Layout.fillWidth: true
            height: 32
            color: "#CC3636"

            Label {
                anchors.centerIn: parent
                text: "AUDIO SETTINGS"
                color: "white"
                font { family: "Inter"; bold: true }
            }
        }

        // Audio Engine Section
        Rectangle {
            Layout.fillWidth: true
            Layout.preferredHeight: engineColumn.implicitHeight + 24
            color: "#272C32"
            border { width: 1; color: "#0A0B08" }

            ColumnLayout {
                id: engineColumn
                anchors { fill: parent; margins: 12 }
                spacing: 8

                Label {
                    text: "AUDIO ENGINE"
                    color: "white"
                    font { family: "Inter"; bold: true }
                }

                // Driver Selection
                RowLayout {
                    Layout.fillWidth: true
                    Label {
                        Layout.preferredWidth: 80
                        text: "Driver"
                        color: "white"
                        font.family: "Inter"
                    }
                    ComboBox {  // Custom ComboBox
                        Layout.fillWidth: true
                        model: AudioEngine.audioApis
                        currentIndex: AudioEngine.currentApi
                        onCurrentIndexChanged: AudioEngine.setCurrentApi(currentIndex)
                    }
                }

                // Buffer Size
                RowLayout {
                    Layout.fillWidth: true
                    Label {
                        Layout.preferredWidth: 80
                        text: "Buffer Size"
                        color: "white"
                        font.family: "Inter"
                    }
                    ComboBox {
                        Layout.fillWidth: true
                        model: ["64", "128", "256", "512", "1024", "2048"]
                        currentIndex: 2
                        onCurrentTextChanged: AudioEngine.setBufferSize(parseInt(currentText))
                    }
                }
            }
        }

        // Device Selection Section
        Rectangle {
            Layout.fillWidth: true
            Layout.fillHeight: true
            color: "#272C32"
            border { width: 1; color: "#0A0B08" }

            ColumnLayout {
                anchors { fill: parent; margins: 12 }
                spacing: 8

                Label {
                    text: "AUDIO DEVICES"
                    color: "white"
                    font { family: "Inter"; bold: true }
                }

                // ASIO Section
                ColumnLayout {
                    id: asioSection
                    visible: AudioEngine.isAsioDevice
                    spacing: 8

                    RowLayout {
                        Layout.fillWidth: true
                        Label {
                            Layout.preferredWidth: 80
                            text: "Interface"
                            color: "white"
                            font.family: "Inter"
                        }
                        ComboBox {  // Custom ComboBox
                            id: asioDeviceSelector
                            Layout.fillWidth: true
                            model: AudioEngine.asioDevices
                            currentIndex: model.indexOf(AudioEngine.currentInput)
                            onActivated: {
                                if (currentIndex >= 0) {
                                    AudioEngine.setCurrentInput(currentText)
                                }
                            }
                        }
                    }

                    Label {
                        Layout.fillWidth: true
                        text: AudioEngine.deviceInfo
                        color: "white"
                        font.family: "Inter"
                        wrapMode: Text.WordWrap
                    }

                    Button {
                        text: "ASIO Control Panel"
                        onClicked: AudioEngine.showAsioPanel()
                    }
                }

                // Standard Section
                ColumnLayout {
                    id: standardSection
                    visible: !AudioEngine.isAsioDevice
                    spacing: 8

                    RowLayout {
                        Layout.fillWidth: true
                        Label {
                            Layout.preferredWidth: 80
                            text: "Input"
                            color: "white"
                            font.family: "Inter"
                        }
                        ComboBox {
                            id: inputSelector
                            Layout.fillWidth: true
                            model: AudioEngine.inputDevices
                            currentIndex: model.indexOf(AudioEngine.currentInput)
                            onCurrentTextChanged: {
                                if (currentText !== "") {
                                    AudioEngine.setCurrentInput(currentText)
                                }
                            }
                        }
                    }

                    RowLayout {
                        Layout.fillWidth: true
                        Label {
                            Layout.preferredWidth: 80
                            text: "Output"
                            color: "white"
                            font.family: "Inter"
                        }
                        ComboBox {
                            Layout.fillWidth: true
                            model: AudioEngine.outputDevices
                            currentIndex: model.indexOf(AudioEngine.currentOutput)
                            onCurrentTextChanged: AudioEngine.setCurrentOutput(currentText)
                        }
                    }
                }
            }
        }

        // Status Bar
        Rectangle {
            Layout.fillWidth: true
            height: 28
            color: "#272C32"
            border { width: 1; color: "#0A0B08" }

            Label {
                anchors { fill: parent; margins: 8 }
                text: AudioEngine.statusText
                color: "white"
                font.family: "Inter"
                elide: Text.ElideRight
            }
        }
    }

    // Add state monitoring
    Connections {
        target: AudioEngine
        
        function onCurrentApiChanged() {
            console.log("API changed, isASIO:", AudioEngine.isAsioDevice)
            if (AudioEngine.isAsioDevice) {
                // Update ASIO device list
                asioDeviceSelector.model = AudioEngine.devices
                
                // Update selection after model is set
                if (AudioEngine.currentInput !== "") {
                    let idx = asioDeviceSelector.model.indexOf(AudioEngine.currentInput)
                    if (idx >= 0) {
                        asioDeviceSelector.currentIndex = idx
                    }
                }
            } else {
                // Clear ASIO selection
                asioDeviceSelector.model = []
                asioDeviceSelector.currentIndex = -1
                
                // Update standard inputs
                inputSelector.model = AudioEngine.devices
                if (AudioEngine.currentInput !== "") {
                    let idx = inputSelector.model.indexOf(AudioEngine.currentInput)
                    if (idx >= 0) {
                        inputSelector.currentIndex = idx
                    }
                }
            }
        }

        function onDevicesChanged() {
            if (AudioEngine.isAsioDevice) {
                asioDeviceSelector.model = AudioEngine.devices
            } else {
                inputSelector.model = AudioEngine.devices
            }
        }

        function onCurrentDeviceChanged() {
            // Handle visibility
            asioSection.visible = AudioEngine.isAsioDevice
            standardSection.visible = !AudioEngine.isAsioDevice
            
            // Update models
            if (AudioEngine.isAsioDevice) {
                asioDeviceSelector.model = AudioEngine.devices
                
                // Update selection
                if (AudioEngine.currentInput !== "") {
                    let idx = asioDeviceSelector.model.indexOf(AudioEngine.currentInput)
                    if (idx >= 0) {
                        asioDeviceSelector.currentIndex = idx
                    }
                }
            }
        }
    }
}

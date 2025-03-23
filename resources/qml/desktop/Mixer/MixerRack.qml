import QtQuick
import QtQuick.Controls
import QtQuick.Layouts
import QtQuick.Dialogs
import "../../Styles" as Styles
import com.futureboard.audio 1.0
import com.futureboard.core 1.0

Rectangle {
    id: mixerRack
    width: 130
    color: "transparent"

    property alias nameInput: trackName

    // VU Meter Component
    Component {
        id: vuMeterComponent
        Rectangle {
            id: vuMeter
            property real leftLevel: 0
            property real rightLevel: 0
            property real leftPeak: 0
            property real rightPeak: 0
            color: "transparent"
            
            function getSegmentColor(level) {
                if (level > 0.9) return Styles.Colors.meterRed
                if (level > 0.7) return Styles.Colors.meterYellow
                return Styles.Colors.meterGreen
            }
            
            Rectangle {
                id: leftChannel
                width: 6
                height: parent.height - 22
                color: Styles.Colors.meterBackground
                anchors.right: parent.horizontalCenter
                anchors.rightMargin: 1
                anchors.top: parent.top

                // Level meter with gradient
                Item {
                    width: parent.width
                    height: parent.height * leftLevel
                    anchors.bottom: parent.bottom
                    clip: true

                    Rectangle {
                        width: parent.width
                        height: parent.parent.height
                        gradient: Gradient {
                            GradientStop { position: 0.0; color: "#FF4444" }  // Red
                            GradientStop { position: 0.1; color: "#FF4444" }
                            GradientStop { position: 0.3; color: "#FFAA00" }  // Yellow
                            GradientStop { position: 0.4; color: "#FFAA00" }
                            GradientStop { position: 0.6; color: "#00FF66" }  // Green
                            GradientStop { position: 1.0; color: "#00FF66" }
                        }
                    }
                }

                // Peak indicator
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
                color: Styles.Colors.meterBackground
                anchors.left: parent.horizontalCenter
                anchors.leftMargin: 1
                anchors.top: parent.top

                // Level meter with gradient
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
                            GradientStop { position: 0.1; color: "#FF4444" }
                            GradientStop { position: 0.3; color: "#FFAA00" }
                            GradientStop { position: 0.4; color: "#FFAA00" }
                            GradientStop { position: 0.6; color: "#00FF66" }
                            GradientStop { position: 1.0; color: "#00FF66" }
                        }
                    }
                }

                // Peak indicator
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
                    AudioEngine.updateLevels()  // Changed from audioEngine to AudioEngine
                    leftPeak = Math.max(leftPeak * 0.995, leftLevel)
                    rightPeak = Math.max(rightPeak * 0.995, rightLevel)
                }
            }
        }
    }

    // Fader Component
    Component {
        id: customFaderComponent
        Rectangle {
            id: faderBackground
            color: "transparent"
            property real value: 0.7

            Rectangle {
                id: faderTrack
                width: 8
                height: parent.height - 20
                color: Styles.Colors.meterBackground
                anchors.centerIn: parent
                radius: 4

                Rectangle {
                    id: faderHandle
                    width: 40
                    height: 20
                    radius: 4
                    color: Styles.Colors.control
                    border.color: Styles.Colors.borderDark
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
                levelText.text = db.toFixed(1) + " dB"
            }
        }
    }

    // Custom ComboBox style
    Component {
        id: customComboBoxStyle
        ComboBox {
            id: control
            font.family: "Inter"
            
            background: Rectangle {
                color: "#272C32"
                border.color: "#0A0B08"
                radius: 2
            }
            
            contentItem: Text {
                leftPadding: 8
                text: control.displayText
                font: control.font
                color: "white"
                verticalAlignment: Text.AlignVCenter
            }
            
            delegate: ItemDelegate {
                width: control.width
                height: 30
                
                background: Rectangle {
                    color: highlighted ? "#353B41" : "#272C32"
                }
                
                contentItem: Text {
                    text: modelData
                    color: "white"
                    font.family: "Inter"
                    verticalAlignment: Text.AlignVCenter
                    leftPadding: 8
                }
            }
            
            popup: Popup {
                y: control.height
                width: control.width
                padding: 1
                
                background: Rectangle {
                    color: "#272C32"
                    border.color: "#0A0B08"
                }
                
                contentItem: ListView {
                    clip: true
                    implicitHeight: contentHeight
                    model: control.popup.visible ? control.delegateModel : null
                }
            }
        }
    }

    // Add VST Plugin Selector Popup
    Popup {
        id: pluginSelectorPopup
        width: 300
        height: 400
        modal: true
        focus: true
        closePolicy: Popup.CloseOnEscape | Popup.CloseOnPressOutside
        
        background: Rectangle {
            color: "#272C32"
            border.color: "#0A0B08"
        }

        ColumnLayout {
            anchors.fill: parent
            anchors.margins: 8
            spacing: 8

            TextField {
                id: searchField
                Layout.fillWidth: true
                height: 30
                placeholderText: "Search plugins..."
                color: "white"
                font.family: "Inter"
                
                background: Rectangle {
                    color: "#191D21"
                    border.color: "#0A0B08"
                    radius: 2
                }
            }

            TabBar {
                id: pluginTypeBar
                Layout.fillWidth: true
                
                TabButton {
                    text: "VST2"
                    font.family: "Inter"
                    background: Rectangle {
                        color: parent.checked ? "#353B41" : "#272C32"
                    }
                    contentItem: Text {
                        text: parent.text
                        color: "white"
                        font: parent.font
                        horizontalAlignment: Text.AlignHCenter
                        verticalAlignment: Text.AlignVCenter
                    }
                }
                TabButton {
                    text: "VST3"
                    font.family: "Inter"
                    background: Rectangle {
                        color: parent.checked ? "#353B41" : "#272C32"
                    }
                    contentItem: Text {
                        text: parent.text
                        color: "white"
                        font: parent.font
                        horizontalAlignment: Text.AlignHCenter
                        verticalAlignment: Text.AlignVCenter
                    }
                }
            }

            ListView {
                id: pluginListView
                Layout.fillWidth: true
                Layout.fillHeight: true
                clip: true
                model: ListModel {
                    id: pluginModel
                    // Placeholder items
                    ListElement { name: "EQ Plugin"; type: "VST2"; path: "" }
                    ListElement { name: "Compressor"; type: "VST3"; path: "" }
                    ListElement { name: "Reverb"; type: "VST2"; path: "" }
                }

                delegate: Rectangle {
                    width: ListView.view.width
                    height: 30
                    color: mouseArea.containsMouse ? "#353B41" : "#272C32"

                    RowLayout {
                        anchors.fill: parent
                        anchors.margins: 8
                        spacing: 8

                        Text {
                            text: name
                            color: "white"
                            font.family: "Inter"
                            Layout.fillWidth: true
                        }

                        Text {
                            text: type
                            color: "#8193A1"
                            font.family: "Inter"
                        }
                    }

                    MouseArea {
                        id: mouseArea
                        anchors.fill: parent
                        hoverEnabled: true
                        onClicked: {
                            efxModel.insert(efxList.count, { 
                                "name": name,
                                "type": type,
                                "path": path,
                                "isEnabled": true
                            })
                            pluginSelectorPopup.close()
                        }
                    }
                }
            }
        }
    }

    ColumnLayout {
        anchors.fill: parent
        spacing: 0

        // Header
        Rectangle {
            id: headerBar
            Layout.fillWidth: true
            Layout.leftMargin: 0
            Layout.rightMargin: 0
            Layout.minimumWidth: 130
            height: 21
            z: 6
            color: Styles.Colors.control
            border.color: Styles.Colors.borderDark

            RowLayout {
                anchors.fill: parent
                anchors.margins: 4
                spacing: 4

                Text {
                    text: "INSERTS"
                    color: Styles.Colors.textPrimary
                    font.family: "Inter"
                    font.weight: Font.Bold
                    Layout.alignment: Qt.AlignLeft
                }

                Item { Layout.fillWidth: true }

                Text {
                    text: "\uE710"
                    color: "#272C32"
                    font.family: "Segoe Fluent Icons"
                    Layout.alignment: Qt.AlignRight

                    MouseArea {
                        anchors.fill: parent
                        onClicked: pluginSelectorPopup.open()
                    }
                }

                Text {
                    text: "\uE792"  // Save icon
                    color: "#272C32"
                    font.family: "Segoe Fluent Icons"
                    MouseArea {
                        anchors.fill: parent
                        onClicked: savePresetDialog.open()
                    }
                }
                Text {
                    text: "\uE7C1"  // Open icon
                    color: "#272C32"
                    font.family: "Segoe Fluent Icons"
                    MouseArea {
                        anchors.fill: parent
                        onClicked: loadPresetDialog.open()
                    }
                }
            }
        }

        // I/O Selector
        Rectangle {
            Layout.fillWidth: true
            Layout.leftMargin: 0
            Layout.rightMargin: 0
            Layout.minimumWidth: 130
            height: 30
            color: "#191D21"
            border.color: "#0A0B08"
            z: 5

            RowLayout {
                anchors.fill: parent
                anchors.margins: 4
                spacing: 4

                Rectangle {
                    Layout.fillWidth: true
                    height: 24
                    color: "#272C32"
                    border.color: "#0A0B08"
                    radius: 2

                    Text {
                        anchors.left: parent.left
                        anchors.leftMargin: 8
                        anchors.verticalCenter: parent.verticalCenter
                        text: inputSelector.currentIndex >= 0 ? inputSelector.currentText : "Select Input..."
                        color: inputSelector.currentIndex >= 0 ? "white" : "#566470"
                        font.family: "Inter"
                        elide: Text.ElideRight
                    }

                    MouseArea {
                        anchors.fill: parent
                        onClicked: ioPopup.opened ? ioPopup.close() : ioPopup.open()
                    }

                    // Down arrow icon
                    Text {
                        anchors.right: parent.right
                        anchors.rightMargin: 8
                        anchors.verticalCenter: parent.verticalCenter
                        text: "\uE70D"
                        font.family: "Segoe Fluent Icons"
                        color: "white"
                    }
                }

                Popup {
                    id: ioPopup
                    width: parent.width
                    height: Math.min(300, contentItem.contentHeight + 2)
                    y: parent.height
                    padding: 1

                    background: Rectangle {
                        color: "#272C32"
                        border.color: "#0A0B08"
                    }

                    contentItem: ListView {
                        id: inputSelector
                        clip: true
                        model: audioEngine.getInputDevices()
                        currentIndex: -1
                        
                        ScrollBar.vertical: ScrollBar {
                            active: true
                            policy: ScrollBar.AsNeeded
                        }

                        delegate: Rectangle {
                            width: inputSelector.width
                            height: 30
                            color: mouseArea.containsMouse ? "#353B41" : "#272C32"

                            Text {
                                anchors.left: parent.left
                                anchors.leftMargin: 8
                                anchors.verticalCenter: parent.verticalCenter
                                text: modelData
                                color: "white"
                                font.family: "Inter"
                                elide: Text.ElideRight
                            }

                            MouseArea {
                                id: mouseArea
                                anchors.fill: parent
                                hoverEnabled: true
                                onClicked: {
                                    inputSelector.currentIndex = index
                                    audioEngine.setInputDevice(index)
                                    ioPopup.close()
                                }
                            }
                        }
                    }
                }
            }
        }

        // Replace Inserts and Sends Racks with SplitView
        SplitView {
            Layout.fillWidth: true
            Layout.minimumWidth: 96
            height: 200  // Combined height of previous inserts + sends
            orientation: Qt.Vertical
            z: 4

            // Inserts Rack
            Rectangle {
                id: efxRack
                SplitView.fillWidth: true
                SplitView.minimumHeight: 30
                SplitView.preferredHeight: 292
                color: "#191D21"
                border.color: "#0A0B08"

                ListModel {
                    id: efxModel
                }

                ListView {
                    id: efxList
                    anchors.fill: parent
                    model: efxModel
                    clip: true
                    
                    ScrollBar.vertical: ScrollBar {
                        id: efxScrollBar
                        active: true
                        policy: ScrollBar.AsNeeded
                        
                        contentItem: Rectangle {
                            implicitWidth: 6
                            radius: width / 2
                            color: efxScrollBar.pressed ? "#81B1FF" : "#353B41"
                        }

                        background: Rectangle {
                            implicitWidth: 6
                            color: "#141618"
                            radius: width / 2
                        }
                    }

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
                                color: model.isEnabled ? "#81B1FF" : "#566470"
                                Layout.alignment: Qt.AlignVCenter

                                MouseArea {
                                    anchors.fill: parent
                                    onClicked: model.isEnabled = !model.isEnabled
                                }
                            }

                            Text {
                                text: name + (type ? " (" + type + ")" : "")
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
                                        console.log("Opening plugin:", name, "at path:", path)
                                    }
                                }
                            }

                            Text {
                                text: "\uE74D"
                                color: "white"
                                font.family: "Segoe Fluent Icons"
                                MouseArea {
                                    anchors.fill: parent
                                    onClicked: efxModel.remove(index)
                                }
                            }
                        }
                    }
                }

                // Rectangle {
                //     height: 20
                //     color: "#141618"
                //     anchors.top: parent.top
                //     anchors.left: parent.left
                //     anchors.right: parent.right
                //     z: 1

                //     Text {
                //         anchors.centerIn: parent
                //         text: "INSERTS"
                //         color: "#566470"
                //         font.family: "Inter"
                //     }
                // }
            }

            // Sends Rack
            Rectangle {
                id: sendRack
                SplitView.fillWidth: true
                SplitView.minimumHeight: 30
                SplitView.preferredHeight: 96
                color: "#191D21"
                border.color: "#0A0B08"

                ListModel {
                    id: sendModel
                    ListElement { name: "Send 1" }
                    ListElement { name: "Send 2" }
                }

                ListView {
                    id: sendList
                    anchors.fill: parent
                    model: sendModel
                    clip: true

                    ScrollBar.vertical: ScrollBar {
                        id: sendScrollBar
                        active: true
                        policy: ScrollBar.AsNeeded
                        
                        contentItem: Rectangle {
                            implicitWidth: 6
                            radius: width / 2
                            color: sendScrollBar.pressed ? "#81B1FF" : "#353B41"
                        }

                        background: Rectangle {
                            implicitWidth: 6
                            color: "#141618"
                            radius: width / 2
                        }
                    }


                }

                Rectangle {
                    height: 20
                    color: "#141618"
                    anchors.top: parent.top
                    anchors.left: parent.left
                    anchors.right: parent.right
                    z: 1

                    Text {
                        anchors.centerIn: parent
                        text: "SENDS"
                        color: "#566470"
                        font.family: "Inter"
                    }
                }
            }
        }

        // Pan Control
        Rectangle {
            Layout.fillWidth: true
            Layout.leftMargin: 0
            Layout.rightMargin: 0
            Layout.minimumWidth: 130
            height: 40
            color: "#191D21"
            border.color: "#0A0B08"
            z: 2

            Slider {
                anchors.centerIn: parent
                width: parent.width - 20
                value: model.pan
                onValueChanged: model.pan = value
            }
        }

        // Main Control Section
        Rectangle {
            Layout.fillWidth: true
            Layout.leftMargin: 0
            Layout.rightMargin: 0
            Layout.minimumWidth: 130
            Layout.fillHeight: true
            color: "#272C32"
            border.color: "#0A0B08"
            z: 1

            // VU Meter
            Loader {
                id: vuMeterLoader
                sourceComponent: vuMeterComponent
                anchors.fill: parent
                z: 1
                onLoaded: {
                    item.leftLevel = model.leftLevel
                    item.rightLevel = model.rightLevel
                }
            }

            // Fader Control
            ColumnLayout {
                anchors.fill: parent
                anchors.margins: 4
                spacing: 4
                z: 2

                Loader {
                    id: faderLoader
                    sourceComponent: customFaderComponent
                    Layout.fillWidth: true
                    Layout.fillHeight: true
                    onLoaded: {
                        item.value = model.volume
                    }
                }

                Text {
                    id: levelText
                    text: "0.0 dB"
                    color: "white"
                    font.family: "Inter"
                    Layout.alignment: Qt.AlignHCenter
                }
            }
        }

        // Mute/Solo Buttons
        Rectangle {
            Layout.fillWidth: true
            height: 20
            color: "#272C32"
            border.color: "#0A0B08"

            Row {
                anchors.centerIn: parent

                Rectangle {
                    width: 65
                    height: 20
                    color: "#272C32"
                    border.color: "#0E1417"

                    property bool isMuted: model.mute
                    onIsMutedChanged: model.mute = isMuted

                    Rectangle {
                        anchors.fill: parent
                        anchors.margins: 1
                        color: parent.isMuted ? "#CC3636" : "#272C32"
                        radius: 1

                        Text {
                            anchors.centerIn: parent
                            text: "M"
                            color: parent.parent.isMuted ? "white" : "#B8C4CF"
                            font.family: "Inter"
                        }
                    }

                    MouseArea {
                        anchors.fill: parent
                        onClicked: parent.isMuted = !parent.isMuted
                    }
                }

                Rectangle {
                    width: 65
                    height: 20
                    color: "#272C32"
                    border.color: "#0E1417"

                    property bool isSolo: model.solo
                    onIsSoloChanged: model.solo = isSolo

                    Rectangle {
                        anchors.fill: parent
                        anchors.margins: 1
                        color: parent.isSolo ? "#CCAA36" : "#272C32"
                        radius: 1

                        Text {
                            anchors.centerIn: parent
                            text: "S"
                            color: parent.parent.isSolo ? "white" : "#B8C4CF"
                            font.family: "Inter"
                        }
                    }

                    MouseArea {
                        anchors.fill: parent
                        onClicked: parent.isSolo = !parent.isSolo
                    }
                }
            }
        }

        // Track Name
        Rectangle {
            Layout.fillWidth: true
            height: 25
            color: "#8193A1"
            border.color: "#0A0B08"

            TextInput {
                id: trackName  // Add this id
                anchors.centerIn: parent
                text: "Track 1"
                color: "#272C32"
                font.family: "Inter"
                horizontalAlignment: Text.AlignHCenter
                readOnly: true

                MouseArea {
                    anchors.fill: parent
                    onDoubleClicked: {
                        nameInput.readOnly = false
                        nameInput.forceActiveFocus()
                    }
                }

                Keys.onReturnPressed: {
                    nameInput.readOnly = true
                    focus = false
                }

                Keys.onEscapePressed: {
                    nameInput.readOnly = true
                    focus = false
                }

                onFocusChanged: {
                    if (!focus) {
                        nameInput.readOnly = true
                    }
                }
            }
        }
    }

    FileDialog {
        id: savePresetDialog
        title: "Save Preset"
        nameFilters: ["XML files (*.xml)"]
        fileMode: FileDialog.SaveFile
        onAccepted: {
            audioEngine.save_preset(selectedFile)
        }
    }

    FileDialog {
        id: loadPresetDialog
        title: "Load Preset"
        nameFilters: ["XML files (*.xml)"]
        fileMode: FileDialog.OpenFile
        onAccepted: {
            audioEngine.load_preset(selectedFile)
        }
    }
}
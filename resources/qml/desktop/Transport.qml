import QtQuick 2.15
import QtQuick.Controls 2.15
import "." as Local

Rectangle {
    id: transportBar
    anchors {
        left: parent.left
        right: parent.right
        top: parent.top
    }
    height: 40
    color: "#353535"

    // Properties for binding
    property string currentKey: "C"
    property string currentScale: "Major"
    property string currentTempo: "120.00"
    property int signatureNumerator: 4
    property int signatureDenominator: 4
    property string timeDisplay: "00:00:00.000"
    property string beatDisplay: "0:0:0:0"
    // property alias currentKey: currentKeyText.text
    // property alias currentScale: currentScaleText.text
    property bool chordCircleVisible: false // Control visibility


    // Common text styling
    QtObject {
        id: textStyles
        property color labelColor: Qt.rgba(1, 1, 1, 0.5)
        property color valueColor: "#ffffff"
        property string fontFamily: "Inter Display"
        property int labelSize: 10
        property int valueSize: 14
    }

    Row {
        id: leftGroups
        anchors {
            left: parent.left
            leftMargin: 16
            verticalCenter: parent.verticalCenter
        }
        spacing: 12
        height: parent.height
        // Group 1 - Key Display with Toggle Button
        Column {
            anchors.verticalCenter: parent.verticalCenter
            spacing: -2

            Text {
                text: "Key"
                font {
                    family: textStyles.fontFamily
                    italic: true
                    pixelSize: textStyles.labelSize
                }
                color: textStyles.labelColor
            }

            Button {
                text: currentKey + " " + currentScale
                font.pixelSize: textStyles.valueSize
                font.family: "Inter Display"
                font.weight: Font.DemiBold
                onClicked: {
                    transportBar.chordCircleVisible = !transportBar.chordCircleVisible
                    console.log("ChordCircle visibility toggled:", transportBar.chordCircleVisible)
                }
                background: Rectangle {
                    color: "transparent"
                }
                palette.buttonText: "white"
                 leftPadding: 0
                 rightPadding: 0
                 topPadding: 0
                 bottomPadding: 0
            }
        }
        // Group 2 - Tempo
        Column {
            anchors.verticalCenter: parent.verticalCenter
            spacing: -2

            Text {
                text: "Tempo"
                font {
                    family: textStyles.fontFamily
                    italic: true
                    pixelSize: textStyles.labelSize
                }
                color: textStyles.labelColor
            }

            Text {
                text: currentTempo
                font {
                    family: textStyles.fontFamily
                    pixelSize: textStyles.valueSize
                    weight: Font.DemiBold
                }
                color: textStyles.valueColor
            }
        }

        // Group 3 - Time Signature
        Column {
            anchors.verticalCenter: parent.verticalCenter
            spacing: -2

            Text {
                text: "Time Signature"
                font {
                    family: textStyles.fontFamily
                    italic: true
                    pixelSize: textStyles.labelSize
                }
                color: textStyles.labelColor
            }

            Text {
                text: signatureNumerator + " / " + signatureDenominator
                font {
                    family: textStyles.fontFamily
                    pixelSize: textStyles.valueSize
                    weight: Font.DemiBold
                }
                color: textStyles.valueColor
            }
        }

        Column {
            anchors.verticalCenter: parent.verticalCenter
            spacing: -2

            Text {
                text: "Timecode"
                font {
                    family: textStyles.fontFamily
                    italic: true
                    pixelSize: textStyles.labelSize
                }
                color: textStyles.labelColor
            }

            Text {
                text: timeDisplay + " / " + beatDisplay
                font {
                    family: textStyles.fontFamily
                    pixelSize: textStyles.valueSize
                    weight: Font.DemiBold
                }
                color: textStyles.valueColor
            }
        }
    }

    Row {
        id: centerControls
        anchors {
            centerIn: parent
            horizontalCenter: parent.horizontalCenter
        }
        spacing: 10
        height: parent.height

        // Mixer Button
        ToolButton {
            id: mixerButton
            width: 20
            height:20
            anchors.verticalCenter: parent.verticalCenter
            background: Rectangle {
                color: "transparent"
            }

            Image {
                anchors.fill: parent
                source: "qrc:/icons/Mixer.png"  // Replace with actual path to PNG icon
                fillMode: Image.PreserveAspectFit
            }

            onClicked: {
                // Implement mixer action
                console.log("Mixer button clicked")
            }
        }

        // Redo Button
        ToolButton {
            id: redoButton
            width: 20
            height:20
            anchors.verticalCenter: parent.verticalCenter
            background: Rectangle {
                color: "transparent"
            }

            Image {
                anchors.fill: parent
                source: "qrc:/icons/Redo.png"  // Replace with actual path to PNG icon
                fillMode: Image.PreserveAspectFit
            }

            onClicked: {
                // Implement redo action
                console.log("Redo button clicked")
            }
        }

        // Undo Button
        ToolButton {
            id: undoButton
            width: 20
            height:20
            anchors.verticalCenter: parent.verticalCenter
            background: Rectangle {
                color: "transparent"
            }

            Image {
                anchors.fill: parent
                source: "qrc:/icons/Undo.png"  // Replace with actual path to PNG icon
                fillMode: Image.PreserveAspectFit
            }

            onClicked: {
                // Implement undo action
                console.log("Undo button clicked")
            }
        }

        // Previous Button
        ToolButton {
            id: prevButton
            width: 20
            height:20
            anchors.verticalCenter: parent.verticalCenter
            background: Rectangle {
                color: "transparent"
            }

            Image {
                anchors.fill: parent
                source: "qrc:/icons/Back.png"  // Replace with actual path to PNG icon
                fillMode: Image.PreserveAspectFit
            }

            onClicked: {
                // Implement previous track/section action
                console.log("Previous button clicked")
            }
        }

        // Record Button
        ToolButton {
            id: recordButton
            width: 20
            height:20
            anchors.verticalCenter: parent.verticalCenter
            background: Rectangle {
                color: "transparent"
            }

            Image {
                anchors.fill: parent
                source: "qrc:/icons/Record.png"  // Replace with actual path to PNG icon
                fillMode: Image.PreserveAspectFit
            }

            onClicked: {
                // Implement record action
                console.log("Record button clicked")
            }
        }

        // Play Button
        ToolButton {
            id: playButton
            width: 20
            height:20
            anchors.verticalCenter: parent.verticalCenter
            background: Rectangle {
                color: "transparent"
            }

            Image {
                anchors.fill: parent
                source: "qrc:/icons/Play.png"  // Replace with actual path to PNG icon
                fillMode: Image.PreserveAspectFit
            }

            onClicked: {
                // Implement play action
                console.log("Play button clicked")
            }
        }

        // Metronome Button
        ToolButton {
            id: metronomeButton
            width: 20
            height:20
            anchors.verticalCenter: parent.verticalCenter
            background: Rectangle {
                color: "transparent"
            }

            Image {
                anchors.fill: parent
                source: "qrc:/icons/Metronome.png"  // Replace with actual path to PNG icon
                fillMode: Image.PreserveAspectFit
            }

            onClicked: {
                // Implement metronome toggle action
                console.log("Metronome button clicked")
            }
        }
    }



    // Existing functions remain the same...
    function updateKey(key, scale) {
        currentKey = key
        currentScale = scale
    }

    function updateTempo(tempo) {
        currentTempo = tempo
    }

    function updateTimeSignature(num, denom) {
        signatureNumerator = num
        signatureDenominator = denom
    }

    function updateTimeDisplay(time, beat) {
        timeDisplay = time
        beatDisplay = beat
    }
}

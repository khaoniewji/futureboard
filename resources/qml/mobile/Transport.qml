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
    height: 48 // Increased height for touch targets
    color: "#353535"

    // Properties remain the same
    property string currentKey: "C"
    property string currentScale: "Major"
    property string currentTempo: "120.00"
    property int signatureNumerator: 4
    property int signatureDenominator: 4
    property string timeDisplay: "00:00:00.000"
    property string beatDisplay: "0:0:0:0"
    property bool chordCircleVisible: false

    // Adjusted text styling for mobile
    QtObject {
        id: textStyles
        property color labelColor: Qt.rgba(1, 1, 1, 0.5)
        property color valueColor: "#ffffff"
        property string fontFamily: "Inter Display"
        property int labelSize: 12 // Increased for mobile
        property int valueSize: 16 // Increased for mobile
    }

    Row {
        id: leftGroups
        anchors {
            left: parent.left
            leftMargin: 8 // Reduced margin for mobile
            verticalCenter: parent.verticalCenter
        }
        spacing: 8 // Reduced spacing for mobile
        height: parent.height

        // Key Display
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

        // Tempo
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

        // Time Signature
        Column {
            anchors.verticalCenter: parent.verticalCenter
            spacing: -2

            Text {
                text: "Time"
                font {
                    family: textStyles.fontFamily
                    italic: true
                    pixelSize: textStyles.labelSize
                }
                color: textStyles.labelColor
            }

            Text {
                text: signatureNumerator + "/" + signatureDenominator
                font {
                    family: textStyles.fontFamily
                    pixelSize: textStyles.valueSize
                    weight: Font.DemiBold
                }
                color: textStyles.valueColor
            }
        }
    }

    // Transport Controls - Centered
    Row {
        id: centerControls
        anchors.centerIn: parent
        spacing: 16 // Increased spacing for touch targets
        height: parent.height

        // Transport buttons with increased size
        Repeater {
            model: [
                {icon: "qrc:/icons/Mixer.png", action: function() { console.log("Mixer clicked") }},
                {icon: "qrc:/icons/Redo.png", action: function() { console.log("Redo clicked") }},
                {icon: "qrc:/icons/Undo.png", action: function() { console.log("Undo clicked") }},
                {icon: "qrc:/icons/Back.png", action: function() { console.log("Back clicked") }},
                {icon: "qrc:/icons/Record.png", action: function() { console.log("Record clicked") }},
                {icon: "qrc:/icons/Play.png", action: function() { console.log("Play clicked") }},
                {icon: "qrc:/icons/Metronome.png", action: function() { console.log("Metronome clicked") }}
            ]

            ToolButton {
                width: 32 // Increased size for touch
                height: 32 // Increased size for touch
                anchors.verticalCenter: parent.verticalCenter

                background: Rectangle {
                    color: "transparent"
                }

                Image {
                    anchors.fill: parent
                    source: modelData.icon
                    fillMode: Image.PreserveAspectFit
                }

                onClicked: modelData.action()
            }
        }
    }

    // Time Display - Right aligned
    Column {
        anchors {
            right: parent.right
            rightMargin: 8
            verticalCenter: parent.verticalCenter
        }
        spacing: -2

        Text {
            text: "Time"
            font {
                family: textStyles.fontFamily
                italic: true
                pixelSize: textStyles.labelSize
            }
            color: textStyles.labelColor
        }

        Text {
            text: timeDisplay
            font {
                family: textStyles.fontFamily
                pixelSize: textStyles.valueSize
                weight: Font.DemiBold
            }
            color: textStyles.valueColor
        }
    }

    // Functions remain the same
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

import QtQuick 2.15
import QtQuick.Controls 2.15
import QtQuick.Layouts
import Qt5Compat.GraphicalEffects
import com.futureboard.system 1.0
import "../Styles" as Styles
import "." as Local

Rectangle {
    id: transportBar
    anchors {
        left: parent.left
        right: parent.right
        top: parent.top
    }
    height: 40
    color: "#252525"  // Direct color instead of style
    border.color: "#121212"

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
        property color labelColor: "#808080"  // Direct secondary text color
        property color valueColor: "#FFFFFF"  // Direct primary text color
        property string fontFamily: "Inter"    // Match mixer font
        property int labelSize: 11
        property int valueSize: 13
    }

    Row {
        id: leftGroups
        anchors {
            left: parent.left
            leftMargin: 8
            verticalCenter: parent.verticalCenter
        }
        spacing: -1
        height: parent.height

        // Key Display Group
        Rectangle {
            height: 32
            width: contentLayout.width + 16
            color: "#272C32"  // Mixer control background
            border.color: "#0A0B08"
            radius: 2
            anchors.verticalCenter: parent.verticalCenter

            ColumnLayout {
                id: contentLayout
                anchors.centerIn: parent
                spacing: 0

                Text {
                    text: "KEY"
                    font.family: textStyles.fontFamily
                    font.pixelSize: textStyles.labelSize
                    color: textStyles.labelColor
                    Layout.alignment: Qt.AlignLeft
                }

                Text {
                    text: currentKey + " " + currentScale
                    font.family: textStyles.fontFamily
                    font.pixelSize: textStyles.valueSize
                    font.weight: Font.Medium
                    color: textStyles.valueColor
                    Layout.alignment: Qt.AlignLeft
                }
            }

            MouseArea {
                anchors.fill: parent
                onClicked: transportBar.chordCircleVisible = !transportBar.chordCircleVisible
            }
        }

        // Tempo Group
        Rectangle {
            height: 32
            width: tempoLayout.width + 16
            color: "#272C32"
            border.color: "#0A0B08"
            radius: 2
            anchors.verticalCenter: parent.verticalCenter

            ColumnLayout {
                id: tempoLayout
                anchors.centerIn: parent
                spacing: 0

                Text {
                    text: "BPM"
                    font.family: textStyles.fontFamily
                    font.pixelSize: textStyles.labelSize
                    color: textStyles.labelColor
                    Layout.alignment: Qt.AlignHLeft
                }

                Text {
                    text: currentTempo
                    font.family: textStyles.fontFamily
                    font.pixelSize: textStyles.valueSize
                    font.weight: Font.Medium
                    color: textStyles.valueColor
                    Layout.alignment: Qt.AlignHLeft
                }
            }
        }

        // Time Signature Group
        Rectangle {
            height: 32
            width: signatureLayout.width + 16
            color: "#272C32"
            border.color: "#0A0B08"
            radius: 2
            anchors.verticalCenter: parent.verticalCenter

            ColumnLayout {
                id: signatureLayout
                anchors.centerIn: parent
                spacing: 0

                Text {
                    text: "TIME"
                    font.family: textStyles.fontFamily
                    font.pixelSize: textStyles.labelSize
                    color: textStyles.labelColor
                    Layout.alignment: Qt.AlignHLeft
                }

                Text {
                    text: signatureNumerator + "/" + signatureDenominator
                    font.family: textStyles.fontFamily
                    font.pixelSize: textStyles.valueSize
                    font.weight: Font.Medium
                    color: textStyles.valueColor
                    Layout.alignment: Qt.AlignHLeft
                }
            }
        }
    }

    // Transport Controls
        // Transport Controls
    Row {
        id: centerControls
        anchors.centerIn: parent
        spacing: -1

        Repeater {
            model: [
                { icon: "qrc:/icons/Record.png", color: "#FF3333" },  // Record
                { icon: "qrc:/icons/Back.png", color: "#808080" },    // Previous
                { icon: "qrc:/icons/Play.png", color: "#3F7FD4" },    // Play
                { icon: "qrc:/icons/Back.png", color: "#808080", rotation: 180 }, // Next
                { icon: "qrc:/icons/Metronome.png", color: "#808080" }  // Metronome
            ]

            Rectangle {
                width: 32
                height: 32
                color: "#272C32"
                border.color: "#0A0B08"
                radius: 2

                Image {
                    anchors.centerIn: parent
                    source: modelData.icon
                    width: 16
                    height: 16
                    rotation: modelData.rotation || 0

                    ColorOverlay {
                        anchors.fill: parent
                        source: parent
                        color: modelData.color
                    }
                }

                MouseArea {
                    anchors.fill: parent
                    onPressed: parent.color = "#353B41"
                    onReleased: parent.color = "#272C32"
                    onClicked: {
                        // Add your click handling logic here
                    }
                }
            }
        }
    }

    // Add before the time display
    Row {
        anchors {
            right: timeLayout.parent.left
            rightMargin: 8
            verticalCenter: parent.verticalCenter
        }
        spacing: -1

        Repeater {
            model: [
                { label: "CPU", value: PerformanceMeter.cpuUsage.toFixed(1) + "%" },
                { label: "RAM", value: PerformanceMeter.ramUsage },
                { label: "DISK", value: PerformanceMeter.diskSpeed }
            ]

            Rectangle {
                height: 32
                width: metricLayout.width + 16
                color: "#272C32"
                border.color: "#0A0B08"
                radius: 2

                ColumnLayout {
                    id: metricLayout
                    anchors.centerIn: parent
                    spacing: 0

                    Text {
                        text: modelData.label
                        font.family: textStyles.fontFamily
                        font.pixelSize: textStyles.labelSize
                        color: textStyles.labelColor
                        Layout.alignment: Qt.AlignLeft
                    }

                    Text {
                        text: modelData.value
                        font.family: textStyles.fontFamily
                        font.pixelSize: textStyles.valueSize
                        font.weight: Font.Medium
                        color: textStyles.valueColor
                        Layout.alignment: Qt.AlignLeft
                    }
                }
            }
        }
    }

    // Time Display
    Rectangle {
        anchors {
            right: parent.right
            rightMargin: 16
            verticalCenter: parent.verticalCenter
        }
        height: 32
        width: timeLayout.width + 16
        color: "#272C32"
        border.color: "#0A0B08"
        radius: 2

        ColumnLayout {
            id: timeLayout
            anchors.centerIn: parent
            spacing: 0

            Text {
                text: "TIME"
                font.family: textStyles.fontFamily
                font.pixelSize: textStyles.labelSize
                color: textStyles.labelColor
                Layout.alignment: Qt.AlignHLeft
            }

            Text {
                text: timeDisplay
                font.family: textStyles.fontFamily
                font.pixelSize: textStyles.valueSize
                font.weight: Font.Medium
                color: textStyles.valueColor
                Layout.alignment: Qt.AlignHLeft
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

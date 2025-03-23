// TrackView.qml
import QtQuick 2.15
import QtQuick.Controls 2.15
import QtQuick.Layouts 1.15
import com.futureboard.core 1.0

Rectangle {
    id: trackView
    color: "#151515"

    property alias trackListModel: trackList.model
    property alias contextMenu: trackContextMenu
    property alias addTrackDialog: addTrackDialog
    property string currentTrackType: "audio"
    property string selectedTrackType: ""  // Add this property

    ListView {
        id: trackList
        anchors.fill: parent
        model: TrackManager.trackModel
        spacing: 0
        clip: true
        boundsBehavior: Flickable.StopAtBounds
        flickDeceleration: 2000
        maximumFlickVelocity: 2000
        interactive: true
        
        delegate: TrackWidget {
            width: trackList.width
            trackName: model.name
            volume: model.volume
            pan: model.pan
            isAudioTrack: model.type === "audio"
            trackNumber: index + 1
        }

        ScrollBar.vertical: ScrollBar {
            policy: ScrollBar.AsNeeded
            interactive: true
            
            background: Rectangle {
                color: "#151515"
                border.color: "#0A0A0A"
            }
            
            contentItem: Rectangle {
                implicitWidth: 8
                radius: width / 2
                color: parent.pressed ? "#404040" : "#303030"
            }
        }
    }

    Menu {
        id: trackContextMenu
        MenuItem { text: "Add Audio Track" }
        MenuItem { text: "Add MIDI Track" }
        MenuItem { text: "Add Automation Track" }
        MenuSeparator {}
        MenuItem { text: "Remove Track" }
    }

    Dialog {
        id: addTrackDialog
        title: "Add Track"
        modal: true
        dim: true
        closePolicy: Popup.CloseOnEscape
        parent: Overlay.overlay
        anchors.centerIn: parent
        width: 300
        height: contentItem.implicitHeight + header.height + footer.height
        padding: 0

        background: Rectangle {
            color: "#202020"
            border.color: "#0A0A0A"
            border.width: 1
            radius: 4
        }

        header: Rectangle {
            color: "#252525"
            height: 32
            width: parent.width
            border.color: "#0A0A0A"
            z: 2

            Text {
                text: addTrackDialog.title
                color: "#B0B0B0"
                font.pixelSize: 12
                font.family: "Inter Display"
                anchors.verticalCenter: parent.verticalCenter
                anchors.left: parent.left
                anchors.leftMargin: 12
            }
        }

        footer: DialogButtonBox {
            height: 48
            alignment: Qt.AlignRight
            spacing: 8
            padding: 8
            background: Rectangle {
                color: "#202020"
                border.color: "#0A0A0A"
                border.width: 1
            }

            standardButtons: Dialog.Ok | Dialog.Cancel

            delegate: Button {
                id: button
                implicitWidth: 80
                implicitHeight: 24

                background: Rectangle {
                    color: button.down ? "#353535" : "#252525"
                    border.color: "#0A0A0A"
                    border.width: 1
                    radius: 2
                }

                contentItem: Text {
                    text: button.text
                    color: "#B0B0B0"
                    font.pixelSize: 11
                    font.family: "Inter Display"
                    horizontalAlignment: Text.AlignHCenter
                    verticalAlignment: Text.AlignVCenter
                }
            }

            onAccepted: {
                if (selectedTrackType) {
                    createTrack(selectedTrackType)
                    selectedTrackType = ""
                    addTrackDialog.close()
                }
            }
            onRejected: {
                selectedTrackType = ""
                addTrackDialog.close()
            }
        }

        contentItem: Rectangle {
            color: "#202020"
            implicitWidth: 300
            implicitHeight: dialogLayout.implicitHeight + 20

            ColumnLayout {
                id: dialogLayout
                anchors {
                    fill: parent
                    margins: 10
                }
                spacing: 8

                Rectangle {
                    Layout.fillWidth: true
                    Layout.preferredHeight: 120
                    color: "#151515"
                    border.color: "#0A0A0A"

                    GridLayout {
                        anchors.fill: parent
                        anchors.margins: 8
                        columns: 3
                        rowSpacing: 8
                        columnSpacing: 8

                        Repeater {
                            model: [
                                {icon: "audio.svg", text: "Audio", type: "audio"},
                                {icon: "midi.svg", text: "MIDI", type: "midi"},
                                {icon: "instrument.svg", text: "Instrument", type: "instrument"},
                                {icon: "group.svg", text: "Group", type: "group"},
                                {icon: "fx.svg", text: "FX", type: "fx"},
                                {icon: "folder.svg", text: "Folder", type: "folder"}
                            ]

                            Rectangle {
                                Layout.preferredWidth: 80
                                Layout.preferredHeight: 48
                                color: selectedTrackType === modelData.type ? "#353535" : (trackTypeMouse.containsMouse ? "#252525" : "#191D21")
                                border.color: "#0A0A0A"

                                ColumnLayout {
                                    anchors.centerIn: parent
                                    spacing: 4

                                    Image {
                                        Layout.alignment: Qt.AlignHCenter
                                        source: "qrc:/icons/" + modelData.icon
                                        width: 16
                                        height: 16
                                    }

                                    Text {
                                        text: modelData.text
                                        color: "#808080"
                                        font.pixelSize: 11
                                        font.family: "Inter Display"
                                    }
                                }

                                MouseArea {
                                    id: trackTypeMouse
                                    anchors.fill: parent
                                    hoverEnabled: true
                                    onClicked: {
                                        selectedTrackType = modelData.type
                                    }
                                }
                            }
                        }
                    }
                }

                // Track count spinner
                SpinBox {
                    id: trackCount
                    Layout.fillWidth: true
                    Layout.preferredHeight: 24
                    from: 1
                    to: 16
                    value: 1
                    editable: true

                    onValueChanged: {
                        console.log("Track count changed:", value)
                    }

                    background: Rectangle {
                        color: "#151515"
                        border.color: "#0A0A0A"
                        radius: 2
                    }

                    contentItem: TextInput {
                        text: trackCount.value
                        color: "#B0B0B0"
                        font.pixelSize: 11
                        font.family: "Inter Display"
                        verticalAlignment: Text.AlignVCenter
                    }
                }
            }
        }
    }

    function createTrack(type) {
        if (!TrackManager.trackModel) {
            console.error("Track model is not initialized")
            return
        }

        // Ensure we get a valid integer
        let count = trackCount.value
        console.log("Creating tracks:", count, "of type:", type)

        TrackManager.addTrack({
            "name": type.charAt(0).toUpperCase() + type.slice(1),
            "type": type,
            "color": "#297ACC",
            "count": count
        })
    }
}

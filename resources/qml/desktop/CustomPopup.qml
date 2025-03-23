import QtQuick 2.15
import QtQuick.Controls 2.15
import QtQuick.Layouts 1.15

Popup {
    id: popup
    z: 1000  // Ensure popup is above other content
    
    property string title: ""
    default property alias content: contentLayout.children

    background: Rectangle {
        color: "#202020"
        border.color: "#0A0A0A"
        border.width: 1
        radius: 4
    }

    contentItem: ColumnLayout {
        spacing: 0

        // Header
        Rectangle {
            Layout.fillWidth: true
            height: 28
            color: "#252525"
            border.color: "#0A0A0A"
            border.width: 1

            Text {
                anchors {
                    verticalCenter: parent.verticalCenter
                    left: parent.left
                    leftMargin: 8
                }
                text: popup.title
                color: "#B0B0B0"
                font.pixelSize: 11
                font.family: "Inter Display"
            }
        }

        // Content
        Rectangle {
            Layout.fillWidth: true
            Layout.fillHeight: true
            color: "#202020"
            border.color: "#0A0A0A"
            border.width: 1

            ColumnLayout {
                id: contentLayout
                anchors.fill: parent
                anchors.margins: 8
                spacing: 8
            }
        }
    }

    // Add enter/exit transitions
    enter: Transition {
        NumberAnimation { property: "opacity"; from: 0.0; to: 1.0; duration: 100 }
    }
    exit: Transition {
        NumberAnimation { property: "opacity"; from: 1.0; to: 0.0; duration: 100 }
    }
}

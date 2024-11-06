import QtQuick 2.15
import QtQuick.Controls 2.15
import QtQuick.Layouts 1.15

Rectangle {
    color: "#262626"
    width: 800
    height: 600

    Rectangle {
        id: mainBackground
        anchors.fill: parent
        color: "#1E1E1E"

        Rectangle {
            id: topBar
            height: 50
            width: parent.width
            color: "#2D2D2D"
            anchors.top: parent.top

            TabBar {
                id: tabBar
                anchors.fill: parent

                TabButton {
                    text: "General"
                }
                TabButton {
                    text: "Audio"
                }
                TabButton {
                    text: "MIDI"
                }
                TabButton {
                    text: "File"
                }
                TabButton {
                    text: "Theme"
                }
                TabButton {
                    text: "Add-on"
                }
                TabButton {
                    text: "About"
                }
            }
        }

        Rectangle {
            id: mainContent
            anchors.right: parent.right
            anchors.top: topBar.bottom
            anchors.bottom: parent.bottom
            color: "#1E1E1E"
        }

        Rectangle {
            id: statusBar
            height: 25
            width: parent.width
            color: "#2D2D2D"
            anchors.bottom: parent.bottom
        }
    }
}

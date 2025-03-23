import QtQuick
import QtQuick.Controls

ComboBox {
    id: control
    
    delegate: ItemDelegate {
        width: control.width
        height: 30
        contentItem: Text {
            text: modelData
            color: "white"
            font.family: "Inter"
            verticalAlignment: Text.AlignVCenter
            elide: Text.ElideRight
        }
        highlighted: control.highlightedIndex === index
        background: Rectangle {
            color: highlighted ? "#CC3636" : "transparent"
        }
    }

    background: Rectangle {
        color: "#353B41"
        border.color: "#0A0B08"
        border.width: 1
        radius: 2
    }

    contentItem: Text {
        text: control.displayText
        color: "white"
        font.family: "Inter"
        verticalAlignment: Text.AlignVCenter
        leftPadding: 8
        elide: Text.ElideRight
    }

    popup: Popup {
        y: control.height
        width: control.width
        padding: 1

        contentItem: ListView {
            clip: true
            implicitHeight: contentHeight
            model: control.popup.visible ? control.delegateModel : null
            currentIndex: control.highlightedIndex
            ScrollIndicator.vertical: ScrollIndicator {}
        }

        background: Rectangle {
            color: "#191D21"
            border.color: "#0A0B08"
            border.width: 1
        }
    }
}

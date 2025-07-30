import QtQuick
import QtQuick.Controls

ComboBox {
    id: combo
    width: 200
    height: 40
    font.pixelSize: 16
    model: ["Option 1", "Option 2", "Option 3"]
    delegate: ItemDelegate {
        text: modelData
        font.pixelSize: 16
        background: Rectangle {
            color: combo.highlightedIndex === index ? theme.focusColor : theme.secondaryColor
        }
    }
    indicator: null
    background: Rectangle {
        color: theme.secondaryColor
        radius: 10
        border.color: theme.borderColor
    }
    contentItem: Text {
        text: combo.displayText
        color: theme.textColor
        verticalAlignment: Text.AlignVCenter
        anchors.verticalCenter: parent.verticalCenter
    }
}

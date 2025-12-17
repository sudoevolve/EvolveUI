import QtQuick
import QtQuick.Controls
import QtQuick.Layouts
import EvolveUI

Page {
    background: Rectangle { color: "transparent" }

    header: Label {
        text: "Search"
        font.pixelSize: 24
        font.bold: true
        padding: 20
        horizontalAlignment: Text.AlignHCenter
        color: theme.textColor
    }

    ColumnLayout {
        anchors.centerIn: parent
        spacing: 20
        width: parent.width * 0.8

        EInput {
            Layout.fillWidth: true
            placeholderText: "Search..."
        }

        EButton {
            text: "Search"
            Layout.alignment: Qt.AlignHCenter
            onClicked: console.log("Search clicked")
        }
    }
}

import QtQuick
import QtQuick.Controls
import QtQuick.Layouts
import EvolveUI

Page {
    background: Rectangle { color: "transparent" }
    
    header: Label {
        text: "Home"
        font.pixelSize: 24
        font.bold: true
        padding: 20
        horizontalAlignment: Text.AlignHCenter
        color: theme.textColor
    }

    ColumnLayout {
        anchors.centerIn: parent
        spacing: 20

        EButton {
            Layout.alignment: Qt.AlignHCenter
            text: "Welcome to EvolveUI"
            iconCharacter: "\uf015"
            onClicked: console.log("Welcome clicked")
        }

        Label {
            text: "This is the Home Page"
            font.pixelSize: 16
            color: theme.textColor
            Layout.alignment: Qt.AlignHCenter
        }   
    }
}

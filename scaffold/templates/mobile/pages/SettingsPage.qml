import QtQuick
import QtQuick.Controls
import QtQuick.Layouts
import EvolveUI

Page {
    background: Rectangle { color: "transparent" }

    header: Label {
        text: "Settings"
        font.pixelSize: 24
        font.bold: true
        padding: 20
        horizontalAlignment: Text.AlignHCenter
        color: theme.textColor
    }

    ColumnLayout {
        anchors.centerIn: parent
        spacing: 20
        
        Label {
            text: "Settings Page"
            font.pixelSize: 16
            color: theme.textColor
        }

        EButton {
        text: theme.isDark ? "white" : "dark"
        iconCharacter: theme.isDark ? "\uf186" : "\uf185"
        iconRotateOnClick: true //图标旋转
        onClicked: {
            theme.toggleTheme()
        }
    }
    }
}

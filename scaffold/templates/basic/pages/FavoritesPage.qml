import QtQuick
import QtQuick.Controls
import QtQuick.Layouts
import EvolveUI

Page {
    padding:20
    background: Rectangle {
        color: "transparent"
    }

    Label {
        text: "Favorites Page"
        anchors.centerIn: parent
        font.pixelSize: 24
        color: theme.textColor
    }

    Flow {
        spacing: 16
        anchors.fill: parent

    EClock {

        }

    }
}

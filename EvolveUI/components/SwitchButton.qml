// MySwitch.qml
import QtQuick 2.15
import QtQuick.Layouts 1.15
import QtQuick.Effects
import "."

Rectangle {
    id: root

    // === 外部接口 ===
    property string text: "Switch"
    property bool checked: false
    signal toggled(bool checked)

    // === 样式属性 ===
    property real radius: 15
    property int fontSize: 16
    property color buttonColor: theme.secondaryColor
    property color hoverColor: Qt.darker(buttonColor, 1.2)
    property color textColor: theme.textColor
    property color thumbColor: theme.textColor
    property bool shadowEnabled: true
    property real pressedScale: 0.96

    property color shadowColor: theme.shadowColor

    implicitHeight: 52
    implicitWidth: layout.implicitWidth + 32
    color: "transparent"

    transform: Scale {
        id: scale
        origin.x: root.width / 2
        origin.y: root.height / 2
    }

    MultiEffect {
        source: background
        anchors.fill: background
        shadowEnabled: root.shadowEnabled
        shadowColor: root.shadowColor
        shadowBlur: theme.shadowBlur
        shadowHorizontalOffset: theme.shadowXOffset
        shadowVerticalOffset: theme.shadowYOffset
    }

    Rectangle {
        id: background
        anchors.fill: parent
        radius: root.radius
        color: mouseArea.containsMouse ? root.hoverColor : root.buttonColor

        Behavior on color { ColorAnimation { duration: 150 } }
        Behavior on opacity { NumberAnimation { duration: 100 } }
    }

    RowLayout {
        id: layout
        anchors.centerIn: parent
        spacing: 12

        // === 滑块开关 ===
        Rectangle {
            id: track
            width: 40
            height: 22
            radius: height / 2
            color: checked ? theme.textColor : "#999999"
            Layout.alignment: Qt.AlignVCenter
            clip: true

            Behavior on color { ColorAnimation { duration: 150 } }

            Rectangle {
                id: thumb
                width: 18
                height: 18
                radius: 9
                color: root.buttonColor
                anchors.verticalCenter: parent.verticalCenter
                x: checked ? (track.width - width - 2) : 2

                Behavior on x { NumberAnimation { duration: 150; easing.type: Easing.OutQuad } }
            }
        }

        // === 文字 ===
        Text {
            text: root.text
            color: root.textColor
            font.pixelSize: root.fontSize
            font.bold: true
            verticalAlignment: Text.AlignVCenter
        }
    }

    MouseArea {
        id: mouseArea
        anchors.fill: parent
        hoverEnabled: true
        cursorShape: Qt.PointingHandCursor

        onPressed: {
            scale.xScale = root.pressedScale
            scale.yScale = root.pressedScale
            background.opacity = 0.85
        }

        onReleased: {
            restoreAnimation.restart()
            background.opacity = 1.0
            checked = !checked
            toggled(checked)
        }

        onCanceled: {
            restoreAnimation.restart()
            background.opacity = 1.0
        }
    }

    ParallelAnimation {
        id: restoreAnimation
        SpringAnimation { target: scale; property: "xScale"; to: 1.0; spring: 2.5; damping: 0.25 }
        SpringAnimation { target: scale; property: "yScale"; to: 1.0; spring: 2.5; damping: 0.25 }
    }
}

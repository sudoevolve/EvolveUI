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
    readonly property real contentScale: 0.4       // 40% 高度比例
    readonly property real trackWidth: root.height * 1
    readonly property real trackHeight: root.height * contentScale
    readonly property real thumbSize: root.height * contentScale

    property int fontSize: root.height * contentScale
    property color buttonColor: theme.secondaryColor
    property color hoverColor: Qt.darker(buttonColor, 1.2)
    property color textColor: theme.textColor
    property color thumbColor: theme.textColor
    property bool shadowEnabled: true
    property real pressedScale: 0.96

    property color shadowColor: theme.shadowColor

    readonly property int horizontalPadding: 16

    implicitHeight: 52
    implicitWidth: layout.implicitWidth + horizontalPadding * 2
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

        // === 滑块轨道 ===
        Rectangle {
            id: track
            width: trackWidth
            height: trackHeight
            radius: height / 2
            color: checked ? theme.textColor : "#999999"
            Layout.alignment: Qt.AlignVCenter
            clip: true

            Behavior on color { ColorAnimation { duration: 150 } }

            Rectangle {
                id: thumb
                width: thumbSize
                height: thumbSize
                radius: thumbSize / 2
                color: root.buttonColor
                anchors.verticalCenter: parent.verticalCenter

                property int edgePadding: 0
                x: checked ? (track.width - width - edgePadding) : edgePadding

                Behavior on x { NumberAnimation { duration: 150; easing.type: Easing.OutQuad } }
            }
        }

        // === 文字 ===
        Text {
            id: label
            text: root.text
            color: root.textColor
            font.pixelSize: fontSize
            font.bold: true
            verticalAlignment: Text.AlignVCenter
            Layout.preferredWidth: label.implicitWidth
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

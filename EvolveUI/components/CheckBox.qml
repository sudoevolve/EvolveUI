import QtQuick 2.15
import QtQuick.Layouts 1.15
import QtQuick.Effects
import "."

Rectangle {
    id: root

    // === 外部接口 ===
    property string text: "Checkbox"
    property bool checked: false
    signal toggled(bool checked)

    // === 样式属性 ===
    readonly property real contentScale: 0.4      // 文字和checkbox相对高度比例
    readonly property real boxSize: root.height * contentScale
    readonly property real fontSize: root.height * contentScale

    property real radius: 15
    property color buttonColor: theme.secondaryColor
    property color hoverColor: Qt.darker(buttonColor, 1.2)
    property color textColor: theme.textColor
    property color checkmarkColor: theme.textColor
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

        Rectangle {
            id: box
            width: boxSize
            height: boxSize
            radius: 4
            color: checked ? checkmarkColor : "transparent"
            border.color: theme.textColor
            border.width: 2
            Layout.alignment: Qt.AlignVCenter | Qt.AlignLeft

            Behavior on color { ColorAnimation { duration: 150 } }

            Text {
                anchors.centerIn: parent
                text: checked ? "\u2713" : ""
                font.pixelSize: boxSize * 0.8
                color: root.buttonColor
                visible: checked
            }
        }

        Text {
            text: root.text
            color: root.textColor
            font.pixelSize: fontSize
            font.bold: true
            verticalAlignment: Text.AlignVCenter
            Layout.preferredWidth: label.implicitWidth
            id: label
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

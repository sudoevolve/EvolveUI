// Button.qml
import QtQuick 2.15
import QtQuick.Layouts 1.15
import QtQuick.Effects

Rectangle {
    id: root

    // === 外部接口 ===
    property string text: "Button"
    property string iconCharacter: "\uf007"
    property string iconFontFamily: ""
    signal clicked

    // === 样式属性 ===
    property real radius: 15
    property color buttonColor: theme.secondaryColor
    property color hoverColor: Qt.darker(buttonColor, 1.2)
    property color textColor: theme.textColor
    property bool shadowEnabled: true
    property real pressedScale: 0.96
    property color shadowColor: theme.shadowColor

    // === 内容尺寸自动计算 ===
    readonly property real contentScale: 0.4
    readonly property real iconSize: root.height * contentScale
    readonly property real fontSize: iconSize * 0.9

    // === 尺寸控制 ===
    readonly property int horizontalPadding: 16
    implicitHeight: 52
    implicitWidth: layout.implicitWidth + horizontalPadding * 2

    color: "transparent"

    transform: Scale {
        id: scale
        origin.x: root.width / 2
        origin.y: root.height / 2
    }

    // === 阴影效果 ===
    MultiEffect {
        source: background
        anchors.fill: background
        shadowEnabled: root.shadowEnabled
        shadowColor: root.shadowColor
        shadowBlur: theme.shadowBlur
        shadowHorizontalOffset: theme.shadowXOffset
        shadowVerticalOffset: theme.shadowYOffset
    }

    // === 背景 ===
    Rectangle {
        id: background
        anchors.fill: parent
        radius: root.radius
        color: mouseArea.containsMouse ? root.hoverColor : root.buttonColor

        Behavior on color { ColorAnimation { duration: 150 } }
        Behavior on opacity { NumberAnimation { duration: 100 } }
    }

    // === 内容布局 ===
    RowLayout {
        id: layout
        anchors.centerIn: parent
        spacing: 8

        Text {
            id: iconLabel
            text: root.iconCharacter
            visible: root.iconCharacter !== ""
            color: root.textColor
            font.pixelSize: root.iconSize
            font.family: root.iconFontFamily
            verticalAlignment: Text.AlignVCenter
            horizontalAlignment: Text.AlignHCenter
            Layout.preferredWidth: iconLabel.implicitWidth
            Layout.preferredHeight: iconSize
        }

        Text {
            id: label
            text: root.text
            visible: root.text !== ""
            color: root.textColor
            font.pixelSize: root.fontSize
            font.bold: true
            verticalAlignment: Text.AlignVCenter
            Layout.preferredWidth: label.implicitWidth
        }
    }

    // === 交互区域与动画 ===
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
            root.clicked()
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

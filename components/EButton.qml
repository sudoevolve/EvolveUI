// EButton.qml
import QtQuick
import QtQuick.Layouts
import QtQuick.Effects

Rectangle {
    id: root

    // ==== 外部接口 ====
    property string text: "Button"                   // 按钮文字
    property string iconCharacter: "\uf013"          // 图标字符 (FontAwesome 等)
    property string iconFontFamily: iconFont.name               // 图标字体
    signal clicked                                   // 点击信号

    // ==== 样式 ====
    property bool backgroundVisible: true            // 是否显示背景
    property real radius: 20                         // 圆角半径
    property color buttonColor: theme.secondaryColor // 默认背景色
    property color hoverColor: Qt.darker(buttonColor, 1.2) // 悬停背景色
    property color textColor: theme.textColor        // 文字颜色
    property color iconColor: theme.textColor
    property bool shadowEnabled: true                // 是否显示阴影
    property real pressedScale: 0.96                 // 按下缩放比例
    property color shadowColor: theme.shadowColor    // 阴影颜色
    property bool iconRotateOnClick: false           //图标是否旋转

    // ==== 尺寸计算 ====
    readonly property real contentScale: 0.4
    readonly property real iconSize: root.height * contentScale
    readonly property real fontSize: iconSize * 0.9

    // ==== 尺寸控制 ====
    readonly property int horizontalPadding: 16
    implicitHeight: 52
    implicitWidth: layout.implicitWidth + horizontalPadding * 2

    color: "transparent"

    transform: Scale {
        id: scale
        origin.x: root.width / 2
        origin.y: root.height / 2
    }

    // ==== 阴影效果 ====
    MultiEffect {
        source: background
        anchors.fill: background
        visible: root.backgroundVisible && root.shadowEnabled
        shadowEnabled: root.shadowEnabled
        shadowColor: root.shadowColor
        shadowBlur: theme.shadowBlur
        shadowHorizontalOffset: theme.shadowXOffset
        shadowVerticalOffset: theme.shadowYOffset
    }

    // ==== 背景 ====
    Rectangle {
        id: background
        anchors.fill: parent
        radius: root.radius
        color: mouseArea.containsMouse ? root.hoverColor : root.buttonColor
        visible: root.backgroundVisible

        Behavior on color { ColorAnimation { duration: 150 } }
        Behavior on opacity { NumberAnimation { duration: 100 } }
    }

    // ==== 内容布局 ====
    RowLayout {
        id: layout
        anchors.centerIn: parent
        spacing: 8

        // 图标 —— 包裹在 Transform 中以便旋转
        Text {
            id: iconLabel
            text: root.iconCharacter
            visible: root.iconCharacter !== ""
            color: root.iconColor
            font.pixelSize: root.iconSize
            font.family: root.iconFontFamily
            verticalAlignment: Text.AlignVCenter
            horizontalAlignment: Text.AlignHCenter
            Layout.preferredWidth: iconLabel.implicitWidth
            Layout.preferredHeight: iconSize

            // 旋转变换
            transform: Rotation {
                id: iconRotation
                origin.x: iconLabel.width / 2
                origin.y: iconLabel.height / 2
                angle: 0
            }

            PropertyAnimation {
                id: rotateAnimation
                target: iconRotation
                property: "angle"
                from: 0
                to: 360
                duration: 200
                easing.type: Easing.InOutQuad
            }

            // 恢复动画（用于释放时）
            SpringAnimation {
                id: restoreRotation
                target: iconRotation
                property: "angle"
                to: 0
                spring: 3
                damping: 0.3
            }
        }

        // 文字
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

    // ==== 交互与动画 ====
    MouseArea {
        id: mouseArea
        anchors.fill: parent
        hoverEnabled: true
        cursorShape: Qt.PointingHandCursor

        onPressed: {
            scale.xScale = root.pressedScale
            scale.yScale = root.pressedScale
            background.opacity = 0.85

            if (root.iconRotateOnClick) {
                rotateAnimation.start()
            }
        }

        onReleased: {
            restoreAnimation.restart()
            background.opacity = 1.0
            root.clicked()

            if (root.iconRotateOnClick) {
                restoreRotation.start()
            }
        }

        onCanceled: {
            restoreAnimation.restart()
            background.opacity = 1.0

            if (root.iconRotateOnClick) {
                restoreRotation.start()
            }
        }
    }

    // 释放时恢复缩放动画
    ParallelAnimation {
        id: restoreAnimation
        SpringAnimation { target: scale; property: "xScale"; to: 1.0; spring: 2.5; damping: 0.25 }
        SpringAnimation { target: scale; property: "yScale"; to: 1.0; spring: 2.5; damping: 0.25 }
    }
}

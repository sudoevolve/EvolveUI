// ESwitchButton.qml
import QtQuick
import QtQuick.Layouts
import QtQuick.Effects

Rectangle {
    id: root

    // === 外部接口 ===
    property string text: "Switch"
    property bool checked: false
    signal toggled(bool checked)

    // === 样式属性 ===
    property bool backgroundVisible: true
    property real radius: 20
    property string size: "m"
    readonly property real contentScale: 0.4
    readonly property real trackWidth: root.height * 1
    readonly property real trackHeight: root.height * contentScale
    readonly property real thumbSize: root.height * contentScale - 2
    property int fontSize: md3.current.fontsize
    property int labelSpacing: md3.current.spacing
    property color containerColor: theme.secondaryColor
    property color hoverColor: Qt.darker(containerColor, 1.2)
    property color textColor: theme.textColor
    property color thumbColor: theme.focusColor
    property bool shadowEnabled: true
    property real pressedScale: 0.96
    property color shadowColor: theme.shadowColor
    readonly property int paddingLeft: md3.current.padding
    readonly property int paddingRight: md3.current.padding

    QtObject {
        id: md3
        property var tokens: ({
            xs: { height: 32, padding: 12, fontsize: 12, spacing: 4 },
            s:  { height: 40, padding: 16, fontsize: 16, spacing: 8 },
            m:  { height: 56, padding: 24, fontsize: 20, spacing: 8 },
            l:  { height: 96, padding: 48, fontsize: 24, spacing: 12 },
            xl: { height: 136, padding: 64, fontsize: 32, spacing: 16 }
        })
        readonly property var current: tokens[root.size] || tokens.m
    }

    // === 尺寸与基础样式 ===
    implicitHeight: md3.current.height
    implicitWidth: layout.implicitWidth + paddingLeft + paddingRight
    color: "transparent"

    // === 缩放动画 ===
    transform: Scale {
        id: scale
        origin.x: root.width / 2
        origin.y: root.height / 2
    }

    ParallelAnimation {
        id: restoreAnimation
        SpringAnimation { target: scale; property: "xScale"; to: 1.0; spring: 2.5; damping: 0.25 }
        SpringAnimation { target: scale; property: "yScale"; to: 1.0; spring: 2.5; damping: 0.25 }
    }

    // === 背景阴影 ===
    MultiEffect {
        source: background
        anchors.fill: background
        shadowEnabled: root.shadowEnabled
        shadowColor: root.shadowColor
        shadowBlur: theme.shadowBlur
        shadowHorizontalOffset: theme.shadowXOffset
        shadowVerticalOffset: theme.shadowYOffset
        visible: root.backgroundVisible && root.shadowEnabled
    }

    // === 背景矩形 ===
    Rectangle {
        id: background
        anchors.fill: parent
        radius: root.radius
        color: mouseArea.containsMouse && root.backgroundVisible
            ? root.hoverColor
            : (root.backgroundVisible ? root.containerColor : "transparent")
        visible: root.backgroundVisible
        Behavior on color { ColorAnimation { duration: 150 } }
        Behavior on opacity { NumberAnimation { duration: 100 } }
    }

    // === 布局：滑块 + 文本 ===
    RowLayout {
        id: layout
        anchors.centerIn: parent
        spacing: labelSpacing

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

            // === 滑块 ===
            Rectangle {
                id: thumb
                width: thumbSize
                height: thumbSize
                radius: thumbSize / 2
                color: root.thumbColor
                anchors.verticalCenter: parent.verticalCenter

                property int edgePadding: 1
                x: checked ? (track.width - width - edgePadding) : edgePadding
                Behavior on x { NumberAnimation { duration: 150; easing.type: Easing.OutQuad } }
            }
        }

        // === 文本 ===
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

    // === 交互处理 ===
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
}

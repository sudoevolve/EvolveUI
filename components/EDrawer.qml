// RightDrawer.qml
import QtQuick
import QtQuick.Layouts
import QtQuick.Effects

Item {
    id: root

    // === 公共接口 ===
    property bool backgroundVisible: true
    property color drawerColor: theme.secondaryColor
    property real radius: 24
    property real columnspacing: 12
    property int padding: 15

    // 阴影属性
    property bool shadowEnabled: true
    property color shadowColor: theme.shadowColor

    // 抽屉状态
    property bool opened: false

    // 默认尺寸
    width: 200
    height: parent ? parent.height : 600

    // === 插槽：用户内容 ===
    default property alias content: contentLayout.data

    // === 对外方法 ===
    function open()   { root.opened = true }
    function close()  { root.opened = false }
    function toggle() { root.opened = !root.opened }

    // === 抽屉 ===
    Item {
        id: drawerContent
        width: root.width
        height: root.height
        y: 0

        // === 阴影 ===
        MultiEffect {
            source: background
            anchors.fill: background
            visible: root.shadowEnabled && root.backgroundVisible
            shadowEnabled: true
            shadowColor: root.shadowColor
            shadowBlur: theme.shadowBlur
            shadowVerticalOffset: theme.shadowYOffset
            shadowHorizontalOffset: theme.shadowXOffset
        }

        // === 背景 ===
        Rectangle {
            id: background
            anchors.fill: parent
            visible: root.backgroundVisible
            radius: root.radius
            color: root.drawerColor
        }

        // === 内容布局 ===
        Column {
            id: contentLayout
            anchors.fill: parent
            spacing: columnspacing
            anchors.margins: root.padding
        }

        // === 动画 ===
        states: [
            State {
                name: "closed"
                when: !root.opened
                PropertyChanges { target: drawerContent; x: parent.width }
            },
            State {
                name: "opened"
                when: root.opened
                PropertyChanges { target: drawerContent; x: parent.width - drawerContent.width }
            }
        ]

        transitions: [
            Transition {
                NumberAnimation { properties: "x"; duration: 500; easing.type: Easing.OutCubic }
            }
        ]
    }
}

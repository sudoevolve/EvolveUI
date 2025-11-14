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
    // 面板宽度（抽屉本体宽度），用于与根宽度（覆盖层）分离
    property int panelWidth: 300

    // 根尺寸：仅为抽屉面板尺寸
    width: root.panelWidth
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
        z: 2
        width: root.panelWidth
        height: root.height
        y: 0
        // 初始位置直接设为关闭态
        x: parent.width

        WheelHandler { onWheel: wheel.accepted = true }

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

        // 抽屉内部拦截层，防止点击穿透
        MouseArea {
            anchors.fill: parent
            enabled: root.opened
            hoverEnabled: true
            acceptedButtons: Qt.AllButtons
            preventStealing: true
        }

        // === 内容布局 ===
        Column {
            id: contentLayout
            z: 1
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
            // 仅在 opened <-> closed 之间切换时执行动画，避免初始从基态到 closed 的动画
            Transition {
                from: "closed"
                to: "opened"
                NumberAnimation { properties: "x"; duration: 500; easing.type: Easing.OutCubic }
            },
            Transition {
                from: "opened"
                to: "closed"
                NumberAnimation { properties: "x"; duration: 500; easing.type: Easing.OutCubic }
            }
        ]
    }

    // 无全屏拦截层；仅抽屉面板内部拦截事件，避免穿透
}

//EAccordion.qml
import QtQuick
import QtQuick.Layouts
import QtQuick.Effects

ColumnLayout {
    id: root
    spacing: 0   // 标题和内容之间不留空隙

    // ==== 外部接口 ====
    property bool backgroundVisible: true        // 是否显示背景
    property string title: "点击展开"             // 标题文字
    property bool expanded: true                 // 是否展开
    default property alias content: contentLayout.data  // 默认内容插槽

    // ==== 样式 ====
    property real radius: 20
    property color headerColor: theme.secondaryColor
    property color headerHoverColor: Qt.darker(headerColor, 1.1)
    property color textColor: theme.textColor
    property color shadowColor: theme.shadowColor
    property bool shadowEnabled: true
    property int headerHeight: 52
    property int contentHeight: 400

    // ==== 1. 标题栏  ====
    Item {
        id: headerContainer
        width: parent.width
        height: root.headerHeight
        Layout.fillWidth: true

        // 阴影效果
        MultiEffect {
            source: header
            anchors.fill: header
            visible: root.shadowEnabled && root.backgroundVisible
            shadowEnabled: true
            shadowColor: root.shadowColor
            shadowBlur: theme.shadowBlur
            shadowVerticalOffset: theme.shadowYOffset
            shadowHorizontalOffset: theme.shadowXOffset
        }

        // 背景矩形
        Rectangle {
            id: header
            visible: root.backgroundVisible
            anchors.fill: parent
            radius: root.radius
            color: mouseArea.containsMouse ? root.headerHoverColor : root.headerColor
            Behavior on color { ColorAnimation { duration: 150 } }
        }

        // 标题栏布局
        RowLayout {
            anchors.fill: parent
            anchors.leftMargin: 16
            anchors.rightMargin: 16
            spacing: 8

            // 标题文字
            Text {
                text: root.title
                color: root.textColor
                font.pixelSize: 16
                font.bold: true
                verticalAlignment: Text.AlignVCenter
                Layout.fillWidth: true
            }

            // 右侧箭头 (展开/折叠状态切换)
            Text {
                text: "\uf054"   // FontAwesome: chevron-right
                font.family: "Font Awesome 6 Free"
                font.pixelSize: 16
                color: theme.focusColor
                rotation: root.expanded ? -90 : 90
                Behavior on rotation {
                    RotationAnimation { duration: 250; easing.type: Easing.InOutQuad }
                }
            }
        }

        // 点击交互
        MouseArea {
            id: mouseArea
            anchors.fill: parent
            hoverEnabled: true
            cursorShape: Qt.PointingHandCursor
            onClicked: root.expanded = !root.expanded
        }
    }

    // ==== 2. 内容区 (可折叠) ====
    Rectangle {
        id: contentWrapper
        radius: root.radius
        Layout.fillWidth: true
        color: root.backgroundVisible ? theme.secondaryColor : "transparent"
        height: root.expanded ? root.contentHeight : 0
        clip: true
        Layout.topMargin: 8

        // 展开/收起过渡动画
        Behavior on height {
            NumberAnimation {
                duration: 250
                easing.type: Easing.OutCubic
            }
        }

        // 自动排列内容组件
        ColumnLayout {
            id: contentLayout
            width: parent.width
        }
    }
}

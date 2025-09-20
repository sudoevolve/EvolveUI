//ECard.qml
import QtQuick
import QtQuick.Layouts
import QtQuick.Effects

Item {
    id: root

    // === 公共接口与样式 ===
    property bool backgroundVisible: true

    property color cardColor: theme.secondaryColor
    property real radius: 20
    property int padding: 15 // 内容区域的内边距

    // 阴影属性
    property bool shadowEnabled: true
    property color shadowColor: theme.shadowColor

    // === 插槽：用户内容插入点 ===
    default property alias content: contentLayout.data

    // 卡片尺寸根据内容自适应
    implicitWidth: contentLayout.implicitWidth + padding * 2
    implicitHeight: contentLayout.implicitHeight + padding * 2

    // === 阴影效果 ===
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

    // === 卡片背景 ===
    Rectangle {
        id: background
        visible: root.backgroundVisible
        anchors.fill: parent
        radius: root.radius
        color: root.cardColor
    }

    // === 内容布局 ===
    // 使用ColumnLayout自动垂直排列内容, 并通过anchors.margins实现内边距
    ColumnLayout {
        id: contentLayout
        anchors.fill: parent
        anchors.margins: root.padding
    }
}

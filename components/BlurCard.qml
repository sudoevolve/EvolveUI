// BlurCard.qml
import QtQuick
import QtQuick.Layouts
import QtQuick.Effects
import Qt5Compat.GraphicalEffects

Item {
    id: root
    width: 100
    height: 100
    clip: true

    // ==== 外部接口 ====
    default property alias content: contentItem.data   // 插槽：用户内容插入点

    // ==== 样式 & 配置 ====
    property Item sourceItem                           // 背景源，用于模糊
    property bool dragable: false                      // 是否可拖动
    property color borderColor: "transparent"          // 边框颜色
    property int borderRadius: 10                      // 圆角
    property int blurRadius: 45                        // 模糊强度

    // ==== 拖动交互 ====
    MouseArea {
        anchors.fill: parent
        enabled: dragable
        drag.target: root
        drag.axis: Drag.XAndYAxis
    }

    // ==== 模糊源 (不可见，仅提供模糊内容) ====
    Item {
        id: blurSourceHolder
        anchors.fill: parent
        visible: false
        clip: true

        FastBlur {
            id: blur
            source: sourceItem
            radius: blurRadius
            width: sourceItem ? sourceItem.width : 0
            height: sourceItem ? sourceItem.height : 0
            x: -root.x
            y: -root.y
        }
    }

    // ==== 遮罩层 (控制模糊区域形状) ====
    Rectangle {
        id: mask
        width: root.width + 2
        height: root.height + 2
        anchors.centerIn: parent
        radius: borderRadius
        color: "red"     // 仅使用 alpha 通道，颜色不影响视觉
        visible: false
    }

    // ==== 模糊效果显示 ====
    OpacityMask {
        anchors.fill: mask
        source: blurSourceHolder
        maskSource: mask
    }

    // ==== 半透明覆盖层 (叠加主题色, 避免过亮/过透明) ====
    Rectangle {
        anchors.fill: parent
        radius: borderRadius
        color: theme.blurOverlayColor
        z: 1
        opacity: 1.0
    }

    // ==== 边框 ====
    Rectangle {
        anchors.fill: parent
        color: "transparent"
        border.color: borderColor
        border.width: borderColor === "transparent" ? 0 : 1
        radius: borderRadius
        z: 2
    }

    // ==== 内容插槽 (放置用户传入的内容) ====
    Item {
        id: contentItem
        anchors.fill: parent
        z: 3   // 始终在模糊层之上
    }
}

import QtQuick 2.15
import QtQuick.Layouts 1.15
import QtQuick.Controls 2.15 // 如果您的项目中使用了 QtQuick.Controls，虽然在这个特定组件中可能不是必需的，但通常会用到
import QtQuick.Effects // 明确指定版本，虽然在导入部分已列出

Rectangle {
    id: root

    property var model: [] // 数组，{ text: string } 格式
    property int selectedIndex: -1 // 当前选中项，-1表示无选中
    signal selectedChanged(int selectedIndex, var selectedData)

    property real radius: 15
    property int fontSize: 16
    property color buttonColor: theme.secondaryColor // 确保 theme 对象可用
    property color hoverColor: Qt.darker(buttonColor, 1.2)
    property color textColor: theme.textColor // 确保 theme 对象可用
    property color checkmarkColor: theme.textColor // 确保 theme 对象可用
    property real pressedScale: 0.96
    property bool shadowEnabled: true
    property color shadowColor: theme.shadowColor // 确保 theme 对象可用

    // 假设 theme 对象提供了这些阴影参数
    // 例如：
    // property real shadowBlur: 20
    // property real shadowXOffset: 0
    // property real shadowYOffset: 5

    implicitWidth: 300
    implicitHeight: model.length * 56 // 根据模型数据项的数量动态计算高度，每项约 56 像素
    color: "transparent"

    // 背景矩形，现在它负责渲染内容并应用层效果
    Rectangle {
        id: background
        anchors.fill: parent
        clip: true // 裁剪内容以遵守圆角
        radius: root.radius
        color: root.buttonColor // 使用根组件的 buttonColor

        // 只有在 shadowEnabled 为 true 时才启用层，以优化性能
        layer.enabled: root.shadowEnabled
        // 将 MultiEffect 作为 layer 的效果应用
        layer.effect: MultiEffect {
            shadowEnabled: root.shadowEnabled // 效果的 shadowEnabled 属性
            shadowColor: root.shadowColor // 效果的 shadowColor 属性
            // 确保 theme 对象有 shadowBlur, shadowXOffset, shadowYOffset 属性
            shadowBlur: theme.shadowBlur
            shadowHorizontalOffset: theme.shadowXOffset
            shadowVerticalOffset: theme.shadowYOffset
        }
    }

    // 按钮列布局，与背景矩形重叠，但不需要自己的阴影
    ColumnLayout {
        id: buttonsColumn
        anchors.fill: parent
        anchors.margins: 10 // 内部边距
        spacing: 6 // 各个按钮之间的间距

        Repeater {
            model: root.model // 使用根组件的 model

            Rectangle {
                id: btn
                width: parent.width // 填充父级宽度
                height: 48 // 固定高度
                radius: root.radius * 0.5 // 按钮圆角为根组件圆角的一半

                property bool hovered: false // 鼠标是否悬停
                property bool checked: root.selectedIndex === index // 当前按钮是否被选中

                // 颜色和边框根据状态变化
                color: hovered ? root.hoverColor : root.buttonColor
                border.color: checked ? root.checkmarkColor : "transparent"
                border.width: 2
                opacity: mouseArea.pressed ? 0.85 : 1.0 // 按下时半透明效果

                // 动画效果
                Behavior on color { ColorAnimation { duration: 150 } }
                Behavior on border.color { ColorAnimation { duration: 150 } }
                Behavior on opacity { NumberAnimation { duration: 100 } }

                // 按下时的缩放效果
                transform: Scale {
                    id: scale
                    origin.x: btn.width / 2
                    origin.y: btn.height / 2
                }

                // 释放鼠标或取消时的恢复动画
                ParallelAnimation {
                    id: restoreAnimation
                    SpringAnimation { target: scale; property: "xScale"; to: 1.0; spring: 2.5; damping: 0.25 }
                    SpringAnimation { target: scale; property: "yScale"; to: 1.0; spring: 2.5; damping: 0.25 }
                }

                RowLayout {
                    anchors.fill: parent
                    anchors.leftMargin: 15
                    anchors.rightMargin: 15
                    spacing: 12
                    Layout.alignment: Qt.AlignVCenter // 垂直居中对齐

                    // 复选框样式
                    Rectangle {
                        id: box
                        width: 24
                        height: 24
                        radius: 6
                        border.color: root.checkmarkColor
                        border.width: 2
                        color: checked ? root.checkmarkColor : "transparent" // 选中时填充颜色
                        Behavior on color { ColorAnimation { duration: 150 } }

                        Text {
                            anchors.centerIn: parent
                            visible: checked // 仅在选中时显示勾号
                            text: "\u2713" // 勾号 Unicode 字符
                            font.pixelSize: 16
                            color: root.buttonColor // 勾号颜色与按钮背景色相同
                        }
                    }

                    // 文本内容
                    Text {
                        text: modelData.text // 显示模型数据中的文本
                        color: root.textColor
                        font.pixelSize: root.fontSize
                        font.bold: checked // 选中时加粗
                        elide: Text.ElideRight // 文本过长时显示省略号
                        Layout.fillWidth: true // 填充剩余宽度
                        Layout.alignment: Qt.AlignVCenter
                    }
                }

                MouseArea {
                    id: mouseArea
                    anchors.fill: parent
                    hoverEnabled: true // 启用悬停事件
                    cursorShape: Qt.PointingHandCursor // 鼠标悬停时显示手型光标

                    onEntered: btn.hovered = true // 鼠标进入时设置悬停状态
                    onExited: btn.hovered = false // 鼠标离开时取消悬停状态

                    onPressed: {
                        scale.xScale = root.pressedScale // 按下时缩放
                        scale.yScale = root.pressedScale
                        btn.opacity = 0.85 // 按下时降低不透明度
                    }

                    onReleased: {
                        restoreAnimation.restart() // 释放时恢复动画
                        btn.opacity = 1.0 // 恢复不透明度

                        if (root.selectedIndex !== index) {
                            root.selectedIndex = index // 更新选中项
                            root.selectedChanged(index, modelData) // 发出选中改变信号
                        }
                    }

                    onCanceled: { // 鼠标操作取消时（例如拖拽出区域）
                        restoreAnimation.restart()
                        btn.opacity = 1.0
                    }
                }
            }
        }
    }
}

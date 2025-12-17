// ECheckBox.qml
import QtQuick
import QtQuick.Layouts
import QtQuick.Controls
import QtQuick.Effects

Rectangle {
    id: root

    // ==== 外部属性和信号 ====
    property var model: []                      // 复选框选项数据
    property var selectedIndices: []            // 选中项索引数组
    signal selectionChanged(var selectedIndices, var selectedData)  // 选中变化信号

    // ==== 样式控制属性 ====
    property bool backgroundVisible: true       // 背景是否显示
    property real radius: 20                    // 圆角半径
    property int fontSize: 16                   // 文本字体大小
    property color containerColor: theme.secondaryColor // 容器颜色
    property color hoverColor: Qt.darker(containerColor, 1.2) // 悬浮颜色
    property color textColor: theme.textColor  // 文本颜色
    property color checkmarkColor: theme.focusColor // 勾选颜色
    property real pressedScale: 0.96           // 按下时缩放比例
    property bool shadowEnabled: true          // 是否启用阴影
    property color shadowColor: theme.shadowColor // 阴影颜色

    // ==== 布局相关尺寸 ====
    property int horizontalPadding: 24
    property int boxSize: 24
    property int labelSpacing: 8
    property int buttonsSpacing: 6
    property int buttonHeight: 40

    // ==== 隐藏文本控件，用于测量文字宽度 ====
    Text {
        id: measureText
        visible: false
        font.pixelSize: root.fontSize
        font.bold: false
    }

    // ==== 函数：更新最大文本宽度 ====
    property real maxTextWidth: 0
    function updateMaxTextWidth() {
        var maxWidth = 0;
        for (var i = 0; i < model.length; i++) {
            measureText.text = model[i].text;
            var w = measureText.width;
            if (w > maxWidth)
                maxWidth = w;
        }
        maxTextWidth = maxWidth;
    }

    Component.onCompleted: updateMaxTextWidth()
    onModelChanged: updateMaxTextWidth()

    // ==== 尺寸计算 ====
    implicitWidth: horizontalPadding * 2 + boxSize + labelSpacing + maxTextWidth + 30
    implicitHeight: model.length > 0
        ? model.length * (buttonHeight + buttonsSpacing) - buttonsSpacing + 20
        : buttonHeight + 20

    width: implicitWidth
    height: implicitHeight
    color: "transparent" // 背景透明

    // ==== 背景矩形，圆角+阴影 ====
    Rectangle {
        id: background
        anchors.fill: parent
        clip: true
        radius: root.radius
        color: root.containerColor
        visible: root.backgroundVisible

        layer.enabled: root.shadowEnabled && root.backgroundVisible
        layer.effect: MultiEffect {
            shadowEnabled: root.shadowEnabled
            shadowColor: root.shadowColor
            shadowBlur: theme.shadowBlur
            shadowHorizontalOffset: theme.shadowXOffset
            shadowVerticalOffset: theme.shadowYOffset
        }
    }

    // ==== 主布局：垂直排列所有复选框按钮 ====
    ColumnLayout {
        id: buttonsColumn
        anchors.top: parent.top
        anchors.topMargin: 10
        anchors.horizontalCenter: parent.horizontalCenter
        spacing: buttonsSpacing
        width: implicitWidth
    }

    // ==== 生成按钮列表 ====
    Repeater {
        model: root.model
        parent: buttonsColumn

        Rectangle {
            id: btn
            implicitWidth: horizontalPadding * 2 + boxSize + labelSpacing + label.implicitWidth + 10
            height: buttonHeight
            radius: root.radius * 0.5

            property bool hovered: false
            property bool checked: root.selectedIndices.indexOf(index) > -1

            // 背景颜色，悬浮变色
            color: root.backgroundVisible
                ? (hovered ? root.hoverColor : root.containerColor)
                : "transparent"

            opacity: mouseArea.pressed ? 0.85 : 1.0

            // 颜色和透明度动画
            Behavior on color { ColorAnimation { duration: 150 } }
            Behavior on border.color { ColorAnimation { duration: 150 } }
            Behavior on opacity { NumberAnimation { duration: 100 } }

            // 缩放动画效果，居中缩放
            transform: Scale {
                id: scale
                origin.x: btn.width / 2
                origin.y: btn.height / 2
            }

            // 弹簧动画，松开恢复缩放
            ParallelAnimation {
                id: restoreAnimation
                SpringAnimation { target: scale; property: "xScale"; to: 1.0; spring: 2.5; damping: 0.25 }
                SpringAnimation { target: scale; property: "yScale"; to: 1.0; spring: 2.5; damping: 0.25 }
            }

            // ==== 按钮内部布局：复选框 + 文本 ====
            RowLayout {
                anchors.fill: parent
                anchors.leftMargin: horizontalPadding
                anchors.rightMargin: horizontalPadding
                spacing: labelSpacing
                Layout.alignment: Qt.AlignVCenter

                // ==== 复选框方块 ====
                Rectangle {
                    id: box
                    width: boxSize
                    height: boxSize
                    radius: boxSize * 0.25
                    border.color: root.checkmarkColor
                    border.width: 2
                    color: checked ? root.checkmarkColor : "transparent"
                    Behavior on color { ColorAnimation { duration: 150 } }

                Text {
                    anchors.centerIn: parent
                    visible: checked
                    text: "\u2713" // 勾号
                    font.pixelSize: 16
                    color: root.textColor
                }
            }

                // ==== 文本标签 ====
                Text {
                    id: label
                    text: modelData.text
                    color: root.textColor
                    font.pixelSize: root.fontSize
                    font.bold: checked
                    elide: Text.ElideRight
                    Layout.preferredWidth: label.implicitWidth
                    Layout.alignment: Qt.AlignVCenter
                }
            }

            // ==== 鼠标交互 ====
            MouseArea {
                id: mouseArea
                anchors.fill: parent
                hoverEnabled: true
                cursorShape: Qt.PointingHandCursor

                onEntered: btn.hovered = true
                onExited: btn.hovered = false

                onPressed: {
                    scale.xScale = root.pressedScale
                    scale.yScale = root.pressedScale
                    btn.opacity = 0.85
                }

                onReleased: {
                    restoreAnimation.restart()
                    btn.opacity = 1.0

                    // 切换选中状态
                    var newSelection = root.selectedIndices.slice();
                    var itemIndex = newSelection.indexOf(index);
                    if (itemIndex > -1) {
                        newSelection.splice(itemIndex, 1);
                    } else {
                        newSelection.push(index);
                    }
                    root.selectedIndices = newSelection;

                    // 收集选中项数据，发信号通知外部
                    var selectedDataItems = [];
                    for(var i = 0; i < root.selectedIndices.length; i++) {
                        selectedDataItems.push(root.model[root.selectedIndices[i]]);
                    }

                    root.selectionChanged(root.selectedIndices, selectedDataItems);
                }

                onCanceled: {
                    restoreAnimation.restart()
                    btn.opacity = 1.0
                }
            }
        }
    }
}

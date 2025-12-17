// ERadioButton.qml
import QtQuick
import QtQuick.Layouts
import QtQuick.Controls
import QtQuick.Effects

Rectangle {
    id: root

    // === 接口属性 ===
    property var model: []                     // [{ text: string }]
    property var selectedIndices: []           // 单选时数组最多一个元素
    signal selectionChanged(var selectedIndices, var selectedData)

    // === 样式属性 ===
    property bool backgroundVisible: true
    property real radius: 20
    property int fontSize: 16
    property color containerColor: theme.secondaryColor
    property color hoverColor: Qt.darker(containerColor, 1.2)
    property color textColor: theme.textColor
    property color checkmarkColor: theme.focusColor
    property real pressedScale: 0.96
    property bool shadowEnabled: true
    property color shadowColor: theme.shadowColor

    // 布局尺寸
    property int horizontalPadding: 24
    property int boxSize: 24
    property int labelSpacing: 12
    property int buttonsSpacing: 6
    property int buttonHeight: 40

    // === 隐藏文本用于测量最大宽度 ===
    Text {
        id: measureText
        visible: false
        font.pixelSize: root.fontSize
    }

    property real maxTextWidth: 0
    function updateMaxTextWidth() {
        var maxWidth = 0
        for (var i = 0; i < model.length; i++) {
            measureText.text = model[i].text
            if (measureText.width > maxWidth)
                maxWidth = measureText.width
        }
        maxTextWidth = maxWidth
    }
    Component.onCompleted: updateMaxTextWidth()
    onModelChanged: updateMaxTextWidth()

    // === 尺寸计算 ===
    implicitWidth: horizontalPadding * 2 + boxSize + labelSpacing + maxTextWidth + 30
    implicitHeight: model.length > 0
        ? model.length * (buttonHeight + buttonsSpacing) - buttonsSpacing + 20
        : buttonHeight + 20

    width: implicitWidth
    height: implicitHeight
    color: "transparent"

    // === 背景 ===
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

    // === 按钮列 ===
    ColumnLayout {
        id: buttonsColumn
        anchors.top: parent.top
        anchors.topMargin: 10
        anchors.horizontalCenter: parent.horizontalCenter
        spacing: buttonsSpacing
        width: implicitWidth
    }

    // === 按钮 Repeater ===
    Repeater {
        model: root.model
        parent: buttonsColumn

        delegate: Rectangle {
            id: btn
            implicitWidth: horizontalPadding * 2 + boxSize + labelSpacing + label.implicitWidth + 10
            height: buttonHeight
            radius: root.radius * 0.5

            // === 状态属性 ===
            property bool hovered: false
            property bool checked: root.selectedIndices.indexOf(index) !== -1

            // 背景显隐控制颜色
            color: root.backgroundVisible
                ? (hovered ? root.hoverColor : root.containerColor)
                : "transparent"
            opacity: mouseArea.pressed ? 0.85 : 1.0

            Behavior on color { ColorAnimation { duration: 150 } }
            Behavior on opacity { NumberAnimation { duration: 100 } }

            // === 缩放动画 ===
            transform: Scale {
                id: scale
                origin.x: btn.width / 2
                origin.y: btn.height / 2
            }
            ParallelAnimation {
                id: restoreAnimation
                SpringAnimation { target: scale; property: "xScale"; to: 1.0; spring: 2.5; damping: 0.25 }
                SpringAnimation { target: scale; property: "yScale"; to: 1.0; spring: 2.5; damping: 0.25 }
            }

            // === 按钮内容布局 ===
            RowLayout {
                anchors.fill: parent
                anchors.leftMargin: horizontalPadding
                anchors.rightMargin: horizontalPadding
                spacing: labelSpacing
                Layout.alignment: Qt.AlignVCenter

                // === 复选框圆圈 ===
                Rectangle {
                    id: box
                    width: boxSize
                    height: boxSize
                    radius: boxSize / 2
                    border.color: root.checkmarkColor
                    border.width: 2
                    color: "transparent"
                    Behavior on color { ColorAnimation { duration: 150 } }

                    Rectangle {
                        anchors.centerIn: parent
                        width: boxSize * 0.5
                        height: boxSize * 0.5
                        radius: width / 2
                        color: checked ? root.checkmarkColor : "transparent"
                        Behavior on color { ColorAnimation { duration: 150 } }
                    }
                }

                // === 标签文本 ===
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

            // === 交互逻辑 ===
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

                    // 单选逻辑
                    var newSelection = []
                    if (root.selectedIndices.length === 0 || root.selectedIndices[0] !== index) {
                        newSelection.push(index)
                    }
                    root.selectedIndices = newSelection

                    // 获取选中数据
                    var selectedDataItems = []
                    for (var i = 0; i < root.selectedIndices.length; i++) {
                        selectedDataItems.push(root.model[root.selectedIndices[i]])
                    }

                    root.selectionChanged(root.selectedIndices, selectedDataItems)
                }

                onCanceled: {
                    restoreAnimation.restart()
                    btn.opacity = 1.0
                }
            }
        }
    }
}

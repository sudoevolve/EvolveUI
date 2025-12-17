// ESlider.qml
import QtQuick
import QtQuick.Controls
import QtQuick.Controls.Basic as Basic
import QtQuick.Layouts
import QtQuick.Effects

Rectangle {
    id: root

    // === 接口属性 ===
    property alias text: label.text
    property real value: 50.0
    property real minimumValue: 0.0
    property real maximumValue: 100.0
    property bool showValueLabel: true
    property bool showSpinBox: false

    property bool showValueText: true
    property string valueSuffix: ""
    property int decimals: 0
    property int labelWidth: 60
    property int valueWidth: 60
    property int stepSize: 1
    property bool valueEditable: true
    property real _scale: Math.pow(10, decimals)
    signal userValueChanged(real value)

    // === 样式属性 ===
    property bool backgroundVisible: true
    property int fontSize: 16
    property real radius: 10
    property color trackColor: theme.secondaryColor
    property color fillColor: theme.focusColor
    property color handleColor: theme.textColor
    property color borderColor: theme.getBorderColor(focused)
    
    // === 间距属性 ===
    property int itemSpacing:  - 12
    property int containerMargins: 10

    // === 状态属性 ===
    property bool focused: false
    property bool isPressed: false
    property bool hovered: false
    property bool _syncing: false
    property bool _ready: false

    color: "transparent"
    implicitWidth: 320
    implicitHeight: 40

    // === 功能方法 ===
    function _updateHandlePosition() {
        const range = maximumValue - minimumValue;
        const percent = range > 0 ? (value - minimumValue) / range : 0;
        const clampedPercent = Math.max(0, Math.min(1, percent));
        // 当显示数值时，限制滑块的最大位置，留出10像素间距
        const maxWidth = (valueLabel.visible || valueText.visible) ? track.width - handle.width - 10 : track.width - handle.width;
        handle.x = clampedPercent * Math.max(0, maxWidth);
        // 保持 fill.width 的绑定，不在此处赋值以免打断绑定
    }

    function _updateValueFromHandle() {
        // 当显示数值时，限制滑块的最大位置，留出10像素间距
        const maxWidth = (valueLabel.visible || valueText.visible) ? track.width - handle.width - 10 : track.width - handle.width;
        const denom = Math.max(0, maxWidth);
        const percent = denom > 0 ? handle.x / denom : 0;
        const clampedPercent = Math.max(0, Math.min(1, percent));
        const newValue = minimumValue + clampedPercent * (maximumValue - minimumValue);
        value = Math.max(minimumValue, Math.min(maximumValue, newValue));
    }

    onMinimumValueChanged: {
        value = Math.max(minimumValue, Math.min(maximumValue, value));
        _updateHandlePosition();
    }

    onMaximumValueChanged: {
        value = Math.max(minimumValue, Math.min(maximumValue, value));
        _updateHandlePosition();
    }

    onValueChanged: _updateHandlePosition()
    Component.onCompleted: {
        // 先把 SpinBox 的值同步为外部设定的 value，再标记就绪，避免初始化过程中覆盖 value
        valueLabel.value = Math.round(root.value * root._scale)
        _ready = true
        _updateHandlePosition()
    }

    // === 背景阴影 ===
    MultiEffect {
        source: background
        anchors.fill: background
        visible: true
        shadowEnabled: true
        shadowColor: theme.shadowColor
        shadowBlur: theme.shadowBlur
        shadowHorizontalOffset: theme.shadowXOffset
        shadowVerticalOffset: theme.shadowYOffset
    }

    // === 背景轨道 ===
    Rectangle {
        id: background
        anchors.fill: parent
        radius: root.radius
        color: root.backgroundVisible ? trackColor : "transparent"
        // 无背景时：选中用主题高亮色，未选中用次级色
        border.color: root.backgroundVisible ? borderColor : (focused ? theme.focusColor : theme.textColor)
        border.width: focused ? 2 : 1
        Behavior on border.width { NumberAnimation { duration: 160; easing.type: Easing.OutCubic } }
        Behavior on border.color { ColorAnimation { duration: 150 } }
    }

    // === 布局：文本 + 滑动条 + 值显示 ===
    Row {
        id: layoutRow
        anchors.fill: parent
        anchors.margins: root.containerMargins
        spacing: root.itemSpacing

        // 文本标签
        Text {
            id: label
            text: root.text
            color: theme.textColor
            font.pixelSize: fontSize
            verticalAlignment: Text.AlignVCenter
            anchors.verticalCenter: parent.verticalCenter
            width: Math.max(root.labelWidth, label.implicitWidth)
            elide: Text.ElideRight
        }

        // 滑动轨道容器
        Item {
            id: track
            width: Math.max(60, layoutRow.width - label.width - ((valueLabel.visible || valueText.visible) ? (valueLabel.visible ? valueLabel.width : valueText.width) : 0) - layoutRow.spacing * ((valueLabel.visible || valueText.visible) ? 2 : 1))
            height: 8
            anchors.verticalCenter: parent.verticalCenter

            onWidthChanged: _updateHandlePosition()

            // 已填充部分
            Rectangle {
                id: fill
                anchors.left: parent.left
                anchors.top: parent.top
                anchors.bottom: parent.bottom
                width: handle.x + handle.width / 2
                radius: height / 2
                color: fillColor
                antialiasing: true
                smooth: true
                Behavior on width {
                    enabled: root.isPressed
                    NumberAnimation { duration: 120; easing.type: Easing.OutCubic }
                }
            }

            // 滑块
            Rectangle {
                id: handle
                width: 24
                height: 24
                radius: width / 2
                color: root.handleColor
                border.color: Qt.lighter(handleColor, 1.2)
                border.width: 1
                anchors.verticalCenter: parent.verticalCenter
                x: 0

                // 阴影效果
                layer.enabled: true
                layer.effect: MultiEffect {
                    shadowEnabled: true
                    shadowColor: theme.shadowColor
                    shadowBlur: 8
                    shadowVerticalOffset: 2
                }

                // 缩放动画
                transform: Scale {
                    id: handleScale
                    origin.x: handle.width / 2
                    origin.y: handle.height / 2
                    Behavior on xScale { SpringAnimation { spring: 2.5; damping: 0.25 } }
                    Behavior on yScale { SpringAnimation { spring: 2.5; damping: 0.25 } }
                }

                Behavior on x { enabled: root.isPressed; SmoothedAnimation { duration: 100 } }

                // === 交互 ===
                MouseArea {
                    anchors.fill: parent
                    drag.target: parent
                    drag.axis: Drag.XAxis
                    drag.minimumX: 0
                    drag.maximumX: {
                        // 当显示数值时，限制拖拽的最大位置，留出10像素间距
                        return (valueLabel.visible || valueText.visible) ? 
                               Math.max(0, track.width - handle.width - 10) : 
                               track.width - handle.width
                    }

                    hoverEnabled: true
                    cursorShape: Qt.PointingHandCursor

                    onPressed: {
                        root.isPressed = true;
                        handleScale.xScale = 0.9;
                        handleScale.yScale = 0.9;
                        root.focused = true;
                    }

                    onReleased: {
                        root.isPressed = false;
                        handleScale.xScale = 1.0;
                        handleScale.yScale = 1.0;
                        root.focused = false;
                    }

                    onPositionChanged: {
                        if (root.isPressed) {
                            _updateValueFromHandle();
                            userValueChanged(value);
                        }
                    }

                    onEntered: hovered = true
                    onExited: hovered = false
                }
            }
        }

        // 当前数值显示
        Basic.SpinBox {
            id: valueLabel
            anchors.verticalCenter: parent.verticalCenter
            visible: root.showValueLabel && root.showSpinBox
            editable: root.valueEditable
            from: Math.round(root.minimumValue * root._scale)
            to: Math.round(root.maximumValue * root._scale)
            stepSize: Math.max(1, Math.round(root.stepSize * root._scale))
            width: implicitWidth  // 使用实际内容宽度而不是固定宽度
            validator: DoubleValidator { bottom: root.minimumValue; top: root.maximumValue; decimals: root.decimals }
            Connections {
                target: root
                function onValueChanged() {
                    if (!root._syncing) {
                        root._syncing = true;
                        valueLabel.value = Math.round(root.value * root._scale);
                        root._syncing = false;
                    }
                }
            }

            // 自定义显示文本与解析（保留单位/小数）
            textFromValue: function(v) {
                var realVal = v / root._scale;
                var txt = (root.decimals === 0 ? Math.round(realVal).toString() : realVal.toFixed(root.decimals));
                return txt + root.valueSuffix;
            }
            valueFromText: function(t) {
                var cleaned = t.replace(root.valueSuffix, "").trim();
                var num = parseFloat(cleaned);
                // 空/无效输入回退到最小值；0 是有效值
                if (isNaN(num)) return from;
                var scaled = Math.round(num * root._scale);
                return Math.max(from, Math.min(to, scaled));
            }

            // 胶囊式显示：内容区与上下箭头分离（可编辑）
            contentItem: Item {
                implicitHeight: Math.max(textItem.implicitHeight + 8, 32)
                // 额外为右侧箭头预留 28px
                implicitWidth: Math.max(textItem.implicitWidth + 16 + 10, 40)
                Rectangle {
                    anchors.fill: parent
                    radius: 10
                    color: root.backgroundVisible ? theme.secondaryColor : "transparent"
                    border.color: root.backgroundVisible ? theme.getBorderColor(root.focused) : "transparent"
                    border.width: root.focused ? 2 : 1
                }
                TextInput {
                    id: textItem
                    anchors.fill: parent
                    anchors.rightMargin: 0
                    anchors.leftMargin: 0
                    verticalAlignment: Text.AlignVCenter
                    horizontalAlignment: Text.AlignHCenter
                    color: theme.textColor
                    font.pixelSize: root.fontSize
                    selectByMouse: true
                    clip: true
                    readOnly: !root.valueEditable
                    inputMethodHints: Qt.ImhPreferNumbers | Qt.ImhNoPredictiveText
                    validator: DoubleValidator { bottom: root.minimumValue; top: root.maximumValue; decimals: root.decimals }
                    // 非编辑状态下从值刷新文本；编辑时不打断用户输入
                    Binding { target: textItem; property: "text"; value: valueLabel.textFromValue(valueLabel.value); when: !textItem.activeFocus }
                    onEditingFinished: valueLabel.value = valueLabel.valueFromText(text)
                    // 文本编辑获得/失去焦点时，同步组件焦点以驱动主题高亮
                    onActiveFocusChanged: root.focused = activeFocus
                    Keys.onReturnPressed: valueLabel.value = valueLabel.valueFromText(text)
                    Keys.onEnterPressed: valueLabel.value = valueLabel.valueFromText(text)
                    Keys.onUpPressed: {
                        valueLabel.increase()
                        textItem.text = valueLabel.textFromValue(valueLabel.value)
                        // 加减也触发高亮反馈
                        root.focused = true
                        focusFlashReset.restart()
                    }
                    Keys.onDownPressed: {
                        valueLabel.decrease()
                        textItem.text = valueLabel.textFromValue(valueLabel.value)
                        // 加减也触发高亮反馈
                        root.focused = true
                        focusFlashReset.restart()
                    }
                }
            }

            // 去掉 SpinBox 默认的背景，避免覆盖内容区胶囊
            background: null

            // 右侧上下箭头胶囊
            up.indicator: Rectangle {
                id: upIndicatorRect
                width: 24
                height: 16
                radius: 6
                // 颜色状态
                property color normalFillColor: root.backgroundVisible ? Qt.rgba(0.9, 0.9, 0.9, 0.12) : "transparent"
                property color hoverFillColor: root.backgroundVisible ? Qt.rgba(0.9, 0.9, 0.9, 0.20) : "transparent"
                property color pressedFillColor: Qt.tint(theme.focusColor, "#22ffffff")
                property color currentFillColor: normalFillColor
                property color normalBorderColor: root.backgroundVisible ? theme.getBorderColor(false) : "transparent"
                property color hoverBorderColor: root.backgroundVisible ? theme.getBorderColor(true) : "transparent"
                property color pressedBorderColor: theme.focusColor
                property color currentBorderColor: normalBorderColor
                color: currentFillColor
                border.color: currentBorderColor
                Behavior on color { ColorAnimation { duration: 120 } }
                Behavior on border.color { ColorAnimation { duration: 120 } }
                anchors.right: parent.right
                anchors.top: parent.top
                anchors.rightMargin: 0
                // 轻微位移与回弹缩放
                property real pressOffset: 0
                Behavior on pressOffset { NumberAnimation { duration: 140; easing.type: Easing.OutCubic } }
                transform: [
                    Scale {
                        id: upIndicatorScale
                        origin.x: width / 2
                        origin.y: height / 2
                        Behavior on xScale { SpringAnimation { spring: 2.2; damping: 0.28 } }
                        Behavior on yScale { SpringAnimation { spring: 2.2; damping: 0.28 } }
                    },
                    Translate { y: upIndicatorRect.pressOffset }
                ]
                Text {
                    anchors.centerIn: parent
                    text: "\uf077" // chevron-up
                    font.family: "Font Awesome 6 Free"
                    font.pixelSize: 12
                    color: theme.textColor
                }
                MouseArea {
                    anchors.fill: parent
                    hoverEnabled: true
                    onPressed: {
                        upIndicatorScale.xScale = 1.0
                        upIndicatorScale.yScale = 0.94
                        parent.pressOffset = -2
                        parent.currentFillColor = parent.pressedFillColor
                        parent.currentBorderColor = parent.pressedBorderColor
                    }
                    onReleased: {
                        upIndicatorScale.xScale = 1.0
                        upIndicatorScale.yScale = 1.0
                        parent.pressOffset = 0
                        if (containsMouse) {
                            parent.currentFillColor = parent.hoverFillColor
                            parent.currentBorderColor = parent.hoverBorderColor
                        } else {
                            parent.currentFillColor = parent.normalFillColor
                            parent.currentBorderColor = parent.normalBorderColor
                        }
                    }
                    onEntered: {
                        parent.currentFillColor = parent.hoverFillColor
                        parent.currentBorderColor = parent.hoverBorderColor
                    }
                    onExited: {
                        parent.currentFillColor = parent.normalFillColor
                        parent.currentBorderColor = parent.normalBorderColor
                    }
                    onClicked: {
                        textItem.focus = false
                        valueLabel.increase()
                        // 加按钮触发高亮反馈
                        root.focused = true
                        focusFlashReset.restart()
                    }
                }
            }
            down.indicator: Rectangle {
                id: downIndicatorRect
                width: 24
                height: 16
                radius: 6
                // 颜色状态
                property color normalFillColor: root.backgroundVisible ? Qt.rgba(0.9, 0.9, 0.9, 0.12) : "transparent"
                property color hoverFillColor: root.backgroundVisible ? Qt.rgba(0.9, 0.9, 0.9, 0.20) : "transparent"
                property color pressedFillColor: Qt.tint(theme.focusColor, "#22ffffff")
                property color currentFillColor: normalFillColor
                property color normalBorderColor: root.backgroundVisible ? theme.getBorderColor(false) : "transparent"
                property color hoverBorderColor: root.backgroundVisible ? theme.getBorderColor(true) : "transparent"
                property color pressedBorderColor: theme.focusColor
                property color currentBorderColor: normalBorderColor
                color: currentFillColor
                border.color: currentBorderColor
                Behavior on color { ColorAnimation { duration: 120 } }
                Behavior on border.color { ColorAnimation { duration: 120 } }
                anchors.right: parent.right
                anchors.bottom: parent.bottom
                anchors.rightMargin: 0
                // 轻微位移与回弹缩放
                property real pressOffset: 0
                Behavior on pressOffset { NumberAnimation { duration: 140; easing.type: Easing.OutCubic } }
                transform: [
                    Scale {
                        id: downIndicatorScale
                        origin.x: width / 2
                        origin.y: height / 2
                        Behavior on xScale { SpringAnimation { spring: 2.2; damping: 0.28 } }
                        Behavior on yScale { SpringAnimation { spring: 2.2; damping: 0.28 } }
                    },
                    Translate { y: downIndicatorRect.pressOffset }
                ]
                Text {
                    anchors.centerIn: parent
                    text: "\uf078" // chevron-down
                    font.family: "Font Awesome 6 Free"
                    font.pixelSize: 12
                    color: theme.textColor
                }
                MouseArea {
                    anchors.fill: parent
                    hoverEnabled: true
                    onPressed: {
                        downIndicatorScale.xScale = 1.0
                        downIndicatorScale.yScale = 0.94
                        parent.pressOffset = 2
                        parent.currentFillColor = parent.pressedFillColor
                        parent.currentBorderColor = parent.pressedBorderColor
                    }
                    onReleased: {
                        downIndicatorScale.xScale = 1.0
                        downIndicatorScale.yScale = 1.0
                        parent.pressOffset = 0
                        if (containsMouse) {
                            parent.currentFillColor = parent.hoverFillColor
                            parent.currentBorderColor = parent.hoverBorderColor
                        } else {
                            parent.currentFillColor = parent.normalFillColor
                            parent.currentBorderColor = parent.normalBorderColor
                        }
                    }
                    onEntered: {
                        parent.currentFillColor = parent.hoverFillColor
                        parent.currentBorderColor = parent.hoverBorderColor
                    }
                    onExited: {
                        parent.currentFillColor = parent.normalFillColor
                        parent.currentBorderColor = parent.normalBorderColor
                    }
                    onClicked: {
                        textItem.focus = false
                        valueLabel.decrease()
                        // 减按钮触发高亮反馈
                        root.focused = true
                        focusFlashReset.restart()
                    }
                }
            }

            // 数值同步到外部 value
            onValueChanged: {
                if (!root._ready) return; // 初始化阶段不回推到 root.value，避免默认值覆盖外部初始值
                var newReal = value / root._scale;
                if (!root._syncing && newReal !== root.value) {
                    root._syncing = true;
                    root.value = newReal;
                    root._syncing = false;
                    userValueChanged(root.value);
                }
                // 非拖动场景下，给一次短暂的高亮反馈
                if (!root.isPressed && !valueLabel.activeFocus) {
                    root.focused = true
                    focusFlashReset.restart()
                }
            }
        }

        // 纯文本数值显示（当不显示SpinBox时）
        Text {
            id: valueText
            anchors.verticalCenter: parent.verticalCenter
            visible: root.showValueLabel && root.showValueText && !root.showSpinBox
            color: theme.textColor
            font.pixelSize: root.fontSize
            width: implicitWidth  // 使用实际内容宽度而不是固定宽度
            horizontalAlignment: Text.AlignHCenter
            text: {
                var realVal = root.value;
                var txt = (root.decimals === 0 ? Math.round(realVal).toString() : realVal.toFixed(root.decimals));
                return txt + root.valueSuffix;
            }
        }
    }

    // 非拖动情况下的短暂高亮复位（确保“直接输入/加减按钮”也有统一的变色反馈）
    Timer {
        id: focusFlashReset
        interval: 300
        repeat: false
        onTriggered: {
            if (!root.isPressed && !valueLabel.activeFocus) {
                root.focused = false
            }
        }
    }
}

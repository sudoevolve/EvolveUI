// EList.qml
import QtQuick
import QtQuick.Layouts
import QtQuick.Controls
import QtQuick.Effects

Item {
    id: root
    clip: false

    width: 200
    height: 200

    // === 接口属性 & 信号 ===
    property var model                    // 列表数据模型
    signal itemClicked(int index, var data)  // 点击回调

    // === 样式属性 ===
    property bool backgroundVisible: true
    property real radius: 20
    property int buttonHeight: 40
    property int itemHeight: buttonHeight
    property int itemFontSize: 16
    property int itemIconSize: 20
    property int horizontalPadding: 24
    property int labelSpacing: 8
    property int buttonsSpacing: 6
    property int listPadding: horizontalPadding
    property real pressedScale: 0.96
    property bool textShown: true
    property color containerColor: theme.secondaryColor
    property color hoverColor: Qt.darker(containerColor, 1.2)
    property color textColor: theme.textColor
    property bool shadowEnabled: true
    property color shadowColor: theme.shadowColor

    // === 背景===
    Rectangle {
        id: background
        anchors.fill: parent
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

    // === 列表内容===
    ListView {
        id: listView
        anchors.fill: parent
        anchors.margins: root.horizontalPadding / 2
        spacing: root.buttonsSpacing
        model: root.model
        clip: true

        delegate: Rectangle {
            id: itemContainer
            width: listView.width
            height: root.itemHeight
            radius: root.radius * 0.5

            // === 状态属性 ===
            property bool hovered: false

            color: root.backgroundVisible
                ? (hovered ? root.hoverColor : root.containerColor)
                : "transparent"

            opacity: mouseArea.pressed ? 0.85 : 1.0

            // === 颜色与透明度动画 ===
            Behavior on color { ColorAnimation { duration: 150 } }
            Behavior on opacity { NumberAnimation { duration: 100 } }

            // === 缩放动画 ===
            transform: Scale {
                id: scale
                origin.x: itemContainer.width / 2
                origin.y: itemContainer.height / 2
            }

            ParallelAnimation {
                id: restoreAnimation
                SpringAnimation { target: scale; property: "xScale"; to: 1.0; spring: 2.5; damping: 0.25 }
                SpringAnimation { target: scale; property: "yScale"; to: 1.0; spring: 2.5; damping: 0.25 }
            }

            // === 内容布局 ===
        RowLayout {
            anchors.fill: parent
            anchors.leftMargin: root.horizontalPadding
            anchors.rightMargin: root.horizontalPadding
            spacing: root.labelSpacing

                // 图标
                Text {
                    text: model.iconChar
                    visible: model.iconChar !== undefined
                    font.family: iconFont.name
                    font.pixelSize: root.itemIconSize
                    color: root.textColor
                    Layout.preferredWidth: root.itemIconSize
                    Layout.preferredHeight: root.itemIconSize
                    verticalAlignment: Text.AlignVCenter
                    horizontalAlignment: Text.AlignHCenter
                }

            Item {
                id: labelWrap
                width: root.textShown ? label.implicitWidth : 0
                height: label.implicitHeight
                Layout.preferredWidth: width
                Layout.fillWidth: true
                Behavior on width { NumberAnimation { duration: 200; easing.type: Easing.OutCubic } }
                clip: true

                Text {
                    id: label
                    anchors.verticalCenter: parent.verticalCenter
                    anchors.left: parent.left
                    text: model.display
                    opacity: root.textShown ? 1 : 0
                    color: root.textColor
                    font.pixelSize: root.itemFontSize
                    horizontalAlignment: Text.AlignLeft
                    elide: Text.ElideRight
                    Behavior on opacity { NumberAnimation { duration: 200; easing.type: Easing.OutCubic } }
                }
            }
            }

            // === 交互事件 ===
            MouseArea {
                id: mouseArea
                anchors.fill: parent
                hoverEnabled: true
                cursorShape: Qt.PointingHandCursor

                onEntered: itemContainer.hovered = true
                onExited: itemContainer.hovered = false

                onPressed: {
                    scale.xScale = root.pressedScale
                    scale.yScale = root.pressedScale
                    itemContainer.opacity = 0.85
                }

                onReleased: {
                    restoreAnimation.restart()
                    itemContainer.opacity = 1.0
                    root.itemClicked(index, { display: model.display, iconChar: model.iconChar })
                }

                onCanceled: {
                    restoreAnimation.restart()
                    itemContainer.opacity = 1.0
                }
            }
        }
    }
}

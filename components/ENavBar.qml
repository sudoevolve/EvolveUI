// ENavBar.qml
import QtQuick
import QtQuick.Layouts
import QtQuick.Controls
import QtQuick.Effects

Rectangle {
    id: root

    // === 接口属性 ===
    property var model: []  // [{ display: string, iconChar: string }]
    property int currentIndex: -1
    signal itemClicked(int index, var modelData)

    // === 样式属性 ===
    property real radius: 20
    property int itemHeight: 50
    property int itemFontSize: 15
    property int itemIconSize: 20
    property int itemSpacing: 8
    property int horizontalPadding: 10
    property real pressedScale: 0.96

    // 背景控制
    property bool backgroundVisible: true

    // 阴影配置
    property bool shadowEnabled: true
    property color shadowColor: theme.shadowColor
    property real shadowBlur: theme.shadowBlur
    property real shadowHorizontalOffset: theme.shadowXOffset
    property real shadowVerticalOffset: theme.shadowYOffset

    // === 尺寸与基础样式 ===
    color: "transparent"
    height: itemHeight + horizontalPadding * 2
    implicitWidth: model.length * (100 + itemSpacing) + horizontalPadding * 2
    implicitHeight: height

    // === 背景 ===
    Rectangle {
        id: background
        anchors.fill: parent
        color: theme.secondaryColor
        radius: root.radius
        visible: root.backgroundVisible

        layer.enabled: root.shadowEnabled && root.backgroundVisible
        layer.effect: MultiEffect {
            shadowEnabled: root.shadowEnabled && root.backgroundVisible
            shadowColor: root.shadowColor
            shadowBlur: root.shadowBlur
            shadowHorizontalOffset: root.shadowHorizontalOffset
            shadowVerticalOffset: root.shadowVerticalOffset
        }
    }

    // === 布局：横向导航 ===
    RowLayout {
        id: row
        anchors.fill: parent
        anchors.margins: horizontalPadding
        spacing: root.itemSpacing

        Repeater {
            model: root.model

            delegate: Rectangle {
                id: navItem
                height: root.itemHeight
                width: 100
                radius: root.radius / 2

                // === 状态属性 ===
                property bool hovered: false

                color: root.backgroundVisible
                    ? (hovered ? Qt.darker(theme.secondaryColor, 1.15) : theme.secondaryColor)
                    : "transparent"
                opacity: mouseArea.pressed ? 0.85 : 1.0

                Behavior on color { ColorAnimation { duration: 150 } }
                Behavior on opacity { NumberAnimation { duration: 100 } }

                // === 缩放动画 ===
                transform: Scale {
                    id: scale
                    origin.x: navItem.width / 2
                    origin.y: navItem.height / 2
                    xScale: 1.0
                    yScale: 1.0
                }

                ParallelAnimation {
                    id: restoreAnimation
                    SpringAnimation { target: scale; property: "xScale"; to: 1.0; spring: 2.5; damping: 0.25 }
                    SpringAnimation { target: scale; property: "yScale"; to: 1.0; spring: 2.5; damping: 0.25 }
                }

                // === 内容布局 ===
                RowLayout {
                    anchors.fill: parent
                    spacing: 8
                    anchors.margins: 10
                    Layout.alignment: Qt.AlignHCenter | Qt.AlignVCenter

                    Text {
                        visible: !!(modelData.iconChar || "")
                        text: modelData.iconChar || ""
                        font.family: iconFont.name
                        font.pixelSize: root.itemIconSize
                        color: root.currentIndex === index
                            ? theme.focusColor
                            : (hovered ? Qt.darker(theme.textColor, 1.2) : theme.textColor)
                        Behavior on color { ColorAnimation { duration: 150 } }
                        horizontalAlignment: Text.AlignHCenter
                        verticalAlignment: Text.AlignVCenter
                    }

                    Text {
                        text: modelData.display || ""
                        font.pixelSize: root.itemFontSize
                        color: root.currentIndex === index
                            ? theme.focusColor
                            : (hovered ? Qt.darker(theme.textColor, 1.2) : theme.textColor)
                        Behavior on color { ColorAnimation { duration: 150 } }
                        verticalAlignment: Text.AlignVCenter
                        elide: Text.ElideRight
                    }
                }

                // === 交互 ===
                MouseArea {
                    id: mouseArea
                    anchors.fill: parent
                    hoverEnabled: true
                    cursorShape: Qt.PointingHandCursor

                    onEntered: navItem.hovered = true
                    onExited: navItem.hovered = false

                    onPressed: {
                        scale.xScale = root.pressedScale
                        scale.yScale = root.pressedScale
                        navItem.opacity = 0.85
                    }

                    onReleased: {
                        restoreAnimation.restart()
                        navItem.opacity = 1.0
                        root.currentIndex = index
                        root.itemClicked(index, modelData)
                    }

                    onCanceled: {
                        restoreAnimation.restart()
                        navItem.opacity = 1.0
                    }
                }
            }
        }
    }
}

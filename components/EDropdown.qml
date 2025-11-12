// EDropdown.qml
import QtQuick
import QtQuick.Layouts
import QtQuick.Controls
import QtQuick.Effects

Item {
    id: root

    // === 基础属性 ===
    property string title: "请选择"
    property bool opened: true
    property var model: []          // [{ text: "选项", value: 1 }]
    property int selectedIndex: -1
    signal selectionChanged(int index, var item)

    // === 样式属性 ===
    property bool backgroundVisible: true
    property real radius: 20
    property color headerColor: theme.secondaryColor
    property color textColor: theme.textColor
    property color shadowColor: theme.shadowColor
    property bool shadowEnabled: true
    property int headerHeight: 52
    property int popupMaxHeight: 300
    property int horizontalPadding: 16
    property real pressedScale: 0.96
    property int popupSpacing: 8

    // === 弹出动画参数 ===
    property int popupEnterDuration: 260
    property int popupExitDuration: 200
    property real popupSlideOffset: -12
    property real popupScaleFrom: 0.98

    width: 200
    height: headerHeight

    // 背景 + 文字分离（避免重影）
    Item {
        id: headerContainer
        anchors.left: parent.left
        anchors.right: parent.right
        height: root.headerHeight

        // 阴影效果（只作用于背景）
        MultiEffect {
            source: headerBackground
            anchors.fill: headerBackground
            visible: root.shadowEnabled
            shadowEnabled: true
            shadowColor: root.shadowColor
            shadowBlur: theme.shadowBlur
            shadowVerticalOffset: theme.shadowYOffset
            shadowHorizontalOffset: theme.shadowXOffset
        }

        // 背景矩形（仅用于阴影，无文字）
        Rectangle {
            id: headerBackground
            anchors.fill: parent
            radius: root.radius
            color: root.backgroundVisible ? root.headerColor : "transparent"
            border.color: root.backgroundVisible ? "transparent" : root.textColor
            border.width: root.backgroundVisible ? 0 : 1
            visible: root.backgroundVisible || root.shadowEnabled
        }

        // 文字和图标（独立绘制，无阴影采样）
        Item {
            anchors.fill: parent

            // 点击缩放动画
            transform: Scale {
                id: headerScale
                origin.x: width / 2
                origin.y: height / 2
            }

            ParallelAnimation {
                id: restoreHeaderAnimation
                SpringAnimation { target: headerScale; property: "xScale"; spring: 2.5; damping: 0.25 }
                SpringAnimation { target: headerScale; property: "yScale"; spring: 2.5; damping: 0.25 }
            }

            RowLayout {
                anchors.fill: parent
                anchors.margins: root.horizontalPadding
                spacing: 0

                Text {
                    text: root.selectedIndex >= 0 ? root.model[root.selectedIndex].text : root.title
                    color: root.textColor
                    font.pixelSize: 16
                    font.bold: true
                    elide: Text.ElideRight
                    verticalAlignment: Text.AlignVCenter
                    Layout.fillWidth: true
                }

                Text {
                    text: "\uf054"
                    font.family: "Font Awesome 6 Free"
                    font.pixelSize: 16
                    color: theme.focusColor
                    rotation: root.opened ? -90 : 90
                    Layout.alignment: Qt.AlignRight | Qt.AlignVCenter
                    Behavior on rotation { RotationAnimation { duration: 250; easing.type: Easing.InOutQuad } }
                }
            }

            // 点击区域
            MouseArea {
                anchors.fill: parent
                hoverEnabled: true
                cursorShape: Qt.PointingHandCursor
                onPressed: {
                    headerScale.xScale = root.pressedScale
                    headerScale.yScale = root.pressedScale
                }
                onReleased: restoreHeaderAnimation.start()
                onCanceled: restoreHeaderAnimation.start()
                onClicked: root.opened = !root.opened
            }
        }
    }

    // 弹出菜单
    Item {
        id: popupContainer
        width: root.width
        // 通过偏移实现下滑动画
        property real popupOffsetY: 0
        y: headerContainer.height + root.popupSpacing + popupOffsetY
        // 改为按动画可见：打开或仍有不透明度时可见，避免立即隐藏打断动画
        enabled: true
        visible: opacity > 0 || root.opened
        // 初始为隐藏，由状态控制 0/1（配合 Transition 实现动画）
        opacity: 0

        // 顶部基准的缩放（轻微回弹）
        transform: Scale {
            id: popupScale
            origin.x: width / 2
            origin.y: 0
        }

        // 阴影（只作用于弹出背景）
        MultiEffect {
            source: popupBackground
            anchors.fill: popupBackground
            visible: root.shadowEnabled
            shadowEnabled: true
            shadowColor: root.shadowColor
            shadowBlur: theme.shadowBlur
            shadowVerticalOffset: theme.shadowYOffset
            shadowHorizontalOffset: theme.shadowXOffset
        }

        // 弹出背景
        Rectangle {
            id: popupBackground
            width: root.width
            radius: root.radius
            color: root.backgroundVisible ? root.headerColor : "transparent"
            clip: true
            height: Math.min(contentLayout.implicitHeight, root.popupMaxHeight)

            // 弹出内容高度变化时的平滑动画
            Behavior on height { NumberAnimation { duration: 220; easing.type: Easing.OutCubic } }

            ColumnLayout {
                id: contentLayout
                width: parent.width
                spacing: 4

                Repeater {
                    model: root.model

                    Item {
                        width: parent.width
                        height: 40
                        // 打开时淡入出现（轻微缩放）
                        opacity: root.opened ? 1 : 0
                        Behavior on opacity { NumberAnimation { duration: 180; easing.type: Easing.OutCubic } }

                        transform: Scale {
                            id: itemAppearScale
                            origin.x: width / 2
                            origin.y: height / 2
                            xScale: root.opened ? 1.0 : 0.98
                            yScale: root.opened ? 1.0 : 0.98
                            // 将 Behavior 放到 Scale 对象上，避免绑定到不存在的 Item 属性
                            Behavior on xScale { NumberAnimation { duration: 180; easing.type: Easing.OutCubic } }
                            Behavior on yScale { NumberAnimation { duration: 180; easing.type: Easing.OutCubic } }
                        }

                        Rectangle {
                            id: itemBg
                            anchors.fill: parent
                            width: parent.width - 30
                            radius: 14
                            color: "transparent"

                            Text {
                                anchors.centerIn: parent
                                text: modelData.text
                                font.pixelSize: 16
                                font.bold: true
                                color: root.textColor
                            }

                            transform: Scale {
                                id: itemScale
                                origin.x: width / 2
                                origin.y: height / 2
                            }

                            ParallelAnimation {
                                id: restoreItemAnimation
                                SpringAnimation { target: itemScale; property: "xScale"; spring: 2.5; damping: 0.25 }
                                SpringAnimation { target: itemScale; property: "yScale"; spring: 2.5; damping: 0.25 }
                                NumberAnimation { target: itemBg; property: "opacity"; to: 1; duration: 150 }
                            }

                            MouseArea {
                                anchors.fill: parent
                                hoverEnabled: true
                                cursorShape: Qt.PointingHandCursor
                                onPressed: {
                                    itemScale.xScale = root.pressedScale
                                    itemScale.yScale = root.pressedScale
                                }
                                onReleased: restoreItemAnimation.start()
                                onCanceled: restoreItemAnimation.start()
                                onClicked: {
                                    root.selectedIndex = index
                                    root.opened = false
                                    root.selectionChanged(index, modelData)
                                }
                            }
                        }
                    }
                }
            }
        }

        // 状态与过渡：控制下滑 + 渐入 + 轻微回弹
        states: [
            State {
                name: "closed"
                when: !root.opened
                PropertyChanges { target: popupContainer; popupOffsetY: popupSlideOffset }
                PropertyChanges { target: popupContainer; opacity: 0 }
                PropertyChanges { target: popupScale; xScale: popupScaleFrom; yScale: popupScaleFrom }
            },
            State {
                name: "open"
                when: root.opened
                PropertyChanges { target: popupContainer; popupOffsetY: 0 }
                PropertyChanges { target: popupContainer; opacity: 1 }
                PropertyChanges { target: popupScale; xScale: 1.0; yScale: 1.0 }
            }
        ]

        transitions: [
            Transition {
                from: "closed"; to: "open"
                SequentialAnimation {
                    ParallelAnimation {
                        NumberAnimation { target: popupContainer; property: "popupOffsetY"; to: 0; duration: popupEnterDuration; easing.type: Easing.OutCubic }
                        NumberAnimation { target: popupContainer; property: "opacity"; to: 1; duration: popupEnterDuration * 0.9; easing.type: Easing.OutCubic }
                        NumberAnimation { target: popupScale; property: "xScale"; to: 1.02; duration: popupEnterDuration * 0.6; easing.type: Easing.OutCubic }
                        NumberAnimation { target: popupScale; property: "yScale"; to: 1.02; duration: popupEnterDuration * 0.6; easing.type: Easing.OutCubic }
                    }
                    ParallelAnimation {
                        NumberAnimation { target: popupScale; property: "xScale"; to: 1.0; duration: popupEnterDuration * 0.4; easing.type: Easing.OutCubic }
                        NumberAnimation { target: popupScale; property: "yScale"; to: 1.0; duration: popupEnterDuration * 0.4; easing.type: Easing.OutCubic }
                    }
                }
            },
            Transition {
                from: "open"; to: "closed"
                ParallelAnimation {
                    NumberAnimation { target: popupContainer; property: "popupOffsetY"; to: popupSlideOffset; duration: popupExitDuration; easing.type: Easing.InCubic }
                    NumberAnimation { target: popupContainer; property: "opacity"; to: 0; duration: popupExitDuration * 0.9; easing.type: Easing.InCubic }
                    NumberAnimation { target: popupScale; property: "xScale"; to: popupScaleFrom; duration: popupExitDuration * 0.6; easing.type: Easing.InCubic }
                    NumberAnimation { target: popupScale; property: "yScale"; to: popupScaleFrom; duration: popupExitDuration * 0.6; easing.type: Easing.InCubic }
                }
            }
        ]
    }

    // 点击外部关闭
    MouseArea {
        anchors.fill: parent
        enabled: root.opened
        onClicked: root.opened = false
    }

    // 安全增强
    Component.onCompleted: {
        if (popupContainer.y + popupContainer.height > parent.height) {
            popupContainer.y = -popupContainer.height - root.popupSpacing
        }
    }

    onModelChanged: {
        if (selectedIndex >= model.length) selectedIndex = -1
    }
}

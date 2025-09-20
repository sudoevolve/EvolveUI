// EDropdown.qml
import QtQuick
import QtQuick.Layouts
import QtQuick.Controls
import QtQuick.Effects

Item {
    id: root

    // === 接口属性 ===
    property string title: "请选择"
    property bool opened: false
    property var model: []                   // [{ text: string, value: any }]
    property int selectedIndex: -1           // 当前选中索引
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

    width: 220
    height: headerHeight

    // === 标题栏 ===
    Item {
        id: headerContainer
        anchors.left: parent.left
        anchors.right: parent.right
        height: root.headerHeight

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

        Rectangle {
            id: header
            visible: root.backgroundVisible
            anchors.fill: parent
            radius: root.radius
            color: root.headerColor

            // 缩放动画
            transform: Scale {
                id: headerScale
                origin.x: width / 2
                origin.y: height / 2
                xScale: 1.0
                yScale: 1.0
            }

            ParallelAnimation {
                id: restoreHeaderAnimation
                SpringAnimation {
                    target: headerScale
                    property: "xScale"
                    spring: 2.5
                    damping: 0.25
                }
                SpringAnimation {
                    target: headerScale
                    property: "yScale"
                    spring: 2.5
                    damping: 0.25
                }
            }

            RowLayout {
                anchors.fill: parent
                anchors.margins: root.horizontalPadding
                spacing: 0

                Text {
                    id: titleText
                    text: root.selectedIndex >= 0 ? root.model[root.selectedIndex].text : root.title
                    color: root.textColor
                    font.pixelSize: 16
                    font.bold: true
                    elide: Text.ElideRight
                    verticalAlignment: Text.AlignVCenter
                    Layout.fillWidth: true
                    Layout.alignment: Qt.AlignVCenter
                }

                Text {
                    text: "\uf054"
                    font.family: "Font Awesome 6 Free"
                    font.pixelSize: 16
                    color: root.textColor
                    rotation: root.opened ? -90 : 90
                    elide: Text.ElideLeft
                    verticalAlignment: Text.AlignVCenter
                    Layout.alignment: Qt.AlignRight | Qt.AlignVCenter
                    Behavior on rotation { RotationAnimation { duration: 250; easing.type: Easing.InOutQuad } }
                }
            }

            MouseArea {
                id: mouseArea
                anchors.fill: parent
                hoverEnabled: true
                cursorShape: Qt.PointingHandCursor

                onPressed: {
                    headerScale.xScale = root.pressedScale
                    headerScale.yScale = root.pressedScale
                }

                onReleased: {
                    restoreHeaderAnimation.start()
                }

                onCanceled: {
                    restoreHeaderAnimation.start()
                }

                onClicked: root.opened = !root.opened
            }
        }
    }

    // === 弹出选择框（===
    Item {
        id: popupContainer
        width: root.width
        y: headerContainer.height + root.popupSpacing
        visible: true
        opacity: root.opened ? 1 : 0

        // 阴影效果
        MultiEffect {
            source: popupBackground
            anchors.fill: popupBackground
            visible: root.shadowEnabled
            shadowEnabled: root.shadowEnabled
            shadowColor: root.shadowColor
            shadowBlur: theme.shadowBlur
            shadowVerticalOffset: theme.shadowYOffset
            shadowHorizontalOffset: theme.shadowXOffset
        }

        // 背景矩形
        Rectangle {
            id: popupBackground
            width: root.width
            radius: root.radius
            color: root.backgroundVisible ? theme.secondaryColor : "transparent"
            clip: true
            height: Math.min(contentLayout.implicitHeight, root.popupMaxHeight)

            ColumnLayout {
                id: contentLayout
                width: parent.width
                spacing: 4

                Repeater {
                    model: root.model

                    Item {
                        width: parent.width
                        height: 40

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
                                xScale: 1.0
                                yScale: 1.0
                            }

                            ParallelAnimation {
                                id: restoreItemAnimation
                                SpringAnimation {
                                    target: itemScale
                                    property: "xScale"
                                    spring: 2.5
                                    damping: 0.25
                                }
                                SpringAnimation {
                                    target: itemScale
                                    property: "yScale"
                                    spring: 2.5
                                    damping: 0.25
                                }
                                NumberAnimation {
                                    target: itemBg
                                    property: "opacity"
                                    to: 1.0
                                    duration: 150
                                    easing.type: Easing.InOutQuad
                                }
                            }

                            MouseArea {
                                id: itemMouseArea
                                anchors.fill: parent
                                hoverEnabled: true
                                cursorShape: Qt.PointingHandCursor

                                onPressed: {
                                    itemScale.xScale = root.pressedScale
                                    itemScale.yScale = root.pressedScale
                                }

                                onReleased: {
                                    restoreItemAnimation.start()
                                }

                                onCanceled: {
                                    restoreItemAnimation.start()
                                }

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

        // === 动画行为 ===
        Behavior on opacity { NumberAnimation { duration: 250; easing.type: Easing.InOutQuad } }
        Behavior on height { NumberAnimation { duration: 250; easing.type: Easing.InOutQuad } }
    }

    // === 点击外部关闭 ===
    MouseArea {
        anchors.fill: parent
        enabled: root.opened
        cursorShape: Qt.ArrowCursor
        onClicked: root.opened = false
    }
}

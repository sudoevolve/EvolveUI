// EDropdown.qml
import QtQuick
import QtQuick.Layouts
import QtQuick.Controls
import QtQuick.Controls.Basic as Basic
import QtQuick.Effects

Item {
    id: root

    // === 基础属性 ===
    property string title: "请选择"
    property bool opened: false
    property var model: []
    property int selectedIndex: -1
    signal selectionChanged(int index, var item)

    // === 样式属性 ===
    property bool backgroundVisible: true
    property real radius: 20
    property color containerColor: theme.secondaryColor
    property color textColor: theme.textColor
    property color shadowColor: theme.shadowColor
    property bool shadowEnabled: true
    property int fontSize: 16
    property color hoverColor: Qt.darker(containerColor, 1.2)
    property int headerHeight: 48
    property int itemHeight: 40
    property int popupMaxHeight: 300
    property int horizontalPadding: 24
    property real pressedScale: 0.96
    property int popupSpacing: 8

    // === 弹出动画参数 ===
    property int popupEnterDuration: 260
    property int popupExitDuration: 200
    property real popupSlideOffset: -12
    property real popupScaleFrom: 0.98

    property int popupDirection: 0 // 0: Down, 1: Up

    width: 200
    height: headerHeight

    Item {
        id: headerContainer
        anchors.left: parent.left
        anchors.right: parent.right
        height: root.headerHeight

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

        Rectangle {
            id: headerBackground
            anchors.fill: parent
            radius: root.radius
            color: root.backgroundVisible ? root.containerColor : "transparent"
            border.color: root.backgroundVisible ? "transparent" : root.textColor
            border.width: root.backgroundVisible ? 0 : 1
            visible: root.backgroundVisible || root.shadowEnabled
        }

        Item {
            anchors.fill: parent

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

            Item {
                anchors.fill: parent
                anchors.leftMargin: root.horizontalPadding
                anchors.rightMargin: root.horizontalPadding

                Text {
                    id: headerText
                    anchors.left: parent.left
                    anchors.right: arrowIcon.left
                    anchors.rightMargin: 8
                    anchors.verticalCenter: parent.verticalCenter

                    text: root.selectedIndex >= 0 ? root.model[root.selectedIndex].text : root.title
                    color: root.textColor
                    font.pixelSize: root.fontSize
                    font.bold: false
                    elide: Text.ElideRight
                    verticalAlignment: Text.AlignVCenter
                }

                Text {
                    id: arrowIcon
                    anchors.right: parent.right
                    anchors.verticalCenter: parent.verticalCenter

                    text: "\uf054"
                    font.family: "Font Awesome 6 Free"
                    font.pixelSize: 16
                    color: theme.focusColor
                    rotation: root.opened ? (root.popupDirection === 1 ? -90 : 90) : 0

                    Behavior on rotation { RotationAnimation { duration: 250; easing.type: Easing.InOutQuad } }
                }
            }

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

    Item {
        id: popupContainer
        width: root.width
        height: popupBackground.height
        property real popupOffsetY: 0
        y: popupDirection === 1
           ? -popupContainer.height - root.popupSpacing + popupOffsetY
           : headerContainer.height + root.popupSpacing + popupOffsetY

        enabled: true
        visible: opacity > 0 || root.opened
        opacity: 0

        transform: Scale {
            id: popupScale
            origin.x: width / 2
            origin.y: 0
        }

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

        Rectangle {
            id: popupBackground
            width: root.width
            radius: root.radius
            color: root.backgroundVisible ? root.containerColor : "transparent"
            clip: true
            height: Math.min(contentListView.contentHeight + 10, root.popupMaxHeight)

            Behavior on height { NumberAnimation { duration: 220; easing.type: Easing.OutCubic } }

            ListView {
                id: contentListView
                anchors.fill: parent
                clip: true
                spacing: 6
                topMargin: 4
                bottomMargin: 4
                model: root.model

                delegate: Item {
                    width: contentListView.width - 24
                    height: root.itemHeight
                    anchors.horizontalCenter: parent.horizontalCenter

                    opacity: root.opened ? 1 : 0
                    Behavior on opacity { NumberAnimation { duration: 180; easing.type: Easing.OutCubic } }

                    transform: Scale {
                        id: itemAppearScale
                        origin.x: width / 2
                        origin.y: height / 2
                        xScale: root.opened ? 1.0 : 0.98
                        yScale: root.opened ? 1.0 : 0.98
                        Behavior on xScale { NumberAnimation { duration: 180; easing.type: Easing.OutCubic } }
                        Behavior on yScale { NumberAnimation { duration: 180; easing.type: Easing.OutCubic } }
                    }

                    Rectangle {
                        id: itemBg
                        anchors.fill: parent
                        radius: 6

                        property bool hovered: false
                        color: !root.backgroundVisible ? "transparent" : (hovered ? root.hoverColor : Qt.rgba(root.hoverColor.r, root.hoverColor.g, root.hoverColor.b, 0))
                        Behavior on color { ColorAnimation { duration: 150 } }

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
                            onEntered: itemBg.hovered = true
                            onExited: itemBg.hovered = false
                        }
                    }

                    Text {
                        anchors.left: parent.left
                        anchors.leftMargin: root.horizontalPadding - 4
                        anchors.verticalCenter: parent.verticalCenter
                        text: modelData.text
                        font.pixelSize: root.fontSize
                        font.bold: false
                        color: root.textColor
                        visible: true
                    }
                }

                ScrollBar.vertical: Basic.ScrollBar {
                    width: 4
                    policy: ScrollBar.AsNeeded
                    active: contentListView.moving || contentListView.dragging

                    contentItem: Rectangle {
                        implicitWidth: 4
                        implicitHeight: 100
                        radius: 2
                        color: root.textColor
                        opacity: 0.3
                    }
                    background: Rectangle {
                        implicitWidth: 4
                        implicitHeight: 100
                        color: "transparent"
                    }
                }
            }
        }

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

    MouseArea {
        anchors.fill: parent
        enabled: root.opened
        onClicked: root.opened = false
    }

    onModelChanged: {
        if (selectedIndex >= model.length) selectedIndex = -1
    }
}

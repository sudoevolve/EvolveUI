// IconListView.qml
import QtQuick 2.15
import QtQuick.Layouts 1.15
import QtQuick.Effects
import "."

Rectangle {
    id: root

    FontLoader {
        id: iconFont
        source: "qrc:/new/prefix1/fonts/fontawesome-free-6.7.2-desktop/otfs/Font Awesome 6 Free-Solid-900.otf"
    }

    // === 外部接口 ===
    property var model
    signal itemClicked(int index, var modelData)

    // === 样式配置 ===
    property real radius: 15
    property int listPadding: 5
    property int itemHeight: 50
    property int itemFontSize: 15
    property int itemIconSize: 20
    property int itemSpacing: 2
    property real itemHoverScale: 1.0
    property real pressedScale: 0.96

    // === 阴影样式 ===
    property bool shadowEnabled: true
    property color shadowColor: theme.shadowColor
    property real shadowBlur: theme.shadowBlur
    property real shadowHorizontalOffset: theme.shadowXOffset
    property real shadowVerticalOffset: theme.shadowYOffset

    color: "transparent"
    implicitWidth: 250
    implicitHeight: 400

    // === 阴影效果 ===
    MultiEffect {
        source: background
        anchors.fill: background
        visible: root.shadowEnabled
        shadowEnabled: root.shadowEnabled
        shadowColor: root.shadowColor
        shadowBlur: root.shadowBlur
        shadowHorizontalOffset: root.shadowHorizontalOffset
        shadowVerticalOffset: root.shadowVerticalOffset
    }

    // === 背景层 ===
    Rectangle {
        id: background
        anchors.fill: parent
        radius: root.radius
        color: theme.secondaryColor
    }

    // === 列表 ===
    ListView {
        id: listView
        anchors.fill: parent
        anchors.margins: root.listPadding
        clip: true
        spacing: root.itemSpacing
        model: root.model

        delegate: Rectangle {
            id: itemContainer
            width: listView.width
            height: root.itemHeight
            radius: root.radius - root.listPadding

            property bool hovered: false

            color: hovered ? Qt.darker(theme.secondaryColor, 1.2) : theme.secondaryColor
            opacity: mouseArea.pressed ? 0.85 : 1.0

            Behavior on color { ColorAnimation { duration: 150 } }
            Behavior on opacity { NumberAnimation { duration: 100 } }

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

            RowLayout {
                anchors.fill: parent
                anchors.leftMargin: 15
                anchors.rightMargin: 15
                spacing: 12

                Text {
                    id: icon
                    visible: !!model.iconChar
                    text: model.iconChar
                    font.family: iconFont.name
                    font.pixelSize: root.itemIconSize
                    color: theme.textColor
                    Layout.preferredWidth: root.itemIconSize
                    Layout.preferredHeight: root.itemIconSize
                    verticalAlignment: Text.AlignVCenter
                    horizontalAlignment: Text.AlignHCenter
                }

                Text {
                    id: label
                    text: model.display
                    color: theme.textColor
                    font.pixelSize: root.itemFontSize
                    elide: Text.ElideRight
                    Layout.fillWidth: true
                    verticalAlignment: Text.AlignVCenter
                }
            }

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
                    listView.currentIndex = index
                    root.itemClicked(index, modelData)
                }

                onCanceled: {
                    restoreAnimation.restart()
                    itemContainer.opacity = 1.0
                }
            }
        }
    }
}

import QtQuick 2.15
import QtQuick.Layouts 1.15
import QtQuick.Controls 2.15
import QtQuick.Effects

Rectangle {
    id: root

    FontLoader {
        id: iconFont
        source: "qrc:/new/prefix1/fonts/fontawesome-free-6.7.2-desktop/otfs/Font Awesome 6 Free-Solid-900.otf"
    }

    // === 外部接口 ===
    property var model: []
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

    // 阴影相关
    property bool shadowEnabled: true
    property color shadowColor: theme.shadowColor
    property real shadowBlur: theme.shadowBlur
    property real shadowHorizontalOffset: theme.shadowXOffset
    property real shadowVerticalOffset: theme.shadowYOffset

    color: "transparent"

    // 用于测量文本最大宽度的隐藏文本
    Text {
        id: measureText
        visible: false
        font.pixelSize: root.itemFontSize
        font.bold: false
    }

    // 计算最大文本宽度
    property real maxTextWidth: 0
    function updateMaxTextWidth() {
        var maxWidth = 0;
        for (var i = 0; i < model.length; i++) {
            var itemText = model[i].display || "";
            measureText.text = itemText;
            if (measureText.width > maxWidth)
                maxWidth = measureText.width;
        }
        maxTextWidth = maxWidth;
    }

    Component.onCompleted: updateMaxTextWidth()
    onModelChanged: updateMaxTextWidth()

    // 自适应宽度 = 图标宽度 + 文本最大宽度 + 左右内边距 + 内部间距
    property int horizontalPadding: 15
    property int iconTextSpacing: 12
    implicitWidth: horizontalPadding * 2 + root.itemIconSize + iconTextSpacing + maxTextWidth + 10
    implicitHeight: model.length > 0
        ? model.length * (itemHeight + itemSpacing) - itemSpacing + listPadding * 2
        : itemHeight + listPadding * 2

    width: implicitWidth
    height: implicitHeight

    Rectangle {
        id: background
        anchors.fill: parent
        clip: true
        radius: root.radius
        color: theme.secondaryColor

        layer.enabled: root.shadowEnabled
        layer.effect: MultiEffect {
            shadowEnabled: root.shadowEnabled
            shadowColor: root.shadowColor
            shadowBlur: root.shadowBlur
            shadowHorizontalOffset: root.shadowHorizontalOffset
            shadowVerticalOffset: root.shadowVerticalOffset
        }
    }

    ListView {
        id: listView
        anchors.fill: parent
        anchors.margins: root.listPadding
        clip: true
        spacing: root.itemSpacing
        model: root.model
        // 关键点：强制宽度 = root.width - 左右padding
        width: root.width - root.listPadding * 2

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
                anchors.leftMargin: root.listPadding
                anchors.rightMargin: root.listPadding
                spacing: root.itemIconSize > 0 ? root.itemIconSize / 2 : 12
                Layout.alignment: Qt.AlignVCenter

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
                    Layout.fillWidth: true  // 填满剩余宽度自适应
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

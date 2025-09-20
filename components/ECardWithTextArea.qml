// ECardWithTextArea.qml
import QtQuick
import QtQuick.Layouts
import QtQuick.Controls
import QtQuick.Effects

Item {
    id: root

    // === 公共接口与样式 ===
    property bool backgroundVisible: true
    property color cardColor: theme.secondaryColor
    property real radius: 20
    property int padding: 15 // 内容区域内边距

    // 阴影属性
    property bool shadowEnabled: true
    property color shadowColor: theme.shadowColor

    // === 插槽：用户内容插入点 ===
    default property alias content: contentLayout.data

    // === 固定卡片尺寸 ===
    width: 300
    height: 200

    // === 阴影效果 ===
    MultiEffect {
        source: background
        anchors.fill: background
        visible: root.shadowEnabled && root.backgroundVisible
        shadowEnabled: true
        shadowColor: root.shadowColor
        shadowBlur: theme.shadowBlur
        shadowVerticalOffset: theme.shadowYOffset
        shadowHorizontalOffset: theme.shadowXOffset

    }

    // === 卡片背景 ===
    Rectangle {
        id: background
        anchors.fill: parent
        radius: root.radius
        color: root.cardColor
        visible: root.backgroundVisible
    }

    // === 内容布局 ===
    ColumnLayout {
        id: contentLayout
        anchors.fill: parent
        anchors.margins: root.padding
        spacing: 10

        Flickable {
            id: textScroll
            Layout.fillWidth: true
            Layout.preferredHeight: parent.height - root.padding*2  // 固定高度填充卡片内部
            clip: true
            contentWidth: textArea.width
            contentHeight: textArea.paintedHeight
            boundsBehavior: Flickable.StopAtBounds
            interactive: true

            TextArea {
                id: textArea
                width: textScroll.width
                wrapMode: Text.Wrap
                font.pixelSize: 16
                placeholderText: "请输入内容"
                palette.placeholderText: theme.textColor
                background: null
                color: theme.textColor

                onTextChanged: {
                    textScroll.contentY = Math.max(0, textScroll.contentHeight - textScroll.height)
                }
            }
        }
    }
}

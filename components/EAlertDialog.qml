import QtQuick
import QtQuick.Controls
import QtQuick.Layouts
import QtQuick.Effects
import "." as Components

Item {
    id: dialogRoot
    anchors.fill: parent
    visible: false
    z: 2000

    // API
    property alias title: titleText.text
    property alias message: messageText.text
    property string cancelText: "Cancel"
    property string confirmText: "Continue"
    property bool dismissOnOverlay: true
    signal confirm()
    signal cancel()

    function open() { visible = true; overlay.opacity = 0.0; overlay.opacity = 1.0; card.scale = 0.92; card.opacity = 0.0; card.scale = 1.0; card.opacity = 1.0 }
    function close() { visible = false }

    // 背景变暗遮罩
    Rectangle {
        id: overlay
        anchors.fill: parent
        color: Qt.rgba(0,0,0,0.45)
        opacity: 0
        Behavior on opacity { NumberAnimation { duration: 220; easing.type: Easing.OutCubic } }
        MouseArea { 
            anchors.fill: parent
            acceptedButtons: Qt.AllButtons  // 接受所有鼠标按钮事件
            propagateComposedEvents: false  // 阻止事件穿透
            hoverEnabled: true  // 启用悬停事件处理
            onClicked: if (dialogRoot.dismissOnOverlay) dialogRoot.close()
            // 阻止所有鼠标事件穿透
            onPressed: function(mouse) { mouse.accepted = true }
            onReleased: function(mouse) { mouse.accepted = true }
            onDoubleClicked: function(mouse) { mouse.accepted = true }
            onWheel: function(wheel) { wheel.accepted = true }
        }
     }

    // 毛玻璃对话框主体
    Components.EBlurCard {
        id: card
        width: 420
        height: contentCol.implicitHeight + 28
        anchors.centerIn: parent
        blurSource: dialogRoot.parent // 使用父内容作为模糊源
        borderRadius: 18
        opacity: 0
        scale: 0.96
        Behavior on opacity { NumberAnimation { duration: 220; easing.type: Easing.OutCubic } }
        Behavior on scale { NumberAnimation { duration: 220; easing.type: Easing.OutBack } }

        // 使用 Layouts，避免 Column 子项 anchors 冲突
        ColumnLayout {
            id: contentCol
            anchors.fill: parent
            anchors.margins: 18
            spacing: 16

            Text {
                id: titleText
                text: "Title"
                font.pixelSize: 20
                font.bold: true
                color: theme ? theme.focusColor : "#ffffff"
                wrapMode: Text.WordWrap
                Layout.fillWidth: true
            }

            Text {
                id: messageText
                text: "Message"
                font.pixelSize: 14
                color: theme ? theme.textColor : "#d0d0d0"
                wrapMode: Text.WordWrap
                Layout.fillWidth: true
            }

            RowLayout {
                Layout.fillWidth: true
                Layout.alignment: Qt.AlignRight
                spacing: 10

                Components.EButton {
                    text: cancelText
                    backgroundVisible: true
                    iconCharacter: "\uf00d" // X 图标
                    onClicked: { dialogRoot.cancel(); dialogRoot.close() }
                }
                Components.EButton {
                    text: confirmText
                    backgroundVisible: true
                    iconCharacter: "\uf00c" // 勾图标
                    onClicked: { dialogRoot.confirm(); dialogRoot.close() }
                }
            }
        }
    }
}

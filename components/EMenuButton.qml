// EMenuButton.qml
import QtQuick
import QtQuick.Controls
import QtQuick.Layouts
import QtQuick.Effects

Item {
    id: root
    
    // ==== 配置属性 ====
    property string text: "Menu"
    property var menuModel: [] // 按钮组 { text: "Option", action: function() {} }
    
    // 样式属性
    property real radius: 10
    property color textColor: theme.textColor
    property color hoverColor: Qt.rgba(0,0,0,0.05)
    property bool backgroundVisible: true // 控制默认背景是否可见
    
    signal itemClicked(int index, string text)

    // 尺寸自适应
    implicitWidth: label.implicitWidth + 24 // 左右各12px padding
    implicitHeight: 40

    // 背景
    Rectangle {
        id: background
        anchors.fill: parent
        radius: root.radius

        color: {
            if (root.backgroundVisible) {
                return menuPopup.visible ? Qt.darker(theme.secondaryColor, 1.1) : theme.secondaryColor
            } else {
                return menuPopup.visible ? root.hoverColor : "transparent"
            }
        }
        
        // 动画
        Behavior on color { ColorAnimation { duration: 100 } }
    }

    // 文本
    Text {
        id: label
        anchors.centerIn: parent
        text: root.text
        color: root.textColor
        font.pixelSize: 14
        font.bold: true
        verticalAlignment: Text.AlignVCenter
        horizontalAlignment: Text.AlignHCenter
    }

    // 交互区域
    MouseArea {
        id: mouseArea
        anchors.fill: parent
        hoverEnabled: true
        cursorShape: Qt.PointingHandCursor
        
        onClicked: {
            if (menuPopup.visible) {
                menuPopup.close()
            } else {
                menuPopup.open()
            }
        }
    }

    // Custom Popup Menu
    Popup {
        id: menuPopup
        y: root.height + 4
        x: 0
        width: 160
        height: Math.min(listView.contentHeight + 8, 300)
        padding: 0
        
        background: Rectangle {
            color: theme.secondaryColor
            radius: root.radius + 2
            border.color: theme.borderColor
            border.width: 1
            
            layer.enabled: true
            layer.effect: MultiEffect {
                shadowEnabled: true
                shadowColor: theme.shadowColor
                shadowBlur: theme.shadowBlur
                shadowVerticalOffset: theme.shadowYOffset
                shadowHorizontalOffset: theme.shadowXOffset
            }
        }

        enter: Transition {
            NumberAnimation { property: "opacity"; from: 0.0; to: 1.0; duration: 150 }
            NumberAnimation { property: "scale"; from: 0.95; to: 1.0; duration: 150; easing.type: Easing.OutCubic }
        }
        
        exit: Transition {
            NumberAnimation { property: "opacity"; from: 1.0; to: 0.0; duration: 100 }
            NumberAnimation { property: "scale"; from: 1.0; to: 0.95; duration: 100 }
        }

        contentItem: ListView {
            id: listView
            model: root.menuModel
            clip: true
            boundsBehavior: Flickable.StopAtBounds
            topMargin: 4
            bottomMargin: 4
            
            delegate: Rectangle {
                id: menuItemDelegate
                width: listView.width
                height: 36
                color: itemMouseArea.containsMouse ? Qt.rgba(0,0,0,0.05) : "transparent"
                radius: 4
                
                property string itemText: (typeof modelData === 'string') ? modelData : (modelData.text || "")
                
                RowLayout {
                    anchors.fill: parent
                    anchors.leftMargin: 12
                    anchors.rightMargin: 12
                    
                    Label {
                        text: itemText
                        color: theme.textColor
                        font.pixelSize: 14
                        Layout.fillWidth: true
                    }
                }
                
                MouseArea {
                    id: itemMouseArea
                    anchors.fill: parent
                    hoverEnabled: true
                    cursorShape: Qt.PointingHandCursor
                    onClicked: {
                        root.itemClicked(index, itemText)
                        if (typeof modelData === 'object' && modelData.action) {
                            modelData.action()
                        }
                        menuPopup.close()
                    }
                }
            }
        }
    }
}

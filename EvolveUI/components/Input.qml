// ShadowInput.qml
import QtQuick 2.15
import QtQuick.Controls 2.15
import QtQuick.Layouts 1.15
import QtQuick.Effects
import "."

Item {
    id: root
    width: 240
    height: 40

    // === 接口属性 ===
    property alias text: textField.text
    property alias placeholderText: textField.placeholderText
    property bool readOnly: false
    property bool passwordField: false
    property bool passwordVisible: false
    signal accepted()

    // === 样式属性 ===
    property int fontSize: 16
    property real radius: 10
    property string showPasswordSymbol: "👁"
    property string hidePasswordSymbol: "🙈"

    // === 外观状态 ===
    property bool enabled: true

    // === 背景容器 + 阴影 ===
    MultiEffect {
        source: background
        anchors.fill: background
        shadowEnabled: true
        shadowColor: theme.shadowColor
        shadowBlur: theme.shadowBlur
        shadowHorizontalOffset: theme.shadowXOffset
        shadowVerticalOffset: theme.shadowYOffset
    }

    Rectangle {
        id: background
        anchors.fill: parent
        radius: root.radius
        border.color: theme.getBorderColor(textField.activeFocus)
        border.width: 1
        color: theme.secondaryColor
        opacity: root.enabled ? 1.0 : 0.6
    }

    RowLayout {
        id: layout
        anchors.fill: parent
        anchors.margins: 8
        spacing: 6

        TextField {
            id: textField
            Layout.fillWidth: true
            Layout.alignment: Qt.AlignVCenter
            height: parent.height * 0.7

            font.pixelSize: root.fontSize
            color: theme.textColor
            placeholderTextColor: theme.textColor
            readOnly: root.readOnly
            enabled: root.enabled
            echoMode: root.passwordField
                      ? (root.passwordVisible ? TextInput.Normal : TextInput.Password)
                      : TextInput.Normal
            background: null
            onAccepted: root.accepted()
        }

        // 密码显示切换按钮
        Text {
            id: eyeToggle
            visible: root.passwordField
            text: root.passwordVisible ? root.hidePasswordSymbol : root.showPasswordSymbol
            color: "#666"
            font.pixelSize: 16
            verticalAlignment: Text.AlignVCenter
            horizontalAlignment: Text.AlignHCenter

            MouseArea {
                anchors.fill: parent
                enabled: root.enabled
                cursorShape: Qt.PointingHandCursor
                onClicked: root.passwordVisible = !root.passwordVisible
            }
        }
    }
}

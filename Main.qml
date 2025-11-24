import QtQuick
import QtQuick.Controls
import QtQuick.Layouts

ApplicationWindow {
    width: 900
    height: 600
    visible: true

    ETheme { id: theme }

    Column {
        anchors.centerIn: parent
        spacing: 16

        EButton {
            text: theme.isDark ? "切换为日间模式" : "切换为夜间模式"
            iconCharacter: theme.isDark ? "\uf186" : "\uf185"
            iconRotateOnClick: true
            onClicked: theme.toggleTheme()
        }

        EInput {
            placeholderText: "输入点什么"
        }
    }
}


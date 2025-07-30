// Theme.qml
import QtQuick 2.15

QtObject {
    id: theme

    property bool isDark: false

    // === 基础颜色 ===
    property color primaryColor: isDark ? "#121212" : "#ffffff"
    property color secondaryColor: isDark ? "#212121" : "#E9EEF6"
    property color textColor: isDark ? "#ffffff" : "#000000"
    property color borderColor: isDark ? "#666666" : "#cccccc"
    property color focusColor: "#ff428587"

    // === 阴影统一样式 ===
    property color shadowColor: isDark ? "#80000000" : "#40000000"
    property real shadowBlur: 1.0
    property int shadowXOffset: 2
    property int shadowYOffset: 2

    // === 方法 ===
    function getBorderColor(focused) {
        return focused ? focusColor : borderColor
    }

    function toggleTheme() {
        isDark = !isDark
    }
}

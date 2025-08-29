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
    property color blurOverlayColor: isDark ? "#4E000000" : "#4EFFFFFF"
    property color focusColor: "#00C4B3"

    // === 阴影统一样式 ===
    property color shadowColor: isDark ? "#80000000" : "#40000000"
    property real shadowBlur: 1.0
    property int shadowXOffset: 2
    property int shadowYOffset: 2

    // === 背景图片（新增）===
    property url backgroundImage: isDark ? "qrc:/new/prefix1/fonts/pic/02.jpg" : "qrc:/new/prefix1/fonts/pic/01.jpg"

    // === 方法 ===
    function getBorderColor(focused) {
        return focused ? focusColor : borderColor
    }

    function toggleTheme() {
        isDark = !isDark
    }
}

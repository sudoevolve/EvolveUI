// ETheme.qml
import QtQuick

QtObject {
    id: theme

    property bool isDark: false

    // === 全局动画窗口状态聚合 ===
    // 当前打开的动画窗口数量（由各 EAnimatedWindow 自动维护）
    property int openAnimatedWindowCount: 0
    // 是否有任意动画窗口处于全屏打开状态
    property bool anyAnimatedWindowOpen: openAnimatedWindowCount > 0

    // === 基础颜色 ===
    property color primaryColor: isDark ? '#1d1d1d' : '#FFFFFF'
    property color secondaryColor: isDark ? '#262626' : '#F8FAFD'
    property color textColor: isDark ? "#ffffff" : "#000000"
    property color borderColor: isDark ? "#666666" : "#cccccc"
    property color blurOverlayColor: isDark ? "#4E000000" : "#4EFFFFFF"
    // 默认强调色（非播放状态使用）
    property color defaultFocusColor: "#00C4B3"
    property color focusColor: defaultFocusColor

    // === 全局音量（0.0 - 1.0），用于 EMusicPlayer 绑定 ===
    property real musicVolume: 0.2

    // === 阴影统一样式 ===
    property color shadowColor: isDark ? "#80000000" : "#40000000"
    property real shadowBlur: 1.0
    property int shadowXOffset: 2
    property int shadowYOffset: 2

    // === 背景图片===
    property url backgroundImage: isDark ? "qrc:/new/prefix1/fonts/pic/02.jpg" : "qrc:/new/prefix1/fonts/pic/01.jpg"


    // === 方法 ===
    function getBorderColor(focused) {
        return focused ? focusColor : borderColor
    }

    function toggleTheme() {
        isDark = !isDark
    }

    // 播放音乐时由 EMusicPlayer 更新 focusColor，这里对强调色切换做缓动渐变
    Behavior on focusColor {
        ColorAnimation {
            duration: 180
            easing.type: Easing.OutCubic
        }
    }
}

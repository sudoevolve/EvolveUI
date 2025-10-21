import QtQuick
import QtQuick.Controls
import QtQuick.Effects

Item {
    id: root
    width: 140
    height: 140

    // === 样式 ===
    property color faceColor: theme.secondaryColor
    property color textColor: theme.textColor
    property color accentColor: theme.focusColor
    property bool backgroundVisible: true
    property bool shadowEnabled: true
    property color shadowColor: theme.shadowColor
    property real radius: 24

    // === 电量数据 ===
    // 0-100
    property int batteryLevel: 100
    // 是否正在充电
    property bool charging: true
    // 标题
    property string title: "Battery"

    readonly property real progress: Math.max(0, Math.min(1, batteryLevel / 100))
    // 低电量时显示警告色
    readonly property color ringColor: batteryLevel <= 20 ? "#FF3B30" : (batteryLevel <= 50 ? "#FF9500" : accentColor)
    readonly property string pctText: batteryLevel + "%"

    onBatteryLevelChanged: {
        // 数值变化时刷新圆环
        ring.requestPaint()
    }

    // 阴影效果（只作用于背景卡片）
    MultiEffect {
        source: background
        anchors.fill: background
        visible: root.shadowEnabled && root.backgroundVisible
        shadowEnabled: true
        shadowColor: root.shadowColor
        shadowBlur: theme.shadowBlur
        shadowHorizontalOffset: theme.shadowXOffset
        shadowVerticalOffset: theme.shadowYOffset
    }

    // 背景卡片
    Rectangle {
        id: background
        anchors.fill: parent
        radius: root.radius
        color: faceColor
        visible: root.backgroundVisible
        antialiasing: true
    }

    Column {
        anchors.fill: parent
        anchors.margins: 12
        spacing: 8

        // 顶部标题
        Text {
            text: root.title
            color: textColor
            font.pixelSize: 16
            font.bold: true
            horizontalAlignment: Text.AlignHCenter
            width: parent.width
        }

        // 中间圆环 + 电池图标
        Item {
            id: ringContainer
            width: 70
            height: 70
            anchors.horizontalCenter: parent.horizontalCenter

            Canvas {
                id: ring
                anchors.fill: parent
                antialiasing: true
                onPaint: {
                    const ctx = getContext("2d")
                    ctx.reset()
                    const w = width, h = height
                    const cx = w / 2, cy = h / 2
                    const trackW = 8
                    const r = Math.min(w, h) / 2 - trackW / 2
                    const start = -Math.PI / 2
                    const end = start + Math.PI * 2
                    const prog = start + Math.PI * 2 * root.progress

                    // 轨道
                    ctx.beginPath()
                    ctx.lineWidth = trackW
                    ctx.strokeStyle = Qt.rgba(theme.textColor.r, theme.textColor.g, theme.textColor.b, 0.25)
                    ctx.lineCap = "round"
                    ctx.arc(cx, cy, r, start, end, false)
                    ctx.stroke()

                    // 进度
                    ctx.beginPath()
                    ctx.lineWidth = trackW
                    ctx.strokeStyle = ringColor
                    ctx.lineCap = "round"
                    ctx.arc(cx, cy, r, start, prog, false)
                    ctx.stroke()
                }
            }

            // 电池图标（简约矩形 + 触点）
            Rectangle {
                id: batteryBody
                width: 22
                height: 36
                radius: 6
                color: Qt.rgba(theme.textColor.r, theme.textColor.g, theme.textColor.b, theme.isDark ? 0.35 : 0.45)
                border.color: Qt.rgba(theme.textColor.r, theme.textColor.g, theme.textColor.b, 0.8)
                border.width: 1
                anchors.centerIn: parent

                // 充电闪电（可选）
                visible: true
            }
            Rectangle {
                id: batteryCap
                width: 8
                height: 6
                radius: 3
                color: Qt.rgba(theme.textColor.r, theme.textColor.g, theme.textColor.b, 0.8)
                anchors.horizontalCenter: batteryBody.horizontalCenter
                anchors.top: batteryBody.top
                anchors.topMargin: -4
            }

            // 充电闪电指示
            FontLoader {
                id: iconFont
                source: "qrc:/new/prefix1/fonts/fontawesome-free-6.7.2-desktop/otfs/Font Awesome 6 Free-Solid-900.otf"
            }
            Text {
                visible: root.charging
                text: "\uf0e7" // bolt
                font.family: iconFont.name
                font.pixelSize: 16
                color: "#FBC557"
                anchors.centerIn: parent
            }

            // 动态重绘
            Connections {
                target: theme
                enabled: !!theme
                ignoreUnknownSignals: true
                function onFocusColorChanged() { ring.requestPaint() }
                function onTextColorChanged() { ring.requestPaint() }
                function onIsDarkChanged() { ring.requestPaint() }
            }
            Component.onCompleted: ring.requestPaint()
            onVisibleChanged: if (visible) ring.requestPaint()
            onWidthChanged: ring.requestPaint()
            onHeightChanged: ring.requestPaint()
        }

        // 底部百分比
        Text {
            text: pctText
            color: textColor
            font.pixelSize: 14
            horizontalAlignment: Text.AlignHCenter
            width: parent.width
        }
    }
}

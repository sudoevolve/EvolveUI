import QtQuick
import QtQuick.Controls
import QtQuick.Effects

/*
  EFitnessProgress.qml
  圆弧进度条（步数/里程等目标进度）
  - 显示顶部标题、中心数值 + 单位、底部图标
  - 粗圆弧进度，圆角端点，带发光效果
*/

Rectangle {
    id: root

    // === 接口属性 ===
    property int goal: 100            // 总目标
    property real value: 60           // 当前值
    property string unit: "KM"        // 单位（例如：步、KM、cal）
    property string title: "WEEKLY GOAL"
    property color progressColor: theme.focusColor          // 当 theme 未传入时使用
    property color trackColor: Qt.rgba(0.6, 0.6, 0.6, 0.55)
    property int ringWidth: 26
    // 阴影控制
    property bool shadowEnabled: true
    property color shadowColor: theme.shadowColor

    // 进度（0-1）
    readonly property real progressRatio: Math.max(0, Math.min(1, goal > 0 ? value / goal : 0))

    // 圆弧角度（以 Canvas 的 0°=3点方向，顺时针为正）
    // 图示类似上方略过底部的半环，这里默认覆盖约 240°
    property real arcStartDeg: -210
    property real arcSpanDeg: 240

    // === 尺寸与样式 ===
    width: 240
    height: 240
    radius: 28
    color: theme.secondaryColor
    antialiasing: true
    // 卡片阴影
    layer.enabled: root.shadowEnabled
    layer.effect: MultiEffect {
        shadowEnabled: root.shadowEnabled
        shadowColor: root.shadowColor
        shadowBlur: theme.shadowBlur
        shadowHorizontalOffset: theme.shadowXOffset
        shadowVerticalOffset: theme.shadowYOffset
    }

    // 图标字体（Font Awesome 6 Free Solid）
    FontLoader {
        id: iconFont
        source: "qrc:/new/prefix1/fonts/fontawesome-free-6.7.2-desktop/otfs/Font Awesome 6 Free-Solid-900.otf"
    }
    property string iconCharacter: "\uf206" // 默认自行车（fa-bicycle）

    // 顶部标题
    Text {
        text: root.title
        anchors.horizontalCenter: parent.horizontalCenter
        anchors.top: parent.top
        anchors.topMargin: 10
        color: theme.textColor
        font.pixelSize: 12
        font.bold: true
        opacity: 0.95
    }

    // 主绘制层：底轨 + 进度弧
    Canvas {
        id: arcCanvas
        anchors.fill: parent
        anchors.margins: 26
        antialiasing: true
        smooth: true

        onPaint: {
            const ctx = getContext("2d")
            ctx.reset()
            const w = width
            const h = height
            const cx = w / 2
            const cy = h / 2
            const r = Math.min(w, h) / 2 - root.ringWidth / 2

            function deg2rad(d) { return d * Math.PI / 180.0 }
            const start = deg2rad(root.arcStartDeg)
            const span = deg2rad(root.arcSpanDeg)
            const end = start + span
            const progEnd = start + span * root.progressRatio

            // 底轨
            ctx.beginPath()
            ctx.lineWidth = root.ringWidth
            ctx.strokeStyle = Qt.rgba(theme.textColor.r, theme.textColor.g, theme.textColor.b, 0.35)
            ctx.lineCap = "round"
            ctx.arc(cx, cy, r, start, end, false)
            ctx.stroke()

            // 进度
            ctx.beginPath()
            ctx.lineWidth = root.ringWidth
            ctx.strokeStyle = theme.focusColor
            ctx.lineCap = "round"
            ctx.arc(cx, cy, r, start, progEnd, false)
            ctx.stroke()
        }
    }

    // 发光效果（围绕进度弧）
    MultiEffect {
        anchors.fill: arcCanvas
        source: arcCanvas
        shadowEnabled: true
        shadowColor: Qt.rgba(theme.focusColor.r, theme.focusColor.g, theme.focusColor.b, 0.7)
        shadowBlur: 26
        shadowHorizontalOffset: 0
        shadowVerticalOffset: 0
        autoPaddingEnabled: false
        opacity: 0.9
    }

    // 中心数值
    Text {
        id: centerValue
        text: Math.round(root.value) + root.unit
        anchors.horizontalCenter: parent.horizontalCenter
        anchors.verticalCenter: parent.verticalCenter
        color: theme.textColor
        font.pixelSize: 40
        font.bold: true
        opacity: 0.98
    }

    // 目标数值标签（位于弧末端附近）
    Item {
        id: goalLabel
        width: 32
        height: 24
        anchors.horizontalCenter: parent.horizontalCenter
        anchors.bottom: parent.bottom
        anchors.bottomMargin: 60

        Rectangle {
            anchors.fill: parent
            radius: 12
            color: Qt.rgba(0.4, 0.4, 0.4, 0.7)
            antialiasing: true

            Text {
                anchors.centerIn: parent
                text: root.goal
                color: theme.textColor
                font.pixelSize: 12
                font.bold: true
            }
        }
    }

    // 底部图标
    Text {
        anchors.horizontalCenter: parent.horizontalCenter
        anchors.bottom: parent.bottom
        anchors.bottomMargin: 20
        text: root.iconCharacter
        font.family: iconFont.name
        font.pixelSize: 28
        color: theme.textColor
        opacity: 0.95
    }

    // === 触发重绘：值与尺寸变化 ===
    Component.onCompleted: arcCanvas.requestPaint()
    onValueChanged: arcCanvas.requestPaint()
    onGoalChanged: arcCanvas.requestPaint()
    onProgressRatioChanged: arcCanvas.requestPaint()
    onArcStartDegChanged: arcCanvas.requestPaint()
    onArcSpanDegChanged: arcCanvas.requestPaint()
    onRingWidthChanged: arcCanvas.requestPaint()
    onWidthChanged: arcCanvas.requestPaint()
    onHeightChanged: arcCanvas.requestPaint()

    // === 触发重绘：主题颜色变化 ===
    Connections {
        target: theme
        enabled: !!theme
        ignoreUnknownSignals: true
        function onFocusColorChanged() { arcCanvas.requestPaint() }
        function onTextColorChanged() { arcCanvas.requestPaint() }
        function onIsDarkChanged() { arcCanvas.requestPaint() }
    }
}

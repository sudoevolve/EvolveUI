import QtQuick
import QtQuick.Controls
import QtQuick.Effects

/*
  ENextHolidayCountdown.qml
  最近节假日到来时间组件：显示最近的节假日日期（MM/DD + 星期几）、名称与剩余天数。
  颜色风格参考 EClock：theme.secondaryColor、theme.textColor、theme.focusColor。

  默认内置几个示例节日（阳历）：
  - 元旦：1/1
  - 劳动节：5/1
  - 国庆节：10/1

  你可以通过 `holidays` 属性自定义节日列表。
*/

Item {
    id: root
    width: 260
    height: 90

    // === 样式 ===
    property color faceColor: theme.secondaryColor
    property color textColor: theme.textColor
    property color accentColor: theme.focusColor
    // 阴影
    property bool backgroundVisible: true
    property bool shadowEnabled: true
    property color shadowColor: theme.shadowColor

    // === 节日数据 ===
    // 网络API（TimelessQ）：https://api.timelessq.com/time/festival
    // 每项最终结构：{ name: "国庆节", month: 10, day: 1 }
    property bool useNetwork: true
    property int apiYear: now.getFullYear()
    property string countryCode: "CN" // 保留（若切换到其他接口需要国家码）
    property string apiUrl: "https://api.timelessq.com/time/festival"
    property bool loading: false
    property string errorMessage: ""

    // 回退本地列表（网络失败时使用）
    property var holidaysFallback: [
        { name: "元旦", month: 1, day: 1 },
        { name: "劳动节", month: 5, day: 1 },
        { name: "国庆节", month: 10, day: 1 }
    ]
    property var holidays: holidaysFallback

    property date now: new Date()
    property var nextHolidayInfo: findNextHoliday(now)

    function pad2(n) { return (n < 10 ? "0" : "") + n }
    function weekdayStr(d) {
        const arr = ["周日", "周一", "周二", "周三", "周四", "周五", "周六"]
        return arr[d.getDay()]
    }

    function findNextHoliday(refDate) {
        const y = refDate.getFullYear()
        let best = null
        for (let i = 0; i < holidays.length; i++) {
            const h = holidays[i]
            let candidate = new Date(y, h.month - 1, h.day)
            if (candidate < refDate) {
                candidate = new Date(y + 1, h.month - 1, h.day)
            }
            const diffDays = Math.ceil((candidate - refDate) / (24 * 3600 * 1000))
            if (!best || diffDays < best.diffDays) {
                best = { name: h.name, date: candidate, diffDays: diffDays }
            }
        }
        return best
    }

    function updateNextHolidayInfo() {
        nextHolidayInfo = findNextHoliday(now)
    }

    function fetchHolidays() {
        if (!useNetwork) { holidays = holidaysFallback; updateNextHolidayInfo(); return }
        loading = true
        errorMessage = ""
        console.log("[Holiday] Fetching:", apiUrl)
        const xhr = new XMLHttpRequest()
        xhr.open("GET", apiUrl)
        xhr.onreadystatechange = function() {
            if (xhr.readyState === XMLHttpRequest.DONE) {
                loading = false
                console.log("[Holiday] Status:", xhr.status)
                if (xhr.status === 200) {
                    try {
                        const payload = JSON.parse(xhr.responseText)
                        // TimelessQ 返回 { errno, errmsg, data: [...] }
                        const arr = Array.isArray(payload) ? payload : (payload.data || [])
                        const parsed = []
                        for (let i = 0; i < arr.length; i++) {
                            const h = arr[i]
                            if (!h) continue
                            // 兼容两种接口字段：TimelessQ: day="YYYY-MM-DD"；Nager: date="YYYY-MM-DD"
                            const dateStr = h.day || h.date
                            if (!dateStr) continue
                            const parts = String(dateStr).split("-")
                            if (parts.length !== 3) continue
                            const month = Number(parts[1])
                            const day = Number(parts[2])
                            const name = h.name || h.localName || ""
                            parsed.push({ name: name, month: month, day: day })
                        }
                        if (parsed.length > 0) {
                            holidays = parsed
                            console.log("[Holiday] Parsed count:", parsed.length)
                            errorMessage = ""
                        } else {
                            holidays = holidaysFallback
                            errorMessage = "未获取到节日数据，已使用本地列表"
                            console.warn("[Holiday] Empty parsed list, falling back")
                        }
                    } catch (e) {
                        holidays = holidaysFallback
                        errorMessage = "解析节日数据失败，已使用本地列表"
                        console.error("[Holiday] Parse error:", e)
                    }
                } else {
                    holidays = holidaysFallback
                    errorMessage = "节日接口请求失败(" + xhr.status + ")，已使用本地列表"
                    console.error("[Holiday] Request failed:", xhr.status)
                }
                updateNextHolidayInfo()
            }
        }
        xhr.send()
    }

    readonly property string dateLine: (nextHolidayInfo ? pad2(nextHolidayInfo.date.getMonth()+1) + "/" + pad2(nextHolidayInfo.date.getDate()) + " - " + weekdayStr(nextHolidayInfo.date) : "--/--")
    readonly property string nameLine: (nextHolidayInfo ? nextHolidayInfo.name : "")
    readonly property string remainLine: (nextHolidayInfo ? ("还有" + nextHolidayInfo.diffDays + "天") : "")

    // 更新时间：每小时（同时检查跨年自动更新 API 年份）
    Timer {
        interval: 3600000
        running: true
        repeat: true
        onTriggered: {
            root.now = new Date()
            if (root.now.getFullYear() !== apiYear) apiYear = root.now.getFullYear()
            updateNextHolidayInfo()
        }
    }

    onApiYearChanged: fetchHolidays()
    onCountryCodeChanged: fetchHolidays()
    onHolidaysChanged: updateNextHolidayInfo()
    onNowChanged: updateNextHolidayInfo()
    Component.onCompleted: { fetchHolidays(); updateNextHolidayInfo() }

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

    Rectangle {
        id: background
        anchors.fill: parent
        radius: 12
        color: faceColor
        visible: root.backgroundVisible
    }

    Row {
        anchors.fill: parent
        anchors.margins: 12
        spacing: 24

        // 左侧日期与文字
        Column {
            spacing: 6
            width: parent.width - ringContainer.width - 24
            Text {
                text: "最近节假日"
                color: textColor
                font.pixelSize: 14
                font.bold: true
            }
            Row {
                spacing: 8
                Text {
                    text: dateLine
                    color: accentColor
                    font.pixelSize: 20
                    font.bold: true
                }
                Text {
                    text: nameLine
                    color: textColor
                    font.pixelSize: 12
                }
            }
            Text {
                text: remainLine
                color: textColor
                font.pixelSize: 12
            }
        }

        // 右侧小圆环（到达进度：距离/30天窗口的比例，仅作视觉参考）
        Item {
            id: ringContainer
            width: 36
            height: 36

            readonly property real windowDays: 30
            readonly property real ratio: {
                if (!nextHolidayInfo) return 0
                const r = Math.max(0, Math.min(1, 1.0 - nextHolidayInfo.diffDays / windowDays))
                return r
            }

            Canvas {
                id: ring
                anchors.fill: parent
                antialiasing: true
                onPaint: {
                    const ctx = getContext("2d")
                    ctx.reset()
                    const w = width, h = height
                    const cx = w/2, cy = h/2
                    const trackW = 5
                    const r = Math.min(w, h)/2 - trackW/2
                    const start = -Math.PI/2
                    const end = start + Math.PI*2
                    const prog = start + Math.PI*2*ringContainer.ratio

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
                    ctx.strokeStyle = accentColor
                    ctx.lineCap = "round"
                    ctx.arc(cx, cy, r, start, prog, false)
                    ctx.stroke()
                }
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
            Connections {
                target: root
                function onNextHolidayInfoChanged() { ring.requestPaint() }
            }
            Component.onCompleted: ring.requestPaint()
            onVisibleChanged: if (visible) ring.requestPaint()
            onWidthChanged: ring.requestPaint()
            onHeightChanged: ring.requestPaint()
        }
    }
}
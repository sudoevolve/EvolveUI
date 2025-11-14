import QtQuick
import QtQuick.Controls
import QtQuick.Effects

Item {
    id: root
    width: 420
    height: 160

    // === 样式 ===
    property color faceColor: theme.secondaryColor
    property real radius: 24
    property bool backgroundVisible: true
    property bool shadowEnabled: true
    property color shadowColor: theme.shadowColor

    // === 一言数据 ===
    property bool useNetworkQuote: true
    property string quoteApiUrl: "https://v1.hitokoto.cn/?encode=json"
    property string quoteText: "加载中…"
    property string quoteFrom: ""
    property string quoteFromWho: ""
    // 每 12 小时刷新一次（单位：毫秒）
    property int quoteRefreshIntervalMs: 12 * 60 * 60 * 1000

    // === 背景图片源（改为 loliapi 随机图片） ===
    property string acgApiUrl: "https://www.loliapi.com/acg/"
    property string bingImageUrl: "" // 实际使用 acgApiUrl 返回的图片
    property string imageDirectUrl: "" // 记录最终解析出的直链，用于外部跳转
    // 每天刷新一次背景（单位：毫秒）
    property int bingRefreshIntervalMs: 24 * 60 * 60 * 1000

    // 阴影（仅作用于背景容器）
    layer.enabled: shadowEnabled && backgroundVisible
    layer.effect: MultiEffect {
        shadowEnabled: root.shadowEnabled && root.backgroundVisible
        shadowColor: root.shadowColor
        shadowBlur: theme.shadowBlur
        shadowHorizontalOffset: theme.shadowXOffset
        shadowVerticalOffset: theme.shadowYOffset
    }

    // === 背景容器与遮罩（与音乐播放器一致的图片遮罩） ===
    Item {
        id: backgroundContainer
        anchors.fill: parent
        clip: true

        // 纯色回退背景
        Rectangle {
            id: fallbackBackground
            anchors.fill: parent
            color: faceColor
            radius: root.radius
            visible: root.backgroundVisible
            antialiasing: true
        }

        // 原始 Bing 图像，隐藏，仅作为 MultiEffect 的 source
        Image {
            id: bingSource
            anchors.fill: parent
            source: root.bingImageUrl
            fillMode: Image.PreserveAspectCrop
            cache: false
            visible: false
            antialiasing: true
            smooth: true
            asynchronous: true
            mipmap: true
            sourceSize: Qt.size(Math.round(width), Math.round(height))

            // 当随机图为 WebP 且当前环境不支持解码时，自动回退到 Bing 壁纸
            onStatusChanged: {
                if (status === Image.Error) {
                    fetchBingImageFallback()
                }
            }
        }

        // 图片遮罩（与音乐播放器相同思路）
        MultiEffect {
            id: bingMasked
            source: bingSource
            anchors.fill: bingSource
            visible: root.backgroundVisible && root.bingImageUrl !== ""
            maskEnabled: true
            maskSource: backgroundMask
        }

        // 圆角遮罩图形
        Item {
            id: backgroundMask
            anchors.fill: bingSource
            layer.enabled: true
            layer.smooth: true
            layer.samples: 4
            visible: false
            Rectangle {
                anchors.fill: parent
                radius: root.radius
                color: "black"
                antialiasing: true
                smooth: true
            }
        }

        // 加载占位：主题色三点动画（图片未就绪时显示）
        ELoader {
            anchors.centerIn: parent
            size: 50
            speed: 0.8
            color: theme ? theme.focusColor : "#5D3FD3"
            visible: root.backgroundVisible && (bingSource.status !== Image.Ready || root.bingImageUrl === "")
            z: 1.5
        }

        // 叠加半透明主题色，避免过亮/过透明（与音乐播放器一致）
        Rectangle {
            anchors.fill: parent
            anchors.margins: -0.5
            radius: root.radius
            visible: root.backgroundVisible && root.bingImageUrl !== ""
            color: theme.blurOverlayColor
            z: 1
            opacity: 1.0
        }
    }

    // === 文本内容与交互 ===
    Item {
        id: contentLayer
        anchors.fill: parent
        z: 2

        // 图标字体（Font Awesome 6 Free Solid）
        FontLoader {
            id: iconFont
            source: "qrc:/new/prefix1/fonts/fontawesome-free-6.7.2-desktop/otfs/Font Awesome 6 Free-Solid-900.otf"
        }

        // 主文案（顶部到作者之上的区域）
        Text {
            id: quote
            anchors.left: parent.left
            anchors.top: parent.top
            anchors.right: parent.right
            anchors.margins: 16
            anchors.rightMargin: 40 // 留出右上角跳转图标的空间，避免挤在一起
            anchors.bottom: authorRow.top
            anchors.bottomMargin: 8
            text: quoteText
            color: theme.textColor
            wrapMode: Text.WordWrap
            maximumLineCount: 3
            elide: Text.ElideRight
            font.pixelSize: 18
            font.bold: true
        }

        // 作者信息（右下角）
        Row {
            id: authorRow
            anchors.right: parent.right
            anchors.bottom: parent.bottom
            anchors.margins: 12
            spacing: 6
            visible: (quoteFrom !== "" || quoteFromWho !== "")
            Text { text: "—"; color: theme.textColor; font.pixelSize: 14 }
            Text {
                text: quoteFromWho !== "" ? quoteFromWho + (quoteFrom !== "" ? " · " + quoteFrom : "") : quoteFrom
                color: theme.textColor
                font.pixelSize: 14
                opacity: 0.85
            }
        }

        // 点击刷新一言
        MouseArea {
            anchors.fill: parent
            z: 3
            hoverEnabled: true
            cursorShape: Qt.PointingHandCursor
            onClicked: {
                // 同时刷新文案与背景图片
                fetchQuote()
                fetchBingImage()
            }
        }

        // 跳转到当前背景图片网页的图标（右上角）
        Text {
            id: openImageIcon
            text: "\uf08e" // FontAwesome: external-link
            font.family: iconFont.name
            font.pixelSize: 16
            color: theme.textColor
            opacity: 0.9
            anchors.top: parent.top
            anchors.right: parent.right
            anchors.topMargin: 12
            anchors.rightMargin: 12
            z: 4
            // 点击打开图片链接
            MouseArea {
                anchors.fill: parent
                hoverEnabled: true
                cursorShape: Qt.PointingHandCursor
                onPressed: openImageIcon.opacity = 0.7
                onReleased: openImageIcon.opacity = 0.9
                onCanceled: openImageIcon.opacity = 0.9
                onClicked: Qt.openUrlExternally(root.imageDirectUrl || root.bingImageUrl)
            }
        }
    }

    // === Hitokoto 拉取 ===
    function fetchQuote() {
        if (!useNetworkQuote) return
        try {
            const xhr = new XMLHttpRequest()
            xhr.open("GET", quoteApiUrl + "&_=" + Date.now())
            xhr.onreadystatechange = function() {
                if (xhr.readyState === XMLHttpRequest.DONE) {
                    if (xhr.status === 200) {
                        try {
                            const payload = JSON.parse(xhr.responseText)
                            root.quoteText = payload.hitokoto || "(无内容)"
                            root.quoteFrom = payload.from || ""
                            root.quoteFromWho = payload.from_who || ""
                        } catch (e) {
                            console.error("[Hitokoto] Parse error:", e)
                        }
                    } else {
                        console.warn("[Hitokoto] Request failed:", xhr.status)
                    }
                }
            }
            xhr.send()
        } catch (err) {
            console.error("[Hitokoto] Fetch error:", err)
        }
    }

    // === Bing 背景拉取 ===
    function fetchBingImage() {
        // 先尝试获取最终跳转后的直链，确保外部打开与当前显示一致
        try {
            const xhr = new XMLHttpRequest()
            xhr.open("GET", root.acgApiUrl + "?_=" + Date.now())
            xhr.onreadystatechange = function() {
                if (xhr.readyState === XMLHttpRequest.DONE) {
                    if (xhr.status === 200) {
                        const finalUrl = xhr.responseURL || ""
                        if (finalUrl && finalUrl.length > 0) {
                            root.bingImageUrl = finalUrl
                            root.imageDirectUrl = finalUrl
                        } else {
                            // 无法获取直链则仍使用随机端点
                            const url = root.acgApiUrl + "?_=" + Date.now()
                            root.bingImageUrl = url
                            root.imageDirectUrl = url
                        }
                    } else {
                        console.warn("[ACG] Request failed:", xhr.status)
                    }
                }
            }
            xhr.send()
        } catch (err) {
            console.error("[ACG] XHR error:", err)
            const url = root.acgApiUrl + "?_=" + Date.now()
            root.bingImageUrl = url
            root.imageDirectUrl = url
        }
    }

    // Bing 回退：当 loliapi 返回 WebP 且环境未部署解码插件时触发
    function fetchBingImageFallback() {
        try {
            const xhr = new XMLHttpRequest()
            const url = "https://www.bing.com/HPImageArchive.aspx?format=js&idx=0&n=1&mkt=en-US&_=" + Date.now()
            xhr.open("GET", url)
            xhr.onreadystatechange = function() {
                if (xhr.readyState === XMLHttpRequest.DONE) {
                    if (xhr.status === 200) {
                        try {
                            const res = JSON.parse(xhr.responseText)
                            if (res && res.images && res.images.length > 0) {
                                const rel = res.images[0].url
                                const direct = "https://www.bing.com" + rel
                                root.bingImageUrl = direct
                                root.imageDirectUrl = direct
                            }
                        } catch (e) {
                            console.error("[Bing Fallback] Parse error:", e)
                        }
                    } else {
                        console.warn("[Bing Fallback] Request failed:", xhr.status)
                    }
                }
            }
            xhr.send()
        } catch (err) {
            console.error("[Bing Fallback] Fetch error:", err)
        }
    }

    // 每 12 小时刷新一句话
    Timer {
        interval: quoteRefreshIntervalMs
        running: useNetworkQuote
        repeat: true
        onTriggered: fetchQuote()
    }

    // 每天刷新背景
    Timer {
        interval: bingRefreshIntervalMs
        running: true
        repeat: true
        onTriggered: fetchBingImage()
    }

    // 生命周期
    Component.onCompleted: {
        if (useNetworkQuote) fetchQuote()
        fetchBingImage()
    }
}

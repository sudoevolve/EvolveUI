// MusicWindow.qml
import QtQuick
import QtQuick.Controls
import QtQuick.Effects
//  C++ 侧读取歌词
import MusicLibrary 1.0

    Item {
        id: root
        anchors.fill: parent
        clip: true

        

        // 主题从外部传入
        property var theme

    // 音乐窗口作用域数据（外部 EAnimatedWindow 传入）
    property string coverImage: ""
    property bool coverIsDefault: false
    property string title: "未知歌曲"
    property string artist: "未知艺术家"
    property var sourceItem: null
    // 歌词数据：解析自 LRC，[{ t:毫秒, text:字符串 }]
        property var lyricsEntries: []
        property int currentLyricIndex: -1
        property bool lyricsAvailable: false
        property string lyricsFilePath: ""
        property bool isLyricScrolling: false
    // 封面显示控制：
    property string displayCoverImage: ""
    property bool displayCoverIsDefault: true
    property string pendingCoverUrl: ""
    property int coverFadeDuration: 1920
    property string circleCoverImage: ""
    property int coverCircleTex: 340
        property int coverTexW: 256
        property int coverTexH: 144

    // 首次进入或外部赋值 sourceItem 时，初始化文案/歌词/封面
        onSourceItemChanged: {
        if (!sourceItem) {
            title = "未知歌曲"
            artist = "未知艺术家"
            displayCoverIsDefault = true
            displayCoverImage = ""
            pendingCoverUrl = ""
            lyricsEntries = []
            lyricsAvailable = false
            lyricsFilePath = ""
            currentLyricIndex = -1
            return
        }

        onCurrentLyricIndexChanged: {
            isLyricScrolling = true
            lyricScrollFlagTimer.restart()
        }

        if (typeof sourceItem.songTitle === "string") title = sourceItem.songTitle
        if (typeof sourceItem.artistName === "string") artist = sourceItem.artistName

        // 初始化封面
        if (sourceItem.coverImageIsDefault) {
            displayCoverIsDefault = true
            displayCoverImage = ""
            pendingCoverUrl = ""
            circleCoverImage = ""
        } else if (sourceItem.coverImage && sourceItem.coverImage.length > 0) {
            if (!displayCoverImage || displayCoverImage.length === 0) {
                displayCoverImage = sourceItem.coverImage
                displayCoverIsDefault = false
                pendingCoverUrl = ""
                circleCoverImage = sourceItem.coverImage
            } else {
                pendingCoverUrl = sourceItem.coverImage
                nextCoverLoader.source = pendingCoverUrl
            }
        }

        // 初始化歌词与当前位置
        loadLyricsForSource(sourceItem.source)
        if (typeof sourceItem.positionMs === "number") {
            updateLyricIndex(sourceItem.positionMs)
        }
    }

    Component.onCompleted: {
        if (!sourceItem) return
        if (typeof sourceItem.songTitle === "string") title = sourceItem.songTitle
        if (typeof sourceItem.artistName === "string") artist = sourceItem.artistName
        loadLyricsForSource(sourceItem.source)
        if (typeof sourceItem.positionMs === "number") updateLyricIndex(sourceItem.positionMs)
        if (sourceItem.coverImageIsDefault) {
            displayCoverIsDefault = true
            displayCoverImage = ""
            pendingCoverUrl = ""
        } else if (sourceItem.coverImage && sourceItem.coverImage.length > 0) {
            // 启动时若已有封面，直接显示，再由预加载机制处理后续切换
            displayCoverImage = sourceItem.coverImage
            displayCoverIsDefault = false
            pendingCoverUrl = ""
        }
        circleCoverImage = displayCoverImage
    }

    // C++侧音乐库对象用于可靠读取本地歌词文件
    MusicLibrary {
        id: musicLib
    }

    // 解析 LRC 文本为时间戳 + 行文本
    function parseLrc(lrcText) {
        var entries = []
        var offsetMs = 0
        var lines = lrcText.split(/\r?\n/)
        for (var i = 0; i < lines.length; i++) {
            var line = lines[i].trim()
            if (line.length === 0) continue

            // 处理 offset 标签
            var offsetMatch = line.match(/^\[offset:([-+]?\d+)\]$/i)
            if (offsetMatch) {
                offsetMs = parseInt(offsetMatch[1]) || 0
                continue
            }

            // 匹配多个时间戳的行，如 [00:12.34][00:15.00]歌词
            var tsRegex = /\[(\d{1,2}):(\d{1,2})(?:[.:](\d{1,3}))?\]/g
            var textPart = line.replace(tsRegex, "").trim()
            if (textPart.length === 0) continue

            var m
            tsRegex.lastIndex = 0
            while ((m = tsRegex.exec(line)) !== null) {
                var mm = parseInt(m[1]) || 0
                var ss = parseInt(m[2]) || 0
                var cs = m[3] ? m[3] : "0"
                // 归一化毫秒（支持两位/三位小数）
                var ms = 0
                if (cs.length === 3) ms = parseInt(cs)
                else if (cs.length === 2) ms = parseInt(cs) * 10
                else ms = parseInt(cs) * 100
                var t = mm * 60000 + ss * 1000 + ms + offsetMs
                if (t < 0) t = 0
                entries.push({ t: t, text: textPart })
            }
        }
        // 按时间排序并去重空白
        entries.sort(function(a, b) { return a.t - b.t })
        return entries
    }

    // 根据音源路径推断并加载同名 .lrc 文件
    function loadLyricsForSource(src) {
        if (!src || src.length === 0) {
            lyricsEntries = []
            lyricsAvailable = false
            lyricsFilePath = ""
            currentLyricIndex = -1
            return
        }

        // 使用 C++ 侧读取歌词文本
        var raw = musicLib.loadLyricsText(src)
        var lrcFileUrl = musicLib.findLyricsFileForSource(src)
        if (raw && raw.length > 0) {
            var parsed = parseLrc(raw)
            if (parsed && parsed.length > 0) {
                lyricsEntries = parsed
                lyricsAvailable = true
                lyricsFilePath = lrcFileUrl
                // 加载完成后，立即根据当前播放进度定位到对应歌词行，避免重新打开时回到顶部
                if (sourceItem && typeof sourceItem.positionMs === "number") {
                    updateLyricIndex(sourceItem.positionMs)
                    // 在视图下一帧确保定位到当前索引
                    Qt.callLater(function() {
                        if (lyricList && currentLyricIndex >= 0) {
                            lyricList.positionViewAtIndex(currentLyricIndex, ListView.Center)
                        }
                    })
                }
                return
            }
        }

        // 未找到或解析失败：清空并显示占位
        lyricsEntries = []
        lyricsAvailable = false
        lyricsFilePath = lrcFileUrl
        currentLyricIndex = -1
    }

    // 移除 QML 端文件回退读取，统一走 C++ 端

    // 根据毫秒进度更新当前歌词行
    function updateLyricIndex(posMs) {
        if (!lyricsAvailable || lyricsEntries.length === 0) {
            currentLyricIndex = -1
            return
        }
        // 从当前索引向前后逼近，避免每次线性扫描
        var idx = currentLyricIndex
        if (idx < 0) idx = 0
        // 向后推进
        while (idx + 1 < lyricsEntries.length && lyricsEntries[idx + 1].t <= posMs) {
            idx++
        }
        // 如播放进度回退，向前退
        while (idx > 0 && lyricsEntries[idx].t > posMs) {
            idx--
        }
        currentLyricIndex = idx
    }

    // 格式化时间（秒 -> mm:ss）
    function formatTime(seconds) {
        var s = Math.max(0, Math.floor(seconds || 0))
        var m = Math.floor(s / 60)
        var ss = s % 60
        return (m < 10 ? "" + m : "" + m) + ":" + (ss < 10 ? "0" + ss : "" + ss)
    }

    FontLoader {
        id: iconFont
        source: "qrc:/new/prefix1/fonts/fontawesome-free-6.7.2-desktop/otfs/Font Awesome 6 Free-Solid-900.otf"
    }

    Timer {
        id: lyricScrollFlagTimer
        interval: 900
        repeat: false
        onTriggered: root.isLyricScrolling = false
    }

    // 纯色底（始终存在，作为模糊封面之下的回退层）
    Rectangle {
        anchors.fill: parent
        color: theme ? theme.secondaryColor : "#222"
        radius: 20
    }

    // 原始专辑封面图像源（隐藏，仅用于 MultiEffect 模糊）
    Image {
        id: fullscreenCoverSource
        anchors.fill: parent
        visible: false
        source: displayCoverIsDefault ? "" : displayCoverImage
        fillMode: Image.PreserveAspectCrop
        cache: true
        asynchronous: false
        antialiasing: true
        smooth: true
        mipmap: false
        sourceSize: Qt.size(coverTexW, coverTexH)
    }
    Image {
        id: fullscreenCoverSourceNext
        anchors.fill: parent
        visible: false
        source: ""
        fillMode: Image.PreserveAspectCrop
        cache: true
        asynchronous: false
        antialiasing: true
        smooth: true
        mipmap: false
        sourceSize: Qt.size(coverTexW, coverTexH)
    }

    // 下一个封面预加载（隐藏），准备好后再切换
    Image {
        id: nextCoverLoader
        anchors.fill: parent
        visible: false
        source: pendingCoverUrl
        fillMode: Image.PreserveAspectCrop
        cache: true
        asynchronous: false
        antialiasing: true
        smooth: true
        mipmap: false
        sourceSize: Qt.size(coverTexW, coverTexH)
        onStatusChanged: {
            if (status === Image.Ready && pendingCoverUrl && pendingCoverUrl.length > 0) {
                fullscreenCoverSourceNext.source = pendingCoverUrl
                fullscreenCoverBlurNext.visible = true
                fullscreenCoverBlurNext.opacity = 0
                coverCrossFadeAnim.restart()
                circleCoverImage = pendingCoverUrl
            }
        }
    }

    // 模糊封面背景
    MultiEffect {
        id: fullscreenCoverBlur
        anchors.fill: parent
        source: fullscreenCoverSource
        visible: (!displayCoverIsDefault && displayCoverImage !== "") || fullscreenCoverBlurNext.visible
        opacity: (!displayCoverIsDefault && displayCoverImage !== "") ? 1 : 0
        blurEnabled: true
        blur: 1.0
        blurMax: 64
        blurMultiplier: 2.0
        autoPaddingEnabled: false
    }
    MultiEffect {
        id: fullscreenCoverBlurNext
        anchors.fill: parent
        source: fullscreenCoverSourceNext
        visible: false
        opacity: 0
        blurEnabled: true
        blur: 1.0
        blurMax: 64
        blurMultiplier: 2.0
        autoPaddingEnabled: false
    }

    ParallelAnimation {
        id: coverCrossFadeAnim
        running: false
        NumberAnimation { target: fullscreenCoverBlurNext; property: "opacity"; from: fullscreenCoverBlurNext.opacity; to: 1; duration: coverFadeDuration; easing.type: Easing.OutCubic }
        NumberAnimation { target: fullscreenCoverBlur; property: "opacity"; from: fullscreenCoverBlur.opacity; to: 0; duration: coverFadeDuration; easing.type: Easing.OutCubic }
        onStopped: {
            if (fullscreenCoverBlurNext.visible && fullscreenCoverBlurNext.opacity >= 1) {
                displayCoverImage = pendingCoverUrl
                displayCoverIsDefault = false
                fullscreenCoverSource.source = displayCoverImage
                fullscreenCoverBlur.opacity = 1
                fullscreenCoverBlurNext.opacity = 0
                fullscreenCoverBlurNext.visible = false
                fullscreenCoverSourceNext.source = ""
                pendingCoverUrl = ""
            }
        }
    }

    // 半透明主题色叠加，压制过亮/过透明
    Rectangle {
        anchors.fill: parent
        color: theme ? theme.blurOverlayColor : Qt.rgba(0,0,0,0.3)
        visible: (!displayCoverIsDefault && displayCoverImage !== "") || fullscreenCoverBlurNext.visible
        z: 2
        opacity: 1.0
    }

    // 横向渐变遮罩（左透明到右纯色）
    Rectangle {
        anchors.fill: parent
        z: 1
        antialiasing: true
        smooth: true
        layer.enabled: true
        layer.smooth: true
        layer.samples: 8
        layer.textureSize: Qt.size(Math.round(width), Math.round(height))
        gradient: Gradient {
            orientation: Gradient.Horizontal
            GradientStop { position: 0.00; color: Qt.rgba(theme.secondaryColor.r, theme.secondaryColor.g, theme.secondaryColor.b, 0.00) }
            GradientStop { position: 0.01; color: Qt.rgba(theme.secondaryColor.r, theme.secondaryColor.g, theme.secondaryColor.b, 0.05) }
            GradientStop { position: 0.02; color: Qt.rgba(theme.secondaryColor.r, theme.secondaryColor.g, theme.secondaryColor.b, 0.10) }
            GradientStop { position: 0.04; color: Qt.rgba(theme.secondaryColor.r, theme.secondaryColor.g, theme.secondaryColor.b, 0.16) }
            GradientStop { position: 0.06; color: Qt.rgba(theme.secondaryColor.r, theme.secondaryColor.g, theme.secondaryColor.b, 0.22) }
            GradientStop { position: 0.10; color: Qt.rgba(theme.secondaryColor.r, theme.secondaryColor.g, theme.secondaryColor.b, 0.30) }
            GradientStop { position: 0.15; color: Qt.rgba(theme.secondaryColor.r, theme.secondaryColor.g, theme.secondaryColor.b, 0.38) }
            GradientStop { position: 0.20; color: Qt.rgba(theme.secondaryColor.r, theme.secondaryColor.g, theme.secondaryColor.b, 0.48) }
            GradientStop { position: 0.25; color: Qt.rgba(theme.secondaryColor.r, theme.secondaryColor.g, theme.secondaryColor.b, 0.58) }
            GradientStop { position: 0.30; color: Qt.rgba(theme.secondaryColor.r, theme.secondaryColor.g, theme.secondaryColor.b, 0.68) }
            GradientStop { position: 0.60; color: Qt.rgba(theme.secondaryColor.r, theme.secondaryColor.g, theme.secondaryColor.b, 0.73) }
            GradientStop { position: 0.75; color: Qt.rgba(theme.secondaryColor.r, theme.secondaryColor.g, theme.secondaryColor.b, 0.78) }
            GradientStop { position: 0.90; color: Qt.rgba(theme.secondaryColor.r, theme.secondaryColor.g, theme.secondaryColor.b, 0.89) }
            GradientStop { position: 1.00; color: theme.secondaryColor }
        }
    }
    

    // 左侧封面
    Item {
        id: rotatingCoverContainer
        anchors.left: parent.left
        anchors.leftMargin: 160
        anchors.verticalCenter: parent.verticalCenter
        width: Math.round(Math.min(parent.height * 0.42, parent.width * 0.32))
        height: width
        z: 4
        visible: circleCoverImage !== ""
        transformOrigin: Item.Center
        property real breatheScale: 1.0
        scale: breatheScale

        ParallelAnimation {
            id: coverBreathe
            running: coverArea.containsMouse
            loops: Animation.Infinite
            SequentialAnimation {
                NumberAnimation { target: rotatingCoverContainer; property: "breatheScale"; from: 1.0; to: 1.03; duration: 1600; easing.type: Easing.InOutSine }
                NumberAnimation { target: rotatingCoverContainer; property: "breatheScale"; from: 1.03; to: 1.0; duration: 1600; easing.type: Easing.InOutSine }
            }
            SequentialAnimation {
                NumberAnimation { target: rotatingCoverContainer; property: "rotation"; from: -1.2; to: 1.2; duration: 2000; easing.type: Easing.InOutSine }
                NumberAnimation { target: rotatingCoverContainer; property: "rotation"; from: 1.2; to: -1.2; duration: 2000; easing.type: Easing.InOutSine }
            }
        }

        Behavior on breatheScale { NumberAnimation { duration: 240; easing.type: Easing.OutCubic } }
        Behavior on rotation { NumberAnimation { duration: 240; easing.type: Easing.OutCubic } }

        Image {
            id: rotatingCoverSource
            anchors.fill: parent
            source: circleCoverImage
            fillMode: Image.PreserveAspectCrop
            cache: true
            asynchronous: false
            visible: false
            antialiasing: true
            smooth: true
            mipmap: false
            sourceSize: Qt.size(coverCircleTex, coverCircleTex)
        }

        ShaderEffectSource {
            id: coverSESource
            sourceItem: rotatingCoverSource
            hideSource: true
            live: true
            smooth: true
            recursive: false
        }

        Item {
            id: rotatingCoverMask
            anchors.fill: parent
            visible: false
            layer.enabled: true
            Rectangle {
                anchors.fill: parent
                radius: 20
                color: "black"
            }
        }

        MultiEffect {
            id: rotatingCoverMasked
            anchors.fill: parent
            source: rotatingCoverSource
            maskEnabled: true
            maskSource: rotatingCoverMask
            autoPaddingEnabled: false
            maskThresholdMin: 0.5
            maskSpreadAtMin: 0.5
            transformOrigin: Item.Center
            z: 1
        }

        MultiEffect {
            anchors.fill: rotatingCoverMasked
            source: rotatingCoverMasked
            visible: circleCoverImage !== ""
            shadowEnabled: true
            shadowColor: theme.shadowColor
            shadowBlur: theme.shadowBlur
            shadowHorizontalOffset: theme.shadowXOffset
            shadowVerticalOffset: theme.shadowYOffset
        }


        // 点击封面：播放/暂停
        MouseArea {
            id: coverArea
            anchors.fill: parent
            hoverEnabled: true
            cursorShape: Qt.PointingHandCursor
            onPressed: {
                // 触发不移动的边框发光反馈
                coverGlowAnim.restart()
            }
            onExited: {
                rotatingCoverContainer.breatheScale = 1.0
                rotatingCoverContainer.rotation = 0
            }
            onClicked: {
                if (!sourceItem) return;
                if (sourceItem.isPlaying) {
                    // 触发暂停信号（由 EMusicPlayer 响应）
                    if (sourceItem.pauseClicked) sourceItem.pauseClicked();
                } else {
                    // 触发播放信号（由 EMusicPlayer 响应）
                    if (sourceItem.playClicked) sourceItem.playClicked();
                }
            }
        }

        // 悬停叠层提示：显示播放/暂停图标并轻微遮罩
        Item {
            id: coverHoverOverlay
            anchors.fill: parent
            z: 3
            // 仅在悬停或按压时淡入显示
            opacity: (coverArea.containsMouse || coverArea.pressed) ? 1.0 : 0.0
            Behavior on opacity { NumberAnimation { duration: 140; easing.type: Easing.OutQuad } }

            // 圆形半透明遮罩，匹配封面形状
            Rectangle {
                anchors.fill: parent
                radius: 20
                color: Qt.rgba(0, 0, 0, 0.09)
                antialiasing: true
                smooth: true
            }

            // 点击发光环（不移动的点击反馈）
            Rectangle {
                id: coverGlowRing
                anchors.fill: parent
                radius: 20
                color: "transparent"
                border.color: sourceItem ? sourceItem.coverProminentColor : (theme ? theme.focusColor : "#ffffff")
                border.width: 2
                opacity: 0.0
                antialiasing: true
                smooth: true
            }

            SequentialAnimation {
                id: coverGlowAnim
                running: false
                NumberAnimation { target: coverGlowRing; property: "opacity"; to: 0.35; duration: 90; easing.type: Easing.OutQuad }
                NumberAnimation { target: coverGlowRing; property: "opacity"; to: 0.0; duration: 240; easing.type: Easing.InQuad }
            }

            // 中心播放/暂停图标
            Text {
                anchors.centerIn: parent
                text: (sourceItem && sourceItem.isPlaying) ? "\uf04c" : "\uf04b"
                font.family: iconFont.name
                font.pixelSize: Math.round(Math.min(parent.width, parent.height) * 0.28)
                color: theme ? theme.textColor : "#ffffff"
                opacity: 0.35
                // 保持位置稳定：固定容器尺寸并居中绘制
                width: parent.width
                height: parent.height
                horizontalAlignment: Text.AlignHCenter
                verticalAlignment: Text.AlignVCenter
                Behavior on opacity { NumberAnimation { duration: 120; easing.type: Easing.OutQuad } }
            }
        }

    }

    // 无封面：显示音乐图标（居中）
    Item {
        anchors.fill: rotatingCoverContainer
        z: 3
        visible: displayCoverIsDefault || displayCoverImage === ""
        Text {
            anchors.centerIn: parent
            text: "\uf001" // FontAwesome fa-music
            font.family: iconFont.name
            font.pixelSize: Math.round(Math.min(parent.width, parent.height) * 0.22)
            color: theme ? theme.textColor : "#ffffff"
            horizontalAlignment: Text.AlignHCenter
            verticalAlignment: Text.AlignVCenter
        }
        // 无封面时同样支持点击播放/暂停
        MouseArea {
            anchors.fill: parent
            hoverEnabled: true
            cursorShape: Qt.PointingHandCursor
            onClicked: {
                if (!sourceItem) return;
                if (sourceItem.isPlaying) {
                    if (sourceItem.pauseClicked) sourceItem.pauseClicked();
                } else {
                    if (sourceItem.playClicked) sourceItem.playClicked();
                }
            }
        }
    }

    // 右侧：标题 + 渐隐滚动歌词
    Item {
        id: lyricsPanel
        anchors.left: rotatingCoverContainer.right
        anchors.leftMargin: 100
        anchors.right: parent.right
        anchors.rightMargin: 40
        anchors.verticalCenter: parent.verticalCenter
        width: Math.max(360, parent.width * 0.42)
        height: Math.round(parent.height * 0.68)
        z: 4

        Column {
            anchors.fill: parent
            spacing: 30
            Column {
                width: parent.width
                spacing: 8
                Text {
                    text: title
                    font.pixelSize: 26
                    font.bold: true
                    color: theme ? theme.textColor : "#ffffff"
                    elide: Text.ElideRight
                    width: parent.width
                }
                Text {
                    text: artist
                    font.pixelSize: 18
                    color: theme ? Qt.darker(theme.textColor, 1.3) : "#cccccc"
                    elide: Text.ElideRight
                    width: parent.width
                }
            }

            // 随播放滚动显示歌词（优先使用 LRC）
            ListView {
                id: lyricList
                width: parent.width
                // 限制最多显示10行
                readonly property int maxVisibleLines: 10
                readonly property int rowHeight: 28
                readonly property int rowSpacing: 10
                height: Math.min(lyricsPanel.height - 42, maxVisibleLines * rowHeight + (maxVisibleLines - 1) * rowSpacing)
                clip: false
                spacing: 10
                boundsBehavior: Flickable.StopAtBounds
                model: lyricsAvailable ? lyricsEntries : [ { text: "未找到歌词" } ]
                currentIndex: currentLyricIndex
                reuseItems: true
                // 高亮移动与范围：将当前行保持在视图偏上的位置
                highlightMoveDuration: 800
                highlightFollowsCurrentItem: true
                preferredHighlightBegin: height * 0.25
                preferredHighlightEnd: height * 0.45
                highlightRangeMode: ListView.StrictlyEnforceRange

                // 列表创建后，用当前位置居中一次，避免初始跳到顶部
                Component.onCompleted: {
                    if (currentLyricIndex >= 0) {
                        Qt.callLater(function() {
                            lyricList.positionViewAtIndex(currentLyricIndex, ListView.Center)
                        })
                    }
                }

                // 内容滚动缓动动画
                Behavior on contentY {
                    NumberAnimation { duration: 800; easing.type: Easing.OutQuint }
                }

                delegate: Item {
                    width: lyricList.width
                    height: lyricList.rowHeight

                    // 歌词缓动偏移：模拟 Apple Music 随动效果
                    transform: Translate {
                        id: lyricTrans
                        y: 0
                    }

                    Connections {
                        target: root
                        function onCurrentLyricIndexChanged() {
                            // 仅处理向下滚动（索引增加）时的“拖拽”延迟效果
                            if (index > currentLyricIndex) {
                                var diff = index - currentLyricIndex
                                // 距离越远，初始向下偏移越大，造成“滞后”感
                                // 限制最大偏移以免过分
                                var dist = Math.min(diff, 8)
                                lyricTrans.y = dist * 13
                                // 延迟归位
                                recoverAnim.delayDuration = dist * 100
                                recoverAnim.restart()
                            } else if (index === currentLyricIndex) {
                                // 当前行也稍微带一点动量，加大偏移量让回弹更明显
                                lyricTrans.y = 30
                                recoverAnim.delayDuration = 0
                                recoverAnim.restart()
                            }
                        }
                    }

                    SequentialAnimation {
                        id: recoverAnim
                        property int delayDuration: 0
                        
                        PauseAnimation { duration: recoverAnim.delayDuration }
                        NumberAnimation {
                            target: lyricTrans
                            property: "y"
                            to: 0
                            duration: 800
                            easing.type: Easing.OutBack
                            // 当前行回弹系数大一些，其他行小一些
                            easing.overshoot: (index === currentLyricIndex) ? 1.5 : 1.4
                        }
                    }

                    // 使用 index 与 currentLyricIndex 比较，避免 ListView.isCurrentItem 在嵌套时不稳定
                    readonly property bool isActive: index === currentLyricIndex
                    // 视口渐隐：顶部两行与底部两行做渐变透明
                    readonly property real centerYInView: (y - lyricList.contentY) + height / 2
                    readonly property real fadeArea: (lyricList.rowHeight * 4) + (lyricList.rowSpacing * 4)
                    readonly property real fadeTopFactor: Math.max(0, Math.min(1, centerYInView / Math.max(1, fadeArea)))
                    readonly property real fadeBottomFactor: Math.max(0, Math.min(1, (lyricList.height - centerYInView) / Math.max(1, fadeArea)))
                    readonly property real edgeFactor: Math.min(fadeTopFactor, fadeBottomFactor)
                    // 堆叠两层文本：底层普通颜色，顶层主题色以裁剪宽度实现从左到右填充
                    Item {
                        id: textStack
                        anchors.fill: parent
                        // 顶/底部渐隐：靠近边缘逐步降低整体不透明度
                        opacity: (isActive ? 1.0 : 0.6) * edgeFactor
                        Behavior on opacity { NumberAnimation { duration: 600; easing.type: Easing.OutCubic } }
                        // 放大动画使当前行视觉更突出
                        scale: isActive ? 1.06 : 1.0
                        Behavior on scale { NumberAnimation { duration: 800; easing.type: Easing.OutQuint } }
                        layer.enabled: isActive
                        layer.smooth: true

                        // 底层普通颜色文本（非当前行透明度为 0.6）
                        Text {
                            id: baseText
                            anchors.verticalCenter: parent.verticalCenter
                            anchors.left: parent.left
                            width: parent.width
                            text: modelData.text
                            wrapMode: Text.NoWrap
                            horizontalAlignment: Text.AlignLeft
                            font.pixelSize: 24
                            font.weight: isActive ? Font.Bold : Font.Normal
                            color: theme ? theme.textColor : "#ffffff"
                            renderType: Text.QtRendering
                            opacity: isActive ? 1.0 : 0.6
                        }

                        // 顶层主题色填充，使用裁剪宽度实现从左到右渐进填充
                        Item {
                            id: fillMask
                            anchors.verticalCenter: parent.verticalCenter
                            anchors.left: parent.left
                            // 根据歌词进度动态填充：本行开始到下一行开始的区间
                            readonly property real lineStart: (index >= 0 && index < lyricsEntries.length) ? lyricsEntries[index].t : 0
                            readonly property real lineEnd: (index + 1 < lyricsEntries.length) ? lyricsEntries[index + 1].t : (sourceItem ? sourceItem.duration : lineStart + 3000)
                            readonly property real posMs: (sourceItem && sourceItem.positionMs) ? sourceItem.positionMs : 0
                            readonly property real ratio: isActive ? Math.max(0, Math.min(1, (posMs - lineStart) / Math.max(1, lineEnd - lineStart))) : 0
                            width: Math.ceil(fillText.paintedWidth * ratio)
                            height: parent.height
                            clip: true

                            Text {
                                id: fillText
                                anchors.verticalCenter: parent.verticalCenter
                                anchors.left: parent.left
                                width: parent.width + 0.1
                                text: modelData.text
                                wrapMode: Text.NoWrap
                                horizontalAlignment: Text.AlignLeft
                                font.pixelSize: baseText.font.pixelSize + 0.1
                                font.weight: isActive ? Font.Bold : Font.Normal
                                color:theme.focusColor
                            }
                        }
                    }
                }
            }

            // 监听播放进度与歌曲切换，驱动歌词滚动
            Connections {
                target: sourceItem
                function onSourceChanged() {
                    // 切歌时重新加载歌词
                    loadLyricsForSource(sourceItem.source)
                    // 切换后按当前进度立即定位歌词（暂停状态下也能保持当前位置）
                    if (sourceItem && typeof sourceItem.positionMs === "number") {
                        updateLyricIndex(sourceItem.positionMs)
                    }
                }
                function onCoverImageChanged() {
                    if (sourceItem.coverImage && sourceItem.coverImage.length > 0) {
                        // 若当前未显示任何封面（首次进入），直接显示以避免空白
                        if (!displayCoverImage || displayCoverImage.length === 0) {
                            displayCoverImage = sourceItem.coverImage
                            displayCoverIsDefault = false
                            pendingCoverUrl = ""
                        } else {
                            // 后续切换仍走预加载，避免闪白
                            pendingCoverUrl = sourceItem.coverImage
                            nextCoverLoader.source = pendingCoverUrl
                        }
                        circleCoverImage = sourceItem.coverImage
                    }
                }
                function onCoverImageIsDefaultChanged() {
                    if (sourceItem.coverImageIsDefault) {
                        displayCoverIsDefault = true
                        displayCoverImage = ""
                        pendingCoverUrl = ""
                        circleCoverImage = ""
                    }
                    // 当为 false 时，不立即切换，等待 nextCoverLoader 加载完毕
                }
                function onSongTitleChanged() {
                    title = sourceItem.songTitle
                }
                function onArtistNameChanged() {
                    artist = sourceItem.artistName
                }
                function onIsPlayingChanged() {
                    if (!sourceItem.isPlaying) {
                        // 暂停不改变 currentIndex，但不再移动
                    }
                }
                function onPositionMsChanged() {
                    updateLyricIndex(sourceItem.positionMs)
                    // 由 StrictlyEnforceRange 保持当前项停留在偏上的范围内
                }
            }
        }
    }

    // 底部控件
    Item {
        id: bottomControls
        anchors.left: parent.left
        anchors.right: parent.right
        anchors.bottom: parent.bottom
        anchors.leftMargin: 240
        anchors.rightMargin: 240
        anchors.bottomMargin: 24
        height: 56
        z: 6
        visible: true

        // 背景条
        Rectangle {
            anchors.fill: parent
            radius: 14
            color: "transparent"
            opacity: 0.85
            antialiasing: true
            smooth: true
        }

        // 内容容器：左侧控制按钮，右侧时间文本
        Item {
            anchors.fill: parent
            anchors.margins: 10

            Row {
                id: controlRow
                anchors.left: parent.left
                anchors.verticalCenter: parent.verticalCenter
                spacing: 22

                // 上一曲
                Text {
                    id: prevIcon
                    text: "\uf04a"
                    font.family: iconFont.name
                    font.pixelSize: 20
                    color: prevArea.pressed ? (theme ? theme.focusColor : "#00C4B3") : (theme ? theme.textColor : "#ffffff")
                    verticalAlignment: Text.AlignVCenter
                    width: 28; height: 28
                    horizontalAlignment: Text.AlignHCenter
                    MouseArea {
                        id: prevArea
                        anchors.fill: parent
                        anchors.margins: -4
                        hoverEnabled: true
                        cursorShape: Qt.PointingHandCursor
                        onClicked: {
                            if (sourceItem && sourceItem.previousClicked) sourceItem.previousClicked()
                        }
                    }
                }

                // 播放/暂停
                Text {
                    id: playPauseIcon
                    text: (sourceItem && sourceItem.isPlaying) ? "\uf04c" : "\uf04b"
                    font.family: iconFont.name
                    font.pixelSize: 22
                    color: playArea.pressed ? (theme ? theme.focusColor : "#00C4B3") : (theme ? theme.textColor : "#ffffff")
                    verticalAlignment: Text.AlignVCenter
                    width: 32; height: 32
                    horizontalAlignment: Text.AlignHCenter
                    transformOrigin: Item.Center
                    // 悬停与按压缩放动画（悬停放大、按压轻微缩小）
                    scale: playArea.pressed ? 0.92 : (playArea.containsMouse ? 1.08 : 1.0)
                    Behavior on scale { NumberAnimation { duration: 100; easing.type: Easing.OutQuad } }

                    // 点击弹跳效果，增强反馈
                    SequentialAnimation {
                        id: playClickBounce
                        running: false
                        NumberAnimation { target: playPauseIcon; property: "scale"; to: 1.15; duration: 90; easing.type: Easing.OutBack }
                        NumberAnimation { target: playPauseIcon; property: "scale"; to: playArea.containsMouse ? 1.08 : 1.0; duration: 140; easing.type: Easing.InQuad }
                    }
                    MouseArea {
                        id: playArea
                        anchors.fill: parent
                        anchors.margins: -4
                        hoverEnabled: true
                        cursorShape: Qt.PointingHandCursor
                        onClicked: {
                            if (!sourceItem) return
                            if (sourceItem.isPlaying) {
                                if (sourceItem.pauseClicked) sourceItem.pauseClicked()
                            } else {
                                if (sourceItem.playClicked) sourceItem.playClicked()
                            }
                            playClickBounce.restart()
                        }
                    }
                }

                // 下一曲
                Text {
                    id: nextIcon
                    text: "\uf04e"
                    font.family: iconFont.name
                    font.pixelSize: 20
                    color: nextArea.pressed ? (theme ? theme.focusColor : "#00C4B3") : (theme ? theme.textColor : "#ffffff")
                    verticalAlignment: Text.AlignVCenter
                    width: 28; height: 28
                    horizontalAlignment: Text.AlignHCenter
                    MouseArea {
                        id: nextArea
                        anchors.fill: parent
                        anchors.margins: -4
                        hoverEnabled: true
                        cursorShape: Qt.PointingHandCursor
                        onClicked: {
                            if (sourceItem && sourceItem.nextClicked) sourceItem.nextClicked()
                        }
                    }
                }
            }

            // 进度条（中间）
            Rectangle {
                id: progressTrack
                anchors.left: controlRow.right
                anchors.leftMargin: 24
                anchors.right: timeText.left
                anchors.rightMargin: 24
                anchors.verticalCenter: parent.verticalCenter
                height: 8
                radius: 4
                color: theme ? Qt.rgba(theme.textColor.r, theme.textColor.g, theme.textColor.b, 0.25) : Qt.rgba(255,255,255,0.25)
                antialiasing: true
                smooth: true
                property bool dragging: false

                // 当前进度比例（优先使用 sourceItem.progress）
                readonly property real ratio: (sourceItem && typeof sourceItem.progress === "number") ? Math.max(0, Math.min(1, sourceItem.progress)) : ((sourceItem && sourceItem.duration > 0) ? Math.max(0, Math.min(1, sourceItem.position / sourceItem.duration)) : 0)

                Rectangle {
                    id: progressFillColor
                    anchors.left: parent.left
                    anchors.verticalCenter: parent.verticalCenter
                    width: parent.width * progressTrack.ratio
                    height: parent.height
                    radius: parent.radius
                    color: theme ? theme.focusColor : "#00C4B3"
                    antialiasing: true
                    smooth: true
                }

                Rectangle {
                    id: handleDot
                    width: 12
                    height: 12
                    radius: 6
                    color: theme ? theme.focusColor : "#00C4B3"
                    border.color: theme ? Qt.lighter(theme.focusColor, 1.4) : Qt.rgba(0, 196, 179, 1)
                    border.width: 1
                    antialiasing: true
                    smooth: true
                    z: 2
                    anchors.verticalCenter: progressTrack.verticalCenter
                    x: Math.max(0, Math.min(progressTrack.width, progressTrack.width * progressTrack.ratio)) - width / 2
                    opacity: (progressArea.containsMouse || progressTrack.dragging) ? 1.0 : 0.0
                    scale: (progressArea.containsMouse || progressTrack.dragging) ? 1.15 : 1.0
                    transformOrigin: Item.Center
                    Behavior on scale { NumberAnimation { duration: 240; easing.type: Easing.OutCubic } }
                }

                

                MouseArea {
                    id: progressArea
                    anchors.fill: parent
                    hoverEnabled: true
                    cursorShape: Qt.PointingHandCursor
                    function setProgressAt(px) {
                        var r = Math.max(0, Math.min(1, px / progressTrack.width))
                        if (sourceItem && sourceItem.seekPositionChanged) sourceItem.seekPositionChanged(r)
                    }
                    onPressed: function(mouse) {
                        progressTrack.dragging = true
                        setProgressAt(mouse.x)
                    }
                    onPositionChanged: function(mouse) {
                        if (pressed) setProgressAt(mouse.x)
                    }
                    onReleased: function(mouse) {
                        setProgressAt(mouse.x)
                        progressTrack.dragging = false
                        progressFillColor.opacity = 0.7
                    }
                }
            }

            // 时间显示
            Text {
                id: timeText
                anchors.right: volumeIcon.left
                anchors.rightMargin: 24
                anchors.verticalCenter: parent.verticalCenter
                text: sourceItem ? (formatTime(sourceItem.position) + " / " + formatTime(sourceItem.duration)) : "--:-- / --:--"
                font.pixelSize: 14
                color: theme ? Qt.darker(theme.textColor, 1.15) : "#dddddd"
                opacity: 0.9
                horizontalAlignment: Text.AlignRight
            }

            Text {
                id: volumeIcon
                anchors.right: volumeTrack.left
                anchors.rightMargin: 8
                anchors.verticalCenter: parent.verticalCenter
                text: theme && theme.musicVolume === 0 ? "\uf026" : "\uf028"
                font.family: iconFont.name
                font.pixelSize: 18
                color: muteArea.pressed ? (theme ? theme.focusColor : "#00C4B3") : (theme ? theme.textColor : "#ffffff")
                width: 24
                height: 24
                horizontalAlignment: Text.AlignHCenter
                verticalAlignment: Text.AlignVCenter
                MouseArea {
                    id: muteArea
                    anchors.fill: parent
                    hoverEnabled: true
                    cursorShape: Qt.PointingHandCursor
                    onClicked: {
                        if (!theme) return
                        if (theme.musicVolume > 0) {
                            theme.musicVolume = 0
                        } else {
                            var restore = volumeTrack.ratio > 0 ? volumeTrack.ratio : 0.2
                            theme.musicVolume = restore
                        }
                    }
                }
            }

            Rectangle {
                id: volumeTrack
                anchors.right: parent.right
                anchors.verticalCenter: parent.verticalCenter
                width: 140
                height: 8
                radius: 4
                color: theme ? Qt.rgba(theme.textColor.r, theme.textColor.g, theme.textColor.b, 0.25) : Qt.rgba(255,255,255,0.25)
                antialiasing: true
                smooth: true
                property bool dragging: false
                readonly property real ratio: theme ? Math.max(0, Math.min(1, theme.musicVolume)) : 0

                Rectangle {
                    anchors.left: parent.left
                    anchors.verticalCenter: parent.verticalCenter
                    width: parent.width * volumeTrack.ratio
                    height: parent.height
                    radius: parent.radius
                    color: theme ? theme.focusColor : "#00C4B3"
                    antialiasing: true
                    smooth: true
                }

                Rectangle {
                    width: 12
                    height: 12
                    radius: 6
                    color: theme ? theme.focusColor : "#00C4B3"
                    border.color: theme ? Qt.lighter(theme.focusColor, 1.4) : Qt.rgba(0, 196, 179, 1)
                    border.width: 1
                    antialiasing: true
                    smooth: true
                    z: 2
                    anchors.verticalCenter: volumeTrack.verticalCenter
                    x: Math.max(0, Math.min(volumeTrack.width, volumeTrack.width * volumeTrack.ratio)) - width / 2
                    opacity: (volumeArea.containsMouse || volumeTrack.dragging) ? 1.0 : 0.0
                    scale: (volumeArea.containsMouse || volumeTrack.dragging) ? 1.15 : 1.0
                    transformOrigin: Item.Center
                    Behavior on scale { NumberAnimation { duration: 240; easing.type: Easing.OutCubic } }
                }

                MouseArea {
                    id: volumeArea
                    anchors.fill: parent
                    hoverEnabled: true
                    cursorShape: Qt.PointingHandCursor
                    function setVolumeAt(px) {
                        var r = Math.max(0, Math.min(1, px / volumeTrack.width))
                        if (theme) theme.musicVolume = r
                    }
                    onPressed: function(mouse) {
                        volumeTrack.dragging = true
                        setVolumeAt(mouse.x)
                    }
                    onPositionChanged: function(mouse) {
                        if (pressed) setVolumeAt(mouse.x)
                    }
                    onReleased: function(mouse) {
                        setVolumeAt(mouse.x)
                        volumeTrack.dragging = false
                    }
                }
            }
        }
    }
}

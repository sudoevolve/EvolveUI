// EMusicPlayer.qml
import QtQuick
import QtQuick.Layouts
import QtQuick.Controls
import QtQuick.Effects
import QtMultimedia
import AudioMetadata 1.0
import MusicLibrary 1.0

Rectangle {
    id: root

        // === 接口属性 ===
        property string source: ""   // 音频文件路径
    property string songTitle: "未知歌曲"
    property string artistName: "未知艺术家"
    property string coverImage: ""
    // 当前封面是否为默认（无元数据）状态，用于效果切换
    property bool coverImageIsDefault: false
    property bool isPlaying: false
    property real progress: 0.0  // 0.0 - 1.0
    property int duration: 0     // 总时长（秒）
    property int position: 0     // 当前位置（秒）
    // 毫秒级进度，用于歌词精确同步
    property int positionMs: 0
    property alias playlistModelRef: playlistModel
    function playSourcePath(p) {
        if (!p || p.length === 0) return
        var src = p
        if (typeof p === 'string' && p.indexOf('file:///') === 0) {
            src = decodeURIComponent(p.substring(8))
        }
        if (musicLibrary && musicLibrary.isValidMusicFile && !musicLibrary.isValidMusicFile(src)) return
        if (root.playlistModelRef && typeof root.playlistModelRef.get === "function") {
            var found = -1
            for (var i = 0; i < root.playlistModelRef.count; i++) {
                var it = root.playlistModelRef.get(i)
                if (it && (it.source === src || it.source === p)) { found = i; break }
            }
            if (found >= 0) { playAt(found); return }
        }
        mediaPlayer.stop()
        if (root.source === src) {
            root.source = ""
        }
        root.source = src
        mediaPlayer.play()
    }

    function addSources(sources) {
        if (!sources || !playlistModel) return
        for (var i = 0; i < sources.length; i++) {
            var s = sources[i]
            if (typeof s === 'string' && s.indexOf('file:///') === 0) s = decodeURIComponent(s.substring(8))
            var exists = false
            for (var j = 0; j < playlistModel.count; j++) {
                var it = playlistModel.get(j)
                if (it && it.source === s) { exists = true; break }
            }
            if (!exists) playlistModel.append({ source: s })
        }
        if (!root.isPlaying && playlistModel.count > 0) {
            root.source = playlistModel.get(0).source
        }
    }

    function resetSources(sources) {
        if (!playlistModel) return
        playlistModel.clear()
        addSources(sources)
        if (playlistModel.count > 0) {
            currentIndex = 0
            root.source = playlistModel.get(0).source
        }
    }

    function stopPlayback() {
        if (mediaPlayer) mediaPlayer.stop()
        root.source = ""
        root.songTitle = "未知歌曲"
        root.artistName = "未知艺术家"
        root.coverImage = ""
        root.coverImageIsDefault = true
        root.isPlaying = false
        root.progress = 0.0
        root.duration = 0
        root.position = 0
        root.positionMs = 0
    }
        // 播放模式：0=循环，1=单曲循环，2=随机
        property int playMode: 0
    
    // 音乐显色（用于主题动态强调色）
    property color coverProminentColor: theme.defaultFocusColor // 采样得到的不透明主色（初始为默认强调色）
    property color previousFocusColor: theme.focusColor   // 播放前的主题强调色
    
    // 自动读取元数据
    property bool autoReadMetadata: true
    // 打开全局动画窗口的处理函数（由上层 Main.qml 传入）
    property var openWindowHandler: null

    // FontAwesome 字体用于默认音乐图标
    FontLoader {
        id: faSolid
        source: "qrc:/new/prefix1/fonts/fontawesome-free-6.7.2-desktop/otfs/Font Awesome 6 Free-Solid-900.otf"
    }

    signal playClicked()
    signal pauseClicked()
    signal previousClicked()
    signal nextClicked()
    signal seekPositionChanged(real newPosition)

    // 允许外部触发：封面点击等
    onPlayClicked: {
        if (mediaPlayer) mediaPlayer.play()
    }
    onPauseClicked: {
        if (mediaPlayer) mediaPlayer.pause()
    }
    // 外部进度条拖动：newPosition 为 0.0-1.0 比例
    onSeekPositionChanged: function(newPosition) {
        if (mediaPlayer && mediaPlayer.duration > 0) {
            mediaPlayer.position = Math.max(0, Math.min(1, newPosition)) * mediaPlayer.duration
        }
    }
    
    // C++ 元数据读取器
    AudioMetadata {
        id: metadataReader
        source: root.source
        
        onTitleChanged: {
            root.songTitle = title
        }
        
        onArtistChanged: {
            root.artistName = artist
        }
        
        onCoverImageUrlChanged: {
            // 移除时间戳，防止生成不可复用的纹理资源导致内存增长
            const url = coverImageUrl.toString()
            if (url.length === 0) {
                // 无封面：标记默认并清空封面 URL（封面用图标显示）
                root.coverImageIsDefault = true
                root.coverImage = ""
            } else {
                root.coverImageIsDefault = false
                // 由于 C++ 始终写入同一临时文件路径，如果不改变字符串，Image 可能复用首次的纹理
                root.coverImage = url + "?v=" + Date.now()
            }
        }
        
        onDurationChanged: {
            root.duration = duration
        }
    }

    
    // 媒体播放器
    MediaPlayer {
        id: mediaPlayer
        source: root.source
        audioOutput: AudioOutput {
            volume: theme.musicVolume
        }
        
        onSourceChanged: {
            console.log("音频源已更改:", source)
            if (source != "") {
                console.log("开始播放音频")
            }
        }
        
        Component.onCompleted: {
            console.log("MediaPlayer组件已加载，音频源:", source)
            if (source != "") {
                console.log("自动开始播放")
            }
        }
        
        onErrorOccurred: function(error, errorString) {
            console.error("MediaPlayer错误:", error, errorString)
        }
        
        onPlaybackStateChanged: {
            console.log("播放状态改变:", playbackState)
            if (playbackState === MediaPlayer.PlayingState) {
                root.isPlaying = true
                console.log("正在播放")
            } else if (playbackState === MediaPlayer.PausedState) {
                root.isPlaying = false
                console.log("已暂停")
            } else if (playbackState === MediaPlayer.StoppedState) {
                root.isPlaying = false
                console.log("已停止")
            }
        }
        
        onPositionChanged: {
            // MediaPlayer.position 为毫秒
            root.positionMs = position
            root.position = Math.floor(position / 1000)
            if (duration > 0) {
                root.progress = position / duration
            }
        }
        
        

        onMediaStatusChanged: {
            if (mediaStatus === MediaPlayer.EndOfMedia) {
                if (root.playMode === 1) {
                    mediaPlayer.position = 0
                    mediaPlayer.play()
                } else if (root.playMode === 2) {
                    root.playRandom()
                } else {
                    root.playNext()
                }
            }
        }
    }
    // === 样式属性 ===
    property real radius: 20
    property int itemHeight: 80
    property int itemFontSize: 15
    property int itemIconSize: 20
    property int horizontalPadding: 10
    property real pressedScale: 0.96

    // 背景控制
    property bool backgroundVisible: true

    // 阴影配置
    property bool shadowEnabled: true
    property color shadowColor: theme.shadowColor
    property real shadowBlur: theme.shadowBlur
    property real shadowHorizontalOffset: theme.shadowXOffset
    property real shadowVerticalOffset: theme.shadowYOffset

    // === 尺寸与基础样式 ===
    color: "transparent"
    height: itemHeight + horizontalPadding * 2
    implicitWidth: 300
    implicitHeight: height

    // === 背景 ===
    Item {
        id: backgroundContainer
        anchors.fill: parent
        clip: false  // 改为false，允许内容超出背景边界

        // 纯色背景（始终可见）
        Rectangle {
            id: fallbackBackground
            anchors.fill: parent
            color: theme.secondaryColor
            radius: root.radius
            visible: root.backgroundVisible
            antialiasing: true
            smooth: true
        }

        // 原始专辑封面图像，隐藏
        Image {
            id: backgroundAlbumCoverSource
            anchors.fill: parent
            // 无元数据时不加载壁纸，背景仍使用纯色叠加
            source: root.coverImageIsDefault ? "" : root.coverImage
            fillMode: Image.PreserveAspectCrop
            cache: false
            asynchronous: false
            sourceSize: Qt.size(Math.round(width * 0.5), Math.round(height * 0.5))
            visible: false
            antialiasing: true
            smooth: true
            mipmap: false
        }

        MultiEffect {
            id: backgroundAlbumCover
            source: backgroundAlbumCoverSource
            anchors.fill: backgroundContainer
            visible: !root.coverImageIsDefault && root.coverImage !== "" && root.backgroundVisible
            
            // 模糊效果
            blurEnabled: true
            blur: 1.0
            blurMax: 32
            blurMultiplier: 2.0
            // 参考 EBlurCard：避免边缘溢出
            autoPaddingEnabled: false
            
            // 圆角遮罩
            maskEnabled: true
            maskSource: backgroundMask
            maskThresholdMin: 0.5
            maskSpreadAtMin: 1.0
        }

        // 参考 EBlurCard：叠加半透明主题色，避免过亮/过透明
        Rectangle {
            anchors.fill: parent
            anchors.margins: -0.5
            radius: root.radius
            visible: !root.coverImageIsDefault && root.coverImage !== "" && root.backgroundVisible
            color: theme.blurOverlayColor
            z: 1
            opacity: 1.0
        }

        // 从专辑封面取色（柔和浅色）
        Canvas {
            id: coverColorSampler
            width: 32; height: 32
            visible: false
            contextType: "2d"

            onPaint: {
                var ctx = getContext("2d")
                ctx.clearRect(0, 0, width, height)
                if (root.coverImage !== "" && coverSource.status === Image.Ready) {
                    // 将封面绘制到 Canvas
                    ctx.drawImage(coverSource, 0, 0, width, height)
                    var data = ctx.getImageData(0, 0, width, height).data

                    // 构建色相直方图，选取高饱和度中等亮度的主色
                    var bins = 36 // 10° 为一档
                    var counts = new Array(bins)
                    var sumR = new Array(bins)
                    var sumG = new Array(bins)
                    var sumB = new Array(bins)
                    for (var bIndex = 0; bIndex < bins; bIndex++) {
                        counts[bIndex] = 0; sumR[bIndex] = 0; sumG[bIndex] = 0; sumB[bIndex] = 0
                    }

                    for (var i = 0; i < data.length; i += 4) {
                        var a = data[i + 3]
                        if (a === 0) continue
                        var r = data[i], g = data[i + 1], b = data[i + 2]
                        var hsv = rgbToHsv(r, g, b)
                        // 放宽筛选条件，让更多颜色进入候选，最后再统一调整亮度
                        if (hsv.s > 0.15 && hsv.v > 0.15 && hsv.v < 0.95) {
                            var bin = Math.floor((hsv.h / 360.0) * bins)
                            if (bin < 0) bin = 0
                            if (bin >= bins) bin = bins - 1
                            counts[bin]++
                            sumR[bin] += r
                            sumG[bin] += g
                            sumB[bin] += b
                        }
                    }

                    var bestBin = -1
                    var bestCount = 0
                    for (var j = 0; j < bins; j++) {
                        if (counts[j] > bestCount) { bestCount = counts[j]; bestBin = j }
                    }

                    var outR, outG, outB
                    if (bestBin >= 0 && bestCount > 0) {
                        outR = sumR[bestBin] / bestCount
                        outG = sumG[bestBin] / bestCount
                        outB = sumB[bestBin] / bestCount
                    } else {
                        // 回退：取整体平均色
                        var totalR = 0, totalG = 0, totalB = 0, totalN = 0
                        for (var k = 0; k < data.length; k += 4) {
                            var aa = data[k + 3]
                            if (aa > 0) {
                                totalR += data[k]
                                totalG += data[k + 1]
                                totalB += data[k + 2]
                                totalN++
                            }
                        }
                        if (totalN > 0) {
                            outR = totalR / totalN
                            outG = totalG / totalN
                            outB = totalB / totalN
                        } else {
                            // 都失败时退回主题色
                            outR = theme.focusColor.r * 255
                            outG = theme.focusColor.g * 255
                            outB = theme.focusColor.b * 255
                        }
                    }

                    // === 优化：基于 HSL 调整亮度，避免过暗或过亮 ===
                    var hsl = rgbToHsl(outR, outG, outB)
                    
                    // 目标亮度范围：0.35 - 0.75
                    var targetL = Math.max(0.35, Math.min(0.75, hsl.l))
                    
                    // 如果原色有一定饱和度但被调亮了，可能变灰，适当补一点饱和度
                    if (hsl.s > 0.1) {
                         // 保持至少 0.3 的饱和度，防止颜色太灰
                         hsl.s = Math.max(hsl.s, 0.3)
                    }
                    
                    hsl.l = targetL
                    var finalRgb = hslToRgb(hsl.h, hsl.s, hsl.l)

                    // 设置波纹颜色（半透明）与主题显色（不透明）
                    var accent = Qt.rgba(finalRgb.r / 255.0, finalRgb.g / 255.0, finalRgb.b / 255.0, 1.0)
                    root.coverProminentColor = accent
                }
            }
        }

        

        // 圆角遮罩
        Item {
            id: backgroundMask
            anchors.fill: backgroundAlbumCoverSource
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
        
        // 横向渐变遮罩（左透明到右纯色）
        Rectangle {
            id: gradientOverlay
            anchors.fill: parent
            anchors.margins: -2
            radius: root.radius - 1
            visible: root.backgroundVisible
            antialiasing: true
            smooth: true
            layer.enabled: true
            layer.smooth: true
            layer.samples: 4

            gradient: Gradient {
                orientation: Gradient.Horizontal
                GradientStop { position: 0.0; color: Qt.rgba(0, 0, 0, 0) }
                GradientStop { position: 1.0; color: theme.secondaryColor }
            }
        }

        // 点击整卡背景打开动画窗口（以整个组件为起点）
        MouseArea {
            id: cardClickArea
            anchors.fill: parent
            hoverEnabled: true
            cursorShape: Qt.PointingHandCursor
            onClicked: {
                if (root.openWindowHandler) {
                    // 统一为单参数：传入源组件
                    root.openWindowHandler(root)
                } else {
                    console.warn("openWindowHandler 未设置：无法打开全屏窗口")
                }
            }
        }

        // 阴影效果
        layer.enabled: root.shadowEnabled && root.backgroundVisible
        layer.effect: MultiEffect {
            shadowEnabled: root.shadowEnabled && root.backgroundVisible
            shadowColor: root.shadowColor
            shadowBlur: root.shadowBlur
            shadowHorizontalOffset: root.shadowHorizontalOffset
            shadowVerticalOffset: root.shadowVerticalOffset
        }
    }



    // === 布局 ===
    RowLayout {
        anchors.fill: parent
        anchors.margins: horizontalPadding
        spacing: 10
        clip: false  // 确保布局不裁剪子元素

        // 封面图片 - 使用MultiEffect遮罩实现圆角
        Item {
            id: coverContainer
            width: root.itemHeight - 10
            height: root.itemHeight - 10
            clip: false  // 改为false，允许缩放时超出边界

            // 原始图像，隐藏
            Image {
                id: coverSource
                // 默认封面时不加载壁纸，避免大图解码
                source: root.coverImageIsDefault ? "" : root.coverImage
                anchors.fill: parent
                fillMode: Image.PreserveAspectCrop
                cache: false
                asynchronous: false
                sourceSize: Qt.size(Math.round(width * 0.6), Math.round(height * 0.6))
                visible: false
                antialiasing: true
                smooth: true
                mipmap: false
            }

            // 默认封面：使用音乐图标而非壁纸
            Item {
                id: defaultCoverSource
                anchors.fill: parent
                visible: false
                // 背景色以主题次级色填充，避免透明
                Rectangle {
                    anchors.fill: parent
                    color: theme.secondaryColor
                    antialiasing: true
                    smooth: true
                }
                // 音乐图标（FontAwesome）
                Text {
                    anchors.centerIn: parent
                    text: "\uf001" // fa-music
                    font.family: faSolid.name
                    font.pixelSize: Math.round(Math.min(defaultCoverSource.width, defaultCoverSource.height) * 0.6)
                    color: theme.textColor
                    horizontalAlignment: Text.AlignHCenter
                    verticalAlignment: Text.AlignVCenter
                }
            }

            // MultiEffect 遮罩效果
            MultiEffect {
                id: coverEffect
                source: root.coverImageIsDefault ? defaultCoverSource : coverSource
                anchors.fill: coverContainer
                maskEnabled: true
                maskSource: coverMask
                autoPaddingEnabled: false
                antialiasing: true
                maskThresholdMin: 0.5
                maskSpreadAtMin: 0.5
                
                // 动态启用抗锯齿图层，仅在播放时生效
                layer.enabled: root.isPlaying
                layer.smooth: true
                layer.samples: 4
                // 图层纹理尺寸严格匹配显示尺寸，避免二次缩放
                layer.textureSize: Qt.size(Math.round(width), Math.round(height))
            }

            // 圆角遮罩
        Item {
            id: coverMask
            anchors.fill: coverContainer
            layer.enabled: true
            layer.smooth: true
            layer.mipmap: false
            visible: false

                Rectangle {
                    anchors.fill: parent
                    radius: 12
                    color: "black" // 黑色用于掩码：纯黑表示完全不透明
                    antialiasing: true
                    smooth: true
                }
            }

            // 已移除封面摇晃效果

            // 播放状态指示
            Rectangle {
                visible: !root.isPlaying
                anchors.centerIn: parent
                width: 20
                height: 20
                radius: 10
                color: Qt.rgba(0, 0, 0, 0.5)
                antialiasing: true

                Rectangle {
                    anchors.centerIn: parent
                    width: 8
                    height: 8
                    radius: 4
                    color: "white"
                    antialiasing: true
                }
            }

            // 点击打开动画窗口
            MouseArea {
                anchors.fill: parent
                hoverEnabled: true
                cursorShape: Qt.PointingHandCursor
                onClicked: {
                    if (root.openWindowHandler) {
                        // 统一为单参数：传入源组件
                        root.openWindowHandler(root)
                    } else {
                        console.warn("openWindowHandler 未设置：无法打开全屏窗口")
                    }
                }
            }
        }

        // 歌曲信息和控制区
        ColumnLayout {
            Layout.fillWidth: true
            Layout.fillHeight: true
            spacing: 5

            // 歌曲信息
            ColumnLayout {
                Layout.fillWidth: true
                spacing: 2

                Text {
                    text: root.songTitle
                    font.pixelSize: root.itemFontSize
                    font.bold: true
                    color: theme.textColor
                    elide: Text.ElideRight
                    Layout.fillWidth: true
                }

                Text {
                    text: root.artistName
                    font.pixelSize: root.itemFontSize - 2
                    color: Qt.darker(theme.textColor, 1.2)
                    elide: Text.ElideRight
                    Layout.fillWidth: true
                }
            }

            // 进度条
                Rectangle {
                    id: progressTrack
                    Layout.fillWidth: true
                    height: 6
                    radius: height / 2
                    color: Qt.rgba(theme.textColor.r, theme.textColor.g, theme.textColor.b, 0.2)
                    antialiasing: true
                    smooth: true
                    property bool dragging: false

                // 填充条：直接绑定到 root.progress，避免中间变量和定时器
                Rectangle {
                    id: progressFillColor
                    width: progressTrack.width * root.progress
                    height: progressTrack.height
                    anchors.verticalCenter: progressTrack.verticalCenter
                    color: theme.focusColor
                    radius: progressTrack.height / 2
                    antialiasing: true
                    smooth: true
                }

                Rectangle {
                    id: handleDot
                    width: 12
                    height: 12
                    radius: 6
                    color: theme.focusColor
                    border.color: Qt.lighter(theme.focusColor, 1.4)
                    border.width: 1
                    antialiasing: true
                    smooth: true
                    z: 2
                    anchors.verticalCenter: progressTrack.verticalCenter
                    x: Math.max(0, Math.min(progressTrack.width, progressTrack.width * root.progress)) - width / 2
                    opacity: (progressArea.containsMouse || progressTrack.dragging) ? 1.0 : 0.0
                    scale: (progressArea.containsMouse || progressTrack.dragging) ? 1.15 : 1.0
                    transformOrigin: Item.Center

                    Behavior on scale {
                        NumberAnimation {
                            duration: 240
                            easing.type: Easing.OutCubic
                        }
                    }
                }

                MouseArea {
                    id: progressArea
                    anchors.fill: parent
                    hoverEnabled: true
                    cursorShape: Qt.PointingHandCursor

                    function setProgressAt(px) {
                        var newProgress = Math.max(0, Math.min(1, px / progressTrack.width))
                        root.progress = newProgress // 直接设置，触发 MediaPlayer 更新
                        mediaPlayer.position = newProgress * mediaPlayer.duration
                        root.seekPositionChanged(newProgress)
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

            // 时间显示和控制按钮
            RowLayout {
                Layout.fillWidth: true
                spacing: 10

                // 时间显示
                Text {
                    text: formatTime(root.position) + " / " + formatTime(root.duration)
                    font.pixelSize: root.itemFontSize - 4
                    color: Qt.darker(theme.textColor, 1.2)
                }

                Item { Layout.fillWidth: true }

                // 控制按钮
                Row {
                    spacing: 15

                    // 上一曲按钮
                    Text {
                        text: "\uf048" // FontAwesome 上一曲图标
                        font.family: iconFont.name
                        font.pixelSize: root.itemIconSize
                        color: prevArea.pressed ? theme.focusColor : theme.textColor
                        verticalAlignment: Text.AlignVCenter

                        MouseArea {
                            id: prevArea
                            anchors.fill: parent
                            anchors.margins: -5
                            cursorShape: Qt.PointingHandCursor
                            onClicked: {
                                // 触发上一曲信号
                                root.previousClicked()
                            }

                            // 缩放效果
                            onPressed: {
                                parent.scale = root.pressedScale
                            }
                            onReleased: {
                                parent.scale = 1.0
                            }
                            onCanceled: {
                                parent.scale = 1.0
                            }
                        }

                        Behavior on scale {
                            NumberAnimation { duration: 100 }
                        }
                    }

                    // 播放/暂停按钮
                    Text {
                        id: playButton
                        text: root.isPlaying ? "\uf04c" : "\uf04b" // FontAwesome 暂停/播放图标
                        font.family: iconFont.name
                        font.pixelSize: root.itemIconSize + 2
                        color: playArea.pressed ? theme.focusColor : theme.textColor
                        verticalAlignment: Text.AlignVCenter

                        // 缩放变换
                        transform: Scale {
                            id: playButtonScale
                            origin.x: playButton.width / 2
                            origin.y: playButton.height / 2
                        }

                        SequentialAnimation {
                            id: playButtonAnimation
                            
                            // 第一阶段：缩小淡出
                            ParallelAnimation {
                                NumberAnimation {
                                    target: playButtonScale
                                    property: "xScale"
                                    to: 0.3
                                    duration: 150
                                    easing.type: Easing.InQuad
                                }
                                NumberAnimation {
                                    target: playButtonScale
                                    property: "yScale"
                                    to: 0.3
                                    duration: 150
                                    easing.type: Easing.InQuad
                                }
                                NumberAnimation {
                                    target: playButton
                                    property: "opacity"
                                    to: 0.2
                                    duration: 150
                                    easing.type: Easing.InQuad
                                }
                            }
                            
                            // 第二阶段：放大淡入
                            ParallelAnimation {
                                NumberAnimation {
                                    target: playButtonScale
                                    property: "xScale"
                                    to: 1.0
                                    duration: 200
                                    easing.type: Easing.OutBack
                                }
                                NumberAnimation {
                                    target: playButtonScale
                                    property: "yScale"
                                    to: 1.0
                                    duration: 200
                                    easing.type: Easing.OutBack
                                }
                                NumberAnimation {
                                    target: playButton
                                    property: "opacity"
                                    to: 1.0
                                    duration: 200
                                    easing.type: Easing.OutQuad
                                }
                            }
                        }

                        MouseArea {
                            id: playArea
                            anchors.fill: parent
                            anchors.margins: -5
                            cursorShape: Qt.PointingHandCursor
                            
                            onClicked: {
                                console.log("播放/暂停按钮被点击，当前状态:", root.isPlaying)
                                
                                // 启动缩小淡出放大淡入动画
                                playButtonAnimation.start()
                                
                                if (root.isPlaying) {
                                    console.log("暂停播放")
                                    mediaPlayer.pause()
                                    root.pauseClicked()
                                } else {
                                    console.log("开始播放")
                                    mediaPlayer.play()
                                    root.playClicked()
                                }
                            }

                            // 按下时的缩放效果
                            onPressed: {
                                playButtonScale.xScale = root.pressedScale
                                playButtonScale.yScale = root.pressedScale
                            }
                            onReleased: {
                                if (!playButtonAnimation.running) {
                                    playButtonRestoreAnimation.restart()
                                }
                            }
                            onCanceled: {
                                if (!playButtonAnimation.running) {
                                    playButtonRestoreAnimation.restart()
                                }
                            }
                        }

                        // 恢复缩放动画（用于按下释放时）
                        ParallelAnimation {
                            id: playButtonRestoreAnimation
                            SpringAnimation { 
                                target: playButtonScale; property: "xScale"; to: 1.0; 
                                spring: 2.5; damping: 0.25 
                            }
                            SpringAnimation { 
                                target: playButtonScale; property: "yScale"; to: 1.0; 
                                spring: 2.5; damping: 0.25 
                            }
                        }
                    }

                    // 下一曲按钮
                    Text {
                        text: "\uf051" // FontAwesome 下一曲图标
                        font.family: iconFont.name
                        font.pixelSize: root.itemIconSize
                        color: nextArea.pressed ? theme.focusColor : theme.textColor
                        verticalAlignment: Text.AlignVCenter

                        MouseArea {
                            id: nextArea
                            anchors.fill: parent
                            anchors.margins: -5
                            cursorShape: Qt.PointingHandCursor
                            onClicked: {
                                // 触发下一曲信号
                                root.nextClicked()
                            }

                            // 缩放效果
                            onPressed: {
                                parent.scale = root.pressedScale
                            }
                            onReleased: {
                                parent.scale = 1.0
                            }
                            onCanceled: {
                                parent.scale = 1.0
                            }
                        }

                        Behavior on scale {
                            NumberAnimation { duration: 100 }
                        }
                    }
                }

                // 播放模式切换：循环 / 单曲循环 / 随机
                Item {
                    id: playModeButton
                    width: (root.itemIconSize + 2)
                    height: (root.itemIconSize + 2)
                    opacity: 0.9

                    // 图标：循环(
                    // \uf01e)、随机(\uf074)。单曲循环在循环图标叠加"1"标记
                    Text {
                        id: playModeIcon
                        anchors.centerIn: parent
                        text: (root.playMode === 2) ? "\uf074" : "\uf021"
                        font.family: iconFont.name
                        font.pixelSize: root.itemIconSize
                        color: playModeArea.pressed ? theme.focusColor : theme.textColor
                        verticalAlignment: Text.AlignVCenter
                        horizontalAlignment: Text.AlignHCenter
                    }

                    // 单曲循环标记
                    Text {
                        id: repeatOneBadge
                        text: "1"
                        visible: root.playMode === 1
                        anchors.centerIn: parent
                        z: 2
                        font.pixelSize: Math.max(10, root.itemIconSize * 0.6)
                        color: playModeArea.pressed ? theme.focusColor : Qt.lighter(theme.textColor, 1.1)
                        horizontalAlignment: Text.AlignHCenter
                        verticalAlignment: Text.AlignVCenter
                    }

                    MouseArea {
                        id: playModeArea
                        anchors.fill: parent
                        anchors.margins: -5
                        cursorShape: Qt.PointingHandCursor
                        onClicked: {
                            root.playMode = (root.playMode + 1) % 3
                            console.log("播放模式切换为:", root.playMode === 0 ? "循环" : (root.playMode === 1 ? "单曲循环" : "随机"))
                        }
                        onPressed: {
                            playModeButton.scale = root.pressedScale
                        }
                        onReleased: {
                            playModeButton.scale = 1.0
                        }
                        onCanceled: {
                            playModeButton.scale = 1.0
                        }
                    }

                    Behavior on scale { NumberAnimation { duration: 100 } }
                }

            }
        }
    }

    // 辅助函数：格式化时间
    function formatTime(seconds) {
        var mins = Math.floor(seconds / 60)
        var secs = seconds % 60
        return mins + ":" + (secs < 10 ? "0" : "") + secs
    }

    // 辅助函数：RGB -> HSV（h:0-360, s/v:0-1）
    function rgbToHsv(r, g, b) {
        r /= 255; g /= 255; b /= 255
        var max = Math.max(r, g, b), min = Math.min(r, g, b)
        var h, s, v = max
        var d = max - min
        s = max === 0 ? 0 : d / max
        if (max === min) {
            h = 0
        } else {
            switch (max) {
            case r: h = (g - b) / d + (g < b ? 6 : 0); break
            case g: h = (b - r) / d + 2; break
            case b: h = (r - g) / d + 4; break
            }
            h *= 60
        }
        return { h: h, s: s, v: v }
    }

    // 辅助函数：RGB -> HSL
    function rgbToHsl(r, g, b) {
        r /= 255; g /= 255; b /= 255
        var max = Math.max(r, g, b), min = Math.min(r, g, b)
        var h, s, l = (max + min) / 2

        if (max === min) {
            h = s = 0 // achromatic
        } else {
            var d = max - min
            s = l > 0.5 ? d / (2 - max - min) : d / (max + min)
            switch (max) {
                case r: h = (g - b) / d + (g < b ? 6 : 0); break
                case g: h = (b - r) / d + 2; break
                case b: h = (r - g) / d + 4; break
            }
            h /= 6
        }
        return { h: h, s: s, l: l }
    }

    // 辅助函数：HSL -> RGB
    function hslToRgb(h, s, l) {
        var r, g, b

        if (s === 0) {
            r = g = b = l // achromatic
        } else {
            var hue2rgb = function(p, q, t) {
                if (t < 0) t += 1
                if (t > 1) t -= 1
                if (t < 1/6) return p + (q - p) * 6 * t
                if (t < 1/2) return q
                if (t < 2/3) return p + (q - p) * (2/3 - t) * 6
                return p
            }

            var q = l < 0.5 ? l * (1 + s) : l + s - l * s
            var p = 2 * l - q
            r = hue2rgb(p, q, h + 1/3)
            g = hue2rgb(p, q, h)
            b = hue2rgb(p, q, h - 1/3)
        }

        return { r: Math.round(r * 255), g: Math.round(g * 255), b: Math.round(b * 255) }
    }
    
    // 自动播放列表管理
    property int currentIndex: 0
    ListModel { id: playlistModel }

    MusicLibrary { 
        id: musicLibrary 
        
        // 连接新的信号，实现自动更新播放列表
        onMusicFilesChanged: function(newFiles) {
            console.log("检测到音乐文件变化，更新播放列表")
            updatePlaylistFromFiles(newFiles)
        }
        
        onFileAdded: function(filePath) {
            console.log("新增音乐文件:", filePath)
            // 可以在这里添加单个文件到播放列表
        }
        
        onFileRemoved: function(filePath) {
            console.log("删除音乐文件:", filePath)
            // 检查当前播放的文件是否被删除
            if (root.source === filePath) {
                console.log("当前播放的文件被删除，停止播放")
                mediaPlayer.stop()
                root.source = ""
                root.songTitle = "未知歌曲"
                root.artistName = "未知艺术家"
                root.coverImage = ""
                
                // 尝试播放下一首
                if (playlistModel.count > 1) {
                    playNext()
                }
            }
            
            // 从播放列表中移除该文件
            for (var i = 0; i < playlistModel.count; i++) {
                if (playlistModel.get(i).source === filePath) {
                    console.log("从播放列表移除文件，索引:", i)
                    playlistModel.remove(i)
                    
                    // 调整当前索引
                    if (i <= currentIndex && currentIndex > 0) {
                        currentIndex--
                    }
                    break
                }
            }
        }
    }

    function loadProjectPlaylist() {
        // 使用新的API，优先读取项目音乐，如果没有则读取Windows音乐文件夹
        const files = musicLibrary.scanAllAvailableMusic(true)
        updatePlaylistFromFiles(files)
        
        // 启动文件监控
        musicLibrary.startWatching()
        console.log("已启动音乐文件监控，监控状态:", musicLibrary.isWatching())
    }
    
    function updatePlaylistFromFiles(files) {
        playlistModel.clear()
        for (var i = 0; i < files.length; i++) {
            playlistModel.append({ source: files[i] })
        }
        if (playlistModel.count > 0) {
            currentIndex = 0
            root.source = playlistModel.get(0).source
            console.log("已加载播放列表，共", playlistModel.count, "首：", root.source)
            console.log("缓存文件数量:", musicLibrary.getCachedFileCount())
        } else {
            console.warn("未找到音乐文件（项目根目录和Windows音乐文件夹）")
        }
    }

    function playAt(index) {
        if (index >= 0 && index < playlistModel.count) {
            currentIndex = index
            var newSource = playlistModel.get(index).source
            
            // 检查文件是否存在
            if (musicLibrary.isValidMusicFile && !musicLibrary.isValidMusicFile(newSource)) {
                console.warn("尝试播放不存在的文件:", newSource)
                // 从播放列表中移除无效文件
                playlistModel.remove(index)
                
                // 尝试播放下一首
                if (playlistModel.count > 0) {
                    var nextIndex = index >= playlistModel.count ? 0 : index
                    playAt(nextIndex)
                }
                return
            }
            
            // 切换前停止播放
            mediaPlayer.stop()

            // 设置新音源并开始播放
            if (root.source === newSource) {
                root.source = ""
            }
            root.source = newSource
            mediaPlayer.play()
        }
    }

    function playNext() {
        if (playlistModel.count === 0) return
        if (root.playMode === 2) { playRandom(); return }
        var next = (currentIndex + 1) % playlistModel.count
        playAt(next)
    }

    function playPrev() {
        if (playlistModel.count === 0) return
        if (root.playMode === 2) { playRandom(); return }
        var prev = (currentIndex - 1 + playlistModel.count) % playlistModel.count
        playAt(prev)
    }

    function playRandom() {
        if (playlistModel.count === 0) return
        var next = currentIndex
        if (playlistModel.count > 1) {
            do {
                next = Math.floor(Math.random() * playlistModel.count)
            } while (next === currentIndex)
        }
        playAt(next)
    }

    Component.onCompleted: {
        loadProjectPlaylist()
        // 初始化/更新取色
        coverColorSampler.requestPaint()
    }

    

    onNextClicked: playNext()
    onPreviousClicked: playPrev()

    // 当封面变更时，重新取色
    onCoverImageChanged: colorSampleTimer.restart()

    // 延迟触发取色，保证资源已加载
    Timer {
        id: colorSampleTimer
        interval: 200
        repeat: false
        onTriggered: coverColorSampler.requestPaint()
    }

    // 当封面图加载完成时，触发重绘取色
    Connections {
        target: coverSource
        function onStatusChanged() {
            if (coverSource.status === Image.Ready) {
                coverColorSampler.requestPaint()
            }
        }
    }

    // 播放时应用封面主色到主题；暂停/停止时回到默认强调色
    onIsPlayingChanged: function() {
        if (root.isPlaying) {
            root.previousFocusColor = theme.focusColor
            theme.focusColor = root.coverProminentColor
        } else {
            theme.focusColor = theme.defaultFocusColor
        }
    }

    // 当主色更新且处于播放中，实时同步到主题
    onCoverProminentColorChanged: function() {
        if (root.isPlaying) {
            theme.focusColor = root.coverProminentColor
        }
    }
}

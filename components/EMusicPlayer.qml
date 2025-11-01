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
    
    // C++ 元数据读取器
    AudioMetadata {
        id: metadataReader
        source: root.source
        
        onTitleChanged: {
            console.log("C++ 标题更新:", title)
            root.songTitle = title
        }
        
        onArtistChanged: {
            console.log("C++ 艺术家更新:", artist)
            root.artistName = artist
        }
        
        onCoverImageUrlChanged: {
            console.log("C++ 封面更新:", coverImageUrl)
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
            console.log("C++ 时长更新:", duration)
            root.duration = duration
        }
        
        onMetadataLoaded: {
            console.log("C++ 元数据加载完成")
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
            root.position = Math.floor(position / 1000)
            if (duration > 0) {
                root.progress = position / duration
            }
        }
        
        onDurationChanged: {
            console.log("音频时长:", Math.floor(duration / 1000), "秒")
        }
        
        onMetaDataChanged: {
            console.log("QML MediaPlayer元数据已更改（已由C++处理）")
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
            asynchronous: true
            sourceSize: Qt.size(Math.round(width), Math.round(height))
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
                        // 选择“显眼”像素：饱和度高、亮度适中
                        if (hsv.s > 0.4 && hsv.v > 0.2 && hsv.v < 0.9) {
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
                        // 回退：取整体平均色（不做浅化）
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

                    // 设置波纹颜色（半透明）与主题显色（不透明）
                    var accent = Qt.rgba(outR / 255.0, outG / 255.0, outB / 255.0, 1.0)
                    waveLayer.waveColor = Qt.rgba(accent.r, accent.g, accent.b, 0.35)
                    root.coverProminentColor = accent
                }
            }
        }

        // 柔和波纹效果（从专辑封面中心发出），不超出背景边界
        Item {
            id: waveLayer
            anchors.fill: parent
            z: 0.8
            clip: true
            visible: root.isPlaying && root.backgroundVisible && root.coverImage !== ""
            property color waveColor: Qt.rgba(theme.focusColor.r, theme.focusColor.g, theme.focusColor.b, 0.25)

            // 波纹圆环（3个错峰动画）
            Repeater {
                model: 3
                Rectangle {
                    id: ring
                    color: "transparent"
                    border.color: waveLayer.waveColor
                    border.width: 2
                    antialiasing: true
                    smooth: true

                    // 以背景容器内的专辑封面中心为波纹中心
                    property var centerPoint: coverContainer.mapToItem(backgroundContainer, coverContainer.width / 2, coverContainer.height / 2)
                    width: Math.min(backgroundContainer.width, backgroundContainer.height)
                    height: width
                    radius: width / 2
                    x: centerPoint.x - width / 2
                    y: centerPoint.y - height / 2

                    opacity: 0.0

                    transform: Scale {
                        id: ringScale
                        origin.x: ring.width / 2
                        origin.y: ring.height / 2
                        xScale: 0.2
                        yScale: 0.2
                    }

                    SequentialAnimation on opacity {
                        id: ringOpacityAnim
                        running: waveLayer.visible
                        loops: Animation.Infinite
                        PauseAnimation { duration: index * 400 }
                        NumberAnimation { to: 0.6; duration: 200; easing.type: Easing.OutQuad }
                        NumberAnimation { to: 0.0; duration: 1400; easing.type: Easing.InQuad }
                    }

                    SequentialAnimation {
                        id: ringScaleAnim
                        running: waveLayer.visible
                        loops: Animation.Infinite
                        PauseAnimation { duration: index * 400 }
                        ParallelAnimation {
                            NumberAnimation { target: ringScale; property: "xScale"; from: 0.2; to: 1.0; duration: 1600; easing.type: Easing.OutCubic }
                            NumberAnimation { target: ringScale; property: "yScale"; from: 0.2; to: 1.0; duration: 1600; easing.type: Easing.OutCubic }
                        }
                    }
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

    // （已移除）局部 EAnimatedWindow，改为调用 Main.qml 全局窗口

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
                asynchronous: true
                sourceSize: Qt.size(Math.round(width), Math.round(height))
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
                    property bool hovering: false
                    property bool dragging: false

                    // 进度填充容器（用于遮罩裁剪）
                    Item {
                        id: fillContainer
                        width: progressTrack.width * root.progress
                        height: progressTrack.height
                        anchors.verticalCenter: progressTrack.verticalCenter
                        z: 1

                        // 原始填充色
                        Rectangle {
                            id: progressFillColor
                            anchors.fill: parent
                            color: theme.focusColor
                            radius: progressTrack.height / 2
                            antialiasing: true
                            smooth: true
                        }

                        // 遮罩形状（圆角胶囊）
                        Item {
                            id: fillMask
                            anchors.fill: parent
                            visible: false
                            layer.enabled: true
                            layer.smooth: true
                            layer.samples: 4
                            Rectangle {
                                anchors.fill: parent
                                radius: progressTrack.height / 2
                                color: "black"
                                antialiasing: true
                                smooth: true
                            }
                        }

                        // 使用遮罩裁剪填充，使窄宽也保持圆角
                        MultiEffect {
                            anchors.fill: fillContainer
                            source: progressFillColor
                            maskEnabled: true
                            maskSource: fillMask
                            autoPaddingEnabled: false
                            antialiasing: true
                        }

                        Behavior on width {
                            NumberAnimation { duration: 100 }
                        }
                    }

                    // 可拖动圆点
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
                        // 回弹动画使用的缩放系数
                        property real animScale: 1.0
                        // 基础缩放（按下略微放大，悬停/拖动显示）
                        property real baseScale: progressArea.pressed ? 1.15 : 1.0
                        scale: (progressArea.containsMouse || progressTrack.dragging) ? animScale * baseScale : 0.0

                        Behavior on x { NumberAnimation { duration: 80 } }
                        Behavior on opacity { NumberAnimation { duration: 120 } }
                        Behavior on scale { enabled: !handleBounce.running; NumberAnimation { duration: 120; easing.type: Easing.OutCubic } }
                    }

                    // 轨道发光层（短暂脉冲）
                    Rectangle {
                        id: trackGlow
                        anchors.fill: fillContainer
                        anchors.margins: -1
                        radius: progressTrack.height / 2
                        color: theme.focusColor
                        opacity: 0.0
                        z: 1.5
                        antialiasing: true
                        smooth: true
                    }

                    // 圆点轻微回弹动画（释放时）
                    PropertyAnimation {
                        id: handleBounce
                        target: handleDot
                        property: "animScale"
                        from: 1.2
                        to: 1.0
                        duration: 180
                        easing.type: Easing.OutBack
                    }

                    // 轨道发光脉冲动画（释放时）
                    SequentialAnimation {
                        id: glowAnim
                        running: false
                        NumberAnimation { target: trackGlow; property: "opacity"; to: 0.28; duration: 120; easing.type: Easing.OutQuad }
                        NumberAnimation { target: trackGlow; property: "opacity"; to: 0.0; duration: 220; easing.type: Easing.InQuad }
                    }

                    // 悬停与拖动交互
                    MouseArea {
                        id: progressArea
                        anchors.fill: parent
                        hoverEnabled: true
                        cursorShape: Qt.PointingHandCursor

                        function setProgressAt(px) {
                            var newProgress = Math.max(0, Math.min(1, px / progressTrack.width))
                            root.progress = newProgress
                            mediaPlayer.position = newProgress * mediaPlayer.duration
                            root.seekPositionChanged(newProgress)
                        }

                        onEntered: progressTrack.hovering = true
                        onExited: progressTrack.hovering = false

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
                            // 释放时触发回弹与发光
                            handleBounce.restart()
                            glowAnim.restart()
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

                // 刷新按钮
                Text {
                    id: refreshButton
                    text: "\uf021" // FontAwesome 刷新图标
                    font.family: iconFont.name
                    font.pixelSize: root.itemIconSize - 2
                    color: refreshArea.pressed ? theme.focusColor : theme.textColor
                    verticalAlignment: Text.AlignVCenter
                    opacity: 0.8

                    // 旋转变换
                    transform: Rotation {
                        id: refreshRotationTransform
                        origin.x: refreshButton.width / 2
                        origin.y: refreshButton.height / 2
                        angle: 0
                    }

                    MouseArea {
                        id: refreshArea
                        anchors.fill: parent
                        anchors.margins: -5
                        cursorShape: Qt.PointingHandCursor
                        onClicked: {
                            console.log("手动刷新音乐列表")
                            refreshRotationAnimation.start()
                            loadProjectPlaylist()
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

                    // 旋转动画
                    SequentialAnimation {
                        id: refreshRotationAnimation
                        
                        NumberAnimation {
                            target: refreshRotationTransform
                            property: "angle"
                            from: 0
                            to: 360
                            duration: 600
                            easing.type: Easing.OutCubic
                        }
                        
                        // 重置角度
                        ScriptAction {
                            script: refreshRotationTransform.angle = 0
                        }
                    }
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
            
            // 切换前停止播放并清理封面，释放旧纹理
            mediaPlayer.stop()
            root.coverImage = ""

            // 设置新音源并开始播放
            root.source = newSource
            mediaPlayer.play()
        }
    }

    function playNext() {
        if (playlistModel.count === 0) return
        var next = (currentIndex + 1) % playlistModel.count
        playAt(next)
    }

    function playPrev() {
        if (playlistModel.count === 0) return
        var prev = (currentIndex - 1 + playlistModel.count) % playlistModel.count
        playAt(prev)
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

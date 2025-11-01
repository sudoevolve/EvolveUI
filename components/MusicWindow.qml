// MusicWindow.qml — 音乐窗口的内容组件（放入 EAnimatedWindow 内）
import QtQuick
import QtQuick.Controls
import QtQuick.Effects

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
    property var lyricsLines: [
        "飞机划过蓝色天际线",
        "是谁带走我心愿",
        "云端书里写着白色语言",
        "浪漫被晚风吹散",
        "我站在时光的背面",
        "等时间的道歉",
        "如果有天我突然失联",
        "你会不会习惯"
    ]

    FontLoader {
        id: iconFont
        source: "qrc:/new/prefix1/fonts/fontawesome-free-6.7.2-desktop/otfs/Font Awesome 6 Free-Solid-900.otf"
    }

    // 纯色底（始终存在，作为模糊封面之下的回退层）
    Rectangle {
        anchors.fill: parent
        color: theme ? theme.secondaryColor : "#222"
    }

    // 原始专辑封面图像源（隐藏，仅用于 MultiEffect 模糊）
    Image {
        id: fullscreenCoverSource
        anchors.fill: parent
        visible: false
        source: coverIsDefault ? "" : coverImage
        fillMode: Image.PreserveAspectCrop
        cache: false
        asynchronous: false
        antialiasing: true
        smooth: true
        mipmap: true
    }

    // 模糊封面背景
    MultiEffect {
        id: fullscreenCoverBlur
        anchors.fill: parent
        source: fullscreenCoverSource
        visible: !coverIsDefault && coverImage !== ""
        opacity: fullscreenCoverSource.status === Image.Ready ? 1 : 0
        Behavior on opacity { NumberAnimation { duration: 260; easing.type: Easing.OutCubic } }
        blurEnabled: true
        blur: 1.0
        blurMax: 64
        blurMultiplier: 2.0
        autoPaddingEnabled: false
    }

    // 半透明主题色叠加，压制过亮/过透明
    Rectangle {
        anchors.fill: parent
        color: theme ? theme.blurOverlayColor : Qt.rgba(0,0,0,0.3)
        visible: !coverIsDefault && coverImage !== ""
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

    // 左侧圆形封面（旋转 + 波纹）
    Item {
        id: rotatingCoverContainer
        anchors.left: parent.left
        anchors.leftMargin: 160
        anchors.verticalCenter: parent.verticalCenter
        width: Math.round(Math.min(parent.height * 0.42, parent.width * 0.32))
        height: width
        z: 4
        visible: !coverIsDefault && coverImage !== ""

        Image {
            id: rotatingCoverSource
            anchors.fill: parent
            source: coverImage
            fillMode: Image.PreserveAspectCrop
            cache: false
            asynchronous: false
            visible: false
            antialiasing: true
            smooth: true
            mipmap: true
        }

        Item {
            id: rotatingCoverMask
            anchors.fill: parent
            visible: false
            layer.enabled: true
            layer.smooth: true
            Rectangle {
                anchors.fill: parent
                radius: width / 2
                color: "black"
                antialiasing: true
                smooth: true
            }
        }

        MultiEffect {
            id: rotatingCoverMasked
            anchors.fill: parent
            source: rotatingCoverSource
            maskEnabled: true
            maskSource: rotatingCoverMask
            autoPaddingEnabled: false
            antialiasing: true
            layer.enabled: true
            layer.smooth: true
            maskThresholdMin: 0.5
            maskSpreadAtMin: 1.0
            layer.textureSize: Qt.size(Math.round(width), Math.round(height))
            transformOrigin: Item.Center
            z: 1
        }

        SequentialAnimation {
            id: coverSpinAnim
            running: sourceItem && sourceItem.isPlaying
            loops: Animation.Infinite
            NumberAnimation { target: rotatingCoverMasked; property: "rotation"; from: 0; to: 360; duration: 18000; easing.type: Easing.Linear }
        }

        Item {
            id: waveLayer
            anchors.fill: parent
            z: -0.5
            clip: false
            visible: sourceItem && sourceItem.isPlaying && !coverIsDefault && coverImage !== ""
            property color waveColor: theme ? Qt.rgba(theme.focusColor.r, theme.focusColor.g, theme.focusColor.b, 0.25) : Qt.rgba(255,255,255,0.25)

            Repeater {
                model: 3
                Rectangle {
                    id: ring
                    color: "transparent"
                    border.color: waveLayer.waveColor
                    border.width: 2
                    antialiasing: true
                    smooth: true

                    width: rotatingCoverContainer.width * 1.25
                    height: width
                    radius: width / 2
                    x: rotatingCoverContainer.width / 2 - width / 2
                    y: rotatingCoverContainer.height / 2 - height / 2

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

            Connections {
                target: sourceItem
                function onIsPlayingChanged() {
                    if (sourceItem && !sourceItem.isPlaying) {
                        rotatingCoverMasked.rotation = 0
                    }
                }
            }
        }
    }

    // 轻微噪声抖动
    ShaderEffect {
        anchors.fill: parent
        z: 2.1
        property real strength: theme && theme.isDark ? 0.05 : 0.03
        fragmentShader: "\n                    uniform lowp float qt_Opacity;\n                    uniform lowp float strength;\n                    void main() {\n                        highp float n = fract(sin(dot(gl_FragCoord.xy, vec2(12.9898, 78.233))) * 43758.5453);\n                        gl_FragColor = vec4(vec3(n), strength) * qt_Opacity;\n                    }\n                "
        visible: !coverIsDefault && coverImage !== ""
    }

    // 无封面：显示音乐图标（居中）
    Item {
        anchors.fill: rotatingCoverContainer
        z: 3
        visible: coverIsDefault || coverImage === ""
        Text {
            anchors.centerIn: parent
            text: "\uf001" // FontAwesome fa-music
            font.family: iconFont.name
            font.pixelSize: Math.round(Math.min(parent.width, parent.height) * 0.22)
            color: theme ? theme.textColor : "#ffffff"
            horizontalAlignment: Text.AlignHCenter
            verticalAlignment: Text.AlignVCenter
        }
    }

    // 右侧：标题 + 渐隐滚动歌词
    Item {
        id: lyricsPanel
        anchors.left: rotatingCoverContainer.right
        anchors.leftMargin: 260
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

            Flickable {
                id: lyricFlick
                width: parent.width
                height: lyricsPanel.height - 42
                contentWidth: width
                clip: true
                interactive: true
                boundsBehavior: Flickable.StopAtBounds
                property bool autoScroll: sourceItem && sourceItem.isPlaying

                Column {
                    id: lyricColumn
                    width: lyricFlick.width
                    spacing: 10
                    Repeater {
                        model: lyricsLines.length
                        delegate: Text {
                            width: lyricColumn.width
                            text: lyricsLines[index]
                            wrapMode: Text.NoWrap
                            horizontalAlignment: Text.AlignLeft
                            color: theme ? theme.textColor : "#ffffff"
                            font.pixelSize: 18
                        }
                    }
                }

                contentHeight: lyricColumn.height
                NumberAnimation on contentY {
                    running: lyricFlick.autoScroll && lyricColumn.height > lyricFlick.height
                    loops: Animation.Infinite
                    from: 0
                    to: Math.max(0, lyricColumn.height - lyricFlick.height)
                    duration: 24000
                    easing.type: Easing.Linear
                }

                Connections {
                    target: sourceItem
                    function onIsPlayingChanged() {
                        lyricFlick.autoScroll = sourceItem && sourceItem.isPlaying
                        if (!lyricFlick.autoScroll) {
                            lyricFlick.contentY = 0
                        }
                    }
                }
            }
        }
    }
}

// ECarousel.qml
import QtQuick
import QtQuick.Controls
import QtQuick.Layouts
import QtQuick.Effects

Item {
    id: root

    // ==== 公共/样式属性 ====
    property real radius: 20
    property bool shadowEnabled: true

    // ==== 数据模型 ====
    property var model: []
    property alias currentIndex: swipeView.currentIndex

    // ==== 尺寸/布局 ====
    implicitWidth: 400
    implicitHeight: width * 9 / 16

    // ==== 背景阴影效果 ====
    MultiEffect {
        source: background
        anchors.fill: background
        visible: root.shadowEnabled
        shadowEnabled: true
        shadowColor: theme.shadowColor
        shadowBlur: theme.shadowBlur
        shadowVerticalOffset: theme.shadowYOffset
        shadowHorizontalOffset: theme.shadowXOffset
    }

    // ==== 背景容器与滑动视图 ====
    Rectangle {
        id: background
        anchors.fill: parent
        radius: root.radius
        color: theme.secondaryColor
        clip: true

        // ==== 图片滑动视图 ====
        Item {
            id: swipeContainer
            anchors.fill: parent
            anchors.margins: -1

            SwipeView {
                id: swipeView
                anchors.fill: parent
                interactive: model.length > 1
                visible: true
                opacity: 0 // 保持可交互但不直接显示（由掩模负责显示）

                // ==== 图片重复显示 ====
                Repeater {
                    model: root.model
                    delegate: Item {
                        width: swipeView.width
                        height: swipeView.height

                        // 原始图像（隐藏），用于 MultiEffect 的 source
                        Image {
                            id: sourceItem
                            anchors.fill: parent
                            fillMode: Image.PreserveAspectCrop
                            cache: true
                            asynchronous: true
                            visible: true

                            // 使用组件大小优化加载
                            property int targetWidth: Math.round(swipeView.width)
                            property int targetHeight: Math.round(swipeView.height)
                            property string optimizedSource: {
                                var src = modelData
                                if (src.indexOf("?") === -1)
                                    return src + "?w=" + targetWidth + "&h=" + targetHeight
                                else
                                    return src + "&w=" + targetWidth + "&h=" + targetHeight
                            }
                            source: optimizedSource
                        }

                        // 移除单图圆角裁剪，保留容器级圆角显示

                        // 加载占位：主题色三点加载动画
                        ELoader {
                            anchors.centerIn: parent
                            size: Math.min(parent.width, parent.height) * 0.15
                            speed: 0.8
                            visible: sourceItem.status !== Image.Ready
                            running: visible
                            z: 2
                        }
                    }
                }
            }

            // 容器级掩模，保证滑动时区域保持圆角
            MultiEffect {
                id: swipeMasked
                source: swipeView
                anchors.fill: parent
                maskEnabled: true
                maskSource: containerMask
                autoPaddingEnabled: false
                antialiasing: true
                layer.enabled: true
                maskThresholdMin: 0.5
                maskSpreadAtMin: 1.0
                z: 1
            }

            // 整体加载占位：当未有图片数据时显示
            ELoader {
                anchors.centerIn: parent
                size: Math.min(parent.width, parent.height) * 0.15
                speed: 0.8
                visible: root.model.length === 0
                running: visible
                z: 3
            }

            // 圆角掩模图形
            Item {
                id: containerMask
                anchors.fill: parent
                layer.enabled: true

                visible: false
                Rectangle {
                    anchors.fill: parent
                    radius: root.radius
                    color: "black"
                }
            }
        }

        // ==== 底部页码指示器 ====
        PageIndicator {
            anchors.bottom: parent.bottom
            anchors.horizontalCenter: parent.horizontalCenter
            anchors.bottomMargin: 15
            count: swipeView.count
            currentIndex: swipeView.currentIndex
            delegate: Rectangle {
                height: 8
                width: index === currentIndex ? 24 : 8
                radius: 4
                color: theme.textColor
                opacity: 0.85
                Behavior on width {
                    NumberAnimation {
                        duration: 250
                        easing.type: Easing.InOutCubic
                    }
                }
            }
        }
    }

    // ==== 生命周期 ====
    Component.onCompleted: fetchBingImages()

    // ==== 函数：获取 Bing 图片 ====
    function fetchBingImages() {
        var xhr = new XMLHttpRequest()
        var url = "https://www.bing.com/HPImageArchive.aspx?format=js&idx=0&n=5&mkt=en-US&_=" + new Date().getTime()
        xhr.open("GET", url)
        xhr.onreadystatechange = function() {
            if (xhr.readyState === XMLHttpRequest.DONE) {
                if (xhr.status === 200) {
                    var response = JSON.parse(xhr.responseText)
                    var images = response.images
                    var urls = []
                    for (var i = 0; i < images.length; i++) {
                        urls.push("https://www.bing.com" + images[i].url)
                    }
                    root.model = urls
                } else {
                    console.log("Failed to fetch Bing images, status: " + xhr.status)
                }
            }
        }
        xhr.send()
    }
}

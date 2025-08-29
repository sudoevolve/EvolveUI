// BingImageCarousel.qml
import QtQuick
import QtQuick.Controls
import QtQuick.Layouts
import QtQuick.Effects
import Qt5Compat.GraphicalEffects

Item {
    id: root

    // ==== 公共/样式属性 ====
    readonly property Theme theme: Theme {}       // 主题对象
    property real radius: 15                       // 背景圆角
    property bool shadowEnabled: true              // 是否显示阴影

    // ==== 数据模型 ====
    property var model: []                          // 图片 URL 数组
    property alias currentIndex: swipeView.currentIndex  // 当前显示索引

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
        SwipeView {
            id: swipeView
            anchors.fill: parent
            interactive: model.length > 1

            layer.enabled: true
            layer.effect: OpacityMask {
                maskSource: Item {
                    width: swipeView.width
                    height: swipeView.height
                    Rectangle {
                        anchors.fill: parent
                        radius: root.radius
                    }
                }
            }

            // ==== 图片重复显示 ====
            Repeater {
                model: root.model
                delegate: Image {
                    width: swipeView.width
                    height: swipeView.height
                    source: modelData
                    fillMode: Image.PreserveAspectCrop
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

            // 鼠标悬停时显示
            opacity: hoverArea.containsMouse ? 1 : 0
            Behavior on opacity {
                OpacityAnimator {
                    duration: 300
                    easing.type: Easing.InOutQuad
                }
            }

            // ==== 页码点样式 ====
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

        // ==== 鼠标悬停捕获区 ====
        MouseArea {
            id: hoverArea
            anchors.fill: parent
            hoverEnabled: true

            onPressed: function(mouse) { mouse.accepted = false }
            onPositionChanged: function(mouse) { mouse.accepted = false }
            onReleased: function(mouse) { mouse.accepted = false }
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
                    console.log("Images count: " + response.images.length)
                    console.log(JSON.stringify(response.images))
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

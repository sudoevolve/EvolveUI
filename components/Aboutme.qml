// Aboutme.qml
import QtQuick
import QtQuick.Layouts

Item {
    id: root
    width: parent.width
    height: parent.height
    visible: true
    property bool windowOpen: false

    // 数据模型
    property var aboutItems: [
        { icon: "💼", label: "专业方向", value: "网络工程（Network Engineering）" },
        { icon: "🔐", label: "技术兴趣", value: "Linux、Figma、网络安全" },
        { icon: "🎨", label: "爱好创作", value: "交互界面开发、美学编程" },
        { icon: "🤯", label: "奇妙想法", value: "各种前端动画" }
    ]

    property int currentIndex: 0
    property string currentText: ""      // 当前正在显示的文本
    property bool isTyping: true         // true=打字中，false=删除中
    property int charIndex: 0            // 当前字符索引

    // 打字机定时器
    Timer {
        id: typewriterTimer
        interval: 80   // 每80ms打一个字
        repeat: true
        running: false

        onTriggered: {
            let item = root.aboutItems[root.currentIndex]
            let fullText = item.icon + " " + item.label + ": " + item.value

            if (root.isTyping) {
                // 正在打字
                root.charIndex += 1
                if (root.charIndex >= fullText.length) {
                    // 打完，停止打字机，启动延迟
                    root.isTyping = false
                    root.charIndex = fullText.length
                    root.currentText = fullText
                    typewriterTimer.stop()   // 👈 关键：停止定时器，避免干扰延迟
                    delayTimer.start()
                    return
                }
                root.currentText = fullText.substring(0, root.charIndex)
            } else {
                // 正在删除
                root.charIndex -= 1
                if (root.charIndex <= 0) {
                    // 删除完毕，切换到下一项
                    root.currentIndex = (root.currentIndex + 1) % root.aboutItems.length
                    root.isTyping = true
                    root.charIndex = 0
                    root.currentText = ""
                    typewriterTimer.interval = 80 // 重置打字速度
                    typewriterTimer.start()       // 重新开始打字
                    return
                }
                root.currentText = fullText.substring(0, root.charIndex)
            }
        }
    }

    // 延迟
    Timer {
        id: delayTimer
        interval: 1500
        repeat: false
        onTriggered: {
            typewriterTimer.interval = 30  // 删除更快一点
            typewriterTimer.start()        // 开始删除
        }
    }

    Column {
        anchors.centerIn: parent
        anchors.top: parent.top
        anchors.topMargin: 60
        spacing: 16

        Text {
            text: "Hello!我是"
            font.pixelSize: 48
            color: theme.textColor
            font.weight: Font.Bold
        }

        Text {
            text: "sudoevolve"
            font.pixelSize: 96
            color: theme.focusColor
            font.weight: Font.Bold
        }

        Text {
            text: "专注于前端架构、跨平台应用开发以及计算机图形学。"
            font.pixelSize: 36
            color: theme.textColor
            font.weight: Font.Normal
        }

        Text {
            text: "喜欢"
            font.pixelSize: 36
            color: theme.focusColor
            font.weight: Font.Normal
        }

        Item {
            width: parent.width
            height: 36
            Row {
                spacing: 12
                anchors.verticalCenter: parent.verticalCenter

                // 当前图标
                Text {
                    text: root.aboutItems[root.currentIndex].icon
                    font.pixelSize: 20
                    color: "#00bfff"
                }

                // 标签 + 值
                Text {
                    id: typewriterDisplay
                    text: root.currentText
                    font.pixelSize: 18
                    color: theme.focusColor
                    font.weight: Font.Bold
                }

                // 光标闪烁
                Text {
                    id: cursor
                    text: "|"
                    font.pixelSize: 18
                    color: theme.focusColor
                    font.weight: Font.Bold
                    visible: root.currentText.length > 0

                    Timer {
                        id: blinkTimer
                        interval: 500
                        repeat: true
                        running: root.windowOpen && root.currentText.length > 0

                        onTriggered: {
                            cursor.visible = !cursor.visible
                        }
                    }
                }
            }
        }

        

        // 按钮行
        RowLayout {
            spacing: 20
            anchors.horizontalCenter: parent.horizontalCenter
            anchors.topMargin: 20

            EButton {
                iconCharacter: "\uf006"
                iconFontFamily: iconFont.name
                iconRotateOnClick: true
                iconColor: "#E3B341"
                text: "关于我"
                onClicked: {
                        Qt.openUrlExternally("https://sudoevolve.github.io")
                    }
            }

            EButton {
                iconCharacter: "\uf0ac"
                iconFontFamily: iconFont.name
                iconRotateOnClick: true
                iconColor: theme ? theme.focusColor : "#00C4B3"
                text: "组件文档"
                onClicked: {
                    Qt.openUrlExternally("http://evolveui.top/")
                }
            }
        }
    }

    // 仅在窗口打开时运行打字机
    Component.onCompleted: {
        if (root.windowOpen) {
            root.isTyping = true
            root.charIndex = 0
            root.currentText = ""
            typewriterTimer.interval = 80
            typewriterTimer.start()
        }
    }

    onWindowOpenChanged: {
        if (root.windowOpen) {
            root.isTyping = true
            root.charIndex = 0
            root.currentText = ""
            typewriterTimer.interval = 80
            typewriterTimer.start()
        } else {
            typewriterTimer.stop()
            delayTimer.stop()
            blinkTimer.running = false
        }
    }
}

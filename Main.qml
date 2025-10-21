import QtQuick
import QtQuick.Controls
import QtQuick.Layouts
import QtQuick.Effects
import "components" as Components

ApplicationWindow {
    id: root
    visible: true
    width: 1200
    height:800
    minimumWidth: 1200
    minimumHeight: 800
    title: "Evolve UI"
    // 去除系统标题栏与边框，但保留普通窗口类型以出现在任务栏
    flags: Qt.Window | Qt.FramelessWindowHint

    // 动画窗口打开状态（用于控制右上角关闭按钮动画）
    // 动画窗口打开状态（自动聚合，避免逐个枚举）
    property bool anyAnimatedWindowOpen: theme.anyAnimatedWindowOpen

    FontLoader {
        id: iconFont
        source: "qrc:/new/prefix1/fonts/fontawesome-free-6.7.2-desktop/otfs/Font Awesome 6 Free-Solid-900.otf"
    }

    Components.ETheme {
        id: theme
    }

    color: theme.primaryColor

    // 全局：无边框窗口缩放边距
    readonly property int resizeMargin: 6

    Item {
        id: contentWrapper
        anchors.fill: parent

    Image {
        id: background
        anchors.fill: parent
        source: theme.backgroundImage
        fillMode: Image.PreserveAspectCrop
        asynchronous: true
        sourceSize.width: root.width
        sourceSize.height: root.height
        cache: false
        transformOrigin: Item.Center
        scale: root.anyAnimatedWindowOpen ? 1.2 : 1.0
        Behavior on scale { NumberAnimation { duration: 300; easing.type: Easing.OutQuad  } }
    }

    // 顶部可拖动区域（自定义标题栏）
    Rectangle {
        id: customTitleBar
        anchors.top: parent.top
        anchors.left: parent.left
        anchors.right: parent.right
        height: 36
        color: "transparent"
        z: 1000

        // 允许通过系统移动窗口（避免自己计算坐标）
        MouseArea {
            anchors.fill: parent
            hoverEnabled: true
            onPressed: root.startSystemMove()
        }

    }

    // === 无边框窗口缩放区域 ===

    // 左侧缩放
    Item {
        anchors.left: parent.left
        anchors.top: parent.top
        anchors.bottom: parent.bottom
        width: resizeMargin
        z: 1000
        MouseArea {
            anchors.fill: parent
            cursorShape: Qt.SizeHorCursor
            onPressed: root.startSystemResize(Qt.LeftEdge)
        }
    }

    // 右侧缩放
    Item {
        anchors.right: parent.right
        anchors.top: parent.top
        anchors.bottom: parent.bottom
        width: resizeMargin
        z: 1000
        MouseArea {
            anchors.fill: parent
            cursorShape: Qt.SizeHorCursor
            onPressed: root.startSystemResize(Qt.RightEdge)
        }
    }

    // 底边缩放
    Item {
        anchors.left: parent.left
        anchors.right: parent.right
        anchors.bottom: parent.bottom
        height: resizeMargin
        z: 1000
        MouseArea {
            anchors.fill: parent
            cursorShape: Qt.SizeVerCursor
            onPressed: root.startSystemResize(Qt.BottomEdge)
        }
    }

    // 顶边缩放（避开右上按钮区域）
    Item {
        anchors.left: parent.left
        anchors.right: parent.right
        anchors.top: parent.top
        anchors.rightMargin: titleButtonsPanel.width + 20
        height: resizeMargin
        z: 1000
        MouseArea {
            anchors.fill: parent
            cursorShape: Qt.SizeVerCursor
            onPressed: root.startSystemResize(Qt.TopEdge)
        }
    }

    // 左下角斜向缩放
    Item {
        anchors.left: parent.left
        anchors.bottom: parent.bottom
        width: resizeMargin
        height: resizeMargin
        z: 1000
        MouseArea {
            anchors.fill: parent
            cursorShape: Qt.SizeBDiagCursor
            onPressed: root.startSystemResize(Qt.LeftEdge | Qt.BottomEdge)
        }
    }

    // 右下角斜向缩放
    Item {
        anchors.right: parent.right
        anchors.bottom: parent.bottom
        width: resizeMargin
        height: resizeMargin
        z: 1000
        MouseArea {
            anchors.fill: parent
            cursorShape: Qt.SizeFDiagCursor
            onPressed: root.startSystemResize(Qt.RightEdge | Qt.BottomEdge)
        }
    }

    //标题
    Item {
        id: evolveTitle
        width: 400
        height: 120
        anchors.top: parent.top
        anchors.right: parent.right
        anchors.topMargin: 40


        Column {
            id: titleColumn
            spacing: 8
            anchors.centerIn: parent

            Row {
                spacing: 6
                anchors.horizontalCenter: parent.horizontalCenter

                Text { text: "E"; font.pixelSize: 48; font.bold: true; color: theme.focusColor }
                Text { text: "v"; font.pixelSize: 48; color: theme.focusColor }
                Text { text: "o"; font.pixelSize: 48; color: theme.focusColor }
                Text { text: "l"; font.pixelSize: 48; color: theme.focusColor }
                Text { text: "v"; font.pixelSize: 48; color: theme.focusColor }
                Text { text: "e"; font.pixelSize: 48; color: theme.focusColor }

                Text { text: " UI ✨"; font.pixelSize: 48; color: "#ffaa00" }
            }

            Rectangle {
                width: 180
                height: 28
                radius: 14
                color: theme.secondaryColor
                anchors.horizontalCenter: parent.horizontalCenter

                Text {
                    text: "🚀 组件库 Design System"
                    anchors.centerIn: parent
                    font.pixelSize: 14
                    color: theme.textColor
                }
            }
        }
    }


    // 左侧侧边栏毛玻璃卡片 + 透明列表
    Components.EBlurCard {
        id: leftSidebarCard
        width: 250
        height: parent.height
        blurSource: background
        borderRadius: 35
        anchors.top: parent.top
        anchors.left: parent.left
        anchors.bottom: parent.bottom
        anchors.leftMargin: -30
        layer.enabled: true

        // 透明版列表
        Components.EList {
            id: sidebarList
            backgroundVisible: false
            radius: 16
            width: parent.width - 40
            height: 180
            anchors.top: parent.top
            anchors.left: parent.left
            anchors.topMargin: 420
            anchors.leftMargin: 60

            model: ListModel {
                ListElement { display: "基础组件"; iconChar: "\uf118" }
                ListElement { display: "无背景组件"; iconChar: "\uf578" }
                ListElement { display: "其他组件"; iconChar: "\uf005" }
            }

            onItemClicked: function(index, data) {
                pages.currentIndex = index
            }
        }
    }


    //头像
    Components.EAvatar {
        id:avatar
        anchors.top: parent.top
        anchors.left: parent.left
        anchors.topMargin: 40
        anchors.leftMargin: 60
        avatarSource: "qrc:/new/prefix1/fonts/pic/avatar.png"
        MouseArea {
            anchors.fill: parent
            onPressed: parent.scale = 0.95
            onReleased: parent.scale = 1.0
            onCanceled: parent.scale = 1.0
            onClicked: {
                animationWrapper1.open(avatar)
            }
        }
    }

    //时间
    Components.ETimeDisplay {
        is24Hour: true
        anchors.top: parent.top
        anchors.left: parent.left
        anchors.topMargin: 160
        anchors.leftMargin: 50
    }

    Components.ESwitchButton {
        text: "侧边栏"
        anchors.bottom: parent.bottom
        anchors.left: parent.left
        anchors.bottomMargin: 100
        anchors.leftMargin: 20
        backgroundVisible: false
        onToggled: {
            console.log("开关状态:", checked)
            drawer1.toggle()
        }
    }

    Components.EButton {
         anchors.bottom: parent.bottom
         anchors.left: parent.left
         anchors.bottomMargin: 60
         anchors.leftMargin: 20
         backgroundVisible: false
         text: theme.isDark ? "切换为日间模式" : "切换为夜间模式"
         iconCharacter: theme.isDark ? "\uf186" : "\uf185"
         iconRotateOnClick: true
         onClicked: theme.toggleTheme()
     }

    Components.EBlurCard {
        id: blurCard
        width: pages.currentItem ? pages.currentItem.width + 30 : 0
        height: pages.currentItem ? pages.currentItem.height + 30 : 0
        visible: pages.currentItem !== null
        blurSource: background

        // 跟随 Flickable 滚动，在已加载页面后面形成模糊面板
        x: 260 - flickable.contentX + 12
        y: 600 - flickable.contentY + 12
        z: 0
        borderRadius: 35
    }

    //右侧内容

    Flickable {
            id: flickable
            anchors.fill: parent
            anchors.topMargin: 100
            anchors.leftMargin: 260  // 和左边 BlurCard 保持间距
            anchors.rightMargin: 40
            flickableDirection: Flickable.VerticalFlick
            clip: false
            contentWidth: pages.currentItem ? Math.max(flowContent.implicitWidth, pages.currentItem.width + 48) : flowContent.implicitWidth
            contentHeight: pages.currentItem ? Math.max(flowContent.implicitHeight, pages.currentItem.height + 48) : flowContent.implicitHeight

        // 页面加载器：点击左侧列表切换展示
        Item {
            id: pages
            anchors.left: parent.left
            anchors.top: parent.top
            anchors.leftMargin: 30
            anchors.topMargin: 580
            property int currentIndex: 0
            property var currentItem: currentIndex === 0 ? baseLoader.item : currentIndex === 1 ? noBgLoader.item : currentIndex === 2 ? otherLoader.item : null

            Loader {
                id: baseLoader
                source: "pages/BaseComponents.qml"
                active: pages.currentIndex === 0
                visible: pages.currentIndex === 0
                onLoaded: {
                    if (item && !item.theme) item.theme = theme
                    if (item && item.viewportWidth !== undefined) item.viewportWidth = flickable.width - 60
                }
            }
            Loader {
                id: noBgLoader
                source: "pages/NoBackgroundComponents.qml"
                active: pages.currentIndex === 1
                visible: pages.currentIndex === 1
                onLoaded: {
                    if (item && !item.theme) item.theme = theme
                    if (item && item.viewportWidth !== undefined) item.viewportWidth = flickable.width - 60
                }
            }
            Loader {
                id: otherLoader
                source: "pages/OtherComponents.qml"
                active: pages.currentIndex === 2
                visible: pages.currentIndex === 2
                onLoaded: {
                    if (item && !item.theme) item.theme = theme
                    if (item && item.viewportWidth !== undefined) item.viewportWidth = flickable.width - 60
                }
            }
        }


        Flow {
            id: flowContent
            width: flickable.width
            spacing: 16
            anchors.top: parent.top
            anchors.left: parent.left
            anchors.right: parent.right
            anchors.leftMargin: 30
            anchors.rightMargin: 30

            Rectangle {
                width: flowContent.width
                height: 600
                color: "transparent"
                // 占位用，制造底部空白
            }
        }

        // 保持页面 Flow 宽度随窗口大小变化
        Connections {
            target: flickable
            function onWidthChanged() {
                if (baseLoader.item && baseLoader.item.viewportWidth !== undefined) baseLoader.item.viewportWidth = flickable.width - 60
                if (noBgLoader.item && noBgLoader.item.viewportWidth !== undefined) noBgLoader.item.viewportWidth = flickable.width - 60
                if (otherLoader.item && otherLoader.item.viewportWidth !== undefined) otherLoader.item.viewportWidth = flickable.width - 60
            }
        }
    }

    Components.EDrawer {
        id: drawer1
        width: 300
        opened: false
        backgroundVisible: true
        anchors.right: parent.right
        anchors.rightMargin: -30
        padding: 30

        // 插入内容
        Components.ECheckBox {
            model: [
                    { text: "选项 A" },
                    { text: "选项 B" },
                    { text: "选项 C" },
                    { text: "选项 D" }
                ]

                onSelectionChanged: (indexes, items) => {
                    console.log("当前勾选索引：", indexes)
                    console.log("当前勾选项：", JSON.stringify(items))
                }
        }

        Components.ERadioButton {
            model: [
                    { text: "男" },
                    { text: "女" },
                    { text: "沃尔玛塑料袋" },
                    { text: "武装直升机" }
                ]

                onSelectionChanged: (index, item) => {
                    console.log("当前勾选索引：", index)

                }
        }

        Components.EDropdown {
            model: [
                { text: "番茄炒鸡蛋" },
                { text: "紫菜汤" },
                { text: "凉拌粉丝" },
                { text: "红烧排骨" }
            ]

            onSelectionChanged: function(index, data) {
                console.log("选中索引:", index, " 文本:", data.text)
            }
        }
    }

    Components.EAnimatedWindow {
        id: animationWrapper1
        Components.Aboutme {}
    }

    Components.EAnimatedWindow {
        id: animationWrapper2
        Column {
            spacing: 8
            anchors.centerIn: parent

            Components.EDataTable {
                width: 650
                height: 400
                selectable: true

                headers: [
                    { key: "index", label: "序号" },
                    { key: "name", label: "姓名" },
                    { key: "age", label: "年龄" },
                    { key: "city", label: "城市" },
                    { key: "email", label: "邮箱" },
                    { key: "about", label: "简介" }
                ]

                model: ListModel {
                    ListElement { name: "张三"; age: 25; city: "北京"; email: "zhangsan@example.com"; about: "热爱编程与开源项目，业余时间写技术博客，喜欢跑步和咖啡。"; checked: false }
                    ListElement { name: "李四"; age: 30; city: "上海"; email: "lisi@example.com"; about: "前端开发工程师，专注用户体验与响应式设计，热衷于探索新框架。"; checked: false }
                    ListElement { name: "王五"; age: 28; city: "广州"; email: "wangwu@example.com"; about: "全栈开发者，擅长Node.js与Python，周末常去爬山，是个户外运动爱好者。"; checked: false }
                    ListElement { name: "赵六"; age: 32; city: "深圳"; email: "zhaoliu@example.com"; about: "AI算法工程师，研究机器学习与计算机视觉，业余玩吉他和摄影。"; checked: false }
                    ListElement { name: "张三"; age: 25; city: "北京"; email: "zhangsan@example.com"; about: "热爱编程与开源项目，业余时间写技术博客，喜欢跑步和咖啡。"; checked: false }
                    ListElement { name: "李四"; age: 30; city: "上海"; email: "lisi@example.com"; about: "前端开发工程师，专注用户体验与响应式设计，热衷于探索新框架。"; checked: false }
                    ListElement { name: "王五"; age: 28; city: "广州"; email: "wangwu@example.com"; about: "全栈开发者，擅长Node.js与Python，周末常去爬山，是个户外运动爱好者。"; checked: false }
                    ListElement { name: "赵六"; age: 32; city: "深圳"; email: "zhaoliu@example.com"; about: "AI算法工程师，研究机器学习与计算机视觉，业余玩吉他和摄影。"; checked: false }
                    ListElement { name: "张三"; age: 25; city: "北京"; email: "zhangsan@example.com"; about: "热爱编程与开源项目，业余时间写技术博客，喜欢跑步和咖啡。"; checked: false }
                    ListElement { name: "李四"; age: 30; city: "上海"; email: "lisi@example.com"; about: "前端开发工程师，专注用户体验与响应式设计，热衷于探索新框架。"; checked: false }
                    ListElement { name: "王五"; age: 28; city: "广州"; email: "wangwu@example.com"; about: "全栈开发者，擅长Node.js与Python，周末常去爬山，是个户外运动爱好者。"; checked: false }
                    ListElement { name: "赵六"; age: 32; city: "深圳"; email: "zhaoliu@example.com"; about: "AI算法工程师，研究机器学习与计算机视觉，业余玩吉他和摄影。"; checked: false }
                }

                onRowClicked: {
                    console.log("点击行：", index, rowData.name)
                }

                onCheckStateChanged: {
                    console.log("勾选状态改变：", index, rowData.name, "checked =", isChecked)
                }
            }

            Components.ECardWithTextArea{
                width: 300
                height: 200
            }
        }
    }

    } // end of contentWrapper

    // 右上角窗口控制按钮面板（移至文件末尾）
    Components.EBlurCard {
        id: titleButtonsPanel
        anchors.right: parent.right
        anchors.top: parent.top
        anchors.rightMargin: 8
        anchors.topMargin: 4
        width: titleButtonsRow.implicitWidth + 14
        height: 38
        borderRadius: 14
        blurSource: contentWrapper
        blurAmount: 1.2
        blurMax: 32
        borderColor: Qt.rgba(theme.borderColor.r, theme.borderColor.g, theme.borderColor.b, theme.borderColor.a * 0.6)
        borderWidth: 1
        z: 1000

        transformOrigin: Item.TopRight
        opacity: root.anyAnimatedWindowOpen ? 0 : 1
        scale: root.anyAnimatedWindowOpen ? 0.6 : 1
        y: root.anyAnimatedWindowOpen ? -20 : 0

        Behavior on opacity { NumberAnimation { duration: 250; easing.type: Easing.OutCubic } }
        Behavior on scale { NumberAnimation { duration: 250; easing.type: Easing.OutCubic } }
        Behavior on y { NumberAnimation { duration: 250; easing.type: Easing.OutCubic } }

        Row {
            id: titleButtonsRow
            spacing: 8
            anchors.fill: parent
            anchors.margins: 7

            Components.EButton {
                width: 28
                height: 24
                radius: 12
                backgroundVisible: true
                text: ""
                iconCharacter: "\uf2d1"
                onClicked: root.showMinimized()
            }

            Components.EButton {
                width: 28
                height: 24
                radius: 12
                backgroundVisible: true
                text: ""
                iconCharacter: "\uf00d"
                onClicked: exitDialog.open()
            }
        }

        MouseArea {
            anchors.fill: parent
            z: 9999
            enabled: root.anyAnimatedWindowOpen
        }
    }

    Components.EAlertDialog {
        id: exitDialog
        title: "要退出应用吗？"
        message: "退出将关闭所有窗口。"
        cancelText: "取消"
        confirmText: "退出"
        dismissOnOverlay: false
        onConfirm: root.close()
    }

}

import QtQuick
import QtQuick.Layouts
import "../components" as Components

Flow {
    property var theme
    property var toastRef
    // 可视区域宽度（由 Main.qml 传入并保持同步）
    property int viewportWidth: 0
    spacing: 16
    width: viewportWidth > 0 ? viewportWidth : 850

    Rectangle {
        width: parent.width
        height: 50
        color: "transparent"
        // 分割占位
        Text {
            text: "--------😎主要组件😎--------"
            anchors.horizontalCenter: parent.horizontalCenter
            anchors.verticalCenter: parent.verticalCenter
            font.pixelSize: 30
            font.bold: true
            color: theme.textColor
        }
    }

    Rectangle {
        width: parent.width
        height: 50
        color: "transparent"
        // 分割占位
        Text {
            text: "🍭各种按钮："
            anchors.verticalCenter: parent.verticalCenter
            font.pixelSize: 20
            font.bold: true
            color: theme.textColor
        }
    }

    Components.EButton {
        text: theme.isDark ? "切换为日间模式" : "切换为夜间模式"
        iconCharacter: theme.isDark ? "\uf186" : "\uf185"
        iconRotateOnClick: true //图标旋转
        onClicked: {
            theme.toggleTheme()
            if (toastRef) toastRef.show(theme.isDark ? "已切换为夜间模式" : "已切换为日间模式")
        }
    }

    Components.EButton {
        id:home
        iconCharacter: "\uf015" // 设置图标字符，这里使用 FontAwesome 中的"主页"图标 Unicode 编码
        text: "主页"
        onClicked: {
            animationWrapper2.open(home)
        }
    }

    Components.EButton {
        text: "弹出 Toast"
        iconCharacter: "\uf0f3"
        onClicked: if (toastRef) toastRef.show("小手拍拍")
    }

    Components.EButton {
        iconCharacter: "\uf013"
        iconRotateOnClick: true
        text: ""
    }

    Components.EButton {
        text: "返回"
        iconCharacter: ""
    }

    Components.ESwitchButton {
        text: "侧边栏"
        onToggled: {
            console.log("开关状态:", checked)
        }
    }

    Rectangle {
        width: parent.width
        height: 50
        color: "transparent"
        // 分割占位
        Text {
            text: "😋一些表单："
            anchors.verticalCenter: parent.verticalCenter
            font.pixelSize: 20
            font.bold: true
            color: theme.textColor
        }
    }

    Components.ESlider {
        width: 280
        text: "音量"
        minimumValue: 0
        maximumValue: 100
        value: Math.round(theme.musicVolume * 100)
        onUserValueChanged: function(value) {
            theme.musicVolume = value / 100.0
            console.log("当前音量：", Math.round(theme.musicVolume * 100) + "%")
        }
    }

    Components.ESlider {
        width: 280
        text: "音量"
        showSpinBox: true
        minimumValue: 0
        maximumValue: 300
        value: 120
        onUserValueChanged: console.log("当前值：", value)
    }

    Components.EInput {
        width: 200
        placeholderText: "输入框 1"
        passwordField: false
    }

    Components.EInput {
        width: 200
        placeholderText: "输入框 2"
        passwordField: true
    }

    Components.ENavBar {
        model: [
            { display: "主页", iconChar: "\uf015" },
            { display: "搜索", iconChar: "\uf002" },
            { display: "设置", iconChar: "\uf013" }
        ]
        onItemClicked: (index, data) => console.log("点击导航项", index, data)
    }

    Rectangle {
        width: parent.width
        height: 16
        color: "transparent"
        // 分割占位
    }

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
            { text: "红烧排骨" }
        ]

        onSelectionChanged: function(index, data) {
            console.log("选中索引:", index, " 文本:", data.text)
        }
    }

    Components.EList {
        radius: 15
        width: 200
        height: 230
        model: ListModel {
            ListElement { display: "个人信息"; iconChar: "\uf007" }
            ListElement { display: "应用设置"; iconChar: "\uf013" }
            ListElement { display: "通知中心"; iconChar: "\uf0f3" }
            ListElement { display: "安全与隐私"; iconChar: "\uf132" }
            ListElement { display: "帮助与反馈"; iconChar: "\uf059" }
            ListElement { display: "关于我们"; iconChar: "\uf129" }
        }
        onItemClicked: (i, text) => console.log("Clicked:", i, text)
    }

    Rectangle {
        width: parent.width
        height: 50
        color: "transparent"
        // 分割占位
        Text {
            text: "🍀好多卡片："
            anchors.verticalCenter: parent.verticalCenter
            font.pixelSize: 20
            font.bold: true
            color: theme.textColor
        }
    }

    Components.ECard{
        ColumnLayout {
            spacing: 5
            Layout.alignment: Qt.AlignVCenter
            Text {
                text: "标题"
                font.bold: true
                font.pixelSize: 20
                color: theme.textColor
            }

            Components.EAvatar {
                avatarSource: "qrc:/new/prefix1/fonts/pic/avatar.png"
            }

            Text {
                text: "自适应大小卡片\n占位占位占位占位\n占位占位占位"
                font.pixelSize: 14
                color: theme.textColor
            }
        }
    }

    Components.ECardWithTextArea{
        width: 300
        height: 200
    }

    Components.ECalendar {
        width: 300
        onDateClicked: (clickedDate) => {
            console.log("选中的日期是: " + clickedDate.toLocaleDateString())
        }
    }

    Rectangle {
        width: parent.width
        height: 50
        color: "transparent"
        // 分割占位
        Text {
            text: "📊图表组件："
            anchors.verticalCenter: parent.verticalCenter
            font.pixelSize: 20
            font.bold: true
            color: theme.textColor
        }
    }

    Components.EAreaChart {
        width: 830
        height: 400
        title: "这是标题"
        subtitle: "这是描述，下面应该是每月数据"

        dataSeries: [
            {
                name: "Mobile",
                    color: Qt.lighter(theme.focusColor, 1.4),
                data: [
                    {month: "Jan", value: 120, label: "January"},
                    {month: "Feb", value: 180, label: "February"},
                    {month: "Mar", value: 237, label: "March"},
                    {month: "Apr", value: 160, label: "April"},
                    {month: "May", value: 90, label: "May"},
                    {month: "Jun", value: 200, label: "June"}
                ]
            },
            {
                name: "Desktop",
                color: theme.focusColor,
                data: [
                    {month: "Jan", value: 80, label: "January"},
                    {month: "Feb", value: 120, label: "February"},
                    {month: "Mar", value: 150, label: "March"},
                    {month: "Apr", value: 110, label: "April"},
                    {month: "May", value: 70, label: "May"},
                    {month: "Jun", value: 140, label: "June"}
                ]
            }
        ]

        onPointClicked: function(index, dataPoint) {
            console.log("点击数据点：", index, dataPoint.label, dataPoint.value)
        }

        onPointHovered: function(index, dataPoint) {
            console.log("悬停数据点：", index, dataPoint.label, dataPoint.value)
        }
    }

    Components.EDataTable {
        width: 830
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

    Components.EAccordion {
        width: 830
        title: "用户协议"

        // 直接把你的组件放在这里ColumnLayout来自动排列

        Text {
            wrapMode: Text.WordWrap
            Layout.alignment: Qt.AlignHCenter
            color: theme.textColor
            text: "请仔细阅读本协议"
            Layout.topMargin: 15
            Layout.bottomMargin: 15
        }
        Text {
            wrapMode: Text.WordWrap
            Layout.fillWidth: true
            color: theme.textColor
            text: "感谢您使用本开源UI库。为了保障您的权益和合理使用，请在使用前仔细阅读以下协议内容：\n\n许可授权\n本UI库采用[MIT]许可证开源，您可以自由使用、复制、修改和分发本库代码，但须保留原作者署名和版权声明。\n\n使用范围\n本库适用于个人或商业项目，您可根据项目需求自由集成和定制，但不得以任何形式声称本库为您原创。\n\n免责声明\n本库按现状提供，不保证完全无误或适合特定用途。作者对因使用本库导致的任何直接或间接损失不承担责任。\n\n贡献与反馈\n欢迎社区贡献代码、报告问题或提出建议，贡献内容默认同意采用本库许可证。\n\n协议修改\n本协议内容可根据项目发展适时更新，建议定期关注最新版本。"
            Layout.topMargin: 15
            Layout.bottomMargin: 30
            Layout.rightMargin: 30
            Layout.leftMargin: 30
        }
    }

    Rectangle {
        width: parent.width
        height: 1000
        color: "transparent"
        // 占位用，制造空白
    }
}

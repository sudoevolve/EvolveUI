//此页面为组件示例
import QtQuick
import QtQuick.Controls
import QtQuick.Layouts
import QtQuick.Effects
import Qt5Compat.GraphicalEffects
import "components" as Components

ApplicationWindow {
    id: root
    visible: true
    width: 1000
    height:800
    title: "Evolve UI"

    FontLoader {
        id: iconFont
        source: "qrc:/new/prefix1/fonts/fontawesome-free-6.7.2-desktop/otfs/Font Awesome 6 Free-Solid-900.otf"
    }

    Components.Theme {
        id: theme
    }

    color: theme.primaryColor

    Image {
        id: background
        anchors.fill: parent
        source: theme.backgroundImage
        fillMode: Image.PreserveAspectCrop
        cache: false
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

                Text { text: "E"; font.pixelSize: 48; font.bold: true; color: "#00C4B3" }
                Text { text: "v"; font.pixelSize: 48; color: "#00C4B3" }
                Text { text: "o"; font.pixelSize: 48; color: "#00C4B3" }
                Text { text: "l"; font.pixelSize: 48; color: "#00C4B3" }
                Text { text: "v"; font.pixelSize: 48; color: "#00C4B3" }
                Text { text: "e"; font.pixelSize: 48; color: "#00C4B3" }

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


    // 左侧侧边栏毛玻璃卡片
    Components.BlurCard {
        width: 240
        height: parent.height
        sourceItem: background
        blurRadius: 60
        borderRadius: 25
        anchors.top: parent.top
        anchors.left: parent.left
        anchors.bottom: parent.bottom
        anchors.leftMargin: -20
        layer.enabled: true
    }


    //头像
    Components.Avatar {
        anchors.top: parent.top
        anchors.left: parent.left
        anchors.topMargin: 40
        anchors.leftMargin: 60
        avatarSource: "qrc:/new/prefix1/fonts/pic/avatar.png"
        }

    //时间
    Components.TimeDisplay {
        is24Hour: true
        anchors.top: parent.top
        anchors.left: parent.left
        anchors.topMargin: 160
        anchors.leftMargin: 50
    }

    Components.Button {
        anchors.bottom: parent.bottom
        anchors.left: parent.left
        anchors.bottomMargin: 100
        anchors.leftMargin: 20
        backgroundVisible: false
        text: theme.isDark ? "切换为日间模式" : "切换为夜间模式"
        iconCharacter: theme.isDark ? "\uf186" : "\uf185"
        iconFontFamily: iconFont.name
        onClicked: theme.toggleTheme()
    }

    Components.BlurCard {
        id: blurCard
        width: flickable.width
        height: flowContent.height + 40
        sourceItem: background

        x: 260 - flickable.contentX  // 关键：x位置减去滚动偏移
        y: 600 - flickable.contentY      // y方向同理
        z: 0
        blurRadius:60
        borderRadius: 25

    }

    //右侧内容

    Flickable {
            id: flickable
            anchors.fill: parent
            anchors.topMargin: 0
            anchors.leftMargin: 260  // 和上方 BlurCard 保持间距
            anchors.rightMargin: 40
            clip: true
            contentWidth: flowContent.implicitWidth
            contentHeight: flowContent.implicitHeight


        Flow {
            id: flowContent
            width: flickable.width
            spacing: 16
            anchors.top: parent.top
            anchors.left: parent.left
            anchors.margins: 20  // 上下左右统一留白

            Rectangle {
                    width: flowContent.width
                    height: 600
                    color: "transparent"
                    // 占位用，制造顶部空白
                }

            Rectangle {
                    width: flickable.width
                    height: 50
                    color: "transparent"
                    // 分割占位
                    Text {
                        text: "--------😎主要组件😎--------"
                        anchors.horizontalCenter: parent.horizontalCenter
                        anchors.verticalCenter: parent.verticalCenter
                        font.pixelSize: 20
                        color: theme.textColor
                    }
                }

            Components.Button {
                text: theme.isDark ? "切换为日间模式" : "切换为夜间模式"
                iconCharacter: theme.isDark ? "\uf186" : "\uf185"
                iconFontFamily: iconFont.name
                onClicked: theme.toggleTheme()
            }

            Components.Button {
                iconCharacter: "\uf015" // 设置图标字符，这里使用 FontAwesome 中的“主页”图标 Unicode 编码
                iconFontFamily: iconFont.name  // 设置图标字体族名称，直接引用 main.qml 中 FontLoader 组件的 name 属性，确保字体正确
                text: "主页"
            }

            Components.Button {
                iconCharacter: "\uf013"
                iconFontFamily: iconFont.name
                text: ""
            }


            Components.Button {
                text: "返回"
                iconCharacter: ""
            }

            Components.SwitchButton {
                text: "高级模式"
                onToggled: console.log("开关状态:", checked)
            }

            Components.Slider {
                width: 300
                text: "音量"
                value: 30
                onUserValueChanged: console.log("当前值：", value)
            }

            Components.Input {
                width: 200
                placeholderText: "输入框 1"
                passwordField: false
            }

            Components.Input {
                width: 200
                placeholderText: "输入框 2"
                passwordField: true
            }

            Components.NavBar {
                model: [
                    { display: "主页", iconChar: "\uf015" },
                    { display: "搜索", iconChar: "\uf002" },
                    { display: "设置", iconChar: "\uf013" }
                ]
                onItemClicked: (index, data) => console.log("点击导航项", index, data)
            }

            Components.CheckBox {
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

            Components.RadioButton {
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

            Components.List {
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

            Components.Card{
                ColumnLayout {
                               spacing: 5
                               Layout.alignment: Qt.AlignVCenter
                               Text {
                                   text: "标题"
                                   font.bold: true
                                   font.pixelSize: 20
                                   color: theme.textColor
                               }

                               Components.Avatar {
                                   avatarSource: "qrc:/new/prefix1/fonts/pic/avatar.png"
                                   }

                               Text {
                                   text: "自适应大小卡片
占位占位占位占位
占位占位占位
占位占位占位"
                                   font.pixelSize: 14
                                   color: theme.textColor
                               }
                           }
            }

            Components.CardWithTextArea{
                width: 300
                height: 200
            }

            Components.Calendar {
                    width: 300
                    onDateClicked: (clickedDate) => {
                        console.log("选中的日期是: " + clickedDate.toLocaleDateString())
                        title = "选中: " + clickedDate.toLocaleDateString()
                    }
                }

            Components.Accordion {
                        width: 660
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
                            text: "感谢您使用本开源UI库。为了保障您的权益和合理使用，请在使用前仔细阅读以下协议内容：
许可授权
本UI库采用[GPL]许可证开源，您可以自由使用、复制、修改和分发本库代码，但须保留原作者署名和版权声明。

使用范围
本库适用于个人或商业项目，您可根据项目需求自由集成和定制，但不得以任何形式声称本库为您原创。

免责声明
本库按“现状”提供，不保证完全无误或适合特定用途。作者对因使用本库导致的任何直接或间接损失不承担责任。

贡献与反馈
欢迎社区贡献代码、报告问题或提出建议，贡献内容默认同意采用本库许可证。

协议修改
本协议内容可根据项目发展适时更新，建议定期关注最新版本。"
                            Layout.topMargin: 15
                            Layout.bottomMargin: 15
                            Layout.rightMargin: 30
                            Layout.leftMargin: 30
                        }
                    }

            Rectangle {
                    width: flowContent.width
                    height: 400
                    color: "transparent"
                    // 占位用，制造空白
                }



            //背景隐藏展示
            Rectangle {
                    width: flickable.width
                    height: 100
                    color: "transparent"
                    // 分割占位
                    Text {
                        text: "--------😘无背景组件😘--------"
                        font.pixelSize: 20
                        anchors.horizontalCenter: parent.horizontalCenter
                        anchors.verticalCenter: parent.verticalCenter
                        color: theme.textColor
                    }
                }


            Components.Button {
                backgroundVisible: false
                text: theme.isDark ? "切换为日间模式" : "切换为夜间模式"
                iconCharacter: theme.isDark ? "\uf186" : "\uf185"
                iconFontFamily: iconFont.name
                onClicked: theme.toggleTheme()
            }

            Components.Button {
                backgroundVisible: false
                iconCharacter: "\uf015" // 设置图标字符，这里使用 FontAwesome 中的“主页”图标 Unicode 编码
                iconFontFamily: iconFont.name  // 设置图标字体族名称，直接引用 main.qml 中 FontLoader 组件的 name 属性，确保字体正确
                text: "主页"
            }

            Components.Button {
                backgroundVisible: false
                iconCharacter: "\uf013"
                iconFontFamily: iconFont.name
                text: ""
            }

            Components.Button {
                backgroundVisible: false
                text: "返回"
                iconCharacter: ""
            }

            Components.SwitchButton {
                backgroundVisible: false
                text: "高级模式"
                onToggled: console.log("开关状态:", checked)
            }

            Components.Slider {
                backgroundVisible: false
                width: 300
                text: "音量"
                value: 30
                onUserValueChanged: console.log("当前值：", value)
            }

            Components.Input {
                backgroundVisible: false
                width: 200
                placeholderText: "输入框 1"
                passwordField: false
            }

            Components.Input {
                backgroundVisible: false
                width: 200
                placeholderText: "输入框 2"
                passwordField: true
            }

            Components.NavBar {
                backgroundVisible: false
                model: [
                    { display: "主页", iconChar: "\uf015" },
                    { display: "搜索", iconChar: "\uf002" },
                    { display: "设置", iconChar: "\uf013" }
                ]
                onItemClicked: (index, data) => console.log("点击导航项", index, data)
            }

            Components.CheckBox {
                backgroundVisible: false
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

            Components.RadioButton {
                backgroundVisible: false
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

            Components.List {
                backgroundVisible: false
                radius: 15
                width: 200
                height: 200
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

            Components.Card{
                backgroundVisible: false
                ColumnLayout {
                               spacing: 5
                               Layout.alignment: Qt.AlignVCenter
                               Text {
                                   text: "标题"
                                   font.bold: true
                                   font.pixelSize: 20
                                   color: theme.textColor
                               }

                               Components.Avatar {
                                   avatarSource: "qrc:/new/prefix1/fonts/pic/avatar.png"
                                   }

                               Text {
                                   text: "自适应大小卡片
占位占位占位占位
占位占位占位
占位占位占位"
                                   font.pixelSize: 14
                                   color: theme.textColor
                               }
                           }
            }

            Components.CardWithTextArea{
                backgroundVisible: false
                width: 300
                height: 200
            }

            Components.Calendar {
                    width: 300
                    backgroundVisible: false
                    onDateClicked: (clickedDate) => {
                        console.log("选中的日期是: " + clickedDate.toLocaleDateString())
                        title = "选中: " + clickedDate.toLocaleDateString()
                    }
                }

            Components.Accordion {
                        width: 660
                        title: "用户协议"
                        backgroundVisible: false

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
                            text: "感谢您使用本开源UI库。为了保障您的权益和合理使用，请在使用前仔细阅读以下协议内容：
许可授权
本UI库采用[GPL]许可证开源，您可以自由使用、复制、修改和分发本库代码，但须保留原作者署名和版权声明。

使用范围
本库适用于个人或商业项目，您可根据项目需求自由集成和定制，但不得以任何形式声称本库为您原创。

免责声明
本库按“现状”提供，不保证完全无误或适合特定用途。作者对因使用本库导致的任何直接或间接损失不承担责任。

贡献与反馈
欢迎社区贡献代码、报告问题或提出建议，贡献内容默认同意采用本库许可证。

协议修改
本协议内容可根据项目发展适时更新，建议定期关注最新版本。"
                            Layout.topMargin: 15
                            Layout.bottomMargin: 15
                            Layout.rightMargin: 30
                            Layout.leftMargin: 30
                        }
                    }

            Rectangle {
                    width: flickable.width
                    height: 400
                    color: "transparent"
                    // 占位用，制造底部空白
                }


            //其他组件
            Rectangle {
                    width: flickable.width
                    height: 100
                    color: "transparent"
                    // 分割占位
                    Text {
                        text: "--------🤯其他组件🤯--------"
                        font.pixelSize: 20
                        anchors.horizontalCenter: parent.horizontalCenter
                        anchors.verticalCenter: parent.verticalCenter
                        color: theme.textColor
                    }
                }


            Components.HoverCard {
                ColumnLayout {
                               spacing: 5
                               Layout.alignment: Qt.AlignVCenter
                               Text {
                                   text: "Hover卡片"
                                   font.bold: true
                                   font.pixelSize: 20
                                   color: theme.textColor
                               }

                               Components.Avatar {
                                   avatarSource: "qrc:/new/prefix1/fonts/pic/avatar.png"
                                   }

                               Text {
                                   text: "Hover卡片
占位占位占位占位
占位占位占位
占位占位占位"
                                   font.pixelSize: 14
                                   color: theme.textColor
                               }
                           }
            }

            Components.Carousel {
                    width: 400

                    model: [
                            ]

                    onCurrentIndexChanged: {
                        console.log("当前轮播图索引: " + currentIndex)
                    }
                }

            Components.Clock {

            }



            Rectangle {
                    width: flowContent.width
                    height: 200
                    color: "transparent"
                    // 占位用，制造底部空白
                }

        }
    }

}

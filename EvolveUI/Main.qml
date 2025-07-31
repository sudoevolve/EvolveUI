import QtQuick 2.15
import QtQuick.Controls 2.15
import QtQuick.Layouts 1.15
import "components" as Components

ApplicationWindow {
    visible: true
    width: 800
    height: 600
    title: "Flow + Flickable响应式布局"

    FontLoader {
        id: iconFont
        source: "qrc:/new/prefix1/fonts/fontawesome-free-6.7.2-desktop/otfs/Font Awesome 6 Free-Solid-900.otf"
    }

    Components.Theme {
        id: theme
    }

    color: theme.primaryColor



        Flow {
            id: flowContent
            width: parent.width
            spacing: 16
            anchors.top: parent.top
            anchors.left: parent.left
            anchors.margins: 20

            // 按钮示例，固定宽高，自动换行
            Components.Button {
                text: theme.isDark ? "切换为日间模式" : "切换为夜间模式"
                iconCharacter: theme.isDark ? "\uf186" : "\uf185"
                iconFontFamily: iconFont.name
                onClicked: theme.toggleTheme()
            }

            Components.Button {
                iconCharacter: "\uf015"
                iconFontFamily: iconFont.name
                text: "主页"
            }

            Components.Button {
                width: 60
                height: 60
                iconCharacter: "\uf013"
                iconFontFamily: iconFont.name
                text: ""
            }

            Components.Button {
                text: "返回"
                iconCharacter: ""
            }

            Components.CheckBox {
                text: "我已阅读并同意协议"
                onToggled: console.log("Checked: ", checked)
            }

            Components.SwitchButton {
                text: "启用高级模式"
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

            Components.RadioButton {
                model: [
                    { text: "选项一" },
                    { text: "选项二" },
                    { text: "选项三" }
                ]
                onSelectedChanged: {
                    console.log("选中了索引:", selectedIndex, "内容:", selectedData)
                }
            }

            Components.List {
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

            Components.HoverCard {

            }
        }

}

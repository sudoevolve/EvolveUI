import QtQuick 2.15
import QtQuick.Controls 2.15
import QtQuick.Layouts 1.15
import "components" as Components

ApplicationWindow {
    visible: true
    width: 800
    height: 600
    title: "流式组件排列示例"
    FontLoader {
        id: iconFont
        source: "qrc:/new/prefix1/fonts/fontawesome-free-6.7.2-desktop/otfs/Font Awesome 6 Free-Solid-900.otf"
    }


    // 主题实例
    Components.Theme {
        id: theme
    }

    // 背景色
    Rectangle {
        anchors.fill: parent
        color: theme.primaryColor
        z: -1
    }

    Flow {
        anchors.fill: parent
        anchors.margins: 20
        spacing: 12

        // 切换按钮
        Components.Button {
                    text: theme.isDark ? "切换为日间模式" : "切换为夜间模式"
                    onClicked: theme.toggleTheme()
                    iconCharacter: theme.isDark ? "\uf186" : "\uf185"  // 示例切换图标（moon/sun）
                    iconFontFamily: iconFont.name
                }

        Components.Button {
            iconCharacter: "\uf015"  // house 图标
            iconFontFamily: iconFont.name
            text: "主页"
        }

        Components.Button {
            iconCharacter: "\uf013"  // gear 图标
            iconFontFamily: iconFont.name
            width: 60
            height: 60
            text: ""
        }

        Components.Button {
            text: "按钮 3"
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
            text: "音量"
            value: 30
            onUserValueChanged: console.log("当前值：", value)
        }

        Components.Input {
            width: 150
            passwordField: false
            placeholderText: "输入框 1"
        }

        Components.Input {
            width: 150
            passwordField: true
            placeholderText: "输入框 2"
        }

        Components.RadioButton {
            id: singleGroup
                width: 160
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
            width: 150
            height: 200
            radius: 15
            model: ListModel {
                ListElement { display: "个人信息"; iconChar: "\uf007" }     // user
                ListElement { display: "应用设置"; iconChar: "\uf013" }     // gear
                ListElement { display: "通知中心"; iconChar: "\uf0f3" }     // bell
                ListElement { display: "安全与隐私"; iconChar: "\uf132" }   // shield-alt
                ListElement { display: "帮助与反馈"; iconChar: "\uf059" }   // question-circle
                ListElement { display: "关于我们"; iconChar: "\uf129" }     // info-circle
            }
            onItemClicked: (i, text) => console.log("Clicked:", i, text)
        }



        Components.HoverCard {

        }

    }
}

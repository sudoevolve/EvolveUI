import QtQuick
import QtQuick.Layouts
import "../components" as Components

Flow {
    property var theme
    // 主窗口传入：打开全屏音乐详情窗口的方法
    property var openMusicWindow
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
            text: "--------🤯其他组件🤯--------"
            font.pixelSize: 30
            font.bold: true
            anchors.horizontalCenter: parent.horizontalCenter
            anchors.verticalCenter: parent.verticalCenter
            color: theme.textColor
        }
    }

    Components.EHoverCard {
        ColumnLayout {
                       spacing: 5
                       Layout.alignment: Qt.AlignVCenter
                       Text {
                           text: "Hover卡片"
                           font.bold: true
                           font.pixelSize: 20
                           color: theme.textColor
                       }

                       Components.EAvatar {
                           avatarSource: "qrc:/new/prefix1/fonts/pic/avatar.png"
                           }

                       Text {
                           text: "Hover卡片\n占位占位占位占位\n占位占位占位\n占位占位占位"
                           font.pixelSize: 14
                           color: theme.textColor
                       }
                   }
    }

    Components.ECarousel {
            width: 400

            model: [
                    ]

            onCurrentIndexChanged: {
                console.log("当前轮播图索引: " + currentIndex)
            }
        }

    Components.EClock {

    }

    // 数字时钟卡片（使用网络天气，图标随天气自动切换）
    Components.EClockCard {
        useNetworkWeather: true
        // 心知天气：在示例中直接设置 Key 与地区
        weatherApiKey: "SLKpiXphkV7ch3vZp"
        weatherLocation: "chengdu"
    }

    Components.EMusicPlayer {
        id: musicPlayer
        // 直接传递全局音乐窗口的打开方法（单参数：源组件）
        openWindowHandler: musicAnimationWindow.openFrom
    }

    // 电量卡片
    Components.EBatteryCard {
        width: 140
        height: 140
        // 示例：可以直接设置电量百分比
        // batteryLevel: 76
    }

    // 每日一言卡片（背景为 Bing）
    Components.EHitokotoCard {
        width: 420
        height: 160
    }


    Components.EFitnessProgress {

    }

    // 年进度
    Components.EYearProgress {
        width: 260
        height: 90
    }

    // 最近节假日到来时间
    Components.ENextHolidayCountdown {
        width: 260
        height: 90
        // 如需自定义节日列表：
        // holidays: [ { name: "端午节", month: 6, day: 10 }, { name: "中秋节", month: 9, day: 16 } ]
    }

        // 简单日期选择器
    Components.ESimpleDatePicker {
        onDateClicked: (clickedDate) => {
            console.log("简单日期选择器选中: " + clickedDate.toLocaleDateString())
        }
    }

    Rectangle {
        width: parent.width
        height: 150
        color: "transparent"
        // 占位用，制造空白
    }

    Rectangle {
        width: 400
        height: 50
        color: "transparent"
        // 占位用，制造空白
    }

/*占用gpu过高
    Components.ELoader {
        size: 50
        x: 150
        speed: 0.8
    }
*/

    Rectangle {
        width: parent.width
        height: 1000
        color: "transparent"
        // 占位用，制造空白
    }
}




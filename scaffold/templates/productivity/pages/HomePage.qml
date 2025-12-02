import QtQuick
import QtQuick.Controls
import QtQuick.Layouts
import EvolveUI

Page {
    id:window
    property alias animatedWindow: animationWrapper
    background: Rectangle {
        color: "transparent"
    }

    // emoji Unicode 范围
    property var emojiRanges: [
        {start: 0x1F600, end: 0x1F64F},  // 😀 - 😻 表情符号
        {start: 0x1F300, end: 0x1F5FF},  // 🌍 - 🏁 自然 / 符号
        {start: 0x1F680, end: 0x1F6FF},  // 🚀 - 🛿 交通工具 / 符号
        {start: 0x1F30D, end: 0x1F567},  // 🌍 - 🕧 其他符号
        {start: 0x1F400, end: 0x1F4D3}   // 🐀 - 📓 动物 / 物品
    ]

    function randomEmoji() {
        // 随机选取一个 Unicode 范围
        var range = emojiRanges[Math.floor(Math.random() * emojiRanges.length)]
        var codePoint = range.start + Math.floor(Math.random() * (range.end - range.start + 1))
        return String.fromCodePoint(codePoint)
    }

    Component {
        id: gridButtonDelegate
        Rectangle {
            id: gridButton
            Layout.fillWidth: true
            Layout.fillHeight: true
            radius: 30
            color: Qt.rgba(Math.random(), Math.random(), Math.random(), 1)
            scale: 1.0
            Behavior on scale { NumberAnimation { duration: 100 } }

            property string currentEmoji: window.randomEmoji()

            Text {
                id: gridText
                text:  gridButton.currentEmoji
                anchors.centerIn: parent
                color: "white"
                font.pixelSize: 25
            }

            MouseArea {
                anchors.fill: parent
                onPressed: parent.scale = 0.95
                onReleased: parent.scale = 1.0
                onCanceled: parent.scale = 1.0
                onClicked: {
                    animationWrapper.open(gridButton)
                    gridButton.currentEmoji = window.randomEmoji()
                }
            }
        }
    }

    GridLayout {
        id: buttonGrid
        columns: 8
        anchors.fill: parent
        anchors.margins: 30
        columnSpacing: 20
        rowSpacing: 20
        Repeater {
            model: 40
            delegate: gridButtonDelegate
        }
    }

    EAnimatedWindow {
        id: animationWrapper
    }

}

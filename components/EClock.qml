// EClock.qml
import QtQuick

Item {
    id: clock
    width: 200
    height: 200

    // ==== 属性 ====
    property color faceColor: theme.secondaryColor
    property color hourHandColor: theme.textColor
    property color minuteHandColor: theme.borderColor
    property color secondDotColor: theme.focusColor

    property date currentTime: new Date()

    // ==== 定时器 ====
    Timer {
        interval: 1000
        running: true
        repeat: true
        onTriggered: clock.currentTime = new Date()
    }

    // ==== 表盘 ====
    Rectangle {
        id: clockFace
        anchors.fill: parent
        color: clock.faceColor
        radius: width / 2
        clip: true

        // 表盘中心
        property real centerX: width / 2
        property real centerY: height / 2

        // ==== 时针 ====
        Rectangle {
            id: hourHand
            width: parent.width * 0.08
            height: parent.height * 0.25
            color: clock.hourHandColor
            radius: width / 2
            x: clockFace.centerX - width / 2
            y: clockFace.centerY - height
            transformOrigin: Item.Bottom
            rotation: (clock.currentTime.getHours() % 12 + clock.currentTime.getMinutes() / 60) * 30
        }

        // ==== 分针 ====
        Rectangle {
            id: minuteHand
            width: parent.width * 0.05
            height: parent.height * 0.35
            color: clock.minuteHandColor
            radius: width / 2
            x: clockFace.centerX - width / 2
            y: clockFace.centerY - height
            transformOrigin: Item.Bottom
            rotation: (clock.currentTime.getMinutes() + clock.currentTime.getSeconds() / 60) * 6
        }

        // ==== 秒点沿圆周 ====
        Rectangle {
            id: secondDot
            width: parent.width * 0.06
            height: width
            color: clock.secondDotColor
            radius: width / 2

            property real pathRadius: parent.width / 2 - width * 1.5
            property real secondsAngle: clock.currentTime.getSeconds() * 6

            x: clockFace.centerX + pathRadius * Math.sin(secondsAngle * Math.PI / 180) - width / 2
            y: clockFace.centerY - pathRadius * Math.cos(secondsAngle * Math.PI / 180) - height / 2
        }
    }
}

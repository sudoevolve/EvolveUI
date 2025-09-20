// ETimeDisplay.qml
import QtQuick
import QtQuick.Controls

Item {
    id: timeDisplay
    width: 100
    height: 100

    // === 接口属性 ===
    property bool is24Hour: true
    property string currentHour: ""
    property string currentMinute: ""
    property bool separatorVisible: true

    // === 布局：时间显示 ===
    Column {
        anchors.centerIn: parent
        spacing: 4
        width: parent.width

        // === 小时文本 ===
        Text {
            id: hourText
            text: currentHour
            font.pixelSize: 60
            font.bold: true
            horizontalAlignment: Text.AlignHCenter
            color: theme.focusColor
            width: parent.width
        }

        // === 分隔线 ===
        Rectangle {
            id: separatorLine
            width: 60
            height: 2
            color: theme.textColor
            anchors.horizontalCenter: parent.horizontalCenter
            visible: separatorVisible
            radius: 1
        }

        // === 分钟文本 ===
        Text {
            id: minuteText
            text: currentMinute
            font.pixelSize: 60
            horizontalAlignment: Text.AlignHCenter
            color: theme.textColor
            width: parent.width
        }
    }

    // === 定时器：更新时间 ===
    Timer {
        id: updateTimer
        interval: 1000
        running: true
        repeat: true

        onTriggered: updateTime()
    }

    // === 方法：更新时间 ===
    function updateTime() {
        var now = new Date()
        var h = now.getHours()
        if (!is24Hour) {
            h = h % 12
            if (h === 0) h = 12
        }
        currentHour = h.toString().padStart(2, "0")
        currentMinute = now.getMinutes().toString().padStart(2, "0")
    }

    // === 初始化时间 ===
    Component.onCompleted: updateTime()
}

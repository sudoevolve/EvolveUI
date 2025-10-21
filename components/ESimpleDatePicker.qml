// ESimpleDatePicker.qml
import QtQuick
import QtQuick.Effects

Item {
    id: root
    
    // ==== 外部接口 ====
    property bool backgroundVisible: true
    property real radius: 20
    property int padding: 16
    property bool shadowEnabled: true
    
    property date selectedDate: new Date()
    signal dateClicked(date clickedDate)
    
    // 显示4天的日期
    property var dateRange: []
    
    implicitWidth: 280
    implicitHeight: 70
    
    // ==== 函数：生成日期范围 ====
    function generateDateRange() {
        var today = new Date()
        var tempRange = []
        
        // 从昨天开始的4天，今天排第二个
        for (var i = -1; i < 3; i++) {
            var date = new Date(today)
            date.setDate(today.getDate() + i)
            tempRange.push({
                date: date,
                dayName: getDayName(date.getDay()),
                dayNumber: date.getDate(),
                isToday: i === 0
            })
        }
        
        dateRange = tempRange
    }
    
    function getDayName(dayIndex) {
        var days = ["Fri", "Sat", "Sun", "Mon", "Tue", "Wed", "Thu"]
        return days[dayIndex]
    }
    
    function isSameDate(date1, date2) {
        return date1.getFullYear() === date2.getFullYear() &&
               date1.getMonth() === date2.getMonth() &&
               date1.getDate() === date2.getDate()
    }
    
    // ==== 生命周期 ====
    Component.onCompleted: generateDateRange()
    
    // ==== 视觉效果 (阴影) ====
    MultiEffect {
        source: background
        anchors.fill: background
        visible: root.shadowEnabled && root.backgroundVisible
        shadowEnabled: true
        shadowColor: theme.shadowColor
        shadowBlur: theme.shadowBlur
        shadowVerticalOffset: theme.shadowYOffset
        shadowHorizontalOffset: theme.shadowXOffset
    }
    
    // ==== 背景 ====
    Rectangle {
        id: background
        visible: root.backgroundVisible
        anchors.fill: parent
        radius: root.radius
        color: theme.secondaryColor
    }
    
    // ==== 日期项目布局 ====
    Row {
        anchors.centerIn: parent
        spacing: 12
        
        Repeater {
            model: dateRange
            delegate: Item {
                width: 55
                height: 50
                
                Rectangle {
                    anchors.fill: parent
                    radius: 16
                    color: modelData.isToday ? theme.focusColor : "transparent"
                    
                    Column {
                        anchors.centerIn: parent
                        spacing: 2
                        
                        // 星期几
                        Text {
                            text: modelData.dayName
                            font.pixelSize: 11
                            font.weight: Font.Normal
                            color: modelData.isToday ? 
                                   theme.secondaryColor : theme.borderColor
                            anchors.horizontalCenter: parent.horizontalCenter
                        }
                        
                        // 日期数字
                        Text {
                            text: modelData.dayNumber
                            font.pixelSize: 16
                            font.weight: Font.Bold
                            color: modelData.isToday ? 
                                   theme.secondaryColor : theme.textColor
                            anchors.horizontalCenter: parent.horizontalCenter
                        }
                        
                        // 今天指示点
                        Rectangle {
                            width: 4
                            height: 4
                            radius: 2
                            color: theme.focusColor
                            anchors.horizontalCenter: parent.horizontalCenter
                            visible: modelData.isToday
                        }
                    }
                }
            }
        }
    }
}
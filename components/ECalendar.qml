// ECalendar.qml
import QtQuick
import QtQuick.Layouts
import QtQuick.Effects

Item {
    id: root

    // ==== 外部接口 ====
    property bool backgroundVisible: true           // 是否显示背景
    property real radius: 20                        // 背景圆角
    property int padding: 15                        // 内边距
    property bool shadowEnabled: true               // 是否显示阴影

    property date selectedDate: new Date()          // 当前选中日期
    signal dateClicked(date clickedDate)            // 日期点击信号

    property int currentYear: selectedDate.getFullYear()  // 当前显示年份
    property int currentMonth: selectedDate.getMonth()    // 当前显示月份
    property var dayModel: []                               // 日历模型数据

    implicitWidth: contentLayout.implicitWidth + padding * 2
    implicitHeight: contentLayout.implicitHeight + padding * 2

    // ==== 函数：生成日历模型 ====
    function generateCalendarModel() {
        var tempModel = [],
            date = new Date(currentYear, currentMonth, 1),
            firstDayOfWeek = date.getDay(),
            daysInMonth = new Date(currentYear, currentMonth + 1, 0).getDate(),
            daysInPrevMonth = new Date(currentYear, currentMonth, 0).getDate(),
            today = new Date(),
            remaining,
            isToday,
            i; // 循环变量

        // 1. 上个月尾部日期
        for (i = 0; i < firstDayOfWeek; i++) {
            tempModel.push({
                day: daysInPrevMonth - firstDayOfWeek + 1 + i,
                isCurrentMonth: false,
                isToday: false,
                dateValue: new Date(currentYear, currentMonth - 1, daysInPrevMonth - firstDayOfWeek + 1 + i)
            });
        }

        // 2. 当前月日期
        for (i = 1; i <= daysInMonth; i++) {
            isToday = (currentYear === today.getFullYear() && currentMonth === today.getMonth() && i === today.getDate());
            tempModel.push({
                day: i,
                isCurrentMonth: true,
                isToday: isToday,
                dateValue: new Date(currentYear, currentMonth, i)
            });
        }

        // 3. 下个月开头日期
        remaining = 42 - tempModel.length;
        for (i = 1; i <= remaining; i++) {
            tempModel.push({
                day: i,
                isCurrentMonth: false,
                isToday: false,
                dateValue: new Date(currentYear, currentMonth + 1, i)
            });
        }

        dayModel = tempModel;
    }

    // ==== 函数：切换月份 ====
    function goToPrevMonth() {
        if (currentMonth > 0) currentMonth--;
        else { currentMonth = 11; currentYear--; }
    }

    function goToNextMonth() {
        if (currentMonth < 11) currentMonth++;
        else { currentMonth = 0; currentYear++; }
    }

    // ==== 生命周期/属性监听 ====
    Component.onCompleted: generateCalendarModel()
    onCurrentMonthChanged: generateCalendarModel()
    onCurrentYearChanged: generateCalendarModel()

    // ==== 视觉效果 (背景与阴影) ====
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

    Rectangle {
        id: background
        visible: root.backgroundVisible
        anchors.fill: parent
        radius: root.radius
        color: theme.secondaryColor
    }

    // ==== 布局主体 ====
    ColumnLayout {
        id: contentLayout
        anchors.fill: parent
        anchors.margins: root.padding

        // ==== 顶部年份与月份切换 ====
        RowLayout {
            Layout.fillWidth: true

            // 上个月按钮
            Text {
                text: "<"
                font.pixelSize: 20
                color: theme.focusColor
                Layout.preferredWidth: 30
                horizontalAlignment: Text.AlignHCenter
                MouseArea { anchors.fill: parent; cursorShape: Qt.PointingHandCursor; onClicked: goToPrevMonth() }
            }

            // 当前年月显示
            Text {
                text: currentYear + "年 " + (currentMonth + 1) + "月"
                font.pixelSize: 18
                font.bold: true
                color: theme.textColor
                Layout.fillWidth: true
                horizontalAlignment: Text.AlignHCenter
            }

            // 下个月按钮
            Text {
                text: ">"
                font.pixelSize: 20
                color: theme.focusColor
                Layout.preferredWidth: 30
                horizontalAlignment: Text.AlignHCenter
                MouseArea { anchors.fill: parent; cursorShape: Qt.PointingHandCursor; onClicked: goToNextMonth() }
            }
        }

        // ==== 星期标题 ====
        GridLayout {
            columns: 7
            Layout.topMargin: 10
            Layout.fillWidth: true

            Repeater {
                model: ["日", "一", "二", "三", "四", "五", "六"]
                delegate: Text {
                    text: modelData
                    color: theme.borderColor
                    font.bold: true
                    horizontalAlignment: Text.AlignHCenter
                    Layout.alignment: Qt.AlignCenter
                    Layout.fillWidth: true
                }
            }
        }

        // ==== 日期格子 ====
        GridLayout {
            id: dayGrid
            columns: 7
            Layout.topMargin: 5
            Layout.fillWidth: true
            columnSpacing: 4
            rowSpacing: 4

            Repeater {
                model: dayModel
                delegate: Rectangle {
                    Layout.fillWidth: true
                    Layout.preferredHeight: (dayGrid.width - (dayGrid.columns - 1) * dayGrid.columnSpacing) / dayGrid.columns
                    Layout.alignment: Qt.AlignCenter
                    radius: width / 2

                    // 选中背景
                    color: {
                        var d1 = modelData.dateValue
                        var d2 = selectedDate
                        if (d1.getFullYear() === d2.getFullYear() && d1.getMonth() === d2.getMonth() && d1.getDate() === d2.getDate())
                            return theme.focusColor
                        return "transparent"
                    }

                    // 日期文字
                    Text {
                        anchors.centerIn: parent
                        text: modelData.day
                        font.bold: modelData.isToday && modelData.isCurrentMonth
                        color: {
                            var d1 = modelData.dateValue
                            var d2 = selectedDate
                            if (d1.getFullYear() === d2.getFullYear() && d1.getMonth() === d2.getMonth() && d1.getDate() === d2.getDate())
                                return theme.isDark ? "#000000" : "#FFFFFF"
                            return modelData.isCurrentMonth ? theme.textColor : theme.borderColor
                        }
                    }

                    // 点击交互
                    MouseArea {
                        anchors.fill: parent
                        cursorShape: Qt.PointingHandCursor
                        onClicked: {
                            if (modelData.isCurrentMonth) {
                                root.selectedDate = modelData.dateValue
                                root.dateClicked(root.dateValue)
                            } else {
                                root.currentYear = modelData.dateValue.getFullYear()
                                root.currentMonth = modelData.dateValue.getMonth()
                                root.selectedDate = modelData.dateValue
                            }
                        }
                    }
                }
            }
        }
    }
}

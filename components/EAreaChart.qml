// EAreaChart.qml
import QtQuick
import QtQuick.Layouts
import QtQuick.Controls
import QtQuick.Effects

Rectangle {
    id: root

    width: 600
    height: 500
    color: "transparent"
    clip: false

    // === 接口属性 & 信号 ===
    property string title: "Area Chart"
    property string subtitle: "以下是前六个月用户访问数"
    
    // 支持多数据系列
    property var dataSeries: [
        {
            name: "Mobile",
            color: theme.focusColor,
            data: [
                {month: "Jan", value: 120, label: "January"},
                {month: "Feb", value: 180, label: "February"}, 
                {month: "Mar", value: 237, label: "March"},
                {month: "Apr", value: 160, label: "April"},
                {month: "May", value: 90, label: "May"},
                {month: "Jun", value: 200, label: "June"}
            ]
        }
    ]
    
    // 兼容单数据系列格式
    property var dataPoints: []
    
    // 内部计算属性：合并的数据系列
    readonly property var effectiveDataSeries: {
        if (dataPoints && dataPoints.length > 0) {
            // 使用旧格式
            return [{
                name: "Data",
                color: theme.focusColor,
                data: dataPoints
            }]
        } else {
            // 使用新格式
            return dataSeries
        }
    }

    // === 线条样式枚举 ===
    enum LineStyle {
        Smooth,
        Linear,
        Step
    }
    
    property int lineStyle: EAreaChart.LineStyle.Smooth

    property color areaColor: Qt.rgba(theme.focusColor.r, theme.focusColor.g, theme.focusColor.b, 0.3)
    property color lineColor: theme.focusColor
    property color tooltipColor: theme.primaryColor
    property color tooltipTextColor: theme.textColor
    property int hoveredIndex: -1

    signal pointClicked(int index, var dataPoint)
    signal pointHovered(int index, var dataPoint)

    // === 样式属性 ===
    property bool backgroundVisible: true
    property real radius: 20
    property int fontSize: 14
    property int titleFontSize: 18
    property int subtitleFontSize: 12
    property color backgroundColor: theme.secondaryColor
    property color textColor: theme.textColor
    property color subtitleColor: Qt.darker(theme.textColor, 1.5)
    property bool shadowEnabled: true
    property color shadowColor: theme.shadowColor
    property int chartPadding: 20
    property int topPadding: 90

    // === 计算属性 ===
    property real maxValue: {
        var max = 0;
        var series = root.effectiveDataSeries;
        for (var s = 0; s < series.length; s++) {
            var data = series[s].data;
            for (var i = 0; i < data.length; i++) {
                if (data[i].value > max) {
                    max = data[i].value;
                }
            }
        }
        return max;
    }

    property real chartWidth: width - chartPadding * 2
    property real chartHeight: height - topPadding - chartPadding - (legend.visible ? 60 : 0)

    // === 背景与阴影 ===
    Rectangle {
        id: background
        anchors.fill: parent
        radius: root.radius
        color: root.backgroundVisible ? root.backgroundColor : "transparent"

        layer.enabled: root.shadowEnabled && root.backgroundVisible
        layer.effect: MultiEffect {
            shadowEnabled: root.shadowEnabled
            shadowColor: root.shadowColor
            shadowBlur: theme.shadowBlur
            shadowHorizontalOffset: theme.shadowXOffset
            shadowVerticalOffset: theme.shadowYOffset
        }
    }

    // === 标题区域 ===
    Column {
        id: titleColumn
        anchors.top: parent.top
        anchors.left: parent.left
        anchors.margins: 40
        spacing: 5

        Text {
            text: root.title
            font.pixelSize: root.titleFontSize
            font.bold: true
            color: root.textColor
        }

        Text {
            text: root.subtitle
            font.pixelSize: root.subtitleFontSize
            color: root.subtitleColor
        }
    }

    // === 样式切换按钮 ===
    Rectangle {
        id: styleButton
        anchors.top: parent.top
        anchors.right: parent.right
        anchors.margins: 40
        width: 80
        height: 32
        radius: 16
        color: root.backgroundVisible ? theme.secondaryColor : "transparent"
        border.color: theme.borderColor
        border.width: root.backgroundVisible ? 1 : 0

        Text {
            anchors.centerIn: parent
            text: {
                switch(root.lineStyle) {
                    case EAreaChart.LineStyle.Smooth: return "Smooth"
                    case EAreaChart.LineStyle.Linear: return "Linear"
                    case EAreaChart.LineStyle.Step: return "Step"
                    default: return "Smooth"
                }
            }
            font.pixelSize: 12
            color: root.textColor
        }

        // 悬停效果
        Rectangle {
            anchors.fill: parent
            radius: parent.radius
            color: theme.focusColor
            opacity: styleButton.hovered ? 0.1 : 0
            
            Behavior on opacity {
                NumberAnimation { duration: 200 }
            }
        }

        property bool hovered: false
        MouseArea {
            anchors.fill: parent
            hoverEnabled: true
            onEntered: parent.hovered = true
            onExited: parent.hovered = false
            onClicked: {
                // 循环切换样式
                switch(root.lineStyle) {
                    case EAreaChart.LineStyle.Smooth:
                        root.lineStyle = EAreaChart.LineStyle.Linear
                        break
                    case EAreaChart.LineStyle.Linear:
                        root.lineStyle = EAreaChart.LineStyle.Step
                        break
                    case EAreaChart.LineStyle.Step:
                        root.lineStyle = EAreaChart.LineStyle.Smooth
                        break
                }
            }
        }
    }

    // === 图表区域 ===
    Item {
        id: chartArea
        anchors.fill: parent
        anchors.topMargin: root.topPadding
        anchors.margins: root.chartPadding

        // === 绘制区域图表 ===
        Canvas {
            id: chartCanvas
            anchors.fill: parent
            anchors.margins: 8  // 增加边距确保完整的圆形数据点可见
            anchors.bottomMargin: legend.visible ? 100 : 40  // 为横轴标签和图例留出空间
            
            // 绘制区域路径的函数
            function drawAreaPath(ctx, points, lineStyle) {
                switch(lineStyle) {
                    case EAreaChart.LineStyle.Linear:
                        // 直线连接
                        for (var i = 1; i < points.length; i++) {
                            ctx.lineTo(points[i].x, points[i].y);
                        }
                        break;
                    case EAreaChart.LineStyle.Step:
                        // 阶梯连接
                        for (var j = 1; j < points.length; j++) {
                            ctx.lineTo(points[j].x, points[j-1].y); // 水平线
                            ctx.lineTo(points[j].x, points[j].y);   // 垂直线
                        }
                        break;
                    case EAreaChart.LineStyle.Smooth:
                    default:
                        // 平滑曲线 - 使用Catmull-Rom样条
                        if (points.length > 2) {
                            // 第一段：从第一个点到第二个点
                            var cp1x = points[0].x + (points[1].x - points[0].x) * 0.25;
                            var cp1y = points[0].y;
                            var cp2x = points[1].x - (points[2].x - points[0].x) * 0.25;
                            var cp2y = points[1].y - (points[2].y - points[0].y) * 0.25;
                            ctx.bezierCurveTo(cp1x, cp1y, cp2x, cp2y, points[1].x, points[1].y);
                            
                            // 中间段：使用Catmull-Rom样条
                            for (var k = 2; k < points.length - 1; k++) {
                                var p0 = points[k-2];
                                var p1 = points[k-1];
                                var p2 = points[k];
                                var p3 = points[k+1];
                                
                                // Catmull-Rom控制点计算
                                var cp1x_cat = p1.x + (p2.x - p0.x) / 6;
                                var cp1y_cat = p1.y + (p2.y - p0.y) / 6;
                                var cp2x_cat = p2.x - (p3.x - p1.x) / 6;
                                var cp2y_cat = p2.y - (p3.y - p1.y) / 6;
                                
                                ctx.bezierCurveTo(cp1x_cat, cp1y_cat, cp2x_cat, cp2y_cat, p2.x, p2.y);
                            }
                            
                            // 最后一段：到最后一个点
                            if (points.length > 2) {
                                var lastIdx = points.length - 1;
                                var cp1x_last = points[lastIdx-1].x + (points[lastIdx].x - points[lastIdx-2].x) * 0.25;
                                var cp1y_last = points[lastIdx-1].y + (points[lastIdx].y - points[lastIdx-2].y) * 0.25;
                                var cp2x_last = points[lastIdx].x - (points[lastIdx].x - points[lastIdx-1].x) * 0.25;
                                var cp2y_last = points[lastIdx].y;
                                ctx.bezierCurveTo(cp1x_last, cp1y_last, cp2x_last, cp2y_last, points[lastIdx].x, points[lastIdx].y);
                            }
                        } else if (points.length === 2) {
                            // 只有两个点时，使用简单的二次曲线
                            var midX = (points[0].x + points[1].x) / 2;
                            var midY = (points[0].y + points[1].y) / 2;
                            ctx.quadraticCurveTo(midX, points[0].y, points[1].x, points[1].y);
                        } else {
                            // 只有一个点时，直接连线
                            ctx.lineTo(points[0].x, points[0].y);
                        }
                        break;
                }
            }
            
            // 绘制线条路径的函数
            function drawLinePath(ctx, points, lineStyle) {
                switch(lineStyle) {
                    case EAreaChart.LineStyle.Linear:
                        // 直线连接
                        for (var i = 1; i < points.length; i++) {
                            ctx.lineTo(points[i].x, points[i].y);
                        }
                        break;
                    case EAreaChart.LineStyle.Step:
                        // 阶梯连接
                        for (var j = 1; j < points.length; j++) {
                            ctx.lineTo(points[j].x, points[j-1].y); // 水平线
                            ctx.lineTo(points[j].x, points[j].y);   // 垂直线
                        }
                        break;
                    case EAreaChart.LineStyle.Smooth:
                    default:
                        // 平滑曲线 - 使用相同的Catmull-Rom算法
                        if (points.length > 2) {
                            // 第一段：从第一个点到第二个点
                            var cp1x_line = points[0].x + (points[1].x - points[0].x) * 0.25;
                            var cp1y_line = points[0].y;
                            var cp2x_line = points[1].x - (points[2].x - points[0].x) * 0.25;
                            var cp2y_line = points[1].y - (points[2].y - points[0].y) * 0.25;
                            ctx.bezierCurveTo(cp1x_line, cp1y_line, cp2x_line, cp2y_line, points[1].x, points[1].y);
                            
                            // 中间段：使用Catmull-Rom样条
                            for (var k = 2; k < points.length - 1; k++) {
                                var p0_line = points[k-2];
                                var p1_line = points[k-1];
                                var p2_line = points[k];
                                var p3_line = points[k+1];
                                
                                // Catmull-Rom控制点计算
                                var cp1x_cat_line = p1_line.x + (p2_line.x - p0_line.x) / 6;
                                var cp1y_cat_line = p1_line.y + (p2_line.y - p0_line.y) / 6;
                                var cp2x_cat_line = p2_line.x - (p3_line.x - p1_line.x) / 6;
                                var cp2y_cat_line = p2_line.y - (p3_line.y - p1_line.y) / 6;
                                
                                ctx.bezierCurveTo(cp1x_cat_line, cp1y_cat_line, cp2x_cat_line, cp2y_cat_line, p2_line.x, p2_line.y);
                            }
                            
                            // 最后一段：到最后一个点
                            if (points.length > 2) {
                                var lastIdx_line = points.length - 1;
                                var cp1x_last_line = points[lastIdx_line-1].x + (points[lastIdx_line].x - points[lastIdx_line-2].x) * 0.25;
                                var cp1y_last_line = points[lastIdx_line-1].y + (points[lastIdx_line].y - points[lastIdx_line-2].y) * 0.25;
                                var cp2x_last_line = points[lastIdx_line].x - (points[lastIdx_line].x - points[lastIdx_line-1].x) * 0.25;
                                var cp2y_last_line = points[lastIdx_line].y;
                                ctx.bezierCurveTo(cp1x_last_line, cp1y_last_line, cp2x_last_line, cp2y_last_line, points[lastIdx_line].x, points[lastIdx_line].y);
                            }
                        } else if (points.length === 2) {
                            // 只有两个点时，使用简单的二次曲线
                            var midX_line = (points[0].x + points[1].x) / 2;
                            var midY_line = (points[0].y + points[1].y) / 2;
                            ctx.quadraticCurveTo(midX_line, points[0].y, points[1].x, points[1].y);
                        } else if (points.length === 1) {
                            // 只有一个点时，不需要绘制线条
                        } else {
                            // 多个点时，直接连线
                            for (var l = 1; l < points.length; l++) {
                                ctx.lineTo(points[l].x, points[l].y);
                            }
                        }
                        break;
                }
            }
            
            onPaint: {
                var ctx = getContext("2d");
                ctx.clearRect(0, 0, width, height);
                
                var series = root.effectiveDataSeries;
                if (series.length === 0 || series[0].data.length === 0) return;

                // 使用第一个系列的数据长度作为基准
                var dataLength = series[0].data.length;
                var stepX = width / dataLength;
                var chartHeight = height - 16; // 为顶部和底部的数据点留出空间
                
                // 为每个数据系列绘制图表
                for (var seriesIndex = 0; seriesIndex < series.length; seriesIndex++) {
                    var currentSeries = series[seriesIndex];
                    var data = currentSeries.data;
                    
                    // 创建路径点 - 居中对齐
                    var points = [];
                    for (var i = 0; i < data.length; i++) {
                        var x = stepX * i + stepX / 2; // 居中对齐
                        var y = 8 + chartHeight - (data[i].value / root.maxValue) * chartHeight;
                        points.push({x: x, y: y});
                    }

                    // 绘制区域填充
                    ctx.beginPath();
                    ctx.moveTo(points[0].x, 8 + chartHeight); // 从底部开始
                    ctx.lineTo(points[0].x, points[0].y); // 到第一个数据点
                    
                    // 根据线条样式绘制不同的曲线
                    drawAreaPath(ctx, points, root.lineStyle);
                    
                    // 回到底部完成区域
                    ctx.lineTo(points[points.length-1].x, 8 + chartHeight);
                    ctx.closePath();
                    
                    // 填充区域 - 使用系列颜色的透明版本
                    var seriesColor = currentSeries.color;
                    var color = Qt.color(seriesColor);
                    ctx.fillStyle = Qt.rgba(color.r, color.g, color.b, 0.3);
                    ctx.fill();

                    // 绘制边界线
                    ctx.beginPath();
                    ctx.moveTo(points[0].x, points[0].y);
                    
                    drawLinePath(ctx, points, root.lineStyle);
                    
                    ctx.strokeStyle = seriesColor;
                    ctx.lineWidth = 2;
                    ctx.stroke();

                    // 绘制数据点 - 只在悬停时显示
                    if (root.hoveredIndex >= 0 && root.hoveredIndex < points.length) {
                        var hoveredPoint = points[root.hoveredIndex];
                        
                        // 绘制外圆
                        ctx.beginPath();
                        ctx.arc(hoveredPoint.x, hoveredPoint.y, 5, 0, 2 * Math.PI);
                        ctx.fillStyle = seriesColor;
                        ctx.fill();
                        
                        // 绘制内圆
                        ctx.beginPath();
                        ctx.arc(hoveredPoint.x, hoveredPoint.y, 3, 0, 2 * Math.PI);
                        ctx.fillStyle = "white";
                        ctx.fill();
                    }
                }
            }

            // 当数据改变时重新绘制
            Connections {
                target: root
                function onDataPointsChanged() { chartCanvas.requestPaint(); }
                function onDataSeriesChanged() { chartCanvas.requestPaint(); }
                function onAreaColorChanged() { chartCanvas.requestPaint(); }
                function onLineColorChanged() { chartCanvas.requestPaint(); }
                function onHoveredIndexChanged() { chartCanvas.requestPaint(); }
            }
        }

        // === 交互层 ===
        MouseArea {
            id: hoverMouseArea
            anchors.fill: parent
            hoverEnabled: true
            
            Timer {
                id: hideTimer
                interval: 200
                repeat: false
                onTriggered: {
                    root.hoveredIndex = -1;
                }
            }
            
            onPositionChanged: function(mouse) {
                hideTimer.stop();
                
                var series = root.effectiveDataSeries;
                if (series.length === 0 || series[0].data.length === 0) return;
                
                // 使用与绘制相同的坐标计算方式
                var dataLength = series[0].data.length;
                var stepX = chartCanvas.width / dataLength;
                var index = Math.floor(mouse.x / stepX);
                index = Math.max(0, Math.min(index, dataLength - 1));
                
                // 计算目标位置
                var baseX = root.chartPadding + index * stepX + stepX / 2;
                var targetX = Math.max(10, Math.min(baseX - tooltip.width/2, root.width - tooltip.width - 10));
                
                var dataValue = series[0].data[index].value;
                var dataY = root.topPadding + root.chartHeight - (dataValue / root.maxValue) * root.chartHeight;
                var targetY = Math.max(10, dataY - tooltip.height - 10);
                
                // 如果之前是隐藏状态，直接设置位置不显示动画
                if (root.hoveredIndex === -1) {
                    tooltip.x = targetX;
                    tooltip.y = targetY;
                } else {
                    tooltip.x = targetX;
                    tooltip.y = targetY;
                }
                
                if (index !== root.hoveredIndex) {
                    root.hoveredIndex = index;
                    root.pointHovered(index, series[0].data[index]);
                }
            }
            
            onExited: function() {
                hideTimer.start();
            }
            
            onClicked: function(mouse) {
                if (root.hoveredIndex >= 0) {
                    var series = root.effectiveDataSeries;
                    if (series.length > 0 && series[0].data.length > root.hoveredIndex) {
                        root.pointClicked(root.hoveredIndex, series[0].data[root.hoveredIndex]);
                    }
                }
            }
        }
    }

    // === X轴标签 ===
    Row {
        anchors.bottom: parent.bottom
        anchors.left: parent.left
        anchors.right: parent.right
        anchors.margins: root.chartPadding
        anchors.bottomMargin: legend.visible ? 75 : 15

        Repeater {
            model: root.effectiveDataSeries.length > 0 ? root.effectiveDataSeries[0].data : []
            delegate: Text {
                width: root.chartWidth / (root.effectiveDataSeries.length > 0 ? root.effectiveDataSeries[0].data.length : 1)
                text: modelData.month
                font.pixelSize: root.fontSize - 2
                color: root.subtitleColor
                horizontalAlignment: Text.AlignHCenter
            }
        }
    }

    // === 悬停提示框 ===
    Rectangle {
        id: tooltip
        // 使用 opacity 控制显示隐藏，配合 Behavior
        opacity: root.hoveredIndex >= 0 ? 1 : 0
        visible: opacity > 0
        
        width: tooltipContent.width + 20
        height: tooltipContent.height + 16
        radius: 8
        color: root.tooltipColor
        border.color: root.lineColor
        border.width: 1
        
        // 动态定位 - 现在由 MouseArea 控制
        x: 0
        y: 0
        
        // 添加平滑移动动画
        Behavior on x {
            enabled: root.hoveredIndex >= 0
            NumberAnimation { duration: 300; easing.type: Easing.OutCubic }
        }
        Behavior on y {
            enabled: root.hoveredIndex >= 0
            NumberAnimation { duration: 300; easing.type: Easing.OutCubic }
        }
        Behavior on opacity {
            NumberAnimation { duration: 200 }
        }

        Column {
            id: tooltipContent
            anchors.centerIn: parent
            spacing: 4

            Text {
                text: root.hoveredIndex >= 0 && root.effectiveDataSeries.length > 0 ? root.effectiveDataSeries[0].data[root.hoveredIndex].label : ""
                font.pixelSize: root.fontSize - 1
                color: root.tooltipTextColor
                font.bold: true
                anchors.horizontalCenter: parent.horizontalCenter
            }

            // 显示所有数据系列的值
            Repeater {
                model: root.effectiveDataSeries
                
                Row {
                    anchors.horizontalCenter: parent.horizontalCenter
                    spacing: 5
                    
                    Rectangle {
                        width: 8
                        height: 8
                        radius: 4
                        color: modelData.color
                        anchors.verticalCenter: parent.verticalCenter
                    }

                    Text {
                        text: modelData.name
                        font.pixelSize: root.fontSize - 2
                        color: root.subtitleColor
                        anchors.verticalCenter: parent.verticalCenter
                    }

                    Text {
                        text: root.hoveredIndex >= 0 && modelData.data.length > root.hoveredIndex ? modelData.data[root.hoveredIndex].value : ""
                        font.pixelSize: root.fontSize - 1
                        color: root.tooltipTextColor
                        font.bold: true
                        anchors.verticalCenter: parent.verticalCenter
                    }
                }
            }
        }

        // 提示框出现动画
        opacity: root.hoveredIndex >= 0 ? 1 : 0
        Behavior on opacity {
            NumberAnimation { duration: 150 }
        }
    }

    // === 底部图例 ===
    Row {
        id: legend
        anchors.bottom: parent.bottom
        anchors.horizontalCenter: parent.horizontalCenter
        anchors.bottomMargin: 20
        spacing: 30
        visible: root.effectiveDataSeries.length > 1 || (root.effectiveDataSeries.length === 1 && root.effectiveDataSeries[0].name !== "Data")

        Repeater {
            model: root.effectiveDataSeries
            
            Row {
                spacing: 8
                
                Rectangle {
                    width: 12
                    height: 12
                    radius: 2
                    color: modelData.color
                    anchors.verticalCenter: parent.verticalCenter
                }
                
                Text {
                    text: modelData.name
                    font.pixelSize: root.fontSize - 2
                    color: root.subtitleColor
                    anchors.verticalCenter: parent.verticalCenter
                }
            }
        }
    }

    // 监听线条样式变化
    Connections {
        target: root
        function onLineStyleChanged() {
            chartCanvas.requestPaint();
        }
    }
}

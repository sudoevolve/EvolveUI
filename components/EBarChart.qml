// EBarChart.qml
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
    property string title: "Bar Chart"
    property string subtitle: "数据统计概览"
    
    // 支持多数据系列
    property var dataSeries: [
        {
            name: "Sales",
            color: theme.focusColor,
            data: [
                {label: "Jan", value: 120},
                {label: "Feb", value: 180}, 
                {label: "Mar", value: 237},
                {label: "Apr", value: 160},
                {label: "May", value: 90},
                {label: "Jun", value: 200}
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

    property color barColor: theme.focusColor
    property color tooltipColor: theme.primaryColor
    property color tooltipTextColor: theme.textColor
    property int hoveredSeriesIndex: -1
    property int hoveredDataIndex: -1

    signal pointClicked(int seriesIndex, int dataIndex, var dataPoint)
    signal pointHovered(int seriesIndex, int dataIndex, var dataPoint)

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
    property real barSpacing: 0.2 // 柱状图间距比例 (0-1)
    property real groupSpacing: 0.3 // 组间距比例 (0-1)

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
        return max > 0 ? max : 100; // 避免除以0
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

    // === 图表区域 ===
    Item {
        id: chartArea
        anchors.fill: parent
        anchors.topMargin: root.topPadding
        anchors.margins: root.chartPadding

        // === 绘制柱状图 ===
        Canvas {
            id: chartCanvas
            anchors.fill: parent
            anchors.margins: 8
            anchors.bottomMargin: legend.visible ? 100 : 40
            
            property var barRects: [] // 存储柱子的区域用于鼠标检测

            onPaint: {
                var ctx = getContext("2d");
                ctx.clearRect(0, 0, width, height);
                
                var series = root.effectiveDataSeries;
                if (series.length === 0 || series[0].data.length === 0) return;

                var dataLength = series[0].data.length;
                var seriesCount = series.length;
                var chartH = height;
                
                // 计算宽度
                // 每一组数据的总宽度 (包含组间距)
                var groupTotalWidth = width / dataLength;
                // 实际的一组数据的宽度 (减去组间距)
                var groupWidth = groupTotalWidth * (1 - root.groupSpacing);
                // 单个柱子的宽度 (减去柱间距)
                var barWidth = (groupWidth / seriesCount) * (1 - (seriesCount > 1 ? root.barSpacing : 0));
                
                // 居中偏移
                var groupOffsetX = (groupTotalWidth - groupWidth) / 2;
                var barStepX = groupWidth / seriesCount;
                var barOffsetX = (barStepX - barWidth) / 2;

                barRects = []; // 重置点击区域

                // 绘制参考线 (Grid)
                ctx.beginPath();
                ctx.strokeStyle = Qt.rgba(root.textColor.r, root.textColor.g, root.textColor.b, 0.1);
                ctx.lineWidth = 1;
                for (var j = 0; j <= 5; j++) {
                    var lineY = chartH * (j / 5);
                    ctx.moveTo(0, lineY);
                    ctx.lineTo(width, lineY);
                }
                ctx.stroke();

                // 绘制柱子
                for (var i = 0; i < dataLength; i++) {
                    var groupX = i * groupTotalWidth + groupOffsetX;

                    for (var s = 0; s < seriesCount; s++) {
                        var data = series[s].data[i];
                        var val = data.value;
                        var barHeight = (val / root.maxValue) * chartH;
                        var x = groupX + s * barStepX + barOffsetX;
                        var y = chartH - barHeight;

                        // 记录区域用于交互
                        barRects.push({
                            x: x,
                            y: y,
                            w: barWidth,
                            h: barHeight,
                            seriesIndex: s,
                            dataIndex: i,
                            value: val,
                            label: data.label
                        });

                        // 绘制柱体
                        ctx.fillStyle = series[s].color;
                        
                        // 如果是悬停状态，改变透明度或亮度
                        if (root.hoveredSeriesIndex === s && root.hoveredDataIndex === i) {
                            ctx.globalAlpha = 0.8;
                        } else {
                            ctx.globalAlpha = 1.0;
                        }

                        // 圆角矩形绘制
                        var r = Math.min(barWidth / 2, 5);
                        ctx.beginPath();
                        ctx.moveTo(x + r, y);
                        ctx.lineTo(x + barWidth - r, y);
                        ctx.quadraticCurveTo(x + barWidth, y, x + barWidth, y + r);
                        ctx.lineTo(x + barWidth, y + barHeight);
                        ctx.lineTo(x, y + barHeight);
                        ctx.lineTo(x, y + r);
                        ctx.quadraticCurveTo(x, y, x + r, y);
                        ctx.closePath();
                        ctx.fill();
                    }
                }
                ctx.globalAlpha = 1.0;
            }

            // 当数据改变时重新绘制
            Connections {
                target: root
                function onDataPointsChanged() { chartCanvas.requestPaint(); }
                function onDataSeriesChanged() { chartCanvas.requestPaint(); }
                function onEffectiveDataSeriesChanged() { chartCanvas.requestPaint(); }
                function onTextColorChanged() { chartCanvas.requestPaint(); }
                function onHoveredSeriesIndexChanged() { chartCanvas.requestPaint(); }
                function onHoveredDataIndexChanged() { chartCanvas.requestPaint(); }
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
                    root.hoveredSeriesIndex = -1;
                    root.hoveredDataIndex = -1;
                }
            }
            
            onPositionChanged: function(mouse) {
                hideTimer.stop();
                
                var rects = chartCanvas.barRects;
                var found = false;
                
                // 转换坐标到canvas坐标系
                var canvasX = mouse.x - chartCanvas.x;
                var canvasY = mouse.y - chartCanvas.y;

                for (var i = 0; i < rects.length; i++) {
                    var r = rects[i];
                    if (canvasX >= r.x && canvasX <= r.x + r.w &&
                        canvasY >= r.y && canvasY <= r.y + r.h) {
                        
                        // 计算目标位置
                        var tooltipX = chartCanvas.x + r.x + r.w/2 - tooltip.width/2;
                        var tooltipY = chartCanvas.y + r.y - tooltip.height - 5;
                        
                        // 边界限制
                        var targetX = Math.max(0, Math.min(tooltipX, root.width - tooltip.width));
                        var targetY = tooltipY;
                        
                        // 如果之前是隐藏状态，直接设置位置不显示动画
                        if (root.hoveredSeriesIndex === -1) {
                            tooltip.x = targetX;
                            tooltip.y = targetY;
                        } else {
                            // 否则让 Behavior 处理动画
                            tooltip.x = targetX;
                            tooltip.y = targetY;
                        }

                        if (root.hoveredSeriesIndex !== r.seriesIndex || root.hoveredDataIndex !== r.dataIndex) {
                            root.hoveredSeriesIndex = r.seriesIndex;
                            root.hoveredDataIndex = r.dataIndex;
                            root.pointHovered(r.seriesIndex, r.dataIndex, root.effectiveDataSeries[r.seriesIndex].data[r.dataIndex]);
                        }
                        
                        found = true;
                        break;
                    }
                }
                
                if (!found) {
                    // 只有当不在任何柱子上时才启动隐藏计时器
                    // 但为了体验，我们可以让它保持显示直到移出区域或者超时
                    // 这里简化：如果不在柱子上，启动计时器
                    if (!hideTimer.running) hideTimer.start();
                }
            }
            
            onExited: function() {
                hideTimer.start();
            }
            
            onClicked: function(mouse) {
                if (root.hoveredSeriesIndex >= 0 && root.hoveredDataIndex >= 0) {
                    var series = root.effectiveDataSeries;
                    var data = series[root.hoveredSeriesIndex].data[root.hoveredDataIndex];
                    root.pointClicked(root.hoveredSeriesIndex, root.hoveredDataIndex, data);
                }
            }
        }
        
        // === Tooltip ===
        Rectangle {
            id: tooltip
            // 使用 opacity 控制显示隐藏，配合 Behavior
            opacity: (root.hoveredSeriesIndex >= 0 && root.hoveredDataIndex >= 0) ? 1 : 0
            visible: opacity > 0
            
            width: tooltipText.contentWidth + 20
            height: tooltipText.contentHeight + 10
            radius: 4
            color: root.tooltipColor
            border.color: root.barColor
            border.width: 1
            
            // 位置由 MouseArea 直接控制
            x: 0
            y: 0
            
            // 添加平滑移动动画
            Behavior on x {
                enabled: root.hoveredSeriesIndex >= 0 // 只有在显示状态下才启用动画
                NumberAnimation { duration: 300; easing.type: Easing.OutCubic }
            }
            Behavior on y {
                enabled: root.hoveredSeriesIndex >= 0
                NumberAnimation { duration: 300; easing.type: Easing.OutCubic }
            }
            Behavior on opacity {
                NumberAnimation { duration: 200 }
            }
            
            Text {
                id: tooltipText
                anchors.centerIn: parent
                color: root.tooltipTextColor
                text: {
                    if (root.hoveredSeriesIndex >= 0 && root.hoveredDataIndex >= 0) {
                        var series = root.effectiveDataSeries[root.hoveredSeriesIndex];
                        var item = series.data[root.hoveredDataIndex];
                        return (series.name ? series.name + "\n" : "") + (item.label || "") + ": " + item.value;
                    }
                    return "";
                }
                horizontalAlignment: Text.AlignHCenter
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
            model: root.effectiveDataSeries.length > 0 ? root.effectiveDataSeries[0].data.length : 0
            
            Item {
                width: (root.width - root.chartPadding * 2) / (root.effectiveDataSeries[0].data.length || 1)
                height: 20
                
                Text {
                    anchors.centerIn: parent
                    text: {
                        var series = root.effectiveDataSeries;
                        if (series.length > 0 && series[0].data.length > index) {
                            var item = series[0].data[index];
                            return item.label || item.month || "";
                        }
                        return "";
                    }
                    font.pixelSize: 10
                    color: root.textColor
                    elide: Text.ElideRight
                }
            }
        }
    }
    
    // === 图例 (Legend) ===
    Row {
        id: legend
        anchors.bottom: parent.bottom
        anchors.horizontalCenter: parent.horizontalCenter
        anchors.bottomMargin: 20
        spacing: 20
        visible: root.effectiveDataSeries.length > 1
        
        Repeater {
            model: root.effectiveDataSeries
            
            Row {
                spacing: 5
                Rectangle {
                    width: 12; height: 12
                    radius: 6
                    color: modelData.color
                    anchors.verticalCenter: parent.verticalCenter
                }
                Text {
                    text: modelData.name
                    color: root.textColor
                    font.pixelSize: 12
                    anchors.verticalCenter: parent.verticalCenter
                }
            }
        }
    }
}

// EPieChart.qml
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
    property string title: "Pie Chart"
    property string subtitle: "数据占比分析"
    
    // 数据系列 - 饼图通常只显示第一个系列的数据
    property var dataSeries: [
        {
            name: "Distribution",
            data: [
                {label: "Category A", value: 30, color: "#FF6384"},
                {label: "Category B", value: 20, color: "#36A2EB"}, 
                {label: "Category C", value: 15, color: "#FFCE56"},
                {label: "Category D", value: 25, color: "#4BC0C0"},
                {label: "Category E", value: 10, color: "#9966FF"}
            ]
        }
    ]
    
    // 兼容单数据系列格式
    property var dataPoints: []
    
    // 内部计算属性：合并的数据系列
    readonly property var effectiveData: {
        var data = [];
        if (dataPoints && dataPoints.length > 0) {
            data = dataPoints;
        } else if (dataSeries && dataSeries.length > 0) {
            data = dataSeries[0].data;
        }
        
        // 确保每个数据点都有颜色
        var defaultColors = ["#FF6384", "#36A2EB", "#FFCE56", "#4BC0C0", "#9966FF", "#FF9F40", "#C9CBCF"];
        var result = [];
        for (var i = 0; i < data.length; i++) {
            var item = data[i];
            // 浅拷贝对象以避免修改原始数据
            var newItem = {
                label: item.label || ("Item " + i),
                value: item.value,
                color: item.color || defaultColors[i % defaultColors.length]
            };
            result.push(newItem);
        }
        return result;
    }

    property color tooltipColor: theme.primaryColor
    property color tooltipTextColor: theme.textColor
    property int hoveredIndex: -1
    
    // 饼图特有属性
    property real innerRadius: 0 // 设置为 > 0 即为环形图(Donut Chart)
    property bool showLabels: true // 是否在扇区上显示标签

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
    property real totalValue: {
        var total = 0;
        var data = root.effectiveData;
        for (var i = 0; i < data.length; i++) {
            total += data[i].value;
        }
        return total > 0 ? total : 1;
    }

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

    // === 动画控制 ===
    Item {
        id: animationController
        visible: false
        Repeater {
            id: sliceAnimators
            model: root.effectiveData.length
            
            Item {
                property real currentOffset: 0
                
                // 目标值绑定
                property real targetOffset: index === root.hoveredIndex ? 10 : 0
                
                // 监听目标值变化并应用动画
                Behavior on currentOffset {
                    NumberAnimation { 
                        duration: 300 
                        easing.type: Easing.OutCubic 
                    }
                }
                
                // 将目标值同步给 currentOffset (通过绑定)
                Binding on currentOffset {
                    value: targetOffset
                }

                onCurrentOffsetChanged: chartCanvas.requestPaint()
            }
        }
    }

    // === 图表区域 ===
    Item {
        id: chartArea
        anchors.fill: parent
        anchors.topMargin: root.topPadding
        anchors.margins: root.chartPadding
        anchors.bottomMargin: legend.visible ? 100 : root.chartPadding

        Canvas {
            id: chartCanvas
            anchors.fill: parent
            
            property var sliceRects: [] // 存储每个扇区的信息用于交互

            onPaint: {
                var ctx = getContext("2d");
                ctx.clearRect(0, 0, width, height);
                
                var data = root.effectiveData;
                if (data.length === 0) return;

                var centerX = width / 2;
                var centerY = height / 2;
                // 半径取宽高中较小值的一半，留出一些边距
                var maxRadius = Math.min(width, height) / 2 - 20;
                
                var currentAngle = -Math.PI / 2; // 从12点钟方向开始
                var total = root.totalValue;
                
                sliceRects = [];

                for (var i = 0; i < data.length; i++) {
                    var item = data[i];
                    var sliceAngle = (item.value / total) * (Math.PI * 2);
                    var endAngle = currentAngle + sliceAngle;
                    
                    // 确定半径 (hover效果)
                    var r = maxRadius;
                    
                    // 获取动画偏移量
                    var animator = sliceAnimators.itemAt(i);
                    if (animator) {
                        r += animator.currentOffset;
                    }
                    
                    // 绘制扇区
                    ctx.beginPath();
                    ctx.moveTo(centerX, centerY);
                    // 如果是环形图，需要处理路径
                    if (root.innerRadius > 0) {
                        // 环形图稍微复杂，简单实现：画扇形，然后最后再盖住中间
                        // 或者使用 arc + lineTo
                        ctx.arc(centerX, centerY, r, currentAngle, endAngle, false);
                        ctx.arc(centerX, centerY, root.innerRadius, endAngle, currentAngle, true); // 反向画内圆
                    } else {
                        ctx.arc(centerX, centerY, r, currentAngle, endAngle, false);
                        ctx.lineTo(centerX, centerY);
                    }
                    ctx.closePath();
                    
                    ctx.fillStyle = item.color;
                    ctx.fill();
                    ctx.strokeStyle = root.backgroundColor; // 扇区间隔线
                    ctx.lineWidth = 2;
                    ctx.stroke();

                    // 记录角度信息用于交互
                    sliceRects.push({
                        startAngle: currentAngle,
                        endAngle: endAngle,
                        innerRadius: root.innerRadius,
                        outerRadius: r,
                        index: i,
                        data: item
                    });

                    // 绘制标签 (如果空间足够)
                    if (root.showLabels && sliceAngle > 0.1) {
                        var midAngle = currentAngle + sliceAngle / 2;
                        var labelRadius = root.innerRadius > 0 ? (r + root.innerRadius) / 2 : r * 0.7;
                        var lx = centerX + Math.cos(midAngle) * labelRadius;
                        var ly = centerY + Math.sin(midAngle) * labelRadius;
                        
                        ctx.fillStyle = "white"; // 假设深色背景或深色扇区
                        // 简单的亮度判断来决定文字颜色? 暂时统一白色或黑色
                        // 这里为了简单，如果颜色太亮用黑色，太暗用白色，或者统一白色带阴影
                        ctx.font = "bold 12px sans-serif";
                        ctx.textAlign = "center";
                        ctx.textBaseline = "middle";
                        
                        // 显示百分比
                        var percent = Math.round((item.value / total) * 100) + "%";
                        ctx.fillText(percent, lx, ly);
                    }

                    currentAngle = endAngle;
                }
                
                // 如果是环形图，中间是空的，不用额外处理，因为arc路径已经处理了
            }

            // 当数据改变时重新绘制
            Connections {
                target: root
                function onDataPointsChanged() { chartCanvas.requestPaint(); }
                function onDataSeriesChanged() { chartCanvas.requestPaint(); }
                function onEffectiveDataChanged() { chartCanvas.requestPaint(); }
                function onBackgroundColorChanged() { chartCanvas.requestPaint(); }
                function onHoveredIndexChanged() { chartCanvas.requestPaint(); }
            }
        }

        // === 交互层 ===
        MouseArea {
            id: interactionArea
            anchors.fill: parent
            hoverEnabled: true
            
            onPositionChanged: function(mouse) {
                var slices = chartCanvas.sliceRects;
                var centerX = chartCanvas.width / 2;
                var centerY = chartCanvas.height / 2;
                var dx = mouse.x - centerX;
                var dy = mouse.y - centerY;
                var dist = Math.sqrt(dx*dx + dy*dy);
                
                // 计算角度 (-PI ~ PI) -> (0 ~ 2PI)
                var angle = Math.atan2(dy, dx);
                // 调整角度以匹配绘制逻辑 (-PI/2 start)
                // atan2 返回 y,x。 0 是 3点钟。
                // 绘制是从 -PI/2 (12点) 开始顺时针。
                
                // 统一转为 0~2PI，从12点顺时针
                // atan2: 0(3点), PI/2(6点), PI/-PI(9点), -PI/2(12点)
                // 目标: 0(12点), PI/2(3点), PI(6点), 3PI/2(9点)
                
                var normalizedAngle = angle + Math.PI/2; // -PI/2 -> 0
                if (normalizedAngle < 0) normalizedAngle += Math.PI * 2;
                
                var found = false;
                for (var i = 0; i < slices.length; i++) {
                    var s = slices[i];
                    // 检查半径
                    if (dist >= s.innerRadius && dist <= s.outerRadius) {
                        // 检查角度
                        // s.startAngle 和 s.endAngle 是基于 -PI/2 为起点的弧度值(可能是负数或大于2PI累加)
                        // 我们需要将鼠标角度也转换到同样的参考系，或者将slice角度规范化
                        
                        // 简单做法：把slice的 start/end 也转为 0-2PI 相对 12点
                        var start = s.startAngle + Math.PI/2;
                        var end = s.endAngle + Math.PI/2;
                        
                        // 处理跨越 2PI 的情况 (应该不会，因为我们是累加的)
                        // 但为了保险，我们直接用相对值比较
                        // 实际上，我们在绘制时是从 -PI/2 开始累加正值的。
                        // 所以 startAngle 范围是 [-PI/2, 3PI/2] (一圈)
                        
                        // 让鼠标角度适应这个范围
                        var mouseA = angle;
                        if (mouseA < -Math.PI/2) mouseA += Math.PI * 2;
                        
                        if (mouseA >= s.startAngle && mouseA < s.endAngle) {
                            if (root.hoveredIndex !== s.index) {
                                root.hoveredIndex = s.index;
                                root.pointHovered(s.index, s.data);
                            }
                            found = true;
                            break;
                        }
                    }
                }
                
                if (!found) {
                    root.hoveredIndex = -1;
                }
            }
            
            onExited: function() {
                root.hoveredIndex = -1;
            }
            
            onClicked: function(mouse) {
                if (root.hoveredIndex >= 0) {
                    var data = root.effectiveData[root.hoveredIndex];
                    root.pointClicked(root.hoveredIndex, data);
                }
            }
        }
        
        // === Tooltip ===
        Rectangle {
            id: tooltip
            visible: root.hoveredIndex >= 0
            width: tooltipText.contentWidth + 20
            height: tooltipText.contentHeight + 10
            radius: 4
            color: root.tooltipColor
            border.color: theme.focusColor
            border.width: 1
            
            // 跟随鼠标
            x: {
                var pos = interactionArea.mouseX + 15;
                if (pos + width > root.width) return interactionArea.mouseX - width - 10;
                return pos;
            }
            y: {
                var pos = interactionArea.mouseY + 15;
                if (pos + height > root.height) return interactionArea.mouseY - height - 10;
                return pos;
            }

            Text {
                id: tooltipText
                anchors.centerIn: parent
                color: root.tooltipTextColor
                text: {
                    if (root.hoveredIndex >= 0) {
                        var item = root.effectiveData[root.hoveredIndex];
                        return item.label + ": " + item.value + " (" + Math.round(item.value/root.totalValue*100) + "%)";
                    }
                    return "";
                }
            }
        }
    }
    
    // === 图例 (Legend) ===
    Flow {
        id: legend
        anchors.bottom: parent.bottom
        anchors.left: parent.left
        anchors.right: parent.right
        anchors.margins: 20
        anchors.bottomMargin: 20
        spacing: 15
        
        Repeater {
            model: root.effectiveData
            
            Row {
                spacing: 5
                Rectangle {
                    width: 12; height: 12
                    radius: 6
                    color: modelData.color
                    anchors.verticalCenter: parent.verticalCenter
                }
                Text {
                    text: modelData.label
                    color: root.textColor
                    font.pixelSize: 12
                    anchors.verticalCenter: parent.verticalCenter
                }
            }
        }
    }
}

// EDataTable.qml
import QtQuick
import QtQuick.Layouts
import QtQuick.Controls
import QtQuick.Effects

Rectangle {
    id: root

    width: 600
    height: 400
    color: "transparent"
    clip: false

    // === 接口属性 & 信号 ===
    property var headers: []
    property ListModel model: ListModel {}
    property bool selectable: false
    signal rowClicked(int index, var rowData)
    signal checkStateChanged(int index, var rowData, bool isChecked)

    // === 样式属性 ===
    property bool backgroundVisible: true
    property real radius: 20
    property int headerHeight: 42
    property int rowHeight: 36
    property int fontSize: 14
    property int cellPadding: 12
    property real pressedScale: 0.97
    property color headerColor: theme.secondaryColor
    property color rowColor: theme.secondaryColor
    property color hoverColor: Qt.darker(rowColor, 1.15)
    property color textColor: theme.textColor
    property color headerTextColor: theme.textColor
    property bool shadowEnabled: true
    property color shadowColor: theme.shadowColor
    property color checkmarkColor: theme.focusColor
    property int boxSize: 20

    // === 动态列宽数组 ===
    property var columnWidths: []

    TextMetrics {
        id: textMetrics
        font.pixelSize: root.fontSize
    }

    // === 响应式表头全选状态 ===
    property string headerCheckState: "none" // none / all / partial

    onModelChanged: updateHeaderCheckState()
    onCheckStateChanged: updateHeaderCheckState()

    function updateHeaderCheckState() {
        if (!model || model.count === 0) {
            headerCheckState = "none";
            return;
        }

        var checkedCount = 0;
        var totalCount = model.count;

        for (var i = 0; i < totalCount; i++) {
            if (model.get(i).checked === true) {
                checkedCount++;
                if (checkedCount === totalCount) break;
            }
        }

        if (checkedCount === totalCount) {
            headerCheckState = "all";
        } else if (checkedCount > 0) {
            headerCheckState = "partial";
        } else {
            headerCheckState = "none";
        }
    }

    // === 计算列宽 ===
    function calculateColumnWidths() {
        var widths = [];
        var i, row, col;
        var value;

        // 初始化默认宽度
        for (i = 0; i < headers.length; i++) {
            widths.push(80);
        }

        // 计算表头宽度
        for (i = 0; i < headers.length; i++) {
            textMetrics.text = headers[i].label;
            widths[i] = Math.max(widths[i], textMetrics.width + cellPadding * 2);
        }

        // 计算数据行宽度
        if (model && model.count > 0) {
            for (row = 0; row < model.count; row++) {
                var rowObj = model.get(row);
                for (col = 0; col < headers.length; col++) {
                    var key = headers[col].key;
                    value = rowObj[key] !== undefined ? String(rowObj[key]) : "-";
                    textMetrics.text = value;
                    widths[col] = Math.max(widths[col], textMetrics.width + cellPadding * 2);
                }
            }
        }

        columnWidths = widths;
    }

    Component.onCompleted: calculateColumnWidths();
    onHeadersChanged: calculateColumnWidths();

    // === 背景与阴影===
    Rectangle {
        id: background
        anchors.fill: parent
        radius: root.radius
        color: root.backgroundVisible ? root.rowColor : "transparent"

        layer.enabled: root.shadowEnabled && root.backgroundVisible
        layer.effect: MultiEffect {
            shadowEnabled: root.shadowEnabled
            shadowColor: root.shadowColor
            shadowBlur: theme.shadowBlur
            shadowHorizontalOffset: theme.shadowXOffset
            shadowVerticalOffset: theme.shadowYOffset
        }

        // === 滚动区域（现在由 background 裁剪）===
        Flickable {
            id: flick
            anchors.fill: parent
            anchors.margins: 10
            clip: true
            flickableDirection: Flickable.HorizontalFlick
            contentWidth: (root.selectable ? 40 : 0) + columnWidths.reduce(function(a, b) { return a + b; }, 0)
            contentHeight: flick.height

            Column {
                width: flick.contentWidth

                // === 表头 ===
                Row {
                    id: headerRow
                    height: root.headerHeight
                    spacing: 0

                    // 全选复选框列
                    Rectangle {
                        visible: root.selectable
                        width: 40
                        height: parent.height
                        color: root.backgroundVisible ? root.headerColor : "transparent"

                        Rectangle {
                            id: headerCheckbox
                            anchors.centerIn: parent
                            width: root.boxSize
                            height: root.boxSize
                            radius: root.boxSize * 0.25
                            border.color: root.checkmarkColor
                            border.width: 2

                            color: root.headerCheckState === "all" ? root.checkmarkColor :
                                   root.headerCheckState === "partial" ? root.checkmarkColor : "transparent"

                            Behavior on color { ColorAnimation { duration: 150 } }

                            Text {
                                anchors.centerIn: parent
                                visible: root.headerCheckState === "all"
                                text: "\u2713"
                                color: root.rowColor
                                font.pixelSize: 16
                                Behavior on opacity { NumberAnimation { duration: 120 } }
                            }

                            Text {
                                anchors.centerIn: parent
                                visible: root.headerCheckState === "partial"
                                text: "\u2212"
                                color: root.rowColor
                                font.pixelSize: 18
                                font.bold: true
                                Behavior on opacity { NumberAnimation { duration: 120 } }
                            }

                            MouseArea {
                                anchors.fill: parent
                                cursorShape: Qt.PointingHandCursor
                                onClicked: {
                                    var newState = root.headerCheckState !== "all";
                                    for (var i = 0; i < root.model.count; i++) {
                                        root.model.setProperty(i, "checked", newState);
                                    }
                                    root.updateHeaderCheckState();
                                }
                            }
                        }
                    }

                    // 数据列头
                    Repeater {
                        model: root.headers
                        delegate: Rectangle {
                            width: root.columnWidths[index]
                            height: parent.height
                            color: root.backgroundVisible ? root.headerColor : "transparent"

                            Text {
                                anchors.centerIn: parent
                                text: modelData.label
                                font.pixelSize: root.fontSize
                                font.bold: true
                                color: root.headerTextColor
                                elide: Text.ElideRight
                            }
                        }
                    }
                }

                // === 数据区 ===
                ListView {
                    id: tableView
                    width: flick.contentWidth
                    height: flick.height - headerRow.height
                    spacing: 2
                    model: root.model
                    clip: true

                    delegate: Rectangle {
                        id: rowContainer
                        width: tableView.width
                        height: root.rowHeight
                        radius: root.radius * 0.5

                        property bool checked: (model.checked !== undefined) ? model.checked : false
                        property var rowData: model
                        property bool hovered: false

                        color: root.backgroundVisible ? (hovered ? root.hoverColor : root.rowColor) : "transparent"
                        opacity: 1.0

                        Behavior on color { ColorAnimation { duration: 150 } }
                        Behavior on opacity { NumberAnimation { duration: 100 } }

                        transform: Scale {
                            id: scale
                            origin.x: rowContainer.width / 2
                            origin.y: rowContainer.height / 2
                        }

                        ParallelAnimation {
                            id: restoreAnimation
                            SpringAnimation { target: scale; property: "xScale"; to: 1.0; spring: 2.5; damping: 0.25 }
                            SpringAnimation { target: scale; property: "yScale"; to: 1.0; spring: 2.5; damping: 0.25 }
                        }

                        Row {
                            anchors.fill: parent
                            spacing: 0

                            // 单行复选框
                            Rectangle {
                                visible: root.selectable
                                width: 40
                                height: parent.height
                                color: "transparent"

                                Rectangle {
                                    id: checkboxRect
                                    anchors.centerIn: parent
                                    width: root.boxSize
                                    height: root.boxSize
                                    radius: root.boxSize * 0.25
                                    border.color: root.checkmarkColor
                                    border.width: 2
                                    color: rowContainer.checked ? root.checkmarkColor : "transparent"
                                    Behavior on color { ColorAnimation { duration: 150 } }

                                    Text {
                                        anchors.centerIn: parent
                                        visible: rowContainer.checked
                                        text: "\u2713"
                                        color: root.rowColor
                                        font.pixelSize: 16
                                    }
                                }
                            }

                            // 数据列
                            Repeater {
                                model: root.headers
                                delegate: Rectangle {
                                    width: root.columnWidths[index]
                                    height: parent.height
                                    color: "transparent"

                                    Text {
                                        anchors.centerIn: parent
                                        text: rowData[modelData.key] !== undefined ? rowData[modelData.key] : "-"
                                        color: root.textColor
                                        font.pixelSize: root.fontSize
                                        elide: Text.ElideRight
                                    }
                                }
                            }
                        }

                        // 点击整行交互
                        MouseArea {
                            anchors.fill: parent
                            hoverEnabled: true
                            cursorShape: Qt.PointingHandCursor

                            onEntered: rowContainer.hovered = true
                            onExited: rowContainer.hovered = false

                            onPressed: {
                                scale.xScale = root.pressedScale
                                scale.yScale = root.pressedScale
                                rowContainer.opacity = 0.85
                            }

                            onReleased: {
                                var newCheckedState = !rowContainer.checked;
                                var currentRowData = root.model.get(index);

                                restoreAnimation.restart();
                                rowContainer.opacity = 1.0;

                                root.model.setProperty(index, "checked", newCheckedState);
                                root.checkStateChanged(index, currentRowData, newCheckedState);
                                root.rowClicked(index, currentRowData);
                            }

                            onCanceled: {
                                restoreAnimation.restart();
                                rowContainer.opacity = 1.0;
                            }
                        }
                    }
                }
            }
        }
    }
}

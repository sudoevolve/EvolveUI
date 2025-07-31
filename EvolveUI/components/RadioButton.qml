import QtQuick 2.15
import QtQuick.Layouts 1.15
import QtQuick.Controls 2.15
import QtQuick.Effects

Rectangle {
    id: root

    // === 外部接口 ===
    property var model: [] // [{ text: string }]
    property int selectedIndex: -1
    signal selectedChanged(int selectedIndex, var selectedData)

    // === 样式属性 ===
    property real radius: 15
    property int fontSize: 16
    property color buttonColor: theme.secondaryColor
    property color hoverColor: Qt.darker(buttonColor, 1.2)
    property color textColor: theme.textColor
    property color checkmarkColor: theme.textColor
    property real pressedScale: 0.96
    property bool shadowEnabled: true
    property color shadowColor: theme.shadowColor

    property int horizontalPadding: 24
    property int boxSize: 24
    property int spacingBetweenBoxAndText: 12
    property int verticalSpacingBetweenButtons: 6
    property int buttonHeight: 48

    // 测量文本宽度用的隐藏Text
    Text {
        id: measureText
        visible: false
        font.pixelSize: root.fontSize
        font.bold: false
    }

    // 通过函数计算最大文本宽度
    property real maxTextWidth: 0
    function updateMaxTextWidth() {
        var maxWidth = 0;
        for (var i = 0; i < model.length; i++) {
            measureText.text = model[i].text;
            var w = measureText.width;
            if (w > maxWidth)
                maxWidth = w;
        }
        maxTextWidth = maxWidth;
    }

    // 组件加载完和model变更时重新计算
    Component.onCompleted: updateMaxTextWidth()
    onModelChanged: updateMaxTextWidth()

    // 根据最大文本宽度计算implicitWidth
    implicitWidth: horizontalPadding * 2 + boxSize + spacingBetweenBoxAndText + maxTextWidth + 30

    implicitHeight: model.length > 0 ? model.length * (buttonHeight + verticalSpacingBetweenButtons) - verticalSpacingBetweenButtons + 20 : buttonHeight + 20

    width: implicitWidth
    height: implicitHeight

    color: "transparent"

    Rectangle {
        id: background
        anchors.fill: parent
        clip: true
        radius: root.radius
        color: root.buttonColor

        layer.enabled: root.shadowEnabled
        layer.effect: MultiEffect {
            shadowEnabled: root.shadowEnabled
            shadowColor: root.shadowColor
            shadowBlur: theme.shadowBlur
            shadowHorizontalOffset: theme.shadowXOffset
            shadowVerticalOffset: theme.shadowYOffset
        }
    }

    ColumnLayout {
        id: buttonsColumn
        anchors.top: parent.top
        anchors.topMargin: 10
        anchors.horizontalCenter: parent.horizontalCenter  // 【居中关键】
        spacing: verticalSpacingBetweenButtons
        width: implicitWidth
    }

    Repeater {
        model: root.model
        parent: buttonsColumn

        Rectangle {
            id: btn
            implicitWidth: horizontalPadding * 2 + boxSize + spacingBetweenBoxAndText + label.implicitWidth + 10
            height: buttonHeight
            radius: root.radius * 0.5

            property bool hovered: false
            property bool checked: root.selectedIndex === index

            color: hovered ? root.hoverColor : root.buttonColor
            border.color: checked ? root.checkmarkColor : "transparent"
            border.width: 2
            opacity: mouseArea.pressed ? 0.85 : 1.0

            Behavior on color { ColorAnimation { duration: 150 } }
            Behavior on border.color { ColorAnimation { duration: 150 } }
            Behavior on opacity { NumberAnimation { duration: 100 } }

            transform: Scale {
                id: scale
                origin.x: btn.width / 2
                origin.y: btn.height / 2
            }

            ParallelAnimation {
                id: restoreAnimation
                SpringAnimation { target: scale; property: "xScale"; to: 1.0; spring: 2.5; damping: 0.25 }
                SpringAnimation { target: scale; property: "yScale"; to: 1.0; spring: 2.5; damping: 0.25 }
            }

            RowLayout {
                anchors.fill: parent
                anchors.leftMargin: horizontalPadding
                anchors.rightMargin: horizontalPadding
                spacing: spacingBetweenBoxAndText
                Layout.alignment: Qt.AlignVCenter

                Rectangle {
                    id: box
                    width: boxSize
                    height: boxSize
                    radius: boxSize * 0.25
                    border.color: root.checkmarkColor
                    border.width: 2
                    color: checked ? root.checkmarkColor : "transparent"
                    Behavior on color { ColorAnimation { duration: 150 } }

                    Text {
                        anchors.centerIn: parent
                        visible: checked
                        text: "\u2713"
                        font.pixelSize: 16
                        color: root.buttonColor
                    }
                }

                Text {
                    id: label
                    text: modelData.text
                    color: root.textColor
                    font.pixelSize: root.fontSize
                    font.bold: checked
                    elide: Text.ElideRight
                    Layout.preferredWidth: label.implicitWidth
                    Layout.alignment: Qt.AlignVCenter
                }
            }

            MouseArea {
                id: mouseArea
                anchors.fill: parent
                hoverEnabled: true
                cursorShape: Qt.PointingHandCursor

                onEntered: btn.hovered = true
                onExited: btn.hovered = false

                onPressed: {
                    scale.xScale = root.pressedScale
                    scale.yScale = root.pressedScale
                    btn.opacity = 0.85
                }

                onReleased: {
                    restoreAnimation.restart()
                    btn.opacity = 1.0

                    if (root.selectedIndex !== index) {
                        root.selectedIndex = index
                        root.selectedChanged(index, modelData)
                    }
                }

                onCanceled: {
                    restoreAnimation.restart()
                    btn.opacity = 1.0
                }
            }
        }
    }
}

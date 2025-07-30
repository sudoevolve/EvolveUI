import QtQuick 2.15
import QtQuick.Controls 2.15
import QtQuick.Layouts 1.15
import QtQuick.Effects
import "."

Rectangle {
    id: root
    width: 300
    height: 40

    property alias text: label.text
    property real value: 50.0
    property real minimumValue: 0.0
    property real maximumValue: 100.0

    property int fontSize: 16
    property real radius: 10

    property color trackColor: theme.isDark ? "#313131" : theme.secondaryColor
    property color fillColor: theme.focusColor
    property color handleColor: theme.textColor
    property color borderColor: theme.getBorderColor(focused)

    signal userValueChanged(real value)

    property bool focused: false
    property bool isPressed: false   // 改名
    property bool hovered: false

    color: "transparent"

    function _updateHandlePosition() {
        const range = maximumValue - minimumValue;
        const percent = (value - minimumValue) / range;
        handle.x = percent * (track.width - handle.width);
        fill.width = handle.x + handle.width / 2;
    }

    function _updateValueFromHandle() {
        const percent = handle.x / (track.width - handle.width);
        value = minimumValue + percent * (maximumValue - minimumValue);
    }

    onValueChanged: _updateHandlePosition()
    Component.onCompleted: _updateHandlePosition()

    MultiEffect {
        source: background
        anchors.fill: background
        visible: true
        shadowEnabled: true
        shadowColor: theme.shadowColor
        shadowBlur: theme.shadowBlur
        shadowHorizontalOffset: theme.shadowXOffset
        shadowVerticalOffset: theme.shadowYOffset
    }

    Rectangle {
        id: background
        anchors.fill: parent
        radius: root.radius
        color: trackColor
        border.color: borderColor
        border.width: focused ? 2 : 1
    }

    Row {
        id: layoutRow
        anchors.fill: parent
        anchors.margins: 8
        spacing: 10

        Text {
            id: label
            text: root.text
            color: theme.textColor
            font.pixelSize: fontSize
            verticalAlignment: Text.AlignVCenter
        }

        Item {
            id: track
            width: 180
            height: 8
            anchors.verticalCenter: parent.verticalCenter

            Rectangle {
                id: fill
                anchors.left: parent.left
                anchors.top: parent.top
                anchors.bottom: parent.bottom
                width: handle.x + handle.width / 2
                radius: height / 2
                color: fillColor
                Behavior on width { SmoothedAnimation { duration: 100 } }
            }

            Rectangle {
                id: handle
                width: 24
                height: 24
                radius: width / 2
                color: handleColor
                border.color: Qt.lighter(handleColor, 1.2)
                border.width: 1
                anchors.verticalCenter: parent.verticalCenter
                x: 0

                layer.enabled: true
                layer.effect: MultiEffect {
                    shadowEnabled: true
                    shadowColor: theme.shadowColor
                    shadowBlur: 8
                    shadowVerticalOffset: 2
                }

                transform: Scale {
                    id: handleScale
                    origin.x: handle.width / 2
                    origin.y: handle.height / 2

                    Behavior on xScale { SpringAnimation { spring: 2.5; damping: 0.25 } }
                    Behavior on yScale { SpringAnimation { spring: 2.5; damping: 0.25 } }
                }

                Behavior on x { SmoothedAnimation { duration: 100 } }

                MouseArea {
                    anchors.fill: parent
                    drag.target: parent
                    drag.axis: Drag.XAxis
                    drag.minimumX: 0
                    drag.maximumX: track.width - handle.width

                    hoverEnabled: true
                    cursorShape: Qt.PointingHandCursor

                    onPressed: {
                        root.isPressed = true;
                        handleScale.xScale = 0.9;
                        handleScale.yScale = 0.9;
                        root.focused = true;
                    }

                    onReleased: {
                        root.isPressed = false;
                        handleScale.xScale = 1.0;
                        handleScale.yScale = 1.0;
                        root.focused = false;
                    }

                    onPositionChanged: {
                        if (root.isPressed) {
                            _updateValueFromHandle();
                            userValueChanged(value);
                        }
                    }

                    onEntered: hovered = true
                    onExited: hovered = false
                }
            }
        }

        Text {
            id: valueLabel
            text: Math.round(value).toString()
            color: theme.textColor
            font.pixelSize: fontSize
            verticalAlignment: Text.AlignVCenter
        }
    }
}

import QtQuick
import QtQuick.Controls
import QtQuick.Effects
import QtQuick.Layouts

Rectangle {
    id: root
    width: 280
    height: 420
    color: "transparent"
    radius: 20

    signal activeDragChanged(bool active)

    property color pickedColor: Qt.rgba(0, 1, 0.88)
    property real hue: 0.0
    property real saturation: 1.0
    property real value: 1.0
    property real alpha: 1.0


    Rectangle {
        id: bgRect
        anchors.fill: parent
        radius: root.radius
        color: theme.secondaryColor
        z: -2
    }
    MultiEffect {
        id: bgShadow
        source: bgRect
        anchors.fill: bgRect
        shadowEnabled: true
        shadowColor: theme.shadowColor
        shadowBlur: theme.shadowBlur
        shadowVerticalOffset: theme.shadowYOffset
        shadowHorizontalOffset: theme.shadowXOffset
        z: -1
    }

    onPickedColorChanged: {
        if (hue !== pickedColor.hsvHue || saturation !== pickedColor.hsvSaturation || value !== pickedColor.hsvValue) {
            hue = pickedColor.hsvHue
            saturation = pickedColor.hsvSaturation
            value = pickedColor.hsvValue
        }
        if (alpha !== pickedColor.a) {
            alpha = pickedColor.a
        }
    }

    onHueChanged: {
        var newColor = Qt.hsva(hue, saturation, value, alpha)
        if (pickedColor !== newColor) {
            pickedColor = newColor
        }
    }

    onSaturationChanged: {
        var newColor = Qt.hsva(hue, saturation, value, alpha)
        if (pickedColor !== newColor) {
            pickedColor = newColor
        }
    }

    onValueChanged: {
        var newColor = Qt.hsva(hue, saturation, value, alpha)
        if (pickedColor !== newColor) {
            pickedColor = newColor
        }
    }

    onAlphaChanged: {
        var newColor = Qt.hsva(hue, saturation, value, alpha)
        if (pickedColor !== newColor) {
            pickedColor = newColor
        }
    }

    Column {
        id: column
        anchors.fill: parent
        anchors.margins: 20
        spacing: 15

        Rectangle {
            id: svPicker
            width: parent.width
            height: 200
            radius: 0
            border.color: theme.borderColor

            gradient: Gradient {
                orientation: Gradient.Horizontal
                GradientStop { position: 0.0; color: Qt.hsva(hue, 0, 1, 1) }
                GradientStop { position: 1.0; color: Qt.hsva(hue, 1, 1, 1) }
            }

            Rectangle {
                width: parent.width
                height: parent.height
                gradient: Gradient {
                    orientation: Gradient.Vertical
                    GradientStop { position: 0.0; color: "transparent" }
                    GradientStop { position: 1.0; color: "black" }
                }
            }

            Rectangle {
                id: svHandle
                x: svPicker.width * saturation - width / 2
                y: svPicker.height * (1 - value) - height / 2
                width: 20
                height: 20
                radius: 10
                border.color: theme.borderColor
                border.width: 2
                color: pickedColor
            }

            MouseArea {
                anchors.fill: parent
                onPressed: (mouse) => {
                                 root.activeDragChanged(true)
                                 saturation = mouse.x / width
                                 value = 1 - mouse.y / height
                             }
                onPositionChanged: (mouse) => {
                                       if (pressed) {
                                           saturation = Math.max(0, Math.min(1, mouse.x / width))
                                           value = 1 - Math.max(0, Math.min(1, mouse.y / height))
                                       }
                                   }
                onReleased: root.activeDragChanged(false)
            }
        }

        Rectangle {
            id: hueSlider
            width: parent.width
            height: 20
            radius: 10

            gradient: Gradient {
                orientation: Gradient.Horizontal
                GradientStop { position: 0.0; color: "red" }
                GradientStop { position: 0.16; color: "yellow" }
                GradientStop { position: 0.33; color: "lime" }
                GradientStop { position: 0.5; color: "cyan" }
                GradientStop { position: 0.66; color: "blue" }
                GradientStop { position: 0.83; color: "magenta" }
                GradientStop { position: 1.0; color: "red" }
            }

            Rectangle {
                id: hueHandle
                x: hueSlider.width * hue - width / 2
                y: (parent.height - height) / 2
                width: 20
                height: 20
                radius: 10
                border.color: theme.borderColor
                border.width: 2
                color: Qt.hsva(hue, 1, 1, 1)
            }

            MouseArea {
                anchors.fill: parent
                onPressed: (mouse) => {
                               root.activeDragChanged(true)
                               hue = mouse.x / width
                           }
                onPositionChanged: (mouse) => {
                                       if (pressed) {
                                           hue = Math.max(0, Math.min(1, mouse.x / width))
                                       }
                                   }
                onReleased: root.activeDragChanged(false)
            }
        }

        Rectangle {
            id: alphaSlider
            width: parent.width
            height: 20
            radius: 10
            color: theme.secondaryColor

            Rectangle {
                anchors.fill: parent
                radius: 10
                gradient: Gradient {
                    orientation: Gradient.Horizontal
                    GradientStop { position: 0.0; color: Qt.hsva(hue, saturation, value, 0) }
                    GradientStop { position: 1.0; color: Qt.hsva(hue, saturation, value, 1) }
                }
            }

            Rectangle {
                id: alphaHandle
                x: alphaSlider.width * alpha - width / 2
                y: (parent.height - height) / 2
                width: 20
                height: 20
                radius: 10
                border.color: theme.borderColor
                border.width: 2
                color: pickedColor
            }

            MouseArea {
                anchors.fill: parent
                onPressed: (mouse) => {
                               root.activeDragChanged(true)
                               alpha = mouse.x / width
                           }
                onPositionChanged: (mouse) => {
                                       if (pressed) {
                                           alpha = Math.max(0, Math.min(1, mouse.x / width))
                                       }
                                   }
                onReleased: root.activeDragChanged(false)
            }
        }
        
        Rectangle {
            width: parent.width
            height: 50
            radius: 8
            color: pickedColor
            border.color: theme.borderColor
        }

        RowLayout {
            width: parent.width
            spacing: 15

            ColumnLayout {
                Layout.fillWidth: true
                spacing: 5

                Text {
                    text: "HEX"
                    font.pixelSize: 12
                    color: theme.textColor
                    opacity: 0.7
                }

                Text {
                    id: hexText
                    text: {
                        const r = Math.round(pickedColor.r * 255).toString(16).padStart(2, '0');
                        const g = Math.round(pickedColor.g * 255).toString(16).padStart(2, '0');
                        const b = Math.round(pickedColor.b * 255).toString(16).padStart(2, '0');
                        const a = Math.round(pickedColor.a * 255).toString(16).padStart(2, '0');
                        return `#${r}${g}${b}${a}`.toUpperCase();
                    }
                    font.bold: true
                    color: theme.textColor

                    MouseArea {
                        anchors.fill: parent
                        cursorShape: Qt.PointingHandCursor
                        onClicked: {
                            copyToClipboard(hexText.text)
                        }
                    }
                }
            }

            ColumnLayout {
                Layout.fillWidth: true
                spacing: 5

                Text {
                    text: "RGBA"
                    font.pixelSize: 12
                    color: theme.textColor
                    opacity: 0.7
                }

                Text {
                    id: rgbText
                    text: {
                        const r = Math.round(pickedColor.r * 255)
                        const g = Math.round(pickedColor.g * 255)
                        const b = Math.round(pickedColor.b * 255)
                        const a = Number(pickedColor.a.toFixed(2))
                        return `rgba(${r}, ${g}, ${b}, ${a})`
                    }
                    font.bold: true
                    color: theme.textColor

                    MouseArea {
                        anchors.fill: parent
                        cursorShape: Qt.PointingHandCursor
                        onClicked: {
                            copyToClipboard(rgbText.text)
                        }
                    }
                }
            }
        }
    }

    function showCopyPopup() {
        copyPopup.opacity = 1
        copyPopup.scale = 1
        copyPopupTimer.start()
    }

    function copyToClipboard(text) {
        clipboardDummy.text = text
        clipboardDummy.selectAll()
        clipboardDummy.copy()
        showCopyPopup()
    }

    TextEdit {
        id: clipboardDummy
        visible: false
        text: ""
    }

    Rectangle {
        id: copyPopup
        anchors.centerIn: parent
        width: 100
        height: 40
        radius: 8
        color: theme.secondaryColor
        border.color: theme.borderColor
        border.width: 2
        opacity: 0
        visible: opacity > 0

        Behavior on opacity {
            OpacityAnimator { duration: 200 }
        }

        Behavior on scale {
            ScaleAnimator { duration: 400; easing.type: Easing.OutElastic } 
        }

        Text {
            anchors.centerIn: parent
            text: "复制成功!"
            color: theme.textColor
        }
    }

    Timer {
        id: copyPopupTimer
        interval: 1500
        repeat: false
        onTriggered: {
            copyPopup.opacity = 0
            copyPopup.scale = 0
        }
    }
}

// HoverCard.qml
import QtQuick 2.15
import QtQuick.Layouts 1.15

Item {
    id: root

    width: 150
    height: 200

    // 最大旋转角度，外部可设置
    property real maxRotationAngle: 15

    // 当前旋转角度，供内部绑定使用
    property real rotationX: 0
    property real rotationY: 0

    // 鼠标是否悬停
    property bool isHovered: mouseArea.containsMouse

    // 缩放动画，点击时缩小至 0.95，释放还原
    scale: mouseArea.pressed ? 0.95 : 1.0
    Behavior on scale { SpringAnimation { spring: 2; damping: 0.2 } }

    Rectangle {
        id: card
        anchors.fill: parent
        radius: 20
        color: theme.secondaryColor

        transform: [
            Rotation {
                id: yRotation
                origin.x: card.width / 2
                origin.y: card.height / 2
                axis { x: 0; y: 1; z: 0 }
                angle: root.rotationY
                Behavior on angle {
                    enabled: !root.isHovered
                    PropertyAnimation { duration: 300; easing.type: Easing.OutCubic }
                }
            },
            Rotation {
                id: xRotation
                origin.x: card.width / 2
                origin.y: card.height / 2
                axis { x: 1; y: 0; z: 0 }
                angle: root.rotationX
                Behavior on angle {
                    enabled: !root.isHovered
                    PropertyAnimation { duration: 300; easing.type: Easing.OutCubic }
                }
            }
        ]

        Text {
            id: promptText
            text: "HOVER OVER"
            color: theme.textColor
            font.bold: true
            font.pixelSize: 15
            anchors.left: parent.left
            anchors.bottom: parent.bottom
            anchors.leftMargin: 12
            anchors.bottomMargin: 12
            opacity: root.isHovered ? 0 : 1
            Behavior on opacity { PropertyAnimation { duration: 300 } }
        }

        Text {
            id: titleText
            text: "悬浮偏移"
            color: theme.textColor
            font.bold: true
            font.pixelSize: 24
            horizontalAlignment: Text.AlignHCenter
            anchors.centerIn: parent
            opacity: root.isHovered ? 1 : 0
            Behavior on opacity { PropertyAnimation { duration: 300; easing.type: Easing.InOutQuad } }
        }
    }

    MouseArea {
        id: mouseArea
        anchors.fill: parent
        hoverEnabled: true

        onPositionChanged: function(mouse) {
            updateRotation(mouse.x, mouse.y)
        }
        onExited: resetRotation()

        function updateRotation(x, y) {
            const centerX = root.width / 2;
            const centerY = root.height / 2;

            const dx = x - centerX;
            const dy = y - centerY;

            root.rotationY = root.maxRotationAngle * dx / centerX;
            root.rotationX = -root.maxRotationAngle * dy / centerY;
        }

        function resetRotation() {
            root.rotationX = 0;
            root.rotationY = 0;
        }
    }

}

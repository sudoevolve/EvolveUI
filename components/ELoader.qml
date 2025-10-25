// ELoader.qml
import QtQuick
import QtQuick.Effects

Item {
    id: root
    width: size
    height: size

    // 外部属性
    property real size: 40
    property real speed: 0.8        // 秒
    property color color: theme ? theme.focusColor : "#5D3FD3"
    property bool running: true

    // 内部计算
    property int spinDuration: Math.round(speed * 2500)  // 容器旋转：speed * 2.5s
    property int wobbleHalf: Math.round(speed * 500)     // 点位上下摆动半周期
    property int delay1: Math.round(speed * 300)         // 点1负延迟近似
    property int delay2: Math.round(speed * 150)         // 点2负延迟近似

    // 旋转容器（整个动画旋转）
    transform: Rotation {
        id: rot
        origin.x: root.width / 2
        origin.y: root.height / 2
        angle: 0
    }

    NumberAnimation {
        id: spinAnim
        target: rot
        property: "angle"
        from: 0
        to: 360
        duration: spinDuration
        loops: Animation.Infinite
        running: root.running
        easing.type: Easing.Linear
    }

    // Wobble 动画采用声明式定义在各个点位中（移除非法返回 QML 对象的 JS 函数）

    // Dot 1
    Item {
        id: dot1
        width: root.width * 0.3
        height: root.height
        x: 0
        y: root.height * 0.05
        transform: Rotation { origin.x: dot1.width / 2; origin.y: dot1.height * 0.85; angle: 60 }

        Rectangle {
            id: c1
            width: dot1.width
            height: width
            x: 0
            y: dot1.height - height
            radius: width / 2
            color: root.color
            opacity: 1.0

            transform: Scale { id: s1; origin.x: width / 2; origin.y: height / 2; xScale: 1.0; yScale: 1.0 }
        }

        // Dot1 摆动动画（含延迟）
        SequentialAnimation {
            id: wobble1
            running: root.running
            loops: Animation.Infinite
            PauseAnimation { duration: delay1 }
            ParallelAnimation {
                NumberAnimation { target: c1; property: "y"; to: (dot1.height - c1.height) - (dot1.height * 0.66); duration: wobbleHalf; easing.type: Easing.InOutQuad }
                NumberAnimation { target: s1; property: "xScale"; to: 0.65; duration: wobbleHalf; easing.type: Easing.InOutQuad }
                NumberAnimation { target: s1; property: "yScale"; to: 0.65; duration: wobbleHalf; easing.type: Easing.InOutQuad }
                NumberAnimation { target: c1; property: "opacity"; to: 0.8; duration: wobbleHalf; easing.type: Easing.InOutQuad }
            }
            ParallelAnimation {
                NumberAnimation { target: c1; property: "y"; to: (dot1.height - c1.height); duration: wobbleHalf; easing.type: Easing.InOutQuad }
                NumberAnimation { target: s1; property: "xScale"; to: 1.0; duration: wobbleHalf; easing.type: Easing.InOutQuad }
                NumberAnimation { target: s1; property: "yScale"; to: 1.0; duration: wobbleHalf; easing.type: Easing.InOutQuad }
                NumberAnimation { target: c1; property: "opacity"; to: 1.0; duration: wobbleHalf; easing.type: Easing.InOutQuad }
            }
        }
    }

    // Dot 2
    Item {
        id: dot2
        width: root.width * 0.3
        height: root.height
        anchors.right: parent.right
        anchors.bottom: parent.bottom
        anchors.bottomMargin: root.height * 0.05
        transform: Rotation { origin.x: dot2.width / 2; origin.y: dot2.height * 0.85; angle: -60 }

        Rectangle {
            id: c2
            width: dot2.width
            height: width
            x: 0
            y: dot2.height - height
            radius: width / 2
            color: root.color
            opacity: 1.0

            transform: Scale { id: s2; origin.x: width / 2; origin.y: height / 2; xScale: 1.0; yScale: 1.0 }
        }

        // Dot2 摆动动画（含延迟）
        SequentialAnimation {
            id: wobble2
            running: root.running
            loops: Animation.Infinite
            PauseAnimation { duration: delay2 }
            ParallelAnimation {
                NumberAnimation { target: c2; property: "y"; to: (dot2.height - c2.height) - (dot2.height * 0.66); duration: wobbleHalf; easing.type: Easing.InOutQuad }
                NumberAnimation { target: s2; property: "xScale"; to: 0.65; duration: wobbleHalf; easing.type: Easing.InOutQuad }
                NumberAnimation { target: s2; property: "yScale"; to: 0.65; duration: wobbleHalf; easing.type: Easing.InOutQuad }
                NumberAnimation { target: c2; property: "opacity"; to: 0.8; duration: wobbleHalf; easing.type: Easing.InOutQuad }
            }
            ParallelAnimation {
                NumberAnimation { target: c2; property: "y"; to: (dot2.height - c2.height); duration: wobbleHalf; easing.type: Easing.InOutQuad }
                NumberAnimation { target: s2; property: "xScale"; to: 1.0; duration: wobbleHalf; easing.type: Easing.InOutQuad }
                NumberAnimation { target: s2; property: "yScale"; to: 1.0; duration: wobbleHalf; easing.type: Easing.InOutQuad }
                NumberAnimation { target: c2; property: "opacity"; to: 1.0; duration: wobbleHalf; easing.type: Easing.InOutQuad }
            }
        }
    }

    // Dot 3
    Item {
        id: dot3
        width: root.width * 0.3
        height: root.height
        x: dot3.width * 1.1666
        y: root.height * 1.05 - height

        Rectangle {
            id: c3
            width: dot3.width
            height: width
            x: 0
            y: dot3.height - height
            radius: width / 2
            color: root.color
            opacity: 1.0

            transform: Scale { id: s3; origin.x: width / 2; origin.y: height / 2; xScale: 1.0; yScale: 1.0 }
        }

        // wobble2：向下位移
        SequentialAnimation {
            running: root.running
            loops: Animation.Infinite
            ParallelAnimation {
                NumberAnimation { target: c3; property: "y"; to: (dot3.height - c3.height) + (dot3.height * 0.66); duration: wobbleHalf; easing.type: Easing.InOutQuad }
                NumberAnimation { target: s3; property: "xScale"; to: 0.65; duration: wobbleHalf; easing.type: Easing.InOutQuad }
                NumberAnimation { target: s3; property: "yScale"; to: 0.65; duration: wobbleHalf; easing.type: Easing.InOutQuad }
                NumberAnimation { target: c3; property: "opacity"; to: 0.8; duration: wobbleHalf; easing.type: Easing.InOutQuad }
            }
            ParallelAnimation {
                NumberAnimation { target: c3; property: "y"; to: (dot3.height - c3.height); duration: wobbleHalf; easing.type: Easing.InOutQuad }
                NumberAnimation { target: s3; property: "xScale"; to: 1.0; duration: wobbleHalf; easing.type: Easing.InOutQuad }
                NumberAnimation { target: s3; property: "yScale"; to: 1.0; duration: wobbleHalf; easing.type: Easing.InOutQuad }
                NumberAnimation { target: c3; property: "opacity"; to: 1.0; duration: wobbleHalf; easing.type: Easing.InOutQuad }
            }
        }
    }
}

// EAnimatedWindow.qml
import QtQuick
import QtQuick.Controls

Item {
    id: animationWrapper
    z: 999
    visible: false
    state: "iconState"
    width: parent.width
    height: parent.height
    focus: visible && state === "fullscreenState"

    // 记录是否已在主题计数中登记为“打开”
    property bool _lastOpenState: false

    // 聚合：根据当前状态更新 theme.openAnimatedWindowCount
    function _updateThemeOpenCount() {
        // 依赖外部传入的 theme（全局在 Main.qml 通过 Loader 传递）
        if (!theme) return
        var nowOpen = (state === "fullscreenState")
        if (nowOpen === _lastOpenState) return
        _lastOpenState = nowOpen
        if (nowOpen) {
            theme.openAnimatedWindowCount += 1
        } else {
            theme.openAnimatedWindowCount -= 1
        }
    }

    // ===== 可配置属性  =====
    property int animDuration: 450
    property real segment1Progress: 0.8
    property real segment1DurationFactor: 0.3
    property real segment2DurationFactor: 0.7
    property real maxTiltAngle: 35
    property color textColor: theme.textColor
    property color fullscreenColor: theme.secondaryColor

    default property alias contentData: contentArea.data  // 允许外部添加子项

    // 初始按钮颜色
    property color buttonColor: theme.secondaryColor

    // ===== 内部状态属性  =====
    property bool isAnimating: false
    property var startState: ({
        x: 0,
        y: 0,
        width: 100,
        height: 100,
        radius: 55,
        color: buttonColor,
        rotationX: 0,
        rotationY: 0,
        sourceItem: null
    })

    // ===== 对外接口函数  =====
    function open(source, txt = "") {
        if (isAnimating || state === "fullscreenState") return;

        isAnimating = true;
        startState.sourceItem = source;
        if (startState.sourceItem) startState.sourceItem.opacity = 0;

        // 1. 获取源控件的中心点坐标映射到 animationWrapper
        var map = startState.sourceItem.mapToItem(
            animationWrapper,
            startState.sourceItem.width / 2,
            startState.sourceItem.height / 2
        );

        // 2. 将左上角设置为中心对齐后的坐标
        startState.x = map.x - startState.sourceItem.width / 2;
        startState.y = map.y - startState.sourceItem.height / 2;

        // 3. 记录宽高、圆角、颜色
        startState.width = startState.sourceItem.width;
        startState.height = startState.sourceItem.height;
        startState.radius = startState.sourceItem.radius !== undefined ? startState.sourceItem.radius : 30;

        // 颜色穿透逻辑
        function findNonTransparentColor(item) {
            if (!item || !item.visible || item.opacity <= 0.01) return null;

            if (item.color && item.color !== "transparent" && item.color !== Qt.transparent) {
                return item.color;
            }

            if (item.textColor && item.textColor !== "transparent" && item.textColor !== Qt.transparent) {
                return item.textColor;
            }

            if (item.fill && item.fill !== "transparent" && item.fill !== Qt.transparent) {
                return item.fill;
            }

            for (var i = 0; i < item.children.length; ++i) {
                var child = item.children[i];
                var foundColor = findNonTransparentColor(child);
                if (foundColor) {
                    return foundColor;
                }
            }

            return null;
        }

        startState.color = findNonTransparentColor(startState.sourceItem);
        if (!startState.color || startState.color === "transparent" || startState.color === Qt.transparent) {
            startState.color = buttonColor;
        }

        // 4. 根据源控件位置计算初始3D倾斜角度
        var sourceCenterX = startState.x + startState.width / 2;
        var sourceCenterY = startState.y + startState.height / 2;
        var windowCenterX = width / 2;
        var windowCenterY = height / 2;
        var deltaX_norm = (sourceCenterX - windowCenterX) / windowCenterX;
        var deltaY_norm = (sourceCenterY - windowCenterY) / windowCenterY;
        startState.rotationX = -deltaY_norm * maxTiltAngle;
        startState.rotationY = deltaX_norm * maxTiltAngle;

        // 手动发射信号，通知绑定更新
        startStateChanged();

        // 5. 设置 appContainer 初始状态
        appContainer.x = startState.x;
        appContainer.y = startState.y;
        appContainer.width = startState.width;
        appContainer.height = startState.height;
        appContainer.radius = startState.radius;
        appContainer.color = startState.color;
        rotationX.angle = startState.rotationX;
        rotationY.angle = startState.rotationY;

        // 6. 启动动画
        visible = true;
        state = "fullscreenState";
        _updateThemeOpenCount();
    }

    // ===== UI 元素 =====
    Rectangle {
        id: appContainer
        clip: true
        transform: [
            Rotation { id: rotationY; axis { x: 0; y: 1; z: 0 } origin.x: appContainer.width / 2; origin.y: appContainer.height / 2 },
            Rotation { id: rotationX; axis { x: 1; y: 0; z: 0 } origin.x: appContainer.width / 2; origin.y: appContainer.height / 2 }
        ]

        // 屏蔽底层点击的拦截层（仅在全屏状态启用）
        MouseArea {
            id: modalBlocker
            anchors.fill: parent
            z: 0
            enabled: animationWrapper.visible && animationWrapper.state === "fullscreenState"
            hoverEnabled: true
            acceptedButtons: Qt.AllButtons
            preventStealing: true
        }

        Item {
            id: windowContent
            anchors.fill: parent
            clip: true
            opacity: 0
            layer.enabled: true
            z: 1

            Item {
                id: contentArea
                anchors.fill: parent
                // 外部的内容会自动加到这里
                }

            EButton {
                iconCharacter: "\uf078"
                iconFontFamily: iconFont.name
                iconRotateOnClick: true
                text: ""
                anchors.top: parent.top;
                anchors.right: parent.right;
                anchors.margins: 10;
                enabled: windowContent.opacity === 1;
                onClicked: {
                    if (animationWrapper.isAnimating) return;
                    animationWrapper.isAnimating = true;
                    animationWrapper.state = "iconState";
                }
            }
        }
    }

    // ==== 状态定义 (States) ====
    states: [
        State {
            name: "iconState"
            PropertyChanges { target: appContainer; x: startState.x; y: startState.y; width: startState.width; height: startState.height }
            PropertyChanges { target: appContainer; radius: startState.radius; color: startState.color }
            PropertyChanges { target: rotationX; angle: startState.rotationX }
            PropertyChanges { target: rotationY; angle: startState.rotationY }
            PropertyChanges { target: windowContent; opacity: 0 }
        },
        State {
            name: "fullscreenState"
            PropertyChanges { target: appContainer; x: 0; y: 0; width: animationWrapper.width; height: animationWrapper.height }
            PropertyChanges { target: appContainer; radius: 0; color: fullscreenColor }
            PropertyChanges { target: rotationX; angle: 0 }
            PropertyChanges { target: rotationY; angle: 0 }
            PropertyChanges { target: windowContent; opacity: 1 }
        }
    ]

    // ==== 动画过渡 (Transitions) ====
    transitions: [
        Transition {
            from: "iconState"; to: "fullscreenState"
            onRunningChanged: if (!running) animationWrapper.isAnimating = false

            ParallelAnimation {
                SequentialAnimation {
                    ParallelAnimation {
                        PropertyAnimation { target: rotationX; property:"angle"; to: startState.rotationX * (1 - segment1Progress); duration: animDuration * segment1DurationFactor; easing.type: Easing.InQuad }
                        PropertyAnimation { target: rotationY; property:"angle"; to: startState.rotationY * (1 - segment1Progress); duration: animDuration * segment1DurationFactor; easing.type: Easing.InQuad }
                        PropertyAnimation { target: appContainer; property:"radius"; to: startState.radius; duration: animDuration * segment1DurationFactor; easing.type: Easing.InQuad }
                        PropertyAnimation { target: appContainer; property:"width"; to: startState.width + (animationWrapper.width - startState.width) * segment1Progress; duration: animDuration * segment1DurationFactor; easing.type: Easing.InQuad }
                        PropertyAnimation { target: appContainer; property:"height"; to: startState.height + (animationWrapper.height - startState.height) * segment1Progress; duration: animDuration * segment1DurationFactor; easing.type: Easing.InQuad }
                        PropertyAnimation { target: appContainer; property:"x"; to: startState.x * (1 - segment1Progress); duration: animDuration * segment1DurationFactor; easing.type: Easing.InQuad }
                        PropertyAnimation { target: appContainer; property:"y"; to: startState.y * (1 - segment1Progress); duration: animDuration * segment1DurationFactor; easing.type: Easing.InQuad }
                    }
                    ParallelAnimation {
                        PropertyAnimation { target: rotationX; property:"angle"; to: 0; duration: animDuration * segment2DurationFactor; easing.type: Easing.OutQuad }
                        PropertyAnimation { target: rotationY; property:"angle"; to: 0; duration: animDuration * segment2DurationFactor; easing.type: Easing.OutQuad }
                        PropertyAnimation { target: appContainer; property:"radius"; to: 0; duration: animDuration * segment2DurationFactor; easing.type: Easing.OutQuad }
                        PropertyAnimation { target: appContainer; property:"width"; to: animationWrapper.width; duration: animDuration * segment2DurationFactor; easing.type: Easing.OutQuad }
                        PropertyAnimation { target: appContainer; property:"height"; to: animationWrapper.height; duration: animDuration * segment2DurationFactor; easing.type: Easing.OutQuad }
                        PropertyAnimation { target: appContainer; property:"x"; to: 0; duration: animDuration * segment2DurationFactor; easing.type: Easing.OutQuad }
                        PropertyAnimation { target: appContainer; property:"y"; to: 0; duration: animDuration * segment2DurationFactor; easing.type: Easing.OutQuad }
                    }
                }
                ColorAnimation { target: appContainer; property:"color"; to: fullscreenColor; duration: animDuration }
                SequentialAnimation {
                    PauseAnimation { duration: animDuration * 0.5 }
                    NumberAnimation { target: windowContent; property:"opacity"; to: 1; duration: animDuration * 0.5 }
                }
            }
        },

        Transition {
            from: "fullscreenState"; to: "iconState"
            onRunningChanged: {
                if (!running) {
                    animationWrapper.isAnimating = false;
                    animationWrapper.visible = false;
                    if (startState.sourceItem) {
                        startState.sourceItem.opacity = 1;
                        startState.sourceItem = null;
                    }
                    // 在动画收尾完成时确保聚合状态为关闭
                    _updateThemeOpenCount();
                }
            }

            ParallelAnimation {
                SequentialAnimation {
                    ParallelAnimation {
                        PropertyAnimation { target: rotationX; property:"angle"; to: startState.rotationX * segment1Progress; duration: animDuration * segment1DurationFactor; easing.type: Easing.InQuad }
                        PropertyAnimation { target: rotationY; property:"angle"; to: startState.rotationY * segment1Progress; duration: animDuration * segment1DurationFactor; easing.type: Easing.InQuad }
                        PropertyAnimation { target: appContainer; property:"radius"; to: startState.radius * segment1Progress; duration: animDuration * segment1DurationFactor; easing.type: Easing.InQuad }
                        PropertyAnimation { target: appContainer; property:"width"; to: startState.width + (animationWrapper.width - startState.width) * (1 - segment1Progress); duration: animDuration * segment1DurationFactor; easing.type: Easing.InQuad }
                        PropertyAnimation { target: appContainer; property:"height"; to: startState.height + (animationWrapper.height - startState.height) * (1 - segment1Progress); duration: animDuration * segment1DurationFactor; easing.type: Easing.InQuad }
                        PropertyAnimation { target: appContainer; property:"x"; to: startState.x * segment1Progress; duration: animDuration * segment1DurationFactor; easing.type: Easing.InQuad }
                        PropertyAnimation { target: appContainer; property:"y"; to: startState.y * segment1Progress; duration: animDuration * segment1DurationFactor; easing.type: Easing.InQuad }
                    }
                    ParallelAnimation {
                        PropertyAnimation { target: rotationX; property:"angle"; to: 0; duration: animDuration * segment2DurationFactor; easing.type: Easing.OutQuad }
                        PropertyAnimation { target: rotationY; property:"angle"; to: 0; duration: animDuration * segment2DurationFactor; easing.type: Easing.OutQuad }
                        PropertyAnimation { target: appContainer; property:"radius"; to: startState.radius; duration: animDuration * segment2DurationFactor; easing.type: Easing.OutQuad }
                        PropertyAnimation { target: appContainer; property:"width"; to: startState.width; duration: animDuration * segment2DurationFactor; easing.type: Easing.OutQuad }
                        PropertyAnimation { target: appContainer; property:"height"; to: startState.height; duration: animDuration * segment2DurationFactor; easing.type: Easing.OutQuad }
                        PropertyAnimation { target: appContainer; property:"x"; to: startState.x; duration: animDuration * segment2DurationFactor; easing.type: Easing.OutQuad }
                        PropertyAnimation { target: appContainer; property:"y"; to: startState.y; duration: animDuration * segment2DurationFactor; easing.type: Easing.OutQuad }
                    }
                }

                ColorAnimation { target: appContainer; property:"color"; to: startState.color; duration: animDuration }
                NumberAnimation { target: windowContent; property:"opacity"; to: 0; duration: animDuration * 0.4 }
            }
        }
    ]

    // 绑定：只要状态变更，尝试更新聚合计数
    onStateChanged: _updateThemeOpenCount()

    // 初始化：确保初始状态与计数一致（通常为 iconState，不会更改计数）
    Component.onCompleted: _updateThemeOpenCount()

    // 防泄漏：组件销毁时如果仍标记为打开，主动减计数
    Component.onDestruction: {
        if (_lastOpenState && theme) theme.openAnimatedWindowCount -= 1
    }
}

// EAvatar.qml
import QtQuick
import QtQuick.Controls
import QtQuick.Effects

Item {
    id: root
    width: 80
    height: 80

    property url avatarSource: "qrc:/new/prefix1/fonts/pic/avatar.png"

    // 原始图像，隐藏
    Image {
        id: sourceItem
        source: root.avatarSource
        anchors.centerIn: parent
        width: root.width
        height: root.height
        fillMode: Image.PreserveAspectCrop
        visible: false
    }

    //
    MultiEffect {
        id: multiEffect
        source: sourceItem
        anchors.fill: sourceItem
        maskEnabled: true
        maskSource: mask
        // 下面两个属性抗锯齿
        maskThresholdMin: 0.5
        maskSpreadAtMin: 1.0

    }

    // 圆形黑色矩形（用于遮罩）
    Item {
        id: mask
        width: sourceItem.width
        height: sourceItem.height
        layer.enabled: true
        visible: false
        

        Rectangle {
            anchors.fill: parent
            radius: width / 2
            color: "black" // 黑色用于掩码：纯黑表示完全不透明
        }
    }
}

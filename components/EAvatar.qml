//EAvatar.qml
import QtQuick 6.2
import QtQuick.Controls
import QtQuick.Effects
import Qt5Compat.GraphicalEffects

Item {
    id: root
    width: 80
    height: 80

    property url avatarSource: "qrc:/new/prefix1/fonts/pic/avatar.png" // 图片路径

    Image {
        id: avatar
        source: root.avatarSource
        anchors.fill: parent
        fillMode: Image.PreserveAspectCrop
    }

    Rectangle {
        id: maskCircle
        anchors.fill: parent
        radius: width / 2
        visible: false // 只作为 mask 使用，不显示
    }

    OpacityMask {
        anchors.fill: parent
        source: avatar
        maskSource: maskCircle
    }
}

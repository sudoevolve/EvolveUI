import QtQuick

Item {
    id: root
    width: size
    height: size

    property real size: 40
    property real speed: 0.8
    property color color: theme ? theme.focusColor : "#5D3FD3"
    property bool running: true

    AnimatedImage {
        anchors.fill: parent
        source: "qrc:/new/prefix1/fonts/loader.gif"
        playing: root.running && root.visible
        fillMode: Image.PreserveAspectFit
        cache: true
    }
}

import QtQuick
import QtQuick.Controls
import QtQuick.Layouts
import QtQuick.Window
import EvolveUI

ApplicationWindow {
    readonly property bool isMobile: Qt.platform.os === "android" || Qt.platform.os === "ios"
    
    width: isMobile ? Screen.width : 375
    height: isMobile ? Screen.height : 812
    visibility: isMobile ? Window.FullScreen : Window.Windowed
    visible: true
    title: "{{PROJECT_NAME}}"

    color: theme.primaryColor

    FontLoader {
        id: iconFont
        source: "qrc:/new/prefix1/fonts/fontawesome-free-6.7.2-desktop/otfs/Font Awesome 6 Free-Solid-900.otf"
    }

    ETheme { id: theme }

    StackLayout {
        id: contentStack
        anchors.fill: parent
        anchors.bottomMargin: 80
        currentIndex: 0

        HomePage {}
        SearchPage {}
        SettingsPage {}
    }

    ENavBar {
        anchors.bottom: parent.bottom
        anchors.horizontalCenter: parent.horizontalCenter
        anchors.bottomMargin: 20
        
        model: [
            { display: "Home", iconChar: "\uf015" },
            { display: "Search", iconChar: "\uf002" },
            { display: "Settings", iconChar: "\uf013" }
        ]
        
        currentIndex: contentStack.currentIndex
        
        onItemClicked: (index, data) => {
            contentStack.currentIndex = index
        }
    }
}

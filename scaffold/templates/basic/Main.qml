import QtQuick
import QtQuick.Controls
import QtQuick.Layouts
import EvolveUI

ApplicationWindow {
    width: 900
    height: 600
    visible: true
    title: "{{PROJECT_NAME}}"

    color: theme.primaryColor

    FontLoader {
        id: iconFont
        source: "qrc:/new/prefix1/fonts/fontawesome-free-6.7.2-desktop/otfs/Font Awesome 6 Free-Solid-900.otf"
    }

    ETheme { id: theme }

    SplitView {
        anchors.fill: parent

        Pane {
            id: sidebar
            padding: 10
            background: Rectangle {
                color: theme.primaryColor
            }
            implicitWidth: 200
            clip: true
            Layout.minimumWidth: 150
            Layout.maximumWidth: 300

            ColumnLayout {
                anchors.fill: parent
                spacing: 10

                EButton {
                    text: "Home"
                    iconCharacter: "\uf015"
                    Layout.fillWidth: true
                    onClicked: contentStack.currentIndex = 0
                }

                EButton {
                    text: "Favorites"
                    iconCharacter: "\uf005"
                    Layout.fillWidth: true
                    onClicked: contentStack.currentIndex = 1
                }

                EButton {
                    text: "Settings"
                    iconCharacter: "\uf013"
                    Layout.fillWidth: true
                    onClicked: contentStack.currentIndex = 2
                }

                Item {
                    Layout.fillHeight: true
                }

                EButton {
                    text: theme.isDark ? "Light Mode" : "Dark Mode"
                    iconCharacter: theme.isDark ? "\uf185" : "\uf186"
                    iconRotateOnClick: true
                    Layout.fillWidth: true
                    onClicked: theme.toggleTheme()
                }
            }
        }

        StackLayout {
            id: contentStack
            currentIndex: 0
            clip: true
            Layout.fillWidth: true

            HomePage {}
            FavoritesPage {}
            SettingsPage {}
        }
    }
}

import QtQuick
import QtQuick.Controls
import QtQuick.Layouts
import EvolveUI

ApplicationWindow {
    width: 960
    height: 549
    visible: true
    title: "demo"

    color: theme.primaryColor

    FontLoader {
        id: iconFont
        source: "qrc:/new/prefix1/fonts/fontawesome-free-6.7.2-desktop/otfs/Font Awesome 6 Free-Solid-900.otf"
    }

    ETheme { id: theme }

    SplitView {
        anchors.fill: parent
        handle: Rectangle {
            implicitWidth: 8
            color: "transparent"
        }

        Pane {
            id: sidebar
            property bool expanded: false
            property int collapsedWidth: 84
            property int expandedWidth: 140
            padding: 10
            background: Rectangle {
                color: theme.secondaryColor
            }
            implicitWidth: expanded ? expandedWidth : collapsedWidth
            clip: true
            SplitView.minimumWidth: collapsedWidth
            SplitView.maximumWidth: 300
            SplitView.preferredWidth: implicitWidth

            Behavior on implicitWidth {
                NumberAnimation { duration: 240; easing.type: Easing.OutCubic }
            }

            HoverHandler {
                onHoveredChanged: sidebar.expanded = hovered
            }

            ColumnLayout {
                anchors.fill: parent
                spacing: 10

                EButton {
                    text: "首页"
                    textShown: sidebar.expanded
                    iconCharacter: "\uf015"
                    backgroundVisible: false
                    Layout.fillWidth: true
                    onClicked: contentStack.currentIndex = 0
                }

                EButton {
                    text: "收藏"
                    textShown: sidebar.expanded
                    iconCharacter: "\uf005"
                    backgroundVisible: false
                    Layout.fillWidth: true
                    onClicked: contentStack.currentIndex = 1
                }

                EButton {
                    text: "设置"
                    textShown: sidebar.expanded
                    iconCharacter: "\uf013"
                    backgroundVisible: false
                    Layout.fillWidth: true
                    onClicked: contentStack.currentIndex = 2
                }

                Item {
                    Layout.fillHeight: true
                }

                EButton {
                    text: theme.isDark ? "浅色" : "深色"
                    textShown: sidebar.expanded
                    iconCharacter: theme.isDark ? "\uf185" : "\uf186"
                    backgroundVisible: false
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

            Item {
                Layout.fillWidth: true
                Layout.fillHeight: true
                opacity: visible ? 1 : 0
                y: visible ? 0 : 12
                Behavior on opacity { NumberAnimation { duration: 240; easing.type: Easing.OutCubic } }
                Behavior on y { NumberAnimation { duration: 240; easing.type: Easing.OutCubic } }
                HomePage { anchors.fill: parent }
            }

            Item {
                Layout.fillWidth: true
                Layout.fillHeight: true
                opacity: visible ? 1 : 0
                y: visible ? 0 : 12
                Behavior on opacity { NumberAnimation { duration: 240; easing.type: Easing.OutCubic } }
                Behavior on y { NumberAnimation { duration: 240; easing.type: Easing.OutCubic } }
                FavoritesPage { anchors.fill: parent }
            }

            Item {
                Layout.fillWidth: true
                Layout.fillHeight: true
                opacity: visible ? 1 : 0
                y: visible ? 0 : 12
                Behavior on opacity { NumberAnimation { duration: 240; easing.type: Easing.OutCubic } }
                Behavior on y { NumberAnimation { duration: 240; easing.type: Easing.OutCubic } }
                SettingsPage { anchors.fill: parent }
            }
        }
    }
}

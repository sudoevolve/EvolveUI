import QtQuick
import QtQuick.Controls
import QtQuick.Layouts
import EvolveUI
import "pages"

ApplicationWindow {
    id: mainWindow
    width: 1280
    height: 720
    visible: true
    title: "{{PROJECT_NAME}}"

    color: theme.primaryColor

    FontLoader {
        id: iconFont
        source: "qrc:/new/prefix1/fonts/fontawesome-free-6.7.2-desktop/otfs/Font Awesome 6 Free-Solid-900.otf"
    }

    ETheme { id: theme }

    // Main Layout
    ColumnLayout {
        anchors.fill: parent
        spacing: 0

        // Top Bar
        Rectangle {
            Layout.fillWidth: true
            Layout.preferredHeight: 48
            color: theme.secondaryColor
            
            // Bottom border for separation
            Rectangle {
                anchors.bottom: parent.bottom
                width: parent.width
                height: 1
                color: Qt.rgba(0,0,0,0.1)
            }

            RowLayout {
                anchors.fill: parent
                anchors.leftMargin: 16
                anchors.rightMargin: 16
                spacing: 16

                // App Title
                Label {
                    text: "Evolve UI"
                    font.bold: true
                    font.pixelSize: 16
                    color: theme.textColor
                    Layout.alignment: Qt.AlignVCenter
                }

                // Vertical Divider
                Rectangle {
                    Layout.fillHeight: true
                    Layout.topMargin: 12
                    Layout.bottomMargin: 12
                    width: 1
                    color: Qt.rgba(0,0,0,0.1)
                }

                // Menu Buttons
                Row {
                    spacing: 4
                    Layout.alignment: Qt.AlignVCenter
                    
                    Repeater {
                        model: ["File", "Edit", "View", "Help"]
                        EMenuButton {
                            text: modelData
                            menuModel: ["Option 1", "Option 2", "Option 3", "Settings", "Exit"]
                            backgroundVisible: false
                            hoverColor: Qt.rgba(0,0,0,0.05)
                            textColor: theme.textColor
                            
                            onItemClicked: (index, itemText) => {
                                console.log("Clicked", text, ":", itemText)
                            }
                        }
                    }
                }

                Item { Layout.fillWidth: true } // Spacer

                // Right-side controls (e.g., User Profile, Notifications)
                Row {
                    spacing: 8
                    Layout.alignment: Qt.AlignVCenter
                    
                    EButton {
                        text: ""
                        iconCharacter: "\uf0f3" // Bell icon
                        width: 32
                        height: 32
                        radius: 16
                        backgroundVisible: false
                        hoverColor: Qt.rgba(0,0,0,0.05)
                        shadowEnabled: false
                    }
                    
                    EButton {
                        text: ""
                        iconCharacter: "\uf007" // User icon
                        width: 32
                        height: 32
                        radius: 16
                        backgroundVisible: false
                        hoverColor: Qt.rgba(0,0,0,0.05)
                        shadowEnabled: false
                    }
                }
            }
        }

        // Content Area with Sidebars
        SplitView {
            Layout.fillWidth: true
            Layout.fillHeight: true
            
            handle: Rectangle {
                implicitWidth: 4
                color: "transparent"
                
                Rectangle {
                    anchors.centerIn: parent
                    width: 1
                    height: parent.height
                    color: Qt.rgba(0,0,0,0.1)
                }
            }

            // Left Sidebar (Navigation)
            Pane {
                id: leftSidebar
                implicitWidth: 240
                SplitView.minimumWidth: 200
                SplitView.maximumWidth: 320
                padding: 0
                background: Rectangle {
                    color: theme.secondaryColor
                }

                ColumnLayout {
                    anchors.fill: parent
                    spacing: 0

                    // Sidebar Header/Section Title
                    Item {
                        Layout.fillWidth: true
                        Layout.preferredHeight: 40
                        
                        Label {
                            anchors.left: parent.left
                            anchors.leftMargin: 16
                            anchors.verticalCenter: parent.verticalCenter
                            text: "MAIN MENU"
                            font.pixelSize: 11
                            font.bold: true
                            color: Qt.rgba(theme.textColor.r, theme.textColor.g, theme.textColor.b, 0.5)
                        }
                    }

                    // Navigation List
                    ListModel {
                        id: navModel
                        ListElement { display: "Dashboard"; iconChar: "\uf015" } // home
                        ListElement { display: "Projects"; iconChar: "\uf07b" }  // folder
                        ListElement { display: "Tasks"; iconChar: "\uf0ae" }     // tasks
                        ListElement { display: "Calendar"; iconChar: "\uf073" }  // calendar
                        ListElement { display: "Reports"; iconChar: "\uf080" }   // chart-bar
                    }

                    ListView {
                        id: navListView
                        Layout.fillWidth: true
                        Layout.fillHeight: true
                        model: navModel
                        clip: true
                        currentIndex: 0

                        delegate: Item {
                            id: navDelegate
                            width: ListView.view.width
                            height: 40
                            
                            property bool isSelected: ListView.view.currentIndex === index
                            property bool isHovered: false

                            scale: 1.0
                            Behavior on scale { NumberAnimation { duration: 100; easing.type: Easing.OutQuad } }

                            // Selection Background (fades in/out)
                            Rectangle {
                                anchors.fill: parent
                                anchors.leftMargin: 8
                                anchors.rightMargin: 8
                                radius: 6
                                color: theme.primaryColor
                                opacity: isSelected ? 1 : 0
                                Behavior on opacity { NumberAnimation { duration: 150 } }
                            }
                            
                            // Hover Background (fades in/out)
                            Rectangle {
                                anchors.fill: parent
                                anchors.leftMargin: 8
                                anchors.rightMargin: 8
                                radius: 6
                                color: Qt.rgba(0,0,0,0.05)
                                opacity: isHovered && !isSelected ? 1 : 0
                                Behavior on opacity { NumberAnimation { duration: 150 } }
                            }

                            // Selection indicator
                            Rectangle {
                                width: 3
                                height: isSelected ? 20 : 0
                                radius: 1.5
                                color: theme.focusColor
                                anchors.left: parent.left
                                anchors.leftMargin: 8
                                anchors.verticalCenter: parent.verticalCenter
                                opacity: isSelected ? 1 : 0
                                
                                Behavior on height { NumberAnimation { duration: 200; easing.type: Easing.OutBack } }
                                Behavior on opacity { NumberAnimation { duration: 200 } }
                            }

                            RowLayout {
                                anchors.fill: parent
                                anchors.leftMargin: 20
                                anchors.rightMargin: 16
                                spacing: 12

                                Text {
                                    text: model.iconChar
                                    font.family: iconFont.name
                                    font.pixelSize: 16
                                    color: isSelected ? theme.textColor : Qt.rgba(theme.textColor.r, theme.textColor.g, theme.textColor.b, 0.7)
                                    Layout.preferredWidth: 20
                                    horizontalAlignment: Text.AlignHCenter
                                    
                                    Behavior on color { ColorAnimation { duration: 150 } }
                                }

                                Label {
                                    text: model.display
                                    color: isSelected ? theme.textColor : Qt.rgba(theme.textColor.r, theme.textColor.g, theme.textColor.b, 0.7)
                                    font.bold: isSelected
                                    Layout.fillWidth: true
                                    
                                    Behavior on color { ColorAnimation { duration: 150 } }
                                }
                            }

                            MouseArea {
                                anchors.fill: parent
                                hoverEnabled: true
                                onEntered: navDelegate.isHovered = true
                                onExited: navDelegate.isHovered = false
                                onPressed: navDelegate.scale = 0.96
                                onReleased: navDelegate.scale = 1.0
                                onCanceled: navDelegate.scale = 1.0
                                onClicked: {
                                    navListView.currentIndex = index
                                    contentStack.currentIndex = index
                                }
                            }
                        }
                    }
                    
                    // Bottom Section (Settings)
                    Item {
                        Layout.fillWidth: true
                        Layout.preferredHeight: 50
                        
                        Rectangle {
                            anchors.top: parent.top
                            width: parent.width
                            height: 1
                            color: Qt.rgba(0,0,0,0.05)
                        }

                        RowLayout {
                            anchors.fill: parent
                            anchors.leftMargin: 16
                            anchors.rightMargin: 16
                            
                            Text {
                                text: "\uf013" // cog
                                font.family: iconFont.name
                                font.pixelSize: 16
                                color: theme.textColor
                            }
                            
                            Label {
                                text: "Settings"
                                color: theme.textColor
                                Layout.fillWidth: true
                            }
                        }
                        
                        MouseArea {
                            anchors.fill: parent
                            cursorShape: Qt.PointingHandCursor
                            onClicked: {
                                // Navigate to settings
                                contentStack.currentIndex = navModel.count // Assuming settings is last
                            }
                        }
                    }
                }
            }

            // Center Content Area
            Rectangle {
                SplitView.minimumWidth: 300
                SplitView.preferredWidth: 600
                SplitView.fillWidth: true
                Layout.fillHeight: true
                color: theme.primaryColor
                clip: true

                StackLayout {
                    id: contentStack
                    anchors.fill: parent
                    anchors.margins: 0 // Add padding around content
                    currentIndex: 0
                    
                    // Dashboard
                    Item {
                        Layout.fillWidth: true
                        Layout.fillHeight: true
                        opacity: visible ? 1 : 0
                        y: visible ? 0 : 12
                        Behavior on opacity { NumberAnimation { duration: 240; easing.type: Easing.OutCubic } }
                        Behavior on y { NumberAnimation { duration: 240; easing.type: Easing.OutCubic } }
                        HomePage { 
                            id: homePage
                            anchors.fill: parent
                        }
                    }

                    // Projects
                    Item {
                        Layout.fillWidth: true
                        Layout.fillHeight: true
                        opacity: visible ? 1 : 0
                        y: visible ? 0 : 12
                        Behavior on opacity { NumberAnimation { duration: 240; easing.type: Easing.OutCubic } }
                        Behavior on y { NumberAnimation { duration: 240; easing.type: Easing.OutCubic } }
                        FavoritesPage {
                            anchors.fill: parent
                        }
                    }

                    // Tasks
                    Item {
                        Layout.fillWidth: true
                        Layout.fillHeight: true
                        opacity: visible ? 1 : 0
                        y: visible ? 0 : 12
                        Behavior on opacity { NumberAnimation { duration: 240; easing.type: Easing.OutCubic } }
                        Behavior on y { NumberAnimation { duration: 240; easing.type: Easing.OutCubic } }
                        TasksPage {
                            anchors.fill: parent
                        }
                    }

                    // Calendar
                    Item {
                        Layout.fillWidth: true
                        Layout.fillHeight: true
                        opacity: visible ? 1 : 0
                        y: visible ? 0 : 12
                        Behavior on opacity { NumberAnimation { duration: 240; easing.type: Easing.OutCubic } }
                        Behavior on y { NumberAnimation { duration: 240; easing.type: Easing.OutCubic } }
                        CalendarPage {
                            anchors.fill: parent
                        }
                    }
                    
                    // Reports
                    Item {
                        Layout.fillWidth: true
                        Layout.fillHeight: true
                        opacity: visible ? 1 : 0
                        y: visible ? 0 : 12
                        Behavior on opacity { NumberAnimation { duration: 240; easing.type: Easing.OutCubic } }
                        Behavior on y { NumberAnimation { duration: 240; easing.type: Easing.OutCubic } }
                        ReportsPage {
                            anchors.fill: parent
                        }
                    }

                    // Settings (Accessed via bottom link)
                    Item {
                        Layout.fillWidth: true
                        Layout.fillHeight: true
                        opacity: visible ? 1 : 0
                        y: visible ? 0 : 12
                        Behavior on opacity { NumberAnimation { duration: 240; easing.type: Easing.OutCubic } }
                        Behavior on y { NumberAnimation { duration: 240; easing.type: Easing.OutCubic } }
                        SettingsPage { 
                            anchors.fill: parent
                            animWindowRef: homePage.animatedWindow 
                        }
                    }
                }
            }

            // Right Sidebar (Inspector/Details)
            Pane {
                id: rightSidebar
                implicitWidth: 260
                SplitView.minimumWidth: 200
                SplitView.maximumWidth: 400
                Layout.fillHeight: true
                padding: 0
                background: Rectangle {
                    color: theme.secondaryColor
                }

                ColumnLayout {
                    anchors.fill: parent
                    spacing: 0

                    // Header
                    Rectangle {
                        Layout.fillWidth: true
                        Layout.preferredHeight: 48
                        color: "transparent"
                        
                        Label {
                            anchors.left: parent.left
                            anchors.leftMargin: 16
                            anchors.verticalCenter: parent.verticalCenter
                            text: "PROPERTIES"
                            font.bold: true
                            font.pixelSize: 12
                            color: theme.textColor
                        }
                        
                        Rectangle {
                            anchors.bottom: parent.bottom
                            width: parent.width
                            height: 1
                            color: Qt.rgba(0,0,0,0.05)
                        }
                    }

                    // Content
                    ScrollView {
                        Layout.fillWidth: true
                        Layout.fillHeight: true
                        contentWidth: availableWidth
                        
                        ColumnLayout {
                            width: parent.width
                            spacing: 24
                            
                            // Section 1
                            ColumnLayout {
                                Layout.fillWidth: true
                                Layout.margins: 16
                                spacing: 8
                                
                                Label {
                                    text: "Item Details"
                                    font.bold: true
                                    color: theme.textColor
                                    Layout.leftMargin: 16
                                }
                                
                                Rectangle {
                                    Layout.fillWidth: true
                                    Layout.preferredHeight: 100
                                    Layout.leftMargin: 16
                                    Layout.rightMargin: 16
                                    color: Qt.rgba(0,0,0,0.03)
                                    radius: 8
                                    border.color: Qt.rgba(0,0,0,0.05)
                                    
                                    Label {
                                        anchors.centerIn: parent
                                        text: "No item selected"
                                        color: Qt.rgba(theme.textColor.r, theme.textColor.g, theme.textColor.b, 0.5)
                                    }
                                }
                            }
                            
                            // Section 2
                            ColumnLayout {
                                Layout.fillWidth: true
                                Layout.margins: 16
                                spacing: 12
                                
                                Label {
                                    text: "Metadata"
                                    font.bold: true
                                    color: theme.textColor
                                    Layout.leftMargin: 16
                                }
                                
                                GridLayout {
                                    columns: 2
                                    rowSpacing: 8
                                    columnSpacing: 16
                                    Layout.leftMargin: 16
                                    Layout.rightMargin: 16
                                    
                                    Label { text: "Created:"; color: Qt.rgba(theme.textColor.r, theme.textColor.g, theme.textColor.b, 0.6) }
                                    Label { text: "2023-10-27"; color: theme.textColor }
                                    
                                    Label { text: "Author:"; color: Qt.rgba(theme.textColor.r, theme.textColor.g, theme.textColor.b, 0.6) }
                                    Label { text: "Admin"; color: theme.textColor }
                                    
                                    Label { text: "Status:"; color: Qt.rgba(theme.textColor.r, theme.textColor.g, theme.textColor.b, 0.6) }
                                    Label { text: "Active"; color: theme.focusColor; font.bold: true }
                                }
                            }
                            
                            Item { Layout.fillHeight: true } // Spacer
                        }
                    }

                    // Footer Actions
                    Rectangle {
                        Layout.fillWidth: true
                        Layout.preferredHeight: 60
                        color: "transparent"
                        
                        Rectangle {
                            anchors.top: parent.top
                            width: parent.width
                            height: 1
                            color: Qt.rgba(0,0,0,0.05)
                        }
                        
                        RowLayout {
                            anchors.fill: parent
                            anchors.margins: 16
                            spacing: 10
                            
                            EButton {
                                text: "Cancel"
                                size: "xs"
                                Layout.fillWidth: true
                                Layout.preferredHeight: 32
                                backgroundVisible: false
                                shadowEnabled: false
                                radius: 6
                            }
                            
                            EButton {
                                text: "Apply"
                                size: "xs"
                                Layout.fillWidth: true
                                Layout.preferredHeight: 32
                                containerColor: theme.focusColor
                                textColor: "white"
                                radius: 6
                                shadowEnabled: true
                            }
                        }
                    }
                }
            }
        }
    }
}

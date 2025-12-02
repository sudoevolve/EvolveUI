import QtQuick
import QtQuick.Controls
import QtQuick.Layouts
import EvolveUI

Page {
    background: Rectangle {
        color: "transparent"
    }

    ColumnLayout {
        anchors.fill: parent
        anchors.margins: 20
        spacing: 20

        Label {
            text: "Reports"
            font.pixelSize: 24
            font.bold: true
            color: theme.textColor
        }

        GridLayout {
            columns: 2
            Layout.fillWidth: true
            Layout.fillHeight: true
            columnSpacing: 20
            rowSpacing: 20

            // Chart 1 Placeholder
            Rectangle {
                Layout.fillWidth: true
                Layout.fillHeight: true
                color: theme.secondaryColor
                radius: 12
                
                ColumnLayout {
                    anchors.fill: parent
                    anchors.margins: 20
                    
                    Label {
                        text: "Weekly Activity"
                        font.bold: true
                        color: theme.textColor
                    }
                    
                    Item { Layout.fillHeight: true }
                    
                    RowLayout {
                        Layout.fillWidth: true
                        Layout.preferredHeight: 150
                        spacing: 20
                        
                        Repeater {
                            model: 7
                            Rectangle {
                                Layout.fillHeight: true
                                Layout.fillWidth: true
                                color: "transparent"
                                
                                Rectangle {
                                    width: parent.width * 0.6
                                    height: parent.height * (0.3 + Math.random() * 0.7)
                                    anchors.bottom: parent.bottom
                                    anchors.horizontalCenter: parent.horizontalCenter
                                    color: theme.focusColor
                                    radius: 4
                                }
                            }
                        }
                    }
                }
            }

            Rectangle {
                Layout.fillWidth: true
                Layout.fillHeight: true
                color: theme.secondaryColor
                radius: 12
                
                ColumnLayout {
                    anchors.fill: parent
                    anchors.margins: 20
                    
                    Label {
                        text: "Project Status"
                        font.bold: true
                        color: theme.textColor
                    }
                    
                    Item { 
                        Layout.fillWidth: true
                        Layout.fillHeight: true
                        
                        Rectangle {
                            width: 120
                            height: 120
                            radius: 60
                            anchors.centerIn: parent
                            border.width: 15
                            border.color: theme.focusColor
                            color: "transparent"
                            
                            Label {
                                anchors.centerIn: parent
                                text: "75%"
                                font.pixelSize: 20
                                font.bold: true
                                color: theme.textColor
                            }
                        }
                    }
                }
            }
            
            Repeater {
                model: [
                    { title: "Total Sales", value: "$12,450", trend: "+15%", icon: "\uf0d6" },
                    { title: "New Users", value: "342", trend: "+5%", icon: "\uf234" }
                ]
                
                Rectangle {
                    Layout.fillWidth: true
                    Layout.preferredHeight: 100
                    color: theme.secondaryColor
                    radius: 12
                    
                    RowLayout {
                        anchors.centerIn: parent
                        spacing: 96
                        
                        // Icon Box
                        Rectangle {
                            width: 48
                            height: 48
                            radius: 12
                            color: Qt.rgba(theme.focusColor.r, theme.focusColor.g, theme.focusColor.b, 0.1)
                            
                            Text {
                                anchors.centerIn: parent
                                text: modelData.icon
                                font.family: iconFont.name
                                font.pixelSize: 24
                                color: theme.focusColor
                            }
                        }

                        ColumnLayout {
                            spacing: 4
                            
                            Label {
                                text: modelData.title
                                color: Qt.rgba(theme.textColor.r, theme.textColor.g, theme.textColor.b, 0.6)
                                font.pixelSize: 14
                            }
                            
                            Label {
                                text: modelData.value
                                font.pixelSize: 24
                                font.bold: true
                                color: theme.textColor
                            }
                            
                            Label {
                                text: modelData.trend
                                color: theme.focusColor
                                font.bold: true
                                font.pixelSize: 12
                            }
                        }
                    }
                }
            }
        }
    }
}

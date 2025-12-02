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
            text: "Tasks"
            font.pixelSize: 24
            font.bold: true
            color: theme.textColor
        }

        // Task List
        ListView {
            Layout.fillWidth: true
            Layout.fillHeight: true
            clip: true
            spacing: 8
            
            model: ListModel {
                ListElement { title: "Review project requirements"; done: true; tag: "High" }
                ListElement { title: "Design UI mockups"; done: false; tag: "High" }
                ListElement { title: "Implement core logic"; done: false; tag: "Medium" }
                ListElement { title: "Unit testing"; done: false; tag: "Medium" }
                ListElement { title: "Documentation"; done: false; tag: "Low" }
                ListElement { title: "Client meeting"; done: false; tag: "High" }
            }

            delegate: Rectangle {
                width: ListView.view.width
                height: 50
                radius: 8
                color: theme.secondaryColor
                border.color: Qt.rgba(0,0,0,0.05)

                RowLayout {
                    anchors.fill: parent
                    anchors.leftMargin: 16
                    anchors.rightMargin: 16
                    spacing: 16

                    Rectangle {
                        width: 20
                        height: 20
                        radius: 4
                        border.color: theme.borderColor
                        color: model.done ? theme.focusColor : "transparent"
                        
                        Text {
                            anchors.centerIn: parent
                            text: "\uf00c"
                            font.family: "Font Awesome 6 Free" 
                            font.styleName: "Solid"
                            visible: model.done
                            color: "white"
                            font.pixelSize: 12
                        }
                    }

                    Label {
                        text: model.title
                        color: theme.textColor
                        font.strikeout: model.done
                        Layout.fillWidth: true
                    }

                    Rectangle {
                        width: 60
                        height: 24
                        radius: 12
                        color: {
                            if (model.tag === "High") return Qt.rgba(1, 0, 0, 0.1)
                            if (model.tag === "Medium") return Qt.rgba(1, 0.6, 0, 0.1)
                            return Qt.rgba(0, 0, 1, 0.1)
                        }
                        
                        Label {
                            anchors.centerIn: parent
                            text: model.tag
                            font.pixelSize: 10
                            color: {
                                if (model.tag === "High") return "red"
                                if (model.tag === "Medium") return "orange"
                                return "blue"
                            }
                        }
                    }
                }
                
                MouseArea {
                    anchors.fill: parent
                    onClicked: model.done = !model.done
                }
            }
        }
    }
}

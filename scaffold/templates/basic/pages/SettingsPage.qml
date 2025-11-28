import QtQuick
import QtQuick.Controls
import QtQuick.Layouts
import EvolveUI

Page {
    property var animWindowRef
    padding: 20
    background: Rectangle {
        color: "transparent"
    }

    Label {
        text: "Settings Page"
        anchors.centerIn: parent
        font.pixelSize: 24
        color: theme.textColor
    }
  
    ColumnLayout {
        spacing: 10

        EButton {
        text: theme.isDark ? "浅色" : "深色"
        iconCharacter: theme.isDark ? "\uf185" : "\uf186"
        iconRotateOnClick: true
        onClicked: theme.toggleTheme()
        }

        ESlider {
            id: animSlider
            width: 280
            text: "动画时长"
            itemSpacing: 10
            minimumValue: 300
            maximumValue: 3000
            decimals: 0
            stepSize: 50
            valueSuffix: "ms"
            value: animWindowRef ? animWindowRef.animDuration : 450
            onUserValueChanged: function(value) {
                if (animWindowRef) animWindowRef.animDuration = Math.round(value)
            }
        }
    }

    

    Connections {
        target: animWindowRef
        function onAnimDurationChanged() { animSlider.value = animWindowRef.animDuration }
    }

    
}

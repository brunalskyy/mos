import QtQuick
import QtQuick.Controls.Basic

// Pill text field
TextField {
    id: f
    implicitHeight: 48
    leftPadding: 18; rightPadding: 18
    color: Theme.textColour
    placeholderTextColor: Theme.textVariant
    font.pixelSize: 15
    selectByMouse: true
    background: Rectangle {
        radius: 24
        color: Theme.surfaceContainer
        border.width: f.activeFocus ? 2 : 1
        border.color: f.activeFocus ? Theme.primary : Theme.outline
    }
}

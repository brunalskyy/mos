import QtQuick
import QtQuick.Controls.Basic
import QtQuick.Layouts

// Material 3 dialog
Popup {
    id: sheet
    default property alias content: body.data
    property string title
    modal: true
    focus: true
    anchors.centerIn: Overlay.overlay
    width: Math.min(460, parent ? parent.width - 48 : 460)
    padding: 24
    closePolicy: Popup.CloseOnEscape | Popup.CloseOnPressOutside
    Overlay.modal: Rectangle { color: Qt.rgba(0, 0, 0, 0.35) }
    enter: Transition {
        NumberAnimation { property: "opacity"; from: 0; to: 1; duration: 160 }
        NumberAnimation { property: "scale"; from: 0.92; to: 1; duration: 220; easing.type: Easing.OutBack }
    }
    exit: Transition { NumberAnimation { property: "opacity"; to: 0; duration: 120 } }
    background: Rectangle { radius: 28; color: Theme.surfaceHigh }
    contentItem: ColumnLayout {
        spacing: 16
        Label { text: sheet.title; color: Theme.textColour; font.pixelSize: 22; font.weight: Font.DemiBold; Layout.fillWidth: true; wrapMode: Text.WordWrap }
        ColumnLayout { id: body; spacing: 14; Layout.fillWidth: true }
    }
}

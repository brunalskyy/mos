import QtQuick
import QtQuick.Controls.Basic
import QtQuick.Layouts

// Title + description on the left, a control on the right
RowLayout {
    default property alias trailing: slot.data
    property string title
    property string sub: ""
    spacing: 16
    Layout.fillWidth: true
    ColumnLayout {
        spacing: 2
        Layout.fillWidth: true
        Label { text: title; color: Theme.onSurface; font.pixelSize: 16; font.weight: Font.Medium; Layout.fillWidth: true; wrapMode: Text.WordWrap }
        Label { text: sub; color: Theme.onSurfaceVariant; font.pixelSize: 13; visible: sub !== ""; wrapMode: Text.WordWrap; Layout.fillWidth: true }
    }
    Row { id: slot; spacing: 8; Layout.alignment: Qt.AlignVCenter }
}

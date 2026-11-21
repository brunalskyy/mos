import QtQuick
import QtQuick.Controls.Basic
import QtQuick.Layouts
import components

// A titled row you scroll sideways
ColumnLayout {
    id: shelf
    property string title
    property string subtitle
    property var apps: []
    property bool notes: false
    signal open(string id)
    Layout.fillWidth: true
    spacing: 12
    visible: apps.length > 0
    ColumnLayout {
        spacing: 0
        Label { text: shelf.title; color: Theme.textColour; font.pixelSize: 22; font.weight: Font.Bold }
        Label { visible: text !== ""; text: shelf.subtitle; color: Theme.textVariant; font.pixelSize: 13 }
    }
    ListView {
        Layout.fillWidth: true
        Layout.preferredHeight: 262
        orientation: ListView.Horizontal
        spacing: 20
        clip: true
        model: shelf.apps
        boundsBehavior: Flickable.StopAtBounds
        delegate: SmallCard {
            required property var modelData
            app: modelData
            note: shelf.notes && modelData.version ? "Version " + modelData.version + " · " + modelData.when : ""
            onOpen: function (id) { shelf.open(id) }
        }
        ScrollBar.horizontal: ScrollBar { policy: ScrollBar.AsNeeded }
    }
}

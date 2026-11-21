import QtQuick
import QtQuick.Controls.Basic
import QtQuick.Layouts
import QtQuick.Effects
import components

// A screenshot card with the app under it (for horizontal shelves)
Item {
    id: c
    property var app: ({})
    property string note
    signal open(string id)
    implicitWidth: 300
    implicitHeight: 262
    scale: ma.pressed ? 0.98 : 1
    Behavior on scale { NumberAnimation { duration: 120 } }
    Item {
        id: shot
        width: parent.width; height: 168
        visible: false; layer.enabled: true
        Rectangle { anchors.fill: parent; color: Theme.surfaceContainer }
        Image { anchors.fill: parent; source: c.app.shot || ""; fillMode: Image.PreserveAspectCrop; asynchronous: true }
    }
    Item { id: m; width: shot.width; height: shot.height; visible: false; layer.enabled: true
           Rectangle { anchors.fill: parent; radius: 22; color: "black" } }
    MultiEffect { width: shot.width; height: shot.height; source: shot; maskEnabled: true; maskSource: m }
    RowLayout {
        y: shot.height + 12
        width: parent.width
        spacing: 12
        AppIcon { source: c.app.icon || ""; size: 48 }
        ColumnLayout {
            Layout.fillWidth: true
            spacing: 1
            Label { Layout.fillWidth: true; text: c.app.name || ""; elide: Text.ElideRight; color: Theme.textColour
                    font.pixelSize: 14; font.weight: Font.DemiBold }
            Label { Layout.fillWidth: true; text: c.note || c.app.summary || ""; elide: Text.ElideRight; color: Theme.textVariant
                    font.pixelSize: 12 }
        }
        GetButton { appId: c.app.id || "" }
    }
    MouseArea { id: ma; anchors.fill: parent; z: -1; cursorShape: Qt.PointingHandCursor; onClicked: c.open(c.app.id) }
}

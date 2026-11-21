import QtQuick
import QtQuick.Controls.Basic
import QtQuick.Layouts
import components

// One app in a list: icon, name, one line about it, and Get
Rectangle {
    id: row
    property var app: ({})
    property int rank: 0
    signal open(string id)
    implicitHeight: 84
    radius: 22
    color: ma.containsMouse ? Theme.alpha(Theme.textColour, 0.05) : "transparent"
    RowLayout {
        anchors.fill: parent
        anchors.leftMargin: 10; anchors.rightMargin: 12
        spacing: 14
        Label { visible: row.rank > 0; text: row.rank; color: Theme.textVariant; font.pixelSize: 15; font.weight: Font.Bold
                Layout.preferredWidth: 20; horizontalAlignment: Text.AlignHCenter }
        AppIcon { source: row.app.icon || ""; size: 60 }
        ColumnLayout {
            Layout.fillWidth: true
            spacing: 2
            Label { Layout.fillWidth: true; text: row.app.name || ""; elide: Text.ElideRight; color: Theme.textColour
                    font.pixelSize: 15; font.weight: Font.DemiBold }
            Label { Layout.fillWidth: true; text: row.app.summary || ""; elide: Text.ElideRight; color: Theme.textVariant
                    font.pixelSize: 13 }
            Label { Layout.fillWidth: true; visible: text !== ""; text: row.app.newVersion ? "Update to " + row.app.newVersion : ""
                    color: Theme.primary; font.pixelSize: 12; font.weight: Font.Medium }
        }
        GetButton { appId: row.app.id || "" }
    }
    MouseArea { id: ma; anchors.fill: parent; z: -1; hoverEnabled: true; cursorShape: Qt.PointingHandCursor
                onClicked: row.open(row.app.id) }
}

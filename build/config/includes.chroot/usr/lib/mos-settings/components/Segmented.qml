import QtQuick
import QtQuick.Controls.Basic
import QtQuick.Layouts

// Material 3 segmented buttons. options: [{value, label}]
Rectangle {
    id: seg
    property var options: []
    property var current
    signal selected(var value)
    implicitHeight: 44
    implicitWidth: row.implicitWidth
    radius: 22
    color: "transparent"
    border.width: 1; border.color: Theme.outline
    clip: true
    RowLayout {
        id: row
        anchors.fill: parent
        spacing: 0
        Repeater {
            model: seg.options
            delegate: Rectangle {
                required property var modelData
                required property int index
                readonly property bool on: seg.current === modelData.value
                Layout.fillHeight: true
                Layout.fillWidth: true
                Layout.preferredWidth: lab.implicitWidth + (on ? 52 : 36)
                color: on ? Theme.secondaryContainer : (m.containsMouse ? Theme.alpha(Theme.onSurface, 0.05) : "transparent")
                radius: index === 0 || index === seg.options.length - 1 ? 22 : 0
                Rectangle { visible: index > 0; width: 1; height: parent.height; color: Theme.outline }
                Row {
                    anchors.centerIn: parent; spacing: 6
                    Image { visible: on; source: Theme.ink("check"); width: 16; height: 16; sourceSize: Qt.size(32, 32); anchors.verticalCenter: parent.verticalCenter }
                    Label { id: lab; text: modelData.label; color: Theme.onSurface; font.pixelSize: 14; font.weight: Font.Medium; anchors.verticalCenter: parent.verticalCenter }
                }
                MouseArea { id: m; anchors.fill: parent; hoverEnabled: true; cursorShape: Qt.PointingHandCursor; onClicked: seg.selected(modelData.value) }
            }
        }
    }
}

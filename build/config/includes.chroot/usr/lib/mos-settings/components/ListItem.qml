import QtQuick
import QtQuick.Controls.Basic
import QtQuick.Layouts

// A tappable row: icon, title, subtitle, value, chevron
Rectangle {
    id: li
    default property alias trailing: slot.data
    property string title
    property string sub: ""
    property string value: ""
    property string iconName: ""
    property color tone: "#757575"
    property string image: ""
    property bool chevron: true
    property bool selected: false
    signal clicked()
    Layout.fillWidth: true
    implicitHeight: Math.max(56, col.implicitHeight + 20)
    radius: 18
    color: selected ? Theme.secondaryContainer : (ma.containsMouse ? Theme.alpha(Theme.textColour, 0.05) : "transparent")
    Behavior on color { ColorAnimation { duration: 120 } }
    RowLayout {
        anchors.fill: parent; anchors.leftMargin: 12; anchors.rightMargin: 12; spacing: 14
        ToneIcon { visible: li.iconName !== ""; name: li.iconName || "info"; tone: li.tone; size: 36 }
        Image { visible: li.image !== ""; source: li.image; Layout.preferredWidth: 36; Layout.preferredHeight: 36; sourceSize: Qt.size(72, 72); fillMode: Image.PreserveAspectFit }
        ColumnLayout {
            id: col
            spacing: 1; Layout.fillWidth: true
            Label { text: li.title; color: Theme.textColour; font.pixelSize: 15; font.weight: Font.Medium; elide: Text.ElideRight; Layout.fillWidth: true }
            Label { text: li.sub; visible: li.sub !== ""; color: Theme.textVariant; font.pixelSize: 13; elide: Text.ElideRight; Layout.fillWidth: true }
        }
        Label { visible: li.value !== ""; text: li.value; color: Theme.textVariant; font.pixelSize: 14 }
        Row { id: slot; spacing: 8; Layout.alignment: Qt.AlignVCenter }
        Image { visible: li.chevron; source: Theme.ink("chevron"); Layout.preferredWidth: 18; Layout.preferredHeight: 18; sourceSize: Qt.size(36, 36); opacity: 0.6 }
    }
    MouseArea { id: ma; anchors.fill: parent; hoverEnabled: true; cursorShape: Qt.PointingHandCursor; onClicked: li.clicked(); z: -1 }
}

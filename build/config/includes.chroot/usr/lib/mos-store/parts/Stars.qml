import QtQuick
import QtQuick.Controls.Basic
import components

// ★★★★☆
Row {
    id: s
    property real value: 0
    property int size: 14
    property bool editable: false
    signal picked(int n)
    spacing: 1
    Repeater {
        model: 5
        Label {
            required property int index
            text: "★"
            font.pixelSize: s.size
            color: index < Math.round(s.value) ? "#F5A623" : Theme.alpha(Theme.textColour, 0.2)
            MouseArea { anchors.fill: parent; enabled: s.editable; cursorShape: Qt.PointingHandCursor
                        onClicked: { s.value = index + 1; s.picked(index + 1) } }
        }
    }
}

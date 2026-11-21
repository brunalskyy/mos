import QtQuick
import QtQuick.Controls.Basic

// Material 3 pill button: filled, tonal or outlined
Rectangle {
    id: b
    property string text
    property bool tonal: false
    property bool outlined: false
    property bool danger: false
    property bool busy: false
    signal clicked()
    implicitWidth: Math.max(88, lbl.implicitWidth + 48)
    implicitHeight: 44
    radius: 22
    color: outlined ? "transparent" : danger ? Theme.error : tonal ? Theme.primaryContainer : Theme.primary
    border.width: outlined ? 1 : 0
    border.color: Theme.outline
    opacity: enabled ? (ma.pressed ? 0.82 : 1) : 0.4
    scale: ma.pressed ? 0.97 : 1
    Behavior on scale { NumberAnimation { duration: 90 } }
    Label {
        id: lbl; anchors.centerIn: parent; text: b.busy ? "…" : b.text
        color: b.outlined ? Theme.primary : b.danger ? Theme.surfaceHigh : b.tonal ? Theme.onPrimaryContainer : Theme.onPrimary
        font.pixelSize: 15; font.weight: Font.DemiBold
    }
    MouseArea { id: ma; anchors.fill: parent; cursorShape: Qt.PointingHandCursor; enabled: b.enabled && !b.busy; onClicked: b.clicked() }
}

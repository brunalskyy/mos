import QtQuick

// Material 3 switch
Item {
    id: sw
    property bool checked: false
    property bool enabled: true
    signal toggled(bool value)
    implicitWidth: 52; implicitHeight: 32
    opacity: enabled ? 1 : 0.4
    Rectangle {
        anchors.fill: parent; radius: 16
        color: sw.checked ? Theme.primary : Theme.surfaceContainer
        border.width: sw.checked ? 0 : 2
        border.color: Theme.outline
        Behavior on color { ColorAnimation { duration: 160 } }
    }
    Rectangle {
        readonly property int d: sw.checked ? 24 : (ma.pressed ? 28 : 16)
        width: d; height: d; radius: d / 2
        anchors.verticalCenter: parent.verticalCenter
        x: sw.checked ? parent.width - d - 4 : (ma.pressed ? 2 : 8)
        color: sw.checked ? Theme.primaryText : Theme.textVariant
        Behavior on x { NumberAnimation { duration: 180; easing.type: Easing.OutBack; easing.overshoot: 1.6 } }
        Behavior on width { NumberAnimation { duration: 140 } }
        Behavior on height { NumberAnimation { duration: 140 } }
    }
    MouseArea {
        id: ma
        anchors.fill: parent; cursorShape: Qt.PointingHandCursor; enabled: sw.enabled
        onClicked: { sw.checked = !sw.checked; sw.toggled(sw.checked) }
    }
}

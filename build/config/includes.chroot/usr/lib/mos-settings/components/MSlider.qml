import QtQuick

// Material 3 slider (thick track, round handle). moved() while dragging, released() at the end.
Item {
    id: s
    property real from: 0
    property real to: 100
    property real value: 50
    property real step: 1
    signal moved(real value)
    signal released(real value)
    implicitHeight: 44
    implicitWidth: 240
    readonly property real pos: Math.max(0, Math.min(1, (value - from) / ((to - from) || 1)))
    Rectangle {
        id: track
        anchors.verticalCenter: parent.verticalCenter
        x: 0; width: parent.width; height: 16; radius: 8
        color: Theme.primaryContainer
    }
    Rectangle {
        anchors.verticalCenter: parent.verticalCenter
        x: 0; width: Math.max(16, s.pos * s.width); height: 16; radius: 8
        color: Theme.primary
    }
    Rectangle {
        width: 6; height: 40; radius: 3
        anchors.verticalCenter: parent.verticalCenter
        x: Math.min(s.width - width, Math.max(0, s.pos * s.width - width / 2))
        color: Theme.primary
        border.width: 2; border.color: Theme.surfaceHigh
    }
    MouseArea {
        anchors.fill: parent; cursorShape: Qt.PointingHandCursor
        function set(mx) {
            var v = s.from + Math.max(0, Math.min(1, mx / s.width)) * (s.to - s.from)
            v = Math.round(v / s.step) * s.step
            if (v !== s.value) { s.value = v; s.moved(v) }
        }
        onPressed: function (e) { set(e.x) }
        onPositionChanged: function (e) { if (pressed) set(e.x) }
        onReleased: s.released(s.value)
    }
}

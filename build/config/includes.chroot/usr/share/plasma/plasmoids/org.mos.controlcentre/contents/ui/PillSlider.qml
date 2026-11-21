import QtQuick
import org.kde.kirigami as Kirigami

// Material 3 Expressive slider: a thick pill that fills with the accent colour,
// the icon sits inside it
Rectangle {
    id: s
    property real value: 50        // 0-100
    property string iconName
    property string fallbackIcon: "configure"
    property color accent
    property color onAccent
    property color off
    property color textColour
    signal moved(int v)

    implicitHeight: Kirigami.Units.gridUnit * 2.6
    radius: height / 2
    color: off
    clip: true

    Rectangle {
        id: fill
        height: parent.height
        width: Math.max(parent.height, parent.width * Math.max(0, Math.min(100, s.value)) / 100)
        radius: s.radius
        color: s.accent
        Behavior on width { enabled: !drag.pressed; NumberAnimation { duration: 160; easing.type: Easing.OutCubic } }
    }
    Kirigami.Icon {
        anchors.left: parent.left
        anchors.leftMargin: (s.height - width) / 2
        anchors.verticalCenter: parent.verticalCenter
        width: Kirigami.Units.iconSizes.smallMedium; height: width
        source: s.iconName
        fallback: s.fallbackIcon
        color: s.onAccent
        isMask: true
    }
    Text {
        anchors.right: parent.right
        anchors.rightMargin: s.height * 0.4
        anchors.verticalCenter: parent.verticalCenter
        text: Math.round(s.value) + "%"
        color: fill.width > s.width - s.height * 1.2 ? s.onAccent : s.textColour
        opacity: 0.75
        font.pixelSize: Kirigami.Units.gridUnit * 0.7
        font.weight: Font.DemiBold
    }
    MouseArea {
        id: drag
        anchors.fill: parent
        cursorShape: Qt.PointingHandCursor
        function set(x) {
            var v = Math.round(Math.max(0, Math.min(100, x / s.width * 100)))
            s.value = v
            s.moved(v)
        }
        onPressed: function (m) { set(m.x) }
        onPositionChanged: function (m) { if (pressed) set(m.x) }
    }
    WheelHandler {
        onWheel: function (e) {
            var v = Math.max(0, Math.min(100, s.value + (e.angleDelta.y > 0 ? 5 : -5)))
            s.value = v
            s.moved(v)
        }
    }
}

// mOS Battery: Material card with a ring, the percentage and a bolt when charging.
import QtQuick

Item {
    id: face
    property color accent: "#E8833A"
    property bool dark: false
    property int percent: 76
    property bool charging: false
    property bool present: true

    function mix(a, b, t) {
        var ca = Qt.lighter(a, 1.0), cb = Qt.lighter(b, 1.0)
        return Qt.rgba(ca.r + (cb.r - ca.r) * t, ca.g + (cb.g - ca.g) * t, ca.b + (cb.b - ca.b) * t, 1)
    }
    readonly property color card: dark ? mix(accent, "#1D1B20", 0.62) : mix(accent, "#FFFFFF", 0.72)
    readonly property color track: dark ? mix(accent, "#1D1B20", 0.4) : mix(accent, "#FFFFFF", 0.45)
    readonly property color fill: percent <= 15 && !charging ? "#E5484D" : (dark ? mix(accent, "#FFFFFF", 0.25) : mix(accent, "#000000", 0.2))
    readonly property color ink: dark ? mix(accent, "#FFFFFF", 0.8) : mix(accent, "#000000", 0.6)
    readonly property real size: Math.min(width, height)
    visible: present
    onPercentChanged: ring.requestPaint()
    onChargingChanged: ring.requestPaint()
    onAccentChanged: ring.requestPaint()

    Rectangle {
        anchors.centerIn: parent
        width: face.size; height: face.size
        radius: face.size * 0.3
        color: face.card
    }
    Canvas {
        id: ring
        anchors.centerIn: parent
        width: face.size * 0.72; height: width
        onPaint: {
            var c = getContext("2d"); c.reset()
            var r = width / 2 - width * 0.07
            c.lineWidth = width * 0.11; c.lineCap = "round"
            c.strokeStyle = face.track
            c.beginPath(); c.arc(width / 2, height / 2, r, 0, 2 * Math.PI); c.stroke()
            c.strokeStyle = face.fill
            c.beginPath(); c.arc(width / 2, height / 2, r, -Math.PI / 2, -Math.PI / 2 + 2 * Math.PI * Math.max(0.02, face.percent / 100)); c.stroke()
        }
    }
    Column {
        anchors.centerIn: parent
        spacing: 0
        Text {
            anchors.horizontalCenter: parent.horizontalCenter
            visible: face.charging
            text: "⚡"; color: face.ink; font.pixelSize: face.size * 0.12
        }
        Text {
            anchors.horizontalCenter: parent.horizontalCenter
            text: face.percent + "%"; color: face.ink
            font.family: "Inter"; font.weight: Font.DemiBold; font.pixelSize: face.size * 0.17
        }
    }
}

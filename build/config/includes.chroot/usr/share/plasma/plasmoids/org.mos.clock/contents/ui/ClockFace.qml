// mOS Clock face: four-petal Material flower, 12 / 3 / 6 / 9, two rounded hands.
// Plain Qt Quick, so it can be previewed outside Plasma.
import QtQuick

Item {
    id: face
    property color accent: "#E8833A"
    property bool dark: false
    property date now: new Date()

    function mix(a, b, t) {
        var ca = Qt.lighter(a, 1.0), cb = Qt.lighter(b, 1.0)
        return Qt.rgba(ca.r + (cb.r - ca.r) * t, ca.g + (cb.g - ca.g) * t, ca.b + (cb.b - ca.b) * t, 1)
    }
    readonly property color petal: dark ? mix(accent, "#1D1B20", 0.62) : mix(accent, "#FFFFFF", 0.72)
    readonly property color numbers: dark ? mix(accent, "#FFFFFF", 0.55) : mix(accent, "#000000", 0.45)
    readonly property color hourHand: dark ? mix(accent, "#FFFFFF", 0.25) : mix(accent, "#000000", 0.25)
    readonly property color minuteHand: dark ? mix(accent, "#FFFFFF", 0.7) : mix(accent, "#000000", 0.55)

    Timer { interval: 1000; running: true; repeat: true; triggeredOnStart: true; onTriggered: face.now = new Date() }
    onNowChanged: hands.requestPaint()
    onAccentChanged: { shape.requestPaint(); hands.requestPaint() }
    onDarkChanged: { shape.requestPaint(); hands.requestPaint() }

    readonly property real size: Math.min(width, height)

    // The flower
    Canvas {
        id: shape
        anchors.centerIn: parent
        width: face.size; height: face.size
        onPaint: {
            var c = getContext("2d"); c.reset()
            var R = width / 2 * 0.98, cx = width / 2, cy = height / 2
            c.beginPath()
            for (var i = 0; i <= 720; i++) {
                var t = 2 * Math.PI * i / 720
                var r = R * (0.74 + 0.26 * Math.pow(Math.abs(Math.cos(2 * t)), 0.7))
                var x = cx + r * Math.cos(t), y = cy + r * Math.sin(t)
                if (i === 0) c.moveTo(x, y); else c.lineTo(x, y)
            }
            c.closePath()
            c.shadowColor = Qt.rgba(0, 0, 0, 0.18); c.shadowBlur = width * 0.04; c.shadowOffsetY = width * 0.015
            c.fillStyle = face.petal
            c.fill()
        }
    }

    // 12, 3, 6, 9 sit in the petals
    Repeater {
        model: [{ n: "12", a: -90 }, { n: "3", a: 0 }, { n: "6", a: 90 }, { n: "9", a: 180 }]
        delegate: Text {
            required property var modelData
            text: modelData.n
            color: face.numbers
            font.family: "Inter"
            font.weight: Font.DemiBold
            font.pixelSize: face.size * 0.13
            x: face.width / 2 + Math.cos(modelData.a * Math.PI / 180) * face.size * 0.36 - width / 2
            y: face.height / 2 + Math.sin(modelData.a * Math.PI / 180) * face.size * 0.36 - height / 2
        }
    }

    // Hands
    Canvas {
        id: hands
        anchors.centerIn: parent
        width: face.size; height: face.size
        onPaint: {
            var c = getContext("2d"); c.reset()
            var cx = width / 2, cy = height / 2, R = width / 2
            var h = face.now.getHours() % 12, m = face.now.getMinutes(), s = face.now.getSeconds()
            var minA = (m + s / 60) / 60 * 2 * Math.PI - Math.PI / 2
            var hourA = (h + m / 60) / 12 * 2 * Math.PI - Math.PI / 2
            c.lineCap = "round"
            c.shadowColor = Qt.rgba(0, 0, 0, 0.22); c.shadowBlur = width * 0.03; c.shadowOffsetY = width * 0.01
            // minute hand: long and slimmer
            c.strokeStyle = face.minuteHand; c.lineWidth = R * 0.11
            c.beginPath(); c.moveTo(cx, cy); c.lineTo(cx + Math.cos(minA) * R * 0.58, cy + Math.sin(minA) * R * 0.58); c.stroke()
            // hour hand: short and thick
            c.strokeStyle = face.hourHand; c.lineWidth = R * 0.15
            c.beginPath(); c.moveTo(cx, cy); c.lineTo(cx + Math.cos(hourA) * R * 0.42, cy + Math.sin(hourA) * R * 0.42); c.stroke()
        }
    }
}

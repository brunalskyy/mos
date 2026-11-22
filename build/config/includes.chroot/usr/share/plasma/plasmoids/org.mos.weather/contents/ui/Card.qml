// mOS widget card: a rounded Material tile in your accent colour (same look as Clock and Battery)
import QtQuick

Rectangle {
    id: card
    property color accent: "#E8833A"
    property bool dark: false
    function mix(a, b, t) {
        var ca = Qt.lighter(a, 1.0), cb = Qt.lighter(b, 1.0)
        return Qt.rgba(ca.r + (cb.r - ca.r) * t, ca.g + (cb.g - ca.g) * t, ca.b + (cb.b - ca.b) * t, 1)
    }
    readonly property color ink: dark ? mix(accent, "#FFFFFF", 0.85) : mix(accent, "#000000", 0.65)
    readonly property color soft: dark ? mix(accent, "#FFFFFF", 0.45) : mix(accent, "#000000", 0.35)
    readonly property color strong: dark ? mix(accent, "#FFFFFF", 0.25) : mix(accent, "#000000", 0.2)
    readonly property real unit: Math.min(width, height)
    color: dark ? mix(accent, "#1D1B20", 0.62) : mix(accent, "#FFFFFF", 0.72)
    radius: Math.min(Math.min(width, height) * 0.22, 34)
}

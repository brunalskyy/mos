pragma Singleton
import QtQuick

// Material You colours worked out from the mOS accent colour
QtObject {
    readonly property bool dark: backend.dark
    readonly property color accent: backend.accent

    function mix(a, b, t) {
        var ca = Qt.lighter(a, 1.0), cb = Qt.lighter(b, 1.0)
        return Qt.rgba(ca.r + (cb.r - ca.r) * t, ca.g + (cb.g - ca.g) * t, ca.b + (cb.b - ca.b) * t, 1)
    }
    function alpha(c, a) { var x = Qt.lighter(c, 1.0); return Qt.rgba(x.r, x.g, x.b, a) }

    readonly property color primary: dark ? mix(accent, "#FFFFFF", 0.35) : mix(accent, "#000000", 0.12)
    readonly property color onPrimary: dark ? mix(accent, "#000000", 0.8) : "#FFFFFF"
    readonly property color primaryContainer: dark ? mix(accent, "#000000", 0.6) : mix(accent, "#FFFFFF", 0.78)
    readonly property color onPrimaryContainer: dark ? mix(accent, "#FFFFFF", 0.82) : mix(accent, "#000000", 0.7)
    readonly property color secondaryContainer: dark ? mix(accent, "#2B2930", 0.82) : mix(accent, "#FFFFFF", 0.86)
    readonly property color surface: dark ? mix(accent, "#141218", 0.94) : mix(accent, "#FFFBFF", 0.96)
    readonly property color surfaceContainer: dark ? mix(accent, "#1D1B20", 0.9) : mix(accent, "#F7F2FA", 0.9)
    readonly property color surfaceHigh: dark ? mix(accent, "#2B2930", 0.9) : "#FFFFFF"
    readonly property color onSurface: dark ? "#E6E0E9" : "#1D1B20"
    readonly property color onSurfaceVariant: dark ? "#CAC4D0" : "#49454F"
    readonly property color outline: dark ? "#49454F" : mix(accent, "#CAC4D0", 0.85)
    readonly property color error: dark ? "#F2B8B5" : "#B3261E"
    readonly property color good: dark ? "#8BD5A0" : "#1E6B3A"

    readonly property string font: "Inter"

    function icon(name) { return Qt.resolvedUrl("../icons/" + name + ".svg") }
    function ink(name) { return Qt.resolvedUrl("../icons/" + name + (dark ? "-inkdark" : "-ink") + ".svg") }
}

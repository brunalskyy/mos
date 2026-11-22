import QtQuick
import QtQuick.Layouts
import QtQuick.Effects
import org.kde.plasma.plasmoid
import org.kde.plasma.core as PlasmaCore
import org.kde.plasma.plasma5support as P5Support
import org.kde.kirigami as Kirigami

// At a glance (like Pixel): the date, then the weather where you are.
// Location comes from your time zone; weather from Open-Meteo (free, no account).
PlasmoidItem {
    id: root
    property date now: new Date()
    property var loc: null
    property real temp: NaN
    property int code: -1
    property bool isDay: true
    property string place: ""

    Plasmoid.backgroundHints: PlasmaCore.Types.NoBackground
    preferredRepresentation: fullRepresentation

    Timer { interval: 30000; running: true; repeat: true; onTriggered: root.now = new Date() }
    Timer { interval: 30 * 60 * 1000; running: root.loc !== null; repeat: true; onTriggered: root.fetchWeather() }
    Timer { id: retry; interval: 60 * 1000; onTriggered: root.fetchWeather() }

    P5Support.DataSource {
        engine: "executable"
        connectedSources: ["mos-cc location"]
        onNewData: function (source, data) {
            disconnectSource(source)
            try {
                root.loc = JSON.parse(data.stdout)
                root.place = root.loc.place
                root.fetchWeather()
            } catch (e) {}
        }
    }

    function fetchWeather() {
        if (!loc) return
        var x = new XMLHttpRequest()
        x.open("GET", "https://api.open-meteo.com/v1/forecast?latitude=" + loc.lat + "&longitude=" + loc.lon
               + "&current=temperature_2m,weather_code,is_day&timezone=auto")
        x.onreadystatechange = function () {
            if (x.readyState !== XMLHttpRequest.DONE) return
            if (x.status !== 200) { retry.restart(); return }
            try {
                var c = JSON.parse(x.responseText).current
                root.temp = c.temperature_2m
                root.code = c.weather_code
                root.isDay = c.is_day === 1
            } catch (e) { retry.restart() }
        }
        x.send()
    }

    // WMO weather codes → words and icons
    function words(c) {
        if (c === 0) return isDay ? "Sunny" : "Clear"
        if (c <= 2) return "Partly cloudy"
        if (c === 3) return "Cloudy"
        if (c <= 48) return "Foggy"
        if (c <= 57) return "Drizzle"
        if (c <= 67) return "Rain"
        if (c <= 77) return "Snow"
        if (c <= 82) return "Showers"
        if (c <= 86) return "Snow showers"
        return "Thunderstorms"
    }
    function icon(c) {
        var n = isDay ? "" : "-night"
        if (c === 0) return "weather-clear" + n
        if (c <= 2) return "weather-few-clouds" + n
        if (c === 3) return "weather-overcast"
        if (c <= 48) return "weather-fog"
        if (c <= 67 || (c >= 80 && c <= 82)) return c <= 57 ? "weather-showers-scattered" + n : "weather-showers" + n
        if (c <= 77 || c <= 86) return "weather-snow"
        return "weather-storm" + n
    }

    fullRepresentation: Item {
        Layout.minimumWidth: Kirigami.Units.gridUnit * 14
        Layout.minimumHeight: Kirigami.Units.gridUnit * 4
        Layout.preferredWidth: Kirigami.Units.gridUnit * 20
        Layout.preferredHeight: Kirigami.Units.gridUnit * 5

        ColumnLayout {
            id: content
            anchors.left: parent.left
            anchors.verticalCenter: parent.verticalCenter
            spacing: Kirigami.Units.smallSpacing
            Text {
                text: Qt.formatDate(root.now, "dddd d MMMM")
                color: "white"
                font.family: "Inter"
                font.pixelSize: Kirigami.Units.gridUnit * 1.55
                font.weight: Font.Normal
            }
            RowLayout {
                spacing: Kirigami.Units.smallSpacing * 1.5
                visible: !isNaN(root.temp)
                Kirigami.Icon {
                    Layout.preferredWidth: Kirigami.Units.iconSizes.smallMedium
                    Layout.preferredHeight: Layout.preferredWidth
                    source: root.icon(root.code)
                    fallback: "weather-few-clouds"
                    // white like the text, so a grey cloud doesn't vanish on a dark wallpaper
                    isMask: true
                    color: "white"
                }
                Text {
                    text: Math.round(root.temp) + "°C · " + root.words(root.code)
                    color: "white"
                    font.family: "Inter"
                    font.pixelSize: Kirigami.Units.gridUnit * 0.95
                    font.weight: Font.Medium
                }
            }
            layer.enabled: GraphicsInfo.api !== GraphicsInfo.Software   // shadow needs the GPU
            layer.effect: MultiEffect {
                shadowEnabled: true
                shadowColor: Qt.rgba(0, 0, 0, 0.45)
                shadowBlur: 0.6
                shadowVerticalOffset: 1
                shadowHorizontalOffset: 0
            }
        }
    }
}

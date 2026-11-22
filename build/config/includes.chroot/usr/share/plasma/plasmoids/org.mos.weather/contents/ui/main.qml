import QtQuick
import QtQuick.Layouts
import org.kde.plasma.plasmoid
import org.kde.plasma.core as PlasmaCore
import org.kde.plasma.plasma5support as P5Support
import org.kde.kirigami as Kirigami

// mOS Weather: small = now, wide = now plus the next five hours.
// Location from your time zone (mos-cc), weather from Open-Meteo (free, no account).
PlasmoidItem {
    id: root
    Plasmoid.backgroundHints: PlasmaCore.Types.NoBackground
    preferredRepresentation: fullRepresentation
    property var loc: null
    property string place: ""
    property real temp: NaN
    property int code: -1
    property bool isDay: true
    property real high: NaN
    property real low: NaN
    property var hours: []
    toolTipMainText: place
    toolTipSubText: isNaN(temp) ? "" : Math.round(temp) + "° · " + words(code)

    Timer { interval: 30 * 60 * 1000; running: root.loc !== null; repeat: true; onTriggered: root.fetch() }
    Timer { id: retry; interval: 60 * 1000; onTriggered: root.fetch() }

    P5Support.DataSource {
        engine: "executable"
        connectedSources: ["mos-cc location"]
        onNewData: function (source, data) {
            disconnectSource(source)
            try {
                root.loc = JSON.parse(data.stdout)
                root.place = root.loc.place
                root.fetch()
            } catch (e) {}
        }
    }

    function fetch() {
        if (!loc) return
        var x = new XMLHttpRequest()
        x.open("GET", "https://api.open-meteo.com/v1/forecast?latitude=" + loc.lat + "&longitude=" + loc.lon
               + "&current=temperature_2m,weather_code,is_day&hourly=temperature_2m,weather_code,is_day"
               + "&daily=temperature_2m_max,temperature_2m_min&forecast_days=2&timezone=auto")
        x.onreadystatechange = function () {
            if (x.readyState !== XMLHttpRequest.DONE) return
            if (x.status !== 200) { retry.restart(); return }
            try {
                var j = JSON.parse(x.responseText)
                root.temp = j.current.temperature_2m
                root.code = j.current.weather_code
                root.isDay = j.current.is_day === 1
                root.high = j.daily.temperature_2m_max[0]
                root.low = j.daily.temperature_2m_min[0]
                var nowIso = j.current.time.slice(0, 13)
                var start = 0
                for (var i = 0; i < j.hourly.time.length; i++) { if (j.hourly.time[i].slice(0, 13) > nowIso) { start = i; break } }
                var list = []
                for (var k = start; k < Math.min(start + 5, j.hourly.time.length); k++)
                    list.push({ hour: j.hourly.time[k].slice(11, 13), temp: j.hourly.temperature_2m[k],
                                code: j.hourly.weather_code[k], day: j.hourly.is_day[k] === 1 })
                root.hours = list
            } catch (e) { retry.restart() }
        }
        x.send()
    }

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
    function icon(c, day) {
        var n = day ? "" : "-night"
        if (c === 0) return "weather-clear" + n
        if (c <= 2) return "weather-few-clouds" + n
        if (c === 3) return "weather-overcast"
        if (c <= 48) return "weather-fog"
        if (c <= 67 || (c >= 80 && c <= 82)) return c <= 57 ? "weather-showers-scattered" + n : "weather-showers" + n
        if (c <= 86) return "weather-snow"
        return "weather-storm" + n
    }

    fullRepresentation: WeatherFace {
        Layout.minimumWidth: Kirigami.Units.gridUnit * 7
        Layout.minimumHeight: Kirigami.Units.gridUnit * 7
        Layout.preferredWidth: Kirigami.Units.gridUnit * 8
        Layout.preferredHeight: Kirigami.Units.gridUnit * 8
        accent: Kirigami.Theme.highlightColor
        dark: Kirigami.ColorUtils.brightnessForColor(Kirigami.Theme.backgroundColor) === Kirigami.ColorUtils.Dark
        place: root.place
        temp: root.temp
        code: root.code
        isDay: root.isDay
        high: root.high
        low: root.low
        hours: root.hours
    }
}

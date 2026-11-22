import QtQuick
import QtQuick.Layouts
import org.kde.kirigami as Kirigami

// WeatherFace: the look of the widget (also used for the previews in Add widgets)
Card {
    id: card
    property string place: ""
    property real temp: NaN
    property int code: -1
    property bool isDay: true
    property real high: NaN
    property real low: NaN
    property var hours: []
    function words(c) {
        if (c === 0) return card.isDay ? "Sunny" : "Clear"
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

    readonly property bool wide: width >= height * 1.6

    RowLayout {
        anchors.fill: parent
        anchors.margins: card.unit * 0.1
        spacing: card.unit * 0.1
        ColumnLayout {
            Layout.fillHeight: true
            Layout.preferredWidth: card.wide ? card.height - card.unit * 0.24 : -1
            Layout.fillWidth: !card.wide
            spacing: 0
            Text { text: card.place || "Weather"; color: card.strong; elide: Text.ElideRight; Layout.fillWidth: true
                   font.family: "Inter"; font.weight: Font.Bold; font.pixelSize: card.unit * 0.1 }
            Text { text: isNaN(card.temp) ? "--" : Math.round(card.temp) + "°"; color: card.ink
                   font.family: "Inter"; font.weight: Font.Light; font.pixelSize: card.unit * 0.3; Layout.topMargin: -card.unit * 0.03 }
            Item { Layout.fillHeight: true }
            Kirigami.Icon { source: card.icon(card.code, card.isDay); fallback: "weather-few-clouds"; isMask: true; color: card.ink
                            Layout.preferredWidth: card.unit * 0.13; Layout.preferredHeight: Layout.preferredWidth; visible: card.code >= 0 }
            Text { text: card.code < 0 ? "" : card.words(card.code); color: card.ink; font.family: "Inter"; font.weight: Font.DemiBold; font.pixelSize: card.unit * 0.08 }
            Text { text: isNaN(card.high) ? "" : "H:" + Math.round(card.high) + "°  L:" + Math.round(card.low) + "°"
                   color: card.soft; font.family: "Inter"; font.weight: Font.Medium; font.pixelSize: card.unit * 0.075 }
        }
        RowLayout {
            visible: card.wide
            Layout.fillWidth: true; Layout.fillHeight: true
            Repeater {
                model: card.hours
                ColumnLayout {
                    Layout.fillWidth: true
                    spacing: card.unit * 0.05
                    Text { Layout.alignment: Qt.AlignHCenter; text: modelData.hour; color: card.soft; font.family: "Inter"; font.weight: Font.DemiBold; font.pixelSize: card.unit * 0.085 }
                    Kirigami.Icon { Layout.alignment: Qt.AlignHCenter; source: card.icon(modelData.code, modelData.day); fallback: "weather-few-clouds"
                                    isMask: true; color: card.ink; Layout.preferredWidth: card.unit * 0.17; Layout.preferredHeight: Layout.preferredWidth }
                    Text { Layout.alignment: Qt.AlignHCenter; text: Math.round(modelData.temp) + "°"; color: card.ink; font.family: "Inter"; font.weight: Font.DemiBold; font.pixelSize: card.unit * 0.1 }
                }
            }
        }
    }
}

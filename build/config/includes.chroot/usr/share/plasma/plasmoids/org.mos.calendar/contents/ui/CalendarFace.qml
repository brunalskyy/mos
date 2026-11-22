import QtQuick
import QtQuick.Layouts
import org.kde.kirigami as Kirigami

// CalendarFace: the look of the widget (also used for the previews in Add widgets)
Card {
    id: card
    property date now: new Date()
    readonly property bool big: width >= Kirigami.Units.gridUnit * 13 && height >= Kirigami.Units.gridUnit * 11

    // Small: weekday, big date, month
    ColumnLayout {
        visible: !card.big
        anchors.left: parent.left; anchors.top: parent.top
        anchors.margins: card.unit * 0.13
        spacing: 0
        Text { text: Qt.formatDate(card.now, "dddd").toUpperCase(); color: card.strong; font.family: "Inter"; font.weight: Font.Bold; font.pixelSize: card.unit * 0.11; font.letterSpacing: 1 }
        Text { text: card.now.getDate(); color: card.ink; font.family: "Inter"; font.weight: Font.Light; font.pixelSize: card.unit * 0.48; Layout.topMargin: -card.unit * 0.04 }
        Text { text: Qt.formatDate(card.now, "MMMM"); color: card.soft; font.family: "Inter"; font.weight: Font.Medium; font.pixelSize: card.unit * 0.1; Layout.topMargin: -card.unit * 0.05 }
    }

    // Big: the month, today in a circle
    ColumnLayout {
        visible: card.big
        anchors.fill: parent
        anchors.margins: card.unit * 0.08
        spacing: card.unit * 0.02
        Text {
            text: Qt.formatDate(card.now, "MMMM yyyy")
            color: card.strong; font.family: "Inter"; font.weight: Font.Bold; font.pixelSize: card.unit * 0.075
            Layout.leftMargin: card.unit * 0.02
        }
        GridLayout {
            id: grid
            columns: 7; rowSpacing: 0; columnSpacing: 0
            Layout.fillWidth: true; Layout.fillHeight: true
            readonly property int firstDow: Qt.locale().firstDayOfWeek % 7
            readonly property date first: new Date(card.now.getFullYear(), card.now.getMonth(), 1)
            readonly property int lead: (first.getDay() - firstDow + 7) % 7
            readonly property int days: new Date(card.now.getFullYear(), card.now.getMonth() + 1, 0).getDate()
            Repeater {
                model: 7
                Text {
                    Layout.fillWidth: true; Layout.preferredWidth: 1; horizontalAlignment: Text.AlignHCenter
                    text: Qt.locale().dayName((grid.firstDow + index) % 7, Locale.ShortFormat).charAt(0).toUpperCase()
                    color: card.soft; font.family: "Inter"; font.weight: Font.DemiBold; font.pixelSize: card.unit * 0.055
                }
            }
            Repeater {
                model: 42
                Item {
                    readonly property int day: index - grid.lead + 1
                    readonly property bool today: day === card.now.getDate()
                    Layout.fillWidth: true; Layout.fillHeight: true; Layout.preferredWidth: 1
                    visible: index < Math.ceil((grid.lead + grid.days) / 7) * 7
                    Rectangle {
                        anchors.centerIn: parent
                        width: Math.min(parent.width, parent.height) * 0.86; height: width; radius: width / 2
                        color: card.strong; visible: parent.today
                    }
                    Text {
                        anchors.centerIn: parent
                        text: parent.day >= 1 && parent.day <= grid.days ? parent.day : ""
                        color: parent.today ? card.color : card.ink
                        font.family: "Inter"; font.weight: parent.today ? Font.Bold : Font.Normal
                        font.pixelSize: card.unit * 0.06
                    }
                }
            }
        }
    }
}

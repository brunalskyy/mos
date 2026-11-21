import QtQuick
import QtQuick.Layouts
import org.kde.kirigami as Kirigami

// A Material 3 month calendar
Rectangle {
    id: cal
    property date today: new Date()
    property color card
    property color textColour
    property color accent
    property color onAccent
    property int offset: 0   // months from this one
    readonly property date shown: new Date(today.getFullYear(), today.getMonth() + offset, 1)

    implicitHeight: lay.implicitHeight + Kirigami.Units.largeSpacing * 2
    radius: Kirigami.Units.gridUnit * 1.2
    color: card

    ColumnLayout {
        id: lay
        anchors.fill: parent
        anchors.margins: Kirigami.Units.largeSpacing
        spacing: Kirigami.Units.smallSpacing
        RowLayout {
            Layout.fillWidth: true
            Text {
                Layout.fillWidth: true
                text: Qt.formatDate(cal.shown, "MMMM yyyy")
                color: cal.textColour
                font.pixelSize: Kirigami.Units.gridUnit * 0.9; font.weight: Font.Bold
                MouseArea { anchors.fill: parent; onClicked: cal.offset = 0 }
            }
            Repeater {
                model: [{ i: "go-previous", d: -1 }, { i: "go-next", d: 1 }]
                Rectangle {
                    required property var modelData
                    width: Kirigami.Units.gridUnit * 1.7; height: width; radius: width / 2
                    color: nav.containsMouse ? Qt.rgba(cal.textColour.r, cal.textColour.g, cal.textColour.b, 0.1) : "transparent"
                    Kirigami.Icon { anchors.centerIn: parent; width: Kirigami.Units.iconSizes.small; height: width
                                    source: modelData.i; color: cal.textColour; isMask: true }
                    MouseArea { id: nav; anchors.fill: parent; hoverEnabled: true; cursorShape: Qt.PointingHandCursor
                                onClicked: cal.offset += modelData.d }
                }
            }
        }
        GridLayout {
            Layout.fillWidth: true
            columns: 7
            rowSpacing: 2; columnSpacing: 2
            Repeater {
                model: 7
                Text {
                    required property int index
                    Layout.fillWidth: true
                    horizontalAlignment: Text.AlignHCenter
                    // weeks start on the locale's first day (Monday in the UK)
                    text: Qt.locale().dayName((Qt.locale().firstDayOfWeek + index) % 7, Locale.ShortFormat).slice(0, 2)
                    color: cal.textColour; opacity: 0.6
                    font.pixelSize: Kirigami.Units.gridUnit * 0.62; font.weight: Font.DemiBold
                }
            }
            Repeater {
                model: 42
                Item {
                    required property int index
                    readonly property int lead: (cal.shown.getDay() - Qt.locale().firstDayOfWeek + 7) % 7
                    readonly property date day: new Date(cal.shown.getFullYear(), cal.shown.getMonth(), index - lead + 1)
                    readonly property bool inMonth: day.getMonth() === cal.shown.getMonth()
                    readonly property bool isToday: day.toDateString() === cal.today.toDateString()
                    Layout.fillWidth: true
                    implicitHeight: Kirigami.Units.gridUnit * 1.6
                    Rectangle {
                        anchors.centerIn: parent
                        width: Math.min(parent.width, parent.height); height: width; radius: width / 2
                        color: cal.accent
                        visible: parent.isToday
                    }
                    Text {
                        anchors.centerIn: parent
                        text: parent.day.getDate()
                        color: parent.isToday ? cal.onAccent : cal.textColour
                        opacity: parent.inMonth ? 1 : 0.35
                        font.pixelSize: Kirigami.Units.gridUnit * 0.7
                        font.weight: parent.isToday ? Font.Bold : Font.Normal
                    }
                }
            }
        }
    }
}

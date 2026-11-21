import QtQuick
import QtQuick.Layouts
import org.kde.plasma.plasmoid
import org.kde.plasma.core as PlasmaCore
import org.kde.kirigami as Kirigami

// mOS taskbar clock. Small time with the date underneath; click it for the
// notification centre with the calendar under it (like Windows 10/11).
PlasmoidItem {
    id: root
    property date now: new Date()
    property int notificationCount: 0
    property var notifs: null

    Plasmoid.backgroundHints: PlasmaCore.Types.NoBackground
    toolTipMainText: Qt.formatDate(now, "dddd d MMMM yyyy")
    toolTipSubText: notificationCount > 0 ? notificationCount + (notificationCount === 1 ? " notification" : " notifications") : "No notifications"

    Timer {
        interval: 1000; running: true; repeat: true; triggeredOnStart: true
        onTriggered: root.now = new Date()
    }

    function mix(a, b, t) { return Qt.rgba(a.r + (b.r - a.r) * t, a.g + (b.g - a.g) * t, a.b + (b.b - a.b) * t, 1) }
    readonly property bool dark: Kirigami.ColorUtils.brightnessForColor(Kirigami.Theme.backgroundColor) === Kirigami.ColorUtils.Dark
    readonly property color accent: dark ? mix(Kirigami.Theme.highlightColor, "white", 0.3) : Kirigami.Theme.highlightColor
    readonly property color onAccent: dark ? mix(Kirigami.Theme.highlightColor, "black", 0.78) : "white"
    readonly property color card: mix(Kirigami.Theme.backgroundColor, Kirigami.Theme.highlightColor, dark ? 0.12 : 0.08)
    readonly property color textColour: Kirigami.Theme.textColor

    // The notification list lives in its own file, so the clock still works if it can't load
    Loader {
        id: notifModelLoader
        source: "NotificationModel.qml"
        onLoaded: root.notifs = item
    }
    Binding { target: root; property: "notificationCount"; value: root.notifs ? root.notifs.count : 0 }

    compactRepresentation: MouseArea {
        id: compact
        Layout.minimumWidth: col.implicitWidth + Kirigami.Units.smallSpacing * 4
        Layout.preferredWidth: Layout.minimumWidth
        hoverEnabled: true
        cursorShape: Qt.PointingHandCursor
        onClicked: root.expanded = !root.expanded
        Rectangle {
            anchors.fill: parent
            anchors.topMargin: Kirigami.Units.smallSpacing
            anchors.bottomMargin: Kirigami.Units.smallSpacing
            radius: height / 2
            color: Kirigami.Theme.textColor
            opacity: root.expanded ? 0.16 : compact.containsMouse ? 0.09 : 0
            Behavior on opacity { NumberAnimation { duration: 120 } }
        }
        ColumnLayout {
            id: col
            anchors.centerIn: parent
            spacing: 0
            Text {
                Layout.alignment: Qt.AlignHCenter
                text: Qt.formatTime(root.now, Qt.locale().timeFormat(Locale.ShortFormat))
                color: root.textColour
                font.pixelSize: Math.round(Math.min(compact.height * 0.3, Kirigami.Units.gridUnit * 0.8))
                font.weight: Font.DemiBold
            }
            Text {
                Layout.alignment: Qt.AlignHCenter
                visible: compact.height > Kirigami.Units.gridUnit * 2
                text: Qt.formatDate(root.now, Qt.locale().dateFormat(Locale.ShortFormat))
                color: root.textColour
                opacity: 0.75
                font.pixelSize: Math.round(Math.min(compact.height * 0.24, Kirigami.Units.gridUnit * 0.66))
            }
        }
        // a dot when there are notifications
        Rectangle {
            visible: root.notificationCount > 0
            width: Kirigami.Units.smallSpacing * 1.6; height: width; radius: width / 2
            color: root.accent
            anchors.right: parent.right
            anchors.top: parent.top
            anchors.rightMargin: Kirigami.Units.smallSpacing
            anchors.topMargin: Kirigami.Units.smallSpacing * 2
        }
    }

    fullRepresentation: ColumnLayout {
        Layout.preferredWidth: Kirigami.Units.gridUnit * 23
        Layout.preferredHeight: Kirigami.Units.gridUnit * 34
        Layout.minimumWidth: Layout.preferredWidth
        Layout.minimumHeight: Kirigami.Units.gridUnit * 24
        spacing: Kirigami.Units.largeSpacing

        // ---- Notifications
        RowLayout {
            Layout.fillWidth: true
            Layout.margins: Kirigami.Units.largeSpacing
            Layout.bottomMargin: 0
            Text {
                Layout.fillWidth: true
                text: "Notifications"
                color: root.textColour
                font.pixelSize: Kirigami.Units.gridUnit * 1.1; font.weight: Font.Bold
            }
            Rectangle {
                visible: root.notificationCount > 0
                implicitWidth: clearText.implicitWidth + Kirigami.Units.gridUnit * 1.4
                implicitHeight: Kirigami.Units.gridUnit * 1.8
                radius: height / 2
                color: root.card
                Text { id: clearText; anchors.centerIn: parent; text: "Clear all"; color: root.textColour
                       font.pixelSize: Kirigami.Units.gridUnit * 0.72; font.weight: Font.DemiBold }
                MouseArea { anchors.fill: parent; cursorShape: Qt.PointingHandCursor
                            onClicked: if (root.notifs) root.notifs.clearAll() }
            }
        }
        Loader {
            Layout.fillWidth: true
            Layout.fillHeight: true
            Layout.leftMargin: Kirigami.Units.largeSpacing
            Layout.rightMargin: Kirigami.Units.largeSpacing
            active: root.notifs !== null
            sourceComponent: NotificationList {
                model: root.notifs
                card: root.card; textColour: root.textColour; accent: root.accent
            }
            Text {
                anchors.centerIn: parent
                visible: root.notificationCount === 0
                text: "No notifications"
                color: root.textColour; opacity: 0.6
                font.pixelSize: Kirigami.Units.gridUnit * 0.8
            }
        }

        // ---- Calendar
        MonthCalendar {
            Layout.fillWidth: true
            Layout.margins: Kirigami.Units.largeSpacing
            Layout.topMargin: 0
            today: root.now
            card: root.card; textColour: root.textColour; accent: root.accent; onAccent: root.onAccent
        }
    }
}

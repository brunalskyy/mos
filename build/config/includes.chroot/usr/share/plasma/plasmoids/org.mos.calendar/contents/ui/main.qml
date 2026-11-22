import QtQuick
import QtQuick.Layouts
import org.kde.plasma.plasmoid
import org.kde.plasma.core as PlasmaCore
import org.kde.kirigami as Kirigami

// mOS Calendar: small = today's date like iOS, big = the whole month
PlasmoidItem {
    id: root
    Plasmoid.backgroundHints: PlasmaCore.Types.NoBackground
    preferredRepresentation: fullRepresentation
    property date now: new Date()
    Timer { interval: 60000; running: true; repeat: true; onTriggered: root.now = new Date() }
    toolTipMainText: Qt.formatDate(now, "dddd d MMMM yyyy")

    fullRepresentation: CalendarFace {
        Layout.minimumWidth: Kirigami.Units.gridUnit * 7
        Layout.minimumHeight: Kirigami.Units.gridUnit * 7
        Layout.preferredWidth: Kirigami.Units.gridUnit * 8
        Layout.preferredHeight: Kirigami.Units.gridUnit * 8
        accent: Kirigami.Theme.highlightColor
        dark: Kirigami.ColorUtils.brightnessForColor(Kirigami.Theme.backgroundColor) === Kirigami.ColorUtils.Dark
        now: root.now
    }
}

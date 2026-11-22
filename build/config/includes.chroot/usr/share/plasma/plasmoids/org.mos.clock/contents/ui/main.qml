import QtQuick
import QtQuick.Layouts
import org.kde.plasma.plasmoid
import org.kde.plasma.core as PlasmaCore
import org.kde.kirigami as Kirigami

PlasmoidItem {
    id: root
    Plasmoid.backgroundHints: PlasmaCore.Types.NoBackground
    preferredRepresentation: fullRepresentation
    toolTipMainText: Qt.formatTime(new Date(), Qt.locale().timeFormat(Locale.ShortFormat))
    toolTipSubText: Qt.formatDate(new Date(), "dddd d MMMM yyyy")
    fullRepresentation: ClockFace {
        // Big enough that Plasma can't squash it into a tiny icon
        Layout.minimumWidth: Kirigami.Units.gridUnit * 10
        Layout.minimumHeight: Kirigami.Units.gridUnit * 10
        Layout.preferredWidth: Kirigami.Units.gridUnit * 12
        Layout.preferredHeight: Kirigami.Units.gridUnit * 12
        accent: Kirigami.Theme.highlightColor
        dark: Kirigami.ColorUtils.brightnessForColor(Kirigami.Theme.backgroundColor) === Kirigami.ColorUtils.Dark
    }
}

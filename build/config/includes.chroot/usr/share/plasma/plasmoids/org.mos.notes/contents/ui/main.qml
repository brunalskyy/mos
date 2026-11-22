import QtQuick
import QtQuick.Controls as QQC2
import QtQuick.Layouts
import org.kde.plasma.plasmoid
import org.kde.plasma.core as PlasmaCore
import org.kde.kirigami as Kirigami

// mOS Notes: a sticky note on your desktop. It saves as you type.
PlasmoidItem {
    id: root
    Plasmoid.backgroundHints: PlasmaCore.Types.NoBackground
    preferredRepresentation: fullRepresentation

    fullRepresentation: NotesFace {
        Layout.minimumWidth: Kirigami.Units.gridUnit * 7
        Layout.minimumHeight: Kirigami.Units.gridUnit * 7
        Layout.preferredWidth: Kirigami.Units.gridUnit * 8
        Layout.preferredHeight: Kirigami.Units.gridUnit * 8
        accent: Kirigami.Theme.highlightColor
        dark: Kirigami.ColorUtils.brightnessForColor(Kirigami.Theme.backgroundColor) === Kirigami.ColorUtils.Dark
        text: Plasmoid.configuration.text
        onEdited: function (t) { Plasmoid.configuration.text = t }
    }
}

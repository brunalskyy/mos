import QtQuick
import QtQuick.Layouts
import org.kde.plasma.plasmoid
import org.kde.plasma.core as PlasmaCore
import org.kde.plasma.plasma5support as P5Support
import org.kde.kirigami as Kirigami

PlasmoidItem {
    id: root
    Plasmoid.backgroundHints: PlasmaCore.Types.NoBackground
    preferredRepresentation: fullRepresentation
    property int percent: 0
    property bool charging: false
    property bool present: false
    toolTipMainText: present ? percent + "%" : "No battery"
    toolTipSubText: charging ? "Charging" : ""

    // Read the battery straight from the system every 30 seconds
    P5Support.DataSource {
        id: src
        engine: "executable"
        readonly property string cmd: "sh -c 'for b in /sys/class/power_supply/BAT*; do cat \"$b/capacity\" \"$b/status\"; break; done'"
        connectedSources: [cmd]
        interval: 30000
        onNewData: function (source, data) {
            var lines = (data.stdout || "").trim().split("\n")
            root.present = lines.length >= 2 && lines[0] !== ""
            root.percent = Math.max(0, Math.min(100, parseInt(lines[0]) || 0))   // some MacBooks report 101-102%
            root.charging = (lines[1] || "") === "Charging" || (lines[1] || "") === "Full"
        }
    }

    fullRepresentation: BatteryFace {
        Layout.minimumWidth: Kirigami.Units.gridUnit * 5
        Layout.minimumHeight: Kirigami.Units.gridUnit * 5
        Layout.preferredWidth: Kirigami.Units.gridUnit * 8
        Layout.preferredHeight: Kirigami.Units.gridUnit * 8
        accent: Kirigami.Theme.highlightColor
        dark: Kirigami.ColorUtils.brightnessForColor(Kirigami.Theme.backgroundColor) === Kirigami.ColorUtils.Dark
        percent: root.percent
        charging: root.charging
        present: root.present
    }
}

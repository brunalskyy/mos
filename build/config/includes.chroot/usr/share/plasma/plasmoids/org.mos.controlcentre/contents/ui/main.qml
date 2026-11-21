import QtQuick
import QtQuick.Layouts
import org.kde.plasma.plasmoid
import org.kde.plasma.core as PlasmaCore
import org.kde.plasma.plasma5support as P5Support
import org.kde.kirigami as Kirigami

// mOS Control Centre: one button in the taskbar showing Wi-Fi, sound and battery
// (like Windows 11); click it for Material 3 tiles and sliders (like Pixel / iOS).
PlasmoidItem {
    id: root
    property var st: ({ wifi: { available: false, on: false, name: "" }, wired: "",
                        bt: { available: false, on: false, device: "" }, dark: false, night: false,
                        dnd: false, profile: "", profiles: [], brightness: -1, volume: 0, muted: false,
                        battery: -1, charging: false })
    property double holdUntil: 0   // don't let an old reading undo what you just pressed

    Plasmoid.backgroundHints: PlasmaCore.Types.NoBackground
    toolTipMainText: "Control Centre"
    toolTipSubText: (st.wired ? "Ethernet" : st.wifi.name ? st.wifi.name : "Not connected")
                    + " · " + (st.muted ? "Muted" : "Volume " + st.volume + "%")
                    + (st.battery >= 0 ? " · " + st.battery + "%" : "")

    // ---------- talking to the system (through mos-cc)
    P5Support.DataSource {
        id: poll
        engine: "executable"
        connectedSources: ["mos-cc state"]
        interval: root.expanded ? 1500 : 8000
        onNewData: function (source, data) {
            if (Date.now() < root.holdUntil) return
            try { root.st = JSON.parse(data.stdout) } catch (e) {}
        }
    }
    P5Support.DataSource {
        id: runner
        engine: "executable"
        onNewData: function (source, data) { disconnectSource(source) }
    }
    function run(args) {
        root.holdUntil = Date.now() + 2500
        runner.connectSource("mos-cc " + args + " #" + Date.now())
    }
    function launch(cmd) {
        runner.connectSource(cmd + " #" + Date.now())
        root.expanded = false
    }
    function patch(path, value) {
        var s = JSON.parse(JSON.stringify(st))
        var o = s, parts = path.split(".")
        for (var i = 0; i < parts.length - 1; i++) o = o[parts[i]]
        o[parts[parts.length - 1]] = value
        st = s
    }
    Timer { id: volTimer; interval: 90; property int v; onTriggered: root.run("volume " + v) }
    Timer { id: brightTimer; interval: 90; property int v; onTriggered: root.run("brightness " + v) }

    // ---------- icons
    readonly property string netIcon: st.wired ? "network-wired-activated"
        : !st.wifi.on ? "network-wireless-disconnected"
        : st.wifi.name ? "network-wireless-signal-excellent" : "network-wireless-signal-none"
    readonly property string volIcon: st.muted || st.volume === 0 ? "audio-volume-muted"
        : st.volume < 34 ? "audio-volume-low" : st.volume < 67 ? "audio-volume-medium" : "audio-volume-high"
    readonly property string batIcon: {
        if (st.battery < 0) return ""
        var lvl = Math.min(100, Math.round(st.battery / 10) * 10)
        return "battery-" + ("00" + lvl).slice(-3) + (st.charging ? "-charging" : "")
    }

    // ---------- Material colours from the Plasma theme
    function mix(a, b, t) { a = Qt.lighter(a, 1.0); b = Qt.lighter(b, 1.0); return Qt.rgba(a.r + (b.r - a.r) * t, a.g + (b.g - a.g) * t, a.b + (b.b - a.b) * t, 1) }
    readonly property bool dark: Kirigami.ColorUtils.brightnessForColor(Kirigami.Theme.backgroundColor) === Kirigami.ColorUtils.Dark
    readonly property color accent: dark ? mix(Kirigami.Theme.highlightColor, "white", 0.3) : Kirigami.Theme.highlightColor
    readonly property color onAccent: dark ? mix(Kirigami.Theme.highlightColor, "black", 0.78) : "white"
    readonly property color off: mix(Kirigami.Theme.backgroundColor, Kirigami.Theme.highlightColor, dark ? 0.16 : 0.12)
    readonly property color textColour: Kirigami.Theme.textColor

    // ---------- in the taskbar
    compactRepresentation: MouseArea {
        id: compact
        Layout.minimumWidth: row.implicitWidth + Kirigami.Units.smallSpacing * 4
        Layout.preferredWidth: Layout.minimumWidth
        hoverEnabled: true
        cursorShape: Qt.PointingHandCursor
        onClicked: root.expanded = !root.expanded
        onWheel: function (w) {
            var v = Math.max(0, Math.min(100, root.st.volume + (w.angleDelta.y > 0 ? 5 : -5)))
            root.patch("volume", v); root.patch("muted", false); root.run("volume " + v)
        }
        Rectangle {
            anchors.fill: parent
            anchors.topMargin: Kirigami.Units.smallSpacing
            anchors.bottomMargin: Kirigami.Units.smallSpacing
            radius: height / 2
            color: Kirigami.Theme.textColor
            opacity: root.expanded ? 0.16 : compact.containsMouse ? 0.09 : 0
            Behavior on opacity { NumberAnimation { duration: 120 } }
        }
        RowLayout {
            id: row
            anchors.centerIn: parent
            spacing: Kirigami.Units.smallSpacing * 1.5
            Kirigami.Icon { source: root.netIcon; implicitWidth: Kirigami.Units.iconSizes.small; implicitHeight: implicitWidth }
            Kirigami.Icon { source: root.volIcon; implicitWidth: Kirigami.Units.iconSizes.small; implicitHeight: implicitWidth }
            Kirigami.Icon { visible: root.batIcon !== ""; source: root.batIcon; implicitWidth: Kirigami.Units.iconSizes.small; implicitHeight: implicitWidth }
        }
    }

    // ---------- the panel
    fullRepresentation: Item {
        Layout.preferredWidth: Kirigami.Units.gridUnit * 22
        Layout.preferredHeight: col.implicitHeight + Kirigami.Units.largeSpacing * 2
        Layout.minimumWidth: Layout.preferredWidth
        Layout.minimumHeight: Layout.preferredHeight

        ColumnLayout {
            id: col
            anchors.fill: parent
            anchors.margins: Kirigami.Units.largeSpacing
            spacing: Kirigami.Units.smallSpacing * 2.5

            // Top: battery on the left, Settings and power on the right
            RowLayout {
                Layout.fillWidth: true
                Text {
                    Layout.fillWidth: true
                    text: root.st.battery >= 0 ? root.st.battery + "%" + (root.st.charging ? " · Charging" : "")
                                               : Qt.formatDate(new Date(), "dddd d MMMM")
                    color: root.textColour
                    font.pixelSize: Kirigami.Units.gridUnit * 0.85; font.weight: Font.DemiBold
                }
                Repeater {
                    model: [{ icon: "configure", cmd: "mos-settings" },
                            { icon: "system-shutdown", cmd: "busctl --user call org.kde.LogoutPrompt /LogoutPrompt org.kde.LogoutPrompt promptAll" }]
                    Rectangle {
                        required property var modelData
                        width: Kirigami.Units.gridUnit * 2.2; height: width; radius: width / 2
                        color: root.off
                        scale: bma.pressed ? 0.92 : 1
                        Behavior on scale { NumberAnimation { duration: 100 } }
                        Kirigami.Icon { anchors.centerIn: parent; width: Kirigami.Units.iconSizes.small; height: width
                                        source: modelData.icon; color: root.textColour; isMask: true }
                        MouseArea { id: bma; anchors.fill: parent; cursorShape: Qt.PointingHandCursor
                                    onClicked: root.launch(modelData.cmd) }
                    }
                }
            }

            // Sliders
            PillSlider {
                Layout.fillWidth: true
                visible: root.st.brightness >= 0
                value: root.st.brightness
                iconName: "brightness-high"; fallbackIcon: "video-display-brightness"
                accent: root.accent; onAccent: root.onAccent; off: root.off; textColour: root.textColour
                onMoved: function (v) { root.patch("brightness", v); brightTimer.v = Math.max(1, v); brightTimer.restart() }
            }
            PillSlider {
                Layout.fillWidth: true
                value: root.st.muted ? 0 : Math.min(100, root.st.volume)
                iconName: root.volIcon; fallbackIcon: "audio-volume-high"
                accent: root.accent; onAccent: root.onAccent; off: root.off; textColour: root.textColour
                onMoved: function (v) { root.patch("volume", v); root.patch("muted", false); volTimer.v = v; volTimer.restart() }
            }

            // Tiles
            GridLayout {
                Layout.fillWidth: true
                columns: 2
                columnSpacing: Kirigami.Units.smallSpacing * 2
                rowSpacing: Kirigami.Units.smallSpacing * 2

                Tile {
                    title: "Wi-Fi"
                    subtitle: root.st.wired ? "Ethernet" : !root.st.wifi.on ? "Off" : root.st.wifi.name || "Not connected"
                    iconName: root.st.wifi.on ? "network-wireless" : "network-wireless-disconnected"
                    on: root.st.wifi.on; more: true
                    accent: root.accent; onAccent: root.onAccent; off: root.off; textColour: root.textColour
                    onToggled: { root.patch("wifi.on", !on); root.run("wifi " + (on ? "on" : "off")) }
                    onOpened: root.launch("mos-settings wifi")
                }
                Tile {
                    title: "Bluetooth"
                    subtitle: !root.st.bt.available ? "Not available" : !root.st.bt.on ? "Off" : root.st.bt.device || "On"
                    iconName: root.st.bt.on ? "bluetooth-active" : "bluetooth-disabled"; fallbackIcon: "bluetooth"
                    on: root.st.bt.on; more: true
                    enabled: root.st.bt.available; opacity: enabled ? 1 : 0.5
                    accent: root.accent; onAccent: root.onAccent; off: root.off; textColour: root.textColour
                    onToggled: { root.patch("bt.on", !on); root.run("bt " + (on ? "on" : "off")) }
                    onOpened: root.launch("mos-settings bluetooth")
                }
                Tile {
                    title: "Dark mode"
                    subtitle: on ? "On" : "Off"
                    iconName: "weather-clear-night"
                    on: root.st.dark
                    accent: root.accent; onAccent: root.onAccent; off: root.off; textColour: root.textColour
                    onToggled: { root.patch("dark", !on); root.holdUntil = Date.now() + 6000; runner.connectSource("mos-cc dark " + (on ? "on" : "off") + " #" + Date.now()) }
                    onOpened: root.launch("mos-settings style")
                }
                Tile {
                    title: "Night Shift"
                    subtitle: on ? "On until sunrise" : "Off"
                    iconName: "redshift-status-on"; fallbackIcon: "weather-clear-night"
                    on: root.st.night
                    accent: root.accent; onAccent: root.onAccent; off: root.off; textColour: root.textColour
                    onToggled: { root.patch("night", !on); root.run("night " + (on ? "on" : "off")) }
                    onOpened: root.launch("mos-settings display")
                }
                Tile {
                    title: "Do not disturb"
                    subtitle: on ? "On" : "Off"
                    iconName: "notifications-disabled"; fallbackIcon: "notification-inactive"
                    on: root.st.dnd
                    accent: root.accent; onAccent: root.onAccent; off: root.off; textColour: root.textColour
                    onToggled: { root.patch("dnd", !on); root.run("dnd " + (on ? "on" : "off")) }
                    onOpened: root.launch("mos-settings notifications")
                }
                Tile {
                    readonly property var names: ({ "power-saver": "Battery saver", "balanced": "Balanced", "performance": "Performance" })
                    title: "Power mode"
                    subtitle: names[root.st.profile] || "Balanced"
                    iconName: root.st.profile === "power-saver" ? "battery-profile-powersave"
                            : root.st.profile === "performance" ? "battery-profile-performance" : "speedometer"
                    fallbackIcon: "speedometer"
                    on: root.st.profile !== "" && root.st.profile !== "balanced"
                    visible: root.st.profiles.length > 0
                    accent: root.accent; onAccent: root.onAccent; off: root.off; textColour: root.textColour
                    onToggled: {
                        var list = root.st.profiles, i = list.indexOf(root.st.profile)
                        var next = list[(i + 1) % list.length]
                        root.patch("profile", next); root.run("profile " + next)
                    }
                    onOpened: root.launch("mos-settings power")
                }
            }
        }
    }
}

// mOS default desktop layout (KDE Plasma 6)
// Floating pill taskbar along the bottom (Windows 10 layout, iOS 27 shape): mOS Start button, pinned and open apps,
// the Control Centre button (Wi-Fi, sound, battery) and a small clock (click it for notifications).
// Desktop: the Amber wallpaper (mOS logo top left), icons on the right, widgets on the left.

var wallpaper = "file:///usr/share/wallpapers/mOS/contents/images/2880x1800.png";

// Desktop: wallpaper and widgets
var desktopsArray = desktopsForActivity(currentActivity());
for (var j = 0; j < desktopsArray.length; j++) {
    var desktop = desktopsArray[j];
    desktop.wallpaperPlugin = "org.kde.image";
    desktop.currentConfigGroup = ["Wallpaper", "org.kde.image", "General"];
    desktop.writeConfig("Image", wallpaper);

    // Desktop icons line up on the right, so the mOS logo on the wallpaper (top left) stays clear.
    desktop.currentConfigGroup = ["General"];
    desktop.writeConfig("alignment", 1);
    desktop.writeConfig("arrangement", 1);

    // Pixel-style widgets down the left side, under the logo: At a glance, the flower clock and the battery ring
    // (the battery one stays hidden on computers without a battery)
    var unit = gridUnit;
    var left = unit * 2;
    desktop.addWidget("org.mos.glance", left, unit * 7, unit * 20, unit * 5);
    desktop.addWidget("org.mos.clock", left, unit * 13, unit * 12, unit * 12);
    desktop.addWidget("org.mos.battery", left + unit * 2, unit * 26, unit * 8, unit * 8);
}


// Tidy system tray: Wi-Fi, sound and battery live in the Control Centre and notifications
// in the clock, so the tray only shows apps that put an icon there (the rest go in the ^ menu)
function mosTidyTray(tray) {
    var id = tray.readConfig("SystrayContainmentId");
    var inner = id ? desktopById(id) : null;
    if (!inner) {
        return;
    }
    inner.currentConfigGroup = ["General"];
    inner.writeConfig("shownItems", []);
    inner.writeConfig("hiddenItems", ["org.kde.plasma.clipboard", "org.kde.kscreen", "org.kde.plasma.keyboardindicator",
                                      "org.kde.plasma.keyboardlayout", "org.kde.plasma.manage-inputmethod",
                                      "org.kde.plasma.printmanager", "org.kde.plasma.vault", "org.kde.kdeconnect",
                                      "org.kde.plasma.cameraindicator", "org.kde.plasma.brightness",
                                      "org.kde.plasma.mediacontroller", "org.kde.plasma.bluetooth",
                                      "org.kde.plasma.notifications", "org.kde.plasma.networkmanagement",
                                      "org.kde.plasma.volume", "org.kde.plasma.battery"]);
}


// Taskbar
var taskbar = new Panel;
taskbar.location = "bottom";
taskbar.height = Math.round(gridUnit * 2.75);
// Floating pill, like the iOS 27 tab bar (the mOS Plasma style gives it round ends)
taskbar.floating = true;
taskbar.alignment = "left";
taskbar.lengthMode = "fill";
taskbar.hiding = "none";

var start = taskbar.addWidget("org.kde.plasma.kickoff");
start.currentConfigGroup = ["General"];
start.writeConfig("icon", "mos-logo");
// Start menu favourites: mOS apps (not the KDE ones mOS replaces)
start.writeConfig("favorites", ["preferred://browser", "applications:mos-settings.desktop", "applications:mos-store.desktop",
                                "applications:org.kde.dolphin.desktop", "applications:org.kde.konsole.desktop",
                                "applications:org.kde.kwrite.desktop", "applications:org.kde.spectacle.desktop"]);
start.writeConfig("favoritesPortedToKAstats", "false");

// Open apps show their name next to the icon, like Windows 10 (Settings > Taskbar to turn off)
var tasks = taskbar.addWidget("org.kde.plasma.taskmanager");
tasks.currentConfigGroup = ["General"];
tasks.writeConfig("launchers", [
    "applications:chromium.desktop",
    "applications:org.kde.dolphin.desktop",
    "applications:mos-store.desktop",
    "applications:mos-settings.desktop",
    "applications:org.kde.konsole.desktop"
]);
tasks.writeConfig("maxStripes", "1");
tasks.writeConfig("groupingStrategy", "0");
tasks.writeConfig("showOnlyCurrentDesktop", "false");
tasks.writeConfig("indicateAudioStreams", "true");
tasks.writeConfig("fill", "false");
// Spread the apps out a bit
tasks.writeConfig("iconSpacing", "2");

taskbar.addWidget("org.kde.plasma.panelspacer");
var tray = taskbar.addWidget("org.kde.plasma.systemtray");
mosTidyTray(tray);

// Control Centre (Wi-Fi, sound, battery) and the clock (click it for notifications)
taskbar.addWidget("org.mos.controlcentre");
taskbar.addWidget("org.mos.taskclock");

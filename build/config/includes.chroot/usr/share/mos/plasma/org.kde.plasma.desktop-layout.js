// mOS default desktop layout (KDE Plasma 6)
// Floating pill taskbar along the bottom (Windows 10 layout, iOS 27 shape): mOS Start button, pinned and open apps,
// tidy system tray (with the notification bell) and a small clock with the date.
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

    // Pixel-style widgets down the left side, under the logo: the flower clock and the battery ring
    // (the battery one stays hidden on computers without a battery)
    var unit = gridUnit;
    var left = unit * 2;
    desktop.addWidget("org.mos.clock", left, unit * 8, unit * 12, unit * 12);
    desktop.addWidget("org.mos.battery", left + unit * 2, unit * 21, unit * 8, unit * 8);
}


// Tidy system tray: Wi-Fi, sound, battery and the notification centre (bell) always show;
// the rest go in the ^ menu
function mosTidyTray(tray) {
    var id = tray.readConfig("SystrayContainmentId");
    var inner = id ? desktopById(id) : null;
    if (!inner) {
        return;
    }
    inner.currentConfigGroup = ["General"];
    inner.writeConfig("shownItems", ["org.kde.plasma.notifications", "org.kde.plasma.networkmanagement",
                                     "org.kde.plasma.volume", "org.kde.plasma.battery"]);
    inner.writeConfig("hiddenItems", ["org.kde.plasma.clipboard", "org.kde.kscreen", "org.kde.plasma.keyboardindicator",
                                      "org.kde.plasma.keyboardlayout", "org.kde.plasma.manage-inputmethod",
                                      "org.kde.plasma.printmanager", "org.kde.plasma.vault", "org.kde.kdeconnect",
                                      "org.kde.plasma.cameraindicator", "org.kde.plasma.brightness",
                                      "org.kde.plasma.mediacontroller", "org.kde.plasma.bluetooth"]);
}

// Smaller clock: time with the date in small text underneath
function mosClock(clock, small) {
    clock.currentConfigGroup = ["Appearance"];
    clock.writeConfig("showDate", "true");
    clock.writeConfig("dateDisplayFormat", small ? "BesideTime" : "BelowTime");
    clock.writeConfig("dateFormat", "shortDate");
    clock.writeConfig("autoFontAndSize", "false");
    clock.writeConfig("fontSize", "9");
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

var tasks = taskbar.addWidget("org.kde.plasma.icontasks");
tasks.currentConfigGroup = ["General"];
tasks.writeConfig("launchers", [
    "applications:chromium.desktop",
    "applications:org.kde.dolphin.desktop",
    "applications:org.kde.discover.desktop",
    "applications:mos-settings.desktop",
    "applications:org.kde.konsole.desktop"
]);
tasks.writeConfig("showOnlyCurrentDesktop", "false");
tasks.writeConfig("indicateAudioStreams", "true");
tasks.writeConfig("fill", "false");
// Spread the apps out a bit
tasks.writeConfig("iconSpacing", "2");

taskbar.addWidget("org.kde.plasma.panelspacer");
var tray = taskbar.addWidget("org.kde.plasma.systemtray");
mosTidyTray(tray);

var time = taskbar.addWidget("org.kde.plasma.digitalclock");
mosClock(time, false);

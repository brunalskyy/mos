// mOS default desktop layout (KDE Plasma 6)
// Windows 10-style taskbar along the bottom: mOS Start button, pinned and open apps,
// system tray, time with the date underneath, and a show-desktop corner.
// Desktop: icons on the desktop, the mOS wallpaper, and widgets (clock, calendar, notes).

var wallpaper = "file:///usr/share/wallpapers/mOS/contents/images/2880x1800.png";

// Desktop: wallpaper and widgets
var desktopsArray = desktopsForActivity(currentActivity());
for (var j = 0; j < desktopsArray.length; j++) {
    var desktop = desktopsArray[j];
    desktop.wallpaperPlugin = "org.kde.image";
    desktop.currentConfigGroup = ["Wallpaper", "org.kde.image", "General"];
    desktop.writeConfig("Image", wallpaper);

    var width = 1280;
    try {
        width = screenGeometry(desktop.screen).width;
    } catch (e) {
        // keep the default width
    }
    var unit = gridUnit;
    var column = width - unit * 20;

    var clock = desktop.addWidget("org.kde.plasma.analogclock", column, unit * 2, unit * 10, unit * 10);
    var calendar = desktop.addWidget("org.kde.plasma.calendar", column - unit * 2, unit * 13, unit * 18, unit * 16);
    var notes = desktop.addWidget("org.kde.plasma.notes", column - unit * 2, unit * 30, unit * 18, unit * 12);
}

// Taskbar
var taskbar = new Panel;
taskbar.location = "bottom";
taskbar.height = Math.round(gridUnit * 2.6);
taskbar.floating = false;
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
    "applications:systemsettings.desktop",
    "applications:org.kde.konsole.desktop",
    "applications:calamares-install-debian.desktop"
]);
tasks.writeConfig("showOnlyCurrentDesktop", "false");
tasks.writeConfig("indicateAudioStreams", "true");
tasks.writeConfig("fill", "false");

taskbar.addWidget("org.kde.plasma.marginsseparator");
taskbar.addWidget("org.kde.plasma.systemtray");

var time = taskbar.addWidget("org.kde.plasma.digitalclock");
time.currentConfigGroup = ["Appearance"];
time.writeConfig("showDate", "true");
time.writeConfig("dateDisplayFormat", "BelowTime");
time.writeConfig("dateFormat", "shortDate");

taskbar.addWidget("org.kde.plasma.showdesktop");

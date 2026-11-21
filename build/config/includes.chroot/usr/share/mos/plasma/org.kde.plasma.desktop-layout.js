// mOS default desktop layout (KDE Plasma 6)
// Floating pill taskbar along the bottom (Windows 10 layout, iOS 27 shape): mOS Start button, pinned and open apps,
// system tray, time with the date underneath, and a show-desktop corner.
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

    // Widgets down the left side, under the logo.
    var unit = gridUnit;
    var left = unit * 2;
    desktop.addWidget("org.kde.plasma.analogclock", left, unit * 9, unit * 10, unit * 10);
    desktop.addWidget("org.kde.plasma.calendar", left, unit * 20, unit * 18, unit * 16);
    desktop.addWidget("org.kde.plasma.notes", left, unit * 37, unit * 18, unit * 12);
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

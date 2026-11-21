// mOS default desktop layout (KDE Plasma 6)
// Top bar: mOS menu, clock in the middle, system tray.
// Dock: floating, always visible, at the bottom.
// Desktop: icons on the desktop and the mOS wallpaper.

var wallpaper = "file:///usr/share/wallpapers/mOS/contents/images/2880x1800.png";

// Desktop
var desktopsArray = desktopsForActivity(currentActivity());
for (var j = 0; j < desktopsArray.length; j++) {
    var desktop = desktopsArray[j];
    desktop.wallpaperPlugin = "org.kde.image";
    desktop.currentConfigGroup = ["Wallpaper", "org.kde.image", "General"];
    desktop.writeConfig("Image", wallpaper);
}

// Top bar
var topBar = new Panel;
topBar.location = "top";
topBar.height = Math.round(gridUnit * 1.6);
topBar.floating = false;

var menu = topBar.addWidget("org.kde.plasma.kickoff");
menu.currentConfigGroup = ["General"];
menu.writeConfig("icon", "mos-logo");

topBar.addWidget("org.kde.plasma.panelspacer");

var clock = topBar.addWidget("org.kde.plasma.digitalclock");
clock.currentConfigGroup = ["Appearance"];
clock.writeConfig("showDate", "true");
clock.writeConfig("dateDisplayFormat", "BesideTime");

topBar.addWidget("org.kde.plasma.panelspacer");
topBar.addWidget("org.kde.plasma.systemtray");

// Dock
var dock = new Panel;
dock.location = "bottom";
dock.height = Math.round(gridUnit * 3.4);
dock.floating = true;
dock.alignment = "center";
dock.lengthMode = "fit";
dock.hiding = "none";

var tasks = dock.addWidget("org.kde.plasma.icontasks");
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

dock.addWidget("org.kde.plasma.marginsseparator");

var allApps = dock.addWidget("org.kde.plasma.kickerdash");
allApps.currentConfigGroup = ["General"];
allApps.writeConfig("icon", "view-app-grid-symbolic");

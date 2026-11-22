// mOS Settings: rebuild the taskbar with the chosen options.
// Runs inside Plasma (org.kde.PlasmaShell.evaluateScript).
var opts = __OPTIONS__;

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


// Keep the apps that are pinned now
var pinned = ["applications:chromium.desktop", "applications:org.kde.dolphin.desktop",
              "applications:mos-store.desktop", "applications:mos-settings.desktop",
              "applications:org.kde.konsole.desktop"];
var old = panels();
for (var i = 0; i < old.length; i++) {
    var tw = old[i].widgets("org.kde.plasma.icontasks").concat(old[i].widgets("org.kde.plasma.taskmanager"));
    if (tw.length > 0) {
        tw[0].currentConfigGroup = ["General"];
        var l = tw[0].readConfig("launchers", "");
        if (l && l.length) {
            pinned = (typeof l === "string") ? l.split(",") : l;
            // the mOS Store replaced KDE Discover
            for (var k = 0; k < pinned.length; k++) {
                if (pinned[k].indexOf("org.kde.discover") >= 0) pinned[k] = "applications:mos-store.desktop";
            }
        }
    }
}
// Keep your Start menu favourites too, unless they're still KDE's (Settings, Discover, Kate...)
var mosFavourites = ["preferred://browser", "applications:mos-settings.desktop", "applications:mos-store.desktop",
                     "applications:org.kde.dolphin.desktop", "applications:org.kde.konsole.desktop",
                     "applications:org.kde.kwrite.desktop", "applications:org.kde.spectacle.desktop"];
var favourites = mosFavourites;
for (var f = 0; f < old.length; f++) {
    var ko = old[f].widgets("org.kde.plasma.kickoff");
    if (ko.length === 0) continue;
    ko[0].currentConfigGroup = ["General"];
    var fav = ko[0].readConfig("favorites", "");
    var list = (typeof fav === "string") ? (fav ? fav.split(",") : []) : (fav || []);
    var kde = /systemsettings|org\.kde\.discover|org\.kde\.kate|kontact|kinfocenter|khelpcenter|konqueror/;
    var stillKde = list.length === 0;
    for (var g = 0; g < list.length; g++) {
        if (kde.test(list[g])) stillKde = true;
    }
    if (!stillKde) favourites = list;
}
for (var j = 0; j < old.length; j++) {
    old[j].remove();
}

var sizes = { small: 2.2, medium: 2.75, large: 3.4 };
var p = new Panel;
p.location = opts.position;
p.height = Math.round(gridUnit * (sizes[opts.size] || 2.75));
// "Windows go below": the taskbar always stays floating and rounded, and windows (even
// maximised ones) slide underneath it, so you see them through the Liquid Glass
p.hiding = opts.autohide ? "autohide" : "windowsgobelow";
// Always see-through, so the Liquid Glass shows even when a window is maximised
p.opacity = "translucent";

if (opts.style === "dock") {
    // macOS: only as wide as the apps, in the middle, always floating
    p.floating = true;
    p.lengthMode = "fit";
    p.alignment = "center";
} else {
    p.floating = !!opts.floating;
    p.lengthMode = "fill";
    p.alignment = "left";
}

var startButton = p.addWidget("org.kde.plasma.kickoff");
startButton.currentConfigGroup = ["General"];
startButton.writeConfig("icon", "mos-logo");
// Start menu favourites: mOS apps (not the KDE ones mOS replaces)
startButton.writeConfig("favorites", favourites);
startButton.writeConfig("favoritesPortedToKAstats", "false");

if (opts.style === "centred") {
    p.addWidget("org.kde.plasma.panelspacer");
}

// App names next to the icons of open apps (like Windows 10), or icons only
var labels = opts.labels !== false && opts.style !== "dock";
var tasks = p.addWidget(labels ? "org.kde.plasma.taskmanager" : "org.kde.plasma.icontasks");
tasks.currentConfigGroup = ["General"];
tasks.writeConfig("launchers", pinned);
tasks.writeConfig("showOnlyCurrentDesktop", "false");
tasks.writeConfig("indicateAudioStreams", "true");
tasks.writeConfig("iconSpacing", String(opts.spacing));
tasks.writeConfig("fill", "false");
if (labels) {
    tasks.writeConfig("maxStripes", "1");
    tasks.writeConfig("groupingStrategy", "0");   // one button per window, each with its name
}

if (opts.style === "centred") {
    p.addWidget("org.kde.plasma.panelspacer");
} else if (opts.style === "windows") {
    var sp = p.addWidget("org.kde.plasma.panelspacer");
}

var tray = p.addWidget("org.kde.plasma.systemtray");
mosTidyTray(tray);

p.addWidget("org.mos.controlcentre");
p.addWidget("org.mos.taskclock");
print("ok");

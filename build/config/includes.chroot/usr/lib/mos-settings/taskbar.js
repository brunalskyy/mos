// mOS Settings: rebuild the taskbar with the chosen options.
// Runs inside Plasma (org.kde.PlasmaShell.evaluateScript).
var opts = __OPTIONS__;

// Keep the apps that are pinned now
var pinned = ["applications:chromium.desktop", "applications:org.kde.dolphin.desktop",
              "applications:org.kde.discover.desktop", "applications:mos-settings.desktop",
              "applications:org.kde.konsole.desktop"];
var old = panels();
for (var i = 0; i < old.length; i++) {
    var tw = old[i].widgets("org.kde.plasma.icontasks");
    if (tw.length > 0) {
        tw[0].currentConfigGroup = ["General"];
        var l = tw[0].readConfig("launchers", "");
        if (l && l.length) {
            pinned = (typeof l === "string") ? l.split(",") : l;
        }
    }
}
for (var j = 0; j < old.length; j++) {
    old[j].remove();
}

var sizes = { small: 2.2, medium: 2.75, large: 3.4 };
var p = new Panel;
p.location = opts.position;
p.height = Math.round(gridUnit * (sizes[opts.size] || 2.75));
p.hiding = opts.autohide ? "autohide" : "none";

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

if (opts.style === "centred") {
    p.addWidget("org.kde.plasma.panelspacer");
}

var tasks = p.addWidget("org.kde.plasma.icontasks");
tasks.currentConfigGroup = ["General"];
tasks.writeConfig("launchers", pinned);
tasks.writeConfig("showOnlyCurrentDesktop", "false");
tasks.writeConfig("indicateAudioStreams", "true");
tasks.writeConfig("iconSpacing", String(opts.spacing));
tasks.writeConfig("fill", "false");

if (opts.style === "centred") {
    p.addWidget("org.kde.plasma.panelspacer");
} else if (opts.style === "windows") {
    var sp = p.addWidget("org.kde.plasma.panelspacer");
}

p.addWidget("org.kde.plasma.marginsseparator");
p.addWidget("org.kde.plasma.systemtray");

var clock = p.addWidget("org.kde.plasma.digitalclock");
clock.currentConfigGroup = ["Appearance"];
clock.writeConfig("showDate", "true");
clock.writeConfig("dateDisplayFormat", opts.size === "small" ? "BesideTime" : "BelowTime");
clock.writeConfig("dateFormat", "shortDate");

if (opts.style !== "dock") {
    p.addWidget("org.kde.plasma.showdesktop");
}
print("ok");

// mOS desktop menu: what you get when you right-click an empty bit of the desktop.
// (Right-clicking a file or folder still gives the full file menu.)
// SPDX-FileCopyrightText: 2026 Bruno Woznicki
// SPDX-License-Identifier: GPL-3.0-or-later
import QtQuick
import org.kde.plasma.extras as PlasmaExtras
import org.kde.plasma.plasma5support as P5Support
import org.kde.plasma.plasmoid

Item {
    id: root
    property var folder   // the desktop's folder model

    P5Support.DataSource {
        id: runner
        engine: "executable"
        onNewData: function (source) { disconnectSource(source) }
    }
    function run(cmd) { runner.connectSource(cmd) }

    function popup(parentItem, x, y) {
        var paste = folder ? folder.action("paste") : null
        pasteItem.enabled = !!(paste && paste.enabled)
        menu.visualParent = parentItem
        menu.open(x, y)
    }

    PlasmaExtras.Menu {
        id: menu
        PlasmaExtras.MenuItem { text: "Add widgets…"; icon: "list-add"; onClicked: root.run("mos-widgets") }
        PlasmaExtras.MenuItem {
            text: "Edit widgets"; icon: "transform-move"
            onClicked: Plasmoid.containment.corona.editMode = true
        }
        PlasmaExtras.MenuItem { separator: true }
        PlasmaExtras.MenuItem { text: "New folder"; icon: "folder-new"; onClicked: if (root.folder) root.folder.createFolder() }
        PlasmaExtras.MenuItem { id: pasteItem; text: "Paste"; icon: "edit-paste"; onClicked: if (root.folder) root.folder.paste() }
        PlasmaExtras.MenuItem { text: "Refresh"; icon: "view-refresh"; onClicked: if (root.folder) root.folder.refresh() }
        PlasmaExtras.MenuItem {
            text: "Open in Terminal"; icon: "utilities-terminal"
            onClicked: root.run("sh -c 'cd \"$(xdg-user-dir DESKTOP 2>/dev/null || echo $HOME/Desktop)\" && exec konsole'")
        }
        PlasmaExtras.MenuItem { separator: true }
        PlasmaExtras.MenuItem { text: "Change wallpaper…"; icon: "preferences-desktop-wallpaper"; onClicked: root.run("mos-settings style") }
        PlasmaExtras.MenuItem { text: "Display settings"; icon: "preferences-desktop-display"; onClicked: root.run("mos-settings display") }
        PlasmaExtras.MenuItem { text: "Settings"; icon: "preferences-system"; onClicked: root.run("mos-settings") }
    }
}

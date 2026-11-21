import QtQuick
import QtQuick.Controls.Basic
import QtQuick.Layouts
import components
import "../parts"

StorePage {
    id: games
    title: "Games"
    property int shown: 60
    property var top: { store.appCount; return store.category("games", 8) }

    HeroCard {
        Layout.fillWidth: true
        visible: games.top.length > 0
        app: games.top[0] || ({})
        label: "TOP GAME"
        onOpen: function (id) { games.open(id) }
    }
    Shelf {
        title: "Popular games"; subtitle: "Launchers, classics and more"
        apps: games.top.slice(1)
        onOpen: function (id) { games.open(id) }
    }
    ColumnLayout {
        Layout.fillWidth: true
        spacing: 6
        Label { text: "All games"; color: Theme.textColour; font.pixelSize: 22; font.weight: Font.Bold }
        GridLayout {
            Layout.fillWidth: true
            columns: width > 900 ? 2 : 1
            columnSpacing: 16; rowSpacing: 4
            Repeater {
                model: { store.appCount; return store.category("games", games.shown) }
                AppRow { required property var modelData; required property int index
                         Layout.fillWidth: true; app: modelData; rank: index + 1
                         onOpen: function (id) { games.open(id) } }
            }
        }
        PillButton { Layout.alignment: Qt.AlignHCenter; tonal: true; text: "Show more"; onClicked: games.shown += 60 }
    }
}

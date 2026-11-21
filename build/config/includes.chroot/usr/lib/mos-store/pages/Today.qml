import QtQuick
import QtQuick.Controls.Basic
import QtQuick.Layouts
import components
import "../parts"

StorePage {
    id: today
    title: "Today"
    subtitle: Qt.formatDate(new Date(), "dddd d MMMM")
    property var data: { store.appCount; return store.today() }

    HeroCard {
        Layout.fillWidth: true
        visible: today.data.appOfTheDay && today.data.appOfTheDay.id !== undefined
        app: today.data.appOfTheDay || ({})
        label: "APP OF THE DAY"
        onOpen: function (id) { today.open(id) }
    }
    Shelf {
        title: "What's new"; subtitle: "Fresh updates to great apps"
        apps: today.data.whatsNew || []; notes: true
        onOpen: function (id) { today.open(id) }
    }
    HeroCard {
        Layout.fillWidth: true
        implicitHeight: 320
        visible: today.data.gameOfTheDay && today.data.gameOfTheDay.id !== undefined
        app: today.data.gameOfTheDay || ({})
        label: "GAME OF THE DAY"
        onOpen: function (id) { today.open(id) }
    }
    ColumnLayout {
        Layout.fillWidth: true
        spacing: 6
        Label { text: "mOS essentials"; color: Theme.textColour; font.pixelSize: 22; font.weight: Font.Bold }
        Label { text: "The apps everyone gets first"; color: Theme.textVariant; font.pixelSize: 13 }
        GridLayout {
            Layout.fillWidth: true
            Layout.topMargin: 8
            columns: width > 900 ? 3 : 2
            columnSpacing: 12; rowSpacing: 4
            Repeater {
                model: today.data.essentials || []
                AppRow { required property var modelData; Layout.fillWidth: true; app: modelData
                         onOpen: function (id) { today.open(id) } }
            }
        }
    }
    Shelf {
        title: "Worth a look"; subtitle: "Something different every day"
        apps: today.data.discover || []
        onOpen: function (id) { today.open(id) }
    }
}

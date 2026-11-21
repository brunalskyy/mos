import QtQuick
import QtQuick.Controls.Basic
import QtQuick.Layouts
import components
import "../parts"

// Apps: categories as chips; each category shows a ranked list you can keep scrolling
StorePage {
    id: browse
    title: "Apps"
    property string cat: ""
    property int shown: 60

    Flow {
        Layout.fillWidth: true
        spacing: 10
        Repeater {
            model: [{ id: "", name: "All", icon: "apps" }].concat(store.categories.filter(function (c) { return c.id !== "games" }))
            Rectangle {
                required property var modelData
                readonly property bool on: browse.cat === modelData.id
                width: chipRow.implicitWidth + 32; height: 40; radius: 20
                color: on ? Theme.secondaryContainer : "transparent"
                border.width: on ? 0 : 1; border.color: Theme.outline
                Row {
                    id: chipRow; anchors.centerIn: parent; spacing: 8
                    Image { source: Theme.ink(modelData.icon); sourceSize: Qt.size(36, 36); width: 18; height: 18
                            anchors.verticalCenter: parent.verticalCenter }
                    Label { text: modelData.name; color: Theme.textColour; font.pixelSize: 14; font.weight: Font.Medium
                            anchors.verticalCenter: parent.verticalCenter }
                }
                MouseArea { anchors.fill: parent; cursorShape: Qt.PointingHandCursor
                            onClicked: { browse.cat = modelData.id; browse.shown = 60; browse.contentY = 0 } }
            }
        }
    }

    // All: a shelf per category
    Repeater {
        model: browse.cat === "" ? store.categories.filter(function (c) { return c.id !== "games" }) : []
        ColumnLayout {
            required property var modelData
            Layout.fillWidth: true
            spacing: 6
            RowLayout {
                Layout.fillWidth: true
                Label { Layout.fillWidth: true; text: modelData.name; color: Theme.textColour; font.pixelSize: 22; font.weight: Font.Bold }
                Label { text: "See all"; color: Theme.primary; font.pixelSize: 14; font.weight: Font.DemiBold
                        MouseArea { anchors.fill: parent; cursorShape: Qt.PointingHandCursor
                                    onClicked: { browse.cat = modelData.id; browse.contentY = 0 } } }
            }
            GridLayout {
                Layout.fillWidth: true
                columns: width > 900 ? 3 : 2
                columnSpacing: 12; rowSpacing: 4
                Repeater {
                    model: { store.appCount; return store.category(modelData.id, 6) }
                    AppRow { required property var modelData; Layout.fillWidth: true; app: modelData
                             onOpen: function (id) { browse.open(id) } }
                }
            }
        }
    }

    // One category: ranked list
    GridLayout {
        Layout.fillWidth: true
        visible: browse.cat !== ""
        columns: width > 900 ? 2 : 1
        columnSpacing: 16; rowSpacing: 4
        Repeater {
            model: { store.appCount; return browse.cat ? store.category(browse.cat, browse.shown) : [] }
            AppRow { required property var modelData; required property int index
                     Layout.fillWidth: true; app: modelData; rank: index + 1
                     onOpen: function (id) { browse.open(id) } }
        }
    }
    PillButton {
        Layout.alignment: Qt.AlignHCenter
        visible: browse.cat !== ""
        tonal: true
        text: "Show more"
        onClicked: browse.shown += 60
    }
}

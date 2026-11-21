import QtQuick
import QtQuick.Controls.Basic
import QtQuick.Layouts
import components
import "../parts"

StorePage {
    id: search
    title: "Search"
    property string q: ""
    property var results: []
    Timer { id: debounce; interval: 160; onTriggered: search.results = store.search(search.q) }

    MField {
        id: field
        Layout.fillWidth: true
        placeholderText: "Apps, games, developers…"
        leftPadding: 50
        font.pixelSize: 16
        implicitHeight: 54
        Component.onCompleted: forceActiveFocus()
        onTextChanged: { search.q = text; debounce.restart() }
        Image { x: 18; anchors.verticalCenter: parent.verticalCenter; source: Theme.ink("search")
                sourceSize: Qt.size(44, 44); width: 22; height: 22 }
    }
    Label {
        visible: search.q !== "" && search.results.length === 0
        text: "Nothing found for “" + search.q + "”"
        color: Theme.textVariant; font.pixelSize: 15
    }
    // ideas while the box is empty
    Flow {
        Layout.fillWidth: true
        visible: search.q === ""
        spacing: 10
        Repeater {
            model: ["Browser", "Music", "Photo editor", "Video", "Chat", "Notes", "Office", "Minecraft", "Code", "Drawing"]
            Rectangle {
                required property string modelData
                width: t.implicitWidth + 32; height: 40; radius: 20
                color: Theme.surfaceContainer
                Label { id: t; anchors.centerIn: parent; text: modelData; color: Theme.textColour; font.pixelSize: 14 }
                MouseArea { anchors.fill: parent; cursorShape: Qt.PointingHandCursor; onClicked: field.text = modelData }
            }
        }
    }
    GridLayout {
        Layout.fillWidth: true
        columns: width > 900 ? 2 : 1
        columnSpacing: 16; rowSpacing: 4
        Repeater {
            model: search.results
            AppRow { required property var modelData; Layout.fillWidth: true; app: modelData
                     onOpen: function (id) { search.open(id) } }
        }
    }
}

import QtQuick
import QtQuick.Controls.Basic
import QtQuick.Layouts
import QtQuick.Effects
import components
import "../parts"

// One app: header with Get, info strip, screenshots, about, what's new, ratings & reviews, information
Rectangle {
    id: ap
    property string appId
    property var app: ({})
    property var size: ({})
    property var rv: ({ reviews: [], average: 0, total: 0, stars: [0, 0, 0, 0, 0], skey: "" })
    property bool reviewsLoading: true
    property bool moreText: false
    signal open(string id)
    signal back()
    color: Theme.surface

    readonly property var job: store.jobs[appId] || null
    readonly property string st: { store.jobs; store.updateCount; store.appCount; return store.stateOf(appId) }
    readonly property bool busy: job !== null && job.state !== "error" && job.state !== "done"

    function load() {
        app = store.app(appId)
        size = ({})
        rv = ({ reviews: [], average: 0, total: 0, stars: [0, 0, 0, 0, 0], skey: "" })
        reviewsLoading = true
        moreText = false
        flick.contentY = 0
        store.fetchSize(appId)
        store.fetchReviews(appId)
    }
    onAppIdChanged: if (appId) load()
    Connections {
        target: store
        function onSizeReady(id, s) { if (id === ap.appId) ap.size = s }
        function onReviewsReady(id, r) { if (id === ap.appId) { ap.rv = r; ap.reviewsLoading = false } }
    }

    Flickable {
        id: flick
        anchors.fill: parent
        contentWidth: width
        contentHeight: col.implicitHeight + 160
        boundsBehavior: Flickable.StopAtBounds
        clip: true
        ScrollBar.vertical: ScrollBar { policy: ScrollBar.AsNeeded }

        ColumnLayout {
            id: col
            width: Math.min(1040, flick.width - 64)
            x: (flick.width - width) / 2
            y: 24
            spacing: 28

            // back
            Rectangle {
                width: 44; height: 44; radius: 22
                color: backMa.containsMouse ? Theme.surfaceContainer : "transparent"
                Image { anchors.centerIn: parent; source: Theme.ink("back"); sourceSize: Qt.size(48, 48); width: 24; height: 24 }
                MouseArea { id: backMa; anchors.fill: parent; hoverEnabled: true; cursorShape: Qt.PointingHandCursor; onClicked: ap.back() }
            }

            // ---- header
            RowLayout {
                Layout.fillWidth: true
                spacing: 24
                AppIcon { source: ap.app.icon || ""; size: 128; Layout.alignment: Qt.AlignTop }
                ColumnLayout {
                    Layout.fillWidth: true
                    spacing: 6
                    Label { Layout.fillWidth: true; text: ap.app.name || ""; color: Theme.textColour; wrapMode: Text.WordWrap
                            font.pixelSize: 32; font.weight: Font.Bold }
                    RowLayout {
                        spacing: 6
                        Label { text: ap.app.developer || "Unknown developer"; color: Theme.primary; font.pixelSize: 15; font.weight: Font.DemiBold }
                        Image { visible: ap.app.verified === true; source: Theme.ink("verified"); sourceSize: Qt.size(40, 40)
                                width: 18; height: 18
                                layer.enabled: true; layer.effect: MultiEffect { colorization: 1; colorizationColor: Theme.primary } }
                    }
                    Label { Layout.fillWidth: true; text: ap.app.summary || ""; color: Theme.textVariant; font.pixelSize: 15
                            wrapMode: Text.WordWrap }
                    RowLayout {
                        Layout.topMargin: 10
                        spacing: 12
                        GetButton { appId: ap.appId; big: true }
                        PillButton {
                            visible: !ap.busy && (ap.st === "installed" || ap.st === "update")
                            outlined: true; text: "Remove"
                            onClicked: removeSheet.open()
                        }
                    }
                    // live install progress: percent, speed, time left
                    ColumnLayout {
                        visible: ap.busy
                        Layout.fillWidth: true
                        Layout.maximumWidth: 460
                        spacing: 6
                        Rectangle {
                            Layout.fillWidth: true; height: 8; radius: 4
                            color: Theme.surfaceContainer
                            Rectangle {
                                width: parent.width * (ap.job ? ap.job.percent : 0) / 100; height: parent.height; radius: 4
                                color: Theme.primary
                                Behavior on width { NumberAnimation { duration: 240 } }
                            }
                        }
                        Label {
                            Layout.fillWidth: true
                            color: Theme.textVariant; font.pixelSize: 13
                            text: !ap.job ? "" : [ap.job.message || "",
                                                  ap.job.percent ? ap.job.percent + "%" : "",
                                                  ap.job.total ? (ap.job.done || "0") + " of " + ap.job.total : "",
                                                  ap.job.speed || "", ap.job.eta || ""].filter(function (x) { return x !== "" }).join("  ·  ")
                        }
                    }
                    Label { visible: ap.job !== null && ap.job.state === "error"; text: ap.job ? (ap.job.message || "") : ""
                            color: Theme.error; font.pixelSize: 13; Layout.fillWidth: true; wrapMode: Text.WordWrap }
                }
            }

            // ---- info strip
            Rectangle {
                Layout.fillWidth: true
                implicitHeight: 84
                radius: 24
                color: Theme.surfaceContainer
                RowLayout {
                    anchors.fill: parent
                    spacing: 0
                    Repeater {
                        model: [
                            { top: ap.rv.total ? ap.rv.average.toFixed(1) + " ★" : "—", sub: ap.rv.total ? ap.rv.total + " ratings" : "No ratings yet" },
                            { top: ap.size.download || "—", sub: ap.size.installed ? ap.size.installed + " installed" : "Download" },
                            { top: ap.app.category || "Apps", sub: "Category" },
                            { top: ap.app.version || "—", sub: "Version" }
                        ]
                        Item {
                            required property var modelData
                            required property int index
                            Layout.fillWidth: true; Layout.fillHeight: true
                            Rectangle { visible: index > 0; width: 1; height: parent.height * 0.5; anchors.verticalCenter: parent.verticalCenter
                                        color: Theme.outline }
                            Column {
                                anchors.centerIn: parent
                                spacing: 2
                                Label { anchors.horizontalCenter: parent.horizontalCenter; text: modelData.top; color: Theme.textColour
                                        font.pixelSize: 18; font.weight: Font.Bold }
                                Label { anchors.horizontalCenter: parent.horizontalCenter; text: modelData.sub; color: Theme.textVariant
                                        font.pixelSize: 12 }
                            }
                        }
                    }
                }
            }

            // ---- screenshots
            ListView {
                id: shots
                Layout.fillWidth: true
                Layout.preferredHeight: 320
                visible: (ap.app.screenshots || []).length > 0
                orientation: ListView.Horizontal
                spacing: 16
                clip: true
                model: ap.app.screenshots || []
                boundsBehavior: Flickable.StopAtBounds
                ScrollBar.horizontal: ScrollBar { policy: ScrollBar.AsNeeded }
                delegate: Item {
                    required property var modelData
                    required property int index
                    width: Math.max(200, img.implicitWidth > 0 ? 300 * img.implicitWidth / img.implicitHeight : 533)
                    height: 300
                    Image { id: img; anchors.fill: parent; source: modelData.thumb; fillMode: Image.PreserveAspectFit
                            asynchronous: true; visible: false }
                    Item { id: sm; anchors.fill: parent; visible: false; layer.enabled: true
                           Rectangle { anchors.fill: parent; radius: 20; color: "black" } }
                    Rectangle { anchors.fill: parent; radius: 20; color: Theme.surfaceContainer; visible: img.status !== Image.Ready
                                BusyIndicator { anchors.centerIn: parent; running: img.status === Image.Loading } }
                    MultiEffect { anchors.fill: parent; source: img; maskEnabled: true; maskSource: sm }
                    MouseArea { anchors.fill: parent; cursorShape: Qt.PointingHandCursor
                                onClicked: { viewer.index = index; viewer.open() } }
                }
            }

            // ---- about
            ColumnLayout {
                Layout.fillWidth: true
                spacing: 8
                visible: (ap.app.description || "") !== ""
                Label { text: "About this app"; color: Theme.textColour; font.pixelSize: 22; font.weight: Font.Bold }
                Label {
                    Layout.fillWidth: true
                    text: ap.app.description || ""
                    textFormat: Text.StyledText
                    wrapMode: Text.WordWrap
                    maximumLineCount: ap.moreText ? 400 : 6
                    elide: Text.ElideRight
                    color: Theme.textColour; font.pixelSize: 15; lineHeight: 1.25
                }
                Label { text: ap.moreText ? "Less" : "More"; color: Theme.primary; font.pixelSize: 14; font.weight: Font.DemiBold
                        MouseArea { anchors.fill: parent; cursorShape: Qt.PointingHandCursor; onClicked: ap.moreText = !ap.moreText } }
            }

            // ---- what's new
            Card {
                visible: (ap.app.version || "") !== ""
                RowLayout {
                    Layout.fillWidth: true
                    Label { Layout.fillWidth: true; text: "What's new"; color: Theme.textColour; font.pixelSize: 20; font.weight: Font.Bold }
                    Label { text: ap.app.releasedText || ""; color: Theme.textVariant; font.pixelSize: 13 }
                }
                Label { text: "Version " + (ap.app.version || ""); color: Theme.textVariant; font.pixelSize: 13 }
                Label { Layout.fillWidth: true; visible: text !== ""; text: ap.app.releaseNotes || ""; textFormat: Text.StyledText
                        wrapMode: Text.WordWrap; color: Theme.textColour; font.pixelSize: 14; maximumLineCount: 10; elide: Text.ElideRight }
            }

            // ---- ratings & reviews
            ColumnLayout {
                Layout.fillWidth: true
                spacing: 14
                RowLayout {
                    Layout.fillWidth: true
                    Label { Layout.fillWidth: true; text: "Ratings & reviews"; color: Theme.textColour; font.pixelSize: 22; font.weight: Font.Bold }
                    PillButton { tonal: true; text: "Write a review"; onClicked: reviewSheet.open() }
                }
                RowLayout {
                    spacing: 28
                    ColumnLayout {
                        spacing: 0
                        Label { text: ap.rv.total ? ap.rv.average.toFixed(1) : "–"; color: Theme.textColour; font.pixelSize: 56; font.weight: Font.Bold }
                        Stars { value: ap.rv.average; size: 16 }
                        Label { text: ap.rv.total ? ap.rv.total + " ratings" : "No ratings yet"; color: Theme.textVariant; font.pixelSize: 12 }
                    }
                    ColumnLayout {
                        spacing: 4
                        Repeater {
                            model: 5
                            RowLayout {
                                required property int index
                                spacing: 8
                                Label { text: (5 - index) + ""; color: Theme.textVariant; font.pixelSize: 12; Layout.preferredWidth: 10 }
                                Rectangle {
                                    Layout.preferredWidth: 240; height: 8; radius: 4; color: Theme.surfaceContainer
                                    Rectangle { height: parent.height; radius: 4; color: Theme.primary
                                                width: ap.rv.total ? parent.width * ap.rv.stars[4 - index] / ap.rv.total : 0 }
                                }
                            }
                        }
                    }
                }
                Label { visible: ap.reviewsLoading; text: "Loading reviews…"; color: Theme.textVariant; font.pixelSize: 14 }
                Label { visible: !ap.reviewsLoading && ap.rv.reviews.length === 0; text: "No reviews yet. Be the first!"
                        color: Theme.textVariant; font.pixelSize: 14 }
                GridLayout {
                    Layout.fillWidth: true
                    columns: width > 760 ? 2 : 1
                    columnSpacing: 16; rowSpacing: 16
                    Repeater {
                        model: ap.rv.reviews.slice(0, 10)
                        Rectangle {
                            required property var modelData
                            Layout.fillWidth: true
                            Layout.alignment: Qt.AlignTop
                            implicitHeight: rcol.implicitHeight + 40
                            radius: 24
                            color: Theme.surfaceContainer
                            ColumnLayout {
                                id: rcol
                                anchors { left: parent.left; right: parent.right; top: parent.top; margins: 20 }
                                spacing: 8
                                RowLayout {
                                    spacing: 12
                                    Avatar { name: modelData.name; size: 40 }
                                    ColumnLayout {
                                        spacing: 1
                                        Label { text: modelData.name; color: Theme.textColour; font.pixelSize: 14; font.weight: Font.DemiBold }
                                        RowLayout {
                                            spacing: 8
                                            Stars { value: modelData.rating; size: 12 }
                                            Label { text: modelData.date; color: Theme.textVariant; font.pixelSize: 12 }
                                        }
                                    }
                                }
                                Label { Layout.fillWidth: true; visible: text !== ""; text: modelData.title; color: Theme.textColour
                                        font.pixelSize: 15; font.weight: Font.DemiBold; wrapMode: Text.WordWrap }
                                Label { Layout.fillWidth: true; text: modelData.text; color: Theme.textColour; font.pixelSize: 14
                                        wrapMode: Text.WordWrap; maximumLineCount: 7; elide: Text.ElideRight }
                                Label { visible: modelData.helpful > 0; text: modelData.helpful + " found this helpful"
                                        color: Theme.textVariant; font.pixelSize: 12 }
                            }
                        }
                    }
                }
                Label { text: "Reviews come from ODRS, shared with other Linux app stores."; color: Theme.textVariant; font.pixelSize: 12 }
            }

            // ---- information
            Card {
                Label { text: "Information"; color: Theme.textColour; font.pixelSize: 20; font.weight: Font.Bold }
                Repeater {
                    model: [
                        { k: "Developer", v: ap.app.developer || "—" },
                        { k: "Size", v: ap.size.installed || "—" },
                        { k: "Category", v: ap.app.category || "—" },
                        { k: "Version", v: ap.app.version || "—" },
                        { k: "Licence", v: (ap.app.license || "—").replace(/LicenseRef-proprietary.*/, "Proprietary") },
                        { k: "App ID", v: ap.appId }
                    ]
                    RowLayout {
                        required property var modelData
                        Layout.fillWidth: true
                        Label { text: modelData.k; color: Theme.textVariant; font.pixelSize: 14; Layout.preferredWidth: 140 }
                        Label { Layout.fillWidth: true; text: modelData.v; color: Theme.textColour; font.pixelSize: 14
                                horizontalAlignment: Text.AlignRight; elide: Text.ElideMiddle }
                    }
                }
                RowLayout {
                    Layout.fillWidth: true
                    visible: (ap.app.homepage || "") !== ""
                    Label { text: "Website"; color: Theme.textVariant; font.pixelSize: 14; Layout.preferredWidth: 140 }
                    Label { Layout.fillWidth: true; text: ap.app.homepage || ""; color: Theme.primary; font.pixelSize: 14
                            horizontalAlignment: Text.AlignRight; elide: Text.ElideMiddle
                            MouseArea { anchors.fill: parent; cursorShape: Qt.PointingHandCursor; onClicked: store.openUrl(ap.app.homepage) } }
                }
            }
        }
    }

    // ---- full-size screenshots
    Popup {
        id: viewer
        property int index: 0
        readonly property var list: ap.app.screenshots || []
        parent: Overlay.overlay
        x: 0; y: 0
        width: parent ? parent.width : 0; height: parent ? parent.height : 0
        modal: true
        padding: 0
        background: Rectangle { color: Qt.rgba(0, 0, 0, 0.88) }
        enter: Transition { NumberAnimation { property: "opacity"; from: 0; to: 1; duration: 180 } }
        exit: Transition { NumberAnimation { property: "opacity"; to: 0; duration: 140 } }
        contentItem: Item {
            focus: true
            Keys.onLeftPressed: viewer.index = Math.max(0, viewer.index - 1)
            Keys.onRightPressed: viewer.index = Math.min(viewer.list.length - 1, viewer.index + 1)
            Keys.onEscapePressed: viewer.close()
            Image {
                anchors.fill: parent; anchors.margins: 70
                source: viewer.list.length ? viewer.list[viewer.index].full : ""
                fillMode: Image.PreserveAspectFit; asynchronous: true
                BusyIndicator { anchors.centerIn: parent; running: parent.status === Image.Loading }
            }
            Label { anchors.bottom: parent.bottom; anchors.bottomMargin: 24; anchors.horizontalCenter: parent.horizontalCenter
                    text: viewer.list.length ? (viewer.list[viewer.index].caption || "") + "   " + (viewer.index + 1) + " / " + viewer.list.length : ""
                    color: "white"; font.pixelSize: 14 }
            Repeater {
                model: [{ d: -1, x: 0, icon: "back" }, { d: 1, x: 1, icon: "chevron" }, { d: 0, x: 2, icon: "close" }]
                Rectangle {
                    required property var modelData
                    width: 48; height: 48; radius: 24
                    color: Qt.rgba(1, 1, 1, 0.14)
                    x: modelData.x === 0 ? 14 : parent.width - 62
                    y: modelData.x === 2 ? 14 : parent.height / 2 - 24
                    visible: modelData.d === 0 || (modelData.d < 0 ? viewer.index > 0 : viewer.index < viewer.list.length - 1)
                    Image { anchors.centerIn: parent; source: Theme.icon(modelData.icon); sourceSize: Qt.size(48, 48); width: 24; height: 24 }
                    MouseArea { anchors.fill: parent; cursorShape: Qt.PointingHandCursor
                                onClicked: modelData.d === 0 ? viewer.close() : viewer.index += modelData.d }
                }
            }
        }
    }

    // ---- remove
    Sheet {
        id: removeSheet
        title: "Remove " + (ap.app.name || "this app") + "?"
        Label { Layout.fillWidth: true; wrapMode: Text.WordWrap; color: Theme.textVariant; font.pixelSize: 14
                text: "You can get it again from the mOS Store any time." }
        RowLayout {
            Layout.alignment: Qt.AlignRight
            spacing: 10
            PillButton { outlined: true; text: "Cancel"; onClicked: removeSheet.close() }
            PillButton { danger: true; text: "Remove"; onClicked: { store.remove(ap.appId); removeSheet.close() } }
        }
    }

    // ---- write a review (signed with your mOS Account name)
    Sheet {
        id: reviewSheet
        title: "Review " + (ap.app.name || "")
        property int stars: 0
        onOpened: { stars = 0; titleField.text = ""; bodyField.text = "" }
        Label { text: "Posting as " + store.reviewerName; color: Theme.textVariant; font.pixelSize: 13 }
        Stars { value: reviewSheet.stars; size: 30; editable: true; onPicked: function (n) { reviewSheet.stars = n } }
        MField { id: titleField; Layout.fillWidth: true; placeholderText: "Title"; maximumLength: 70 }
        ScrollView {
            Layout.fillWidth: true
            Layout.preferredHeight: 140
            TextArea {
                id: bodyField
                placeholderText: "What do you think of it?"
                wrapMode: TextEdit.Wrap
                color: Theme.textColour; placeholderTextColor: Theme.textVariant; font.pixelSize: 15
                padding: 16
                background: Rectangle { radius: 20; color: Theme.surfaceContainer
                                        border.width: bodyField.activeFocus ? 2 : 1
                                        border.color: bodyField.activeFocus ? Theme.primary : Theme.outline }
            }
        }
        RowLayout {
            Layout.alignment: Qt.AlignRight
            spacing: 10
            PillButton { outlined: true; text: "Cancel"; onClicked: reviewSheet.close() }
            PillButton {
                text: "Send"
                enabled: reviewSheet.stars > 0 && bodyField.text.trim().length >= 10
                onClicked: { store.submitReview(ap.appId, reviewSheet.stars, titleField.text, bodyField.text, ap.rv.skey); reviewSheet.close() }
            }
        }
    }
}

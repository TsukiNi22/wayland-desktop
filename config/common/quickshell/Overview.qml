// wayland-desktop overview content: search field, workspaces with their live windows, dock, applications grid
// (opened and closed by shell.qml; every color, the font, the radius and the motion come from the style theme)

import QtQuick
import QtQuick.Effects
import Quickshell
import Quickshell.Hyprland
import Quickshell.Widgets

Item {
    id: overview

    required property var theme
    required property string mode
    required property bool shown
    property var monitor: null

    signal closeRequested
    signal modeRequested(string next)
    signal hidden

    readonly property bool open: mode !== "closed"
    readonly property string query: search.text.trim().toLowerCase()
    readonly property bool appsMode: mode === "apps" || query.length > 0
    // 0 closed -> 1 open, and 0 workspaces -> 1 applications (animated)
    property real progress: 0
    property real appsProgress: appsMode ? 1 : 0
    property int selected: 0
    // window dragged to another workspace (HyprlandToplevel)
    property var dragged: null
    property string hoveredTitle: ""
    readonly property Item ghost: ghostItem

    // motion of the style: overshoot / back (bounce), snap (fast), soft (slow)
    readonly property int speed: theme.motion === "soft" ? 520 : (theme.motion === "snap" ? 240 : 380)
    readonly property int curve: theme.motion === "soft" ? Easing.InOutSine
        : (theme.motion === "snap" ? Easing.OutExpo : Easing.OutBack)

    Behavior on appsProgress {
        NumberAnimation {
            duration: overview.speed
            easing.type: Easing.OutCubic
        }
    }

    // =========================
    // Data
    // =========================
    readonly property var workspaces: {
        const name = overview.monitor ? overview.monitor.name : "";
        const list = Hyprland.workspaces.values.filter(w => w.id > 0 && (!name || !w.monitor || w.monitor.name === name));
        const ids = list.map(w => w.id).sort((a, b) => a - b);

        // GNOME: one empty workspace after the last one
        ids.push(ids.length ? ids[ids.length - 1] + 1 : 1);
        return ids;
    }
    readonly property int activeWorkspace: overview.monitor && overview.monitor.activeWorkspace
        ? overview.monitor.activeWorkspace.id : (Hyprland.focusedWorkspace ? Hyprland.focusedWorkspace.id : 1)
    readonly property real screenWidth: overview.monitor ? overview.monitor.width / overview.monitor.scale : overview.width
    readonly property real screenHeight: overview.monitor ? overview.monitor.height / overview.monitor.scale : overview.height
    readonly property real cardWidth: Math.min((overview.width * 0.88 - 28 * (workspaces.length - 1)) / workspaces.length,
        overview.width * 0.25)
    readonly property string wallpaper: "file://" + Quickshell.env("HOME") + "/.config/wayland-desktop/styles/"
        + overview.theme.style + "/wallpaper.jpg"

    readonly property var apps: DesktopEntries.applications.values.filter(e => !e.noDisplay)
        .sort((a, b) => a.name.localeCompare(b.name))
    readonly property var results: {
        const q = overview.query;
        const scored = [];

        if (!q)
            return overview.apps;
        for (const entry of overview.apps) {
            const name = entry.name.toLowerCase();
            const extra = [entry.genericName, entry.comment, entry.id].concat(entry.keywords).join(" ").toLowerCase();
            const score = name.startsWith(q) ? 0 : (name.includes(q) ? 1 : (extra.includes(q) ? 2 : -1));

            if (score >= 0)
                scored.push({ entry: entry, score: score });
        }
        scored.sort((a, b) => a.score - b.score || a.entry.name.localeCompare(b.entry.name));
        return scored.map(s => s.entry);
    }

    // favorites (when installed), then the other running applications
    readonly property var favorites: ["kitty", "org.mozilla.firefox", "firefox", "org.gnome.Nautilus",
        "org.gnome.TextEditor", "code", "com.visualstudio.code", "spotify", "com.spotify.Client", "discord",
        "com.discordapp.Discord", "steam"]
    readonly property var dock: {
        const items = [];
        const known = {};
        const add = (entry, running) => {
            if (!entry)
                return;
            if (known[entry.id]) {
                known[entry.id].running = known[entry.id].running || running;
                return;
            }
            known[entry.id] = { entry: entry, running: running };
            items.push(known[entry.id]);
        };

        for (const id of overview.favorites)
            add(DesktopEntries.byId(id), false);
        for (const toplevel of Hyprland.toplevels.values) {
            const ipc = toplevel.lastIpcObject;

            if (ipc && ipc.class)
                add(DesktopEntries.heuristicLookup(ipc.class), true);
        }
        return items;
    }

    onResultsChanged: selected = 0

    function windowsOf(id) {
        return Hyprland.toplevels.values.filter(t => t.workspace && t.workspace.id === id);
    }

    function icon(name) {
        return Quickshell.iconPath(name || "", "application-x-executable");
    }

    function iconOf(toplevel) {
        const ipc = toplevel ? toplevel.lastIpcObject : null;
        const entry = ipc && ipc.class ? DesktopEntries.heuristicLookup(ipc.class) : null;

        return icon(entry ? entry.icon : (ipc ? ipc.class : ""));
    }

    // =========================
    // Actions (Hyprland 0.55+ dispatches Lua)
    // =========================
    function address(toplevel) {
        return toplevel.address.startsWith("0x") ? toplevel.address : "0x" + toplevel.address;
    }

    function goTo(id) {
        Hyprland.dispatch(`hl.dsp.focus({ workspace = ${id} })`);
        overview.closeRequested();
    }

    function switchTo(offset) {
        Hyprland.dispatch(`hl.dsp.focus({ workspace = "r${offset > 0 ? "+" : "-"}1" })`);
    }

    function focusWindow(toplevel) {
        Hyprland.dispatch(`hl.dsp.focus({ window = "address:${address(toplevel)}" })`);
        overview.closeRequested();
    }

    function closeWindow(toplevel) {
        Hyprland.dispatch(`hl.dsp.window.close({ window = "address:${address(toplevel)}" })`);
    }

    function moveDragged(id) {
        if (overview.dragged)
            Hyprland.dispatch(`hl.dsp.window.move({ workspace = ${id}, window = "address:${address(overview.dragged)}" })`);
        refresh.restart();
    }

    function launch(entry) {
        if (!entry)
            return;
        entry.execute();
        overview.closeRequested();
    }

    // a running application of the dock: its first window, else a new one
    function activate(item) {
        const toplevel = Hyprland.toplevels.values.find(t => {
            const ipc = t.lastIpcObject;
            const entry = ipc && ipc.class ? DesktopEntries.heuristicLookup(ipc.class) : null;

            return entry && entry.id === item.entry.id;
        });

        if (toplevel)
            focusWindow(toplevel);
        else
            launch(item.entry);
    }

    function key(event) {
        const count = overview.results.length;
        const columns = Math.max(1, Math.floor(grid.width / grid.cellWidth));
        let handled = true;

        switch (event.key) {
        case Qt.Key_Escape:
            if (search.text)
                search.text = "";
            else if (overview.mode === "apps")
                overview.modeRequested("overview");
            else
                overview.closeRequested();
            break;
        case Qt.Key_Return:
        case Qt.Key_Enter:
            if (overview.appsMode)
                launch(overview.results[overview.selected]);
            else
                goTo(overview.activeWorkspace);
            break;
        case Qt.Key_Down:
            if (overview.appsMode)
                overview.selected = Math.min(count - 1, overview.selected + columns);
            else
                overview.modeRequested("apps");
            break;
        case Qt.Key_Up:
            if (overview.appsMode && overview.selected < columns && !search.text)
                overview.modeRequested("overview");
            else
                overview.selected = Math.max(0, overview.selected - columns);
            break;
        case Qt.Key_Tab:
            overview.selected = (overview.selected + 1) % Math.max(1, count);
            break;
        case Qt.Key_Backtab:
            overview.selected = (overview.selected - 1 + Math.max(1, count)) % Math.max(1, count);
            break;
        case Qt.Key_Left:
        case Qt.Key_Right:
            if (search.text) {
                handled = false;
            } else if (overview.appsMode) {
                overview.selected = Math.max(0, Math.min(count - 1, overview.selected + (event.key === Qt.Key_Left ? -1 : 1)));
            } else {
                switchTo(event.key === Qt.Key_Left ? -1 : 1);
            }
            break;
        default:
            handled = false;
        }
        event.accepted = handled;
    }

    onOpenChanged: {
        if (open) {
            search.text = "";
            overview.selected = 0;
            closing.stop();
            opening.start();
            search.forceActiveFocus();
        } else {
            opening.stop();
            closing.start();
        }
    }
    onShownChanged: {
        if (shown)
            search.forceActiveFocus();
    }
    onSelectedChanged: grid.positionViewAtIndex(overview.selected, GridView.Contain)

    NumberAnimation {
        id: opening

        target: overview
        property: "progress"
        to: 1
        duration: overview.speed
        easing.type: Easing.OutCubic
    }

    NumberAnimation {
        id: closing

        target: overview
        property: "progress"
        to: 0
        duration: 170
        easing.type: Easing.InCubic
        onFinished: overview.hidden()
    }

    Timer {
        id: refresh

        interval: 120
        onTriggered: Hyprland.refreshToplevels()
    }

    // =========================
    // Background
    // =========================
    // the wallpaper of the style, blurred, behind everything (the windows live in the workspace cards)
    Image {
        id: backdrop

        anchors.fill: parent
        source: overview.wallpaper
        sourceSize.width: 1280
        fillMode: Image.PreserveAspectCrop
        asynchronous: true
        visible: false
    }

    MultiEffect {
        anchors.fill: parent
        source: backdrop
        blurEnabled: true
        blur: 1
        blurMax: 48
        brightness: -0.1
        opacity: overview.progress
        scale: 1.06 - 0.06 * overview.progress
    }

    Rectangle {
        anchors.fill: parent
        color: overview.theme.bg
        opacity: 0.5 * overview.progress
    }

    Rectangle {
        anchors.fill: parent
        opacity: overview.progress

        gradient: Gradient {
            GradientStop {
                position: 0
                color: Qt.alpha(overview.theme.accent, 0.14)
            }
            GradientStop {
                position: 0.55
                color: "transparent"
            }
            GradientStop {
                position: 1
                color: Qt.alpha(overview.theme.accent2, 0.1)
            }
        }
    }

    MouseArea {
        anchors.fill: parent
        acceptedButtons: Qt.LeftButton | Qt.RightButton
        onClicked: overview.closeRequested()
    }

    // =========================
    // Search
    // =========================
    Rectangle {
        id: searchBox

        anchors.horizontalCenter: parent.horizontalCenter
        y: 46 - (1 - overview.progress) * 40
        width: 480
        height: 48
        radius: Math.min(overview.theme.radius + 6, height / 2)
        opacity: overview.progress
        color: Qt.alpha(overview.theme.surface, 0.92)
        border.width: search.activeFocus ? 2 : 1
        border.color: search.activeFocus ? overview.theme.accent : overview.theme.border

        Text {
            id: searchIcon

            anchors.left: parent.left
            anchors.leftMargin: 18
            anchors.verticalCenter: parent.verticalCenter
            text: ""
            color: overview.theme.muted
            font.family: "Font Awesome 6 Free"
            font.weight: Font.Black
            font.pixelSize: 15
        }

        TextInput {
            id: search

            anchors.left: searchIcon.right
            anchors.right: parent.right
            anchors.leftMargin: 12
            anchors.rightMargin: 18
            anchors.verticalCenter: parent.verticalCenter
            focus: true
            color: overview.theme.fg
            selectionColor: overview.theme.accent
            selectedTextColor: overview.theme.accentText
            font.family: overview.theme.font
            font.pixelSize: 16
            clip: true
            Keys.onPressed: event => overview.key(event)
        }

        Text {
            anchors.left: search.left
            anchors.verticalCenter: parent.verticalCenter
            visible: !search.text
            text: overview.mode === "apps" ? "Search applications" : "Type to search"
            color: overview.theme.muted
            font.family: overview.theme.font
            font.pixelSize: 16
        }
    }

    // =========================
    // Workspaces
    // =========================
    Row {
        id: strip

        anchors.horizontalCenter: parent.horizontalCenter
        y: overview.height * 0.43 - height / 2 - overview.appsProgress * 90
        spacing: 28
        opacity: 1 - overview.appsProgress
        visible: opacity > 0.01

        Repeater {
            model: overview.workspaces

            WorkspaceCard {
                required property int modelData
                required property int index

                host: overview
                theme: overview.theme
                workspaceId: modelData
                order: index
                width: overview.cardWidth
            }
        }
    }

    Text {
        anchors.horizontalCenter: parent.horizontalCenter
        y: strip.y + strip.height + 34
        opacity: (1 - overview.appsProgress) * overview.progress
        text: overview.hoveredTitle || "click: go  ·  drag a window: move it  ·  middle click: close  ·  ← →: workspaces  ·  Super: applications"
        color: overview.hoveredTitle ? overview.theme.fg : overview.theme.muted
        font.family: overview.theme.font
        font.pixelSize: overview.hoveredTitle ? 15 : 13
        elide: Text.ElideRight
        width: Math.min(implicitWidth, overview.width * 0.8)
    }

    // =========================
    // Applications
    // =========================
    GridView {
        id: grid

        readonly property int columns: Math.max(1, Math.floor(overview.width * 0.8 / cellWidth))

        anchors.horizontalCenter: parent.horizontalCenter
        y: 130 + (1 - overview.appsProgress) * 90
        width: columns * cellWidth
        height: dock.y - y - 26
        opacity: overview.appsProgress * overview.progress
        visible: opacity > 0.01
        cellWidth: 150
        cellHeight: 138
        clip: true
        boundsBehavior: Flickable.StopAtBounds
        model: overview.results

        delegate: AppTile {
            required property var modelData
            required property int index

            entry: modelData
            selected: index === overview.selected
            onLaunched: overview.launch(modelData)
            onHovered: overview.selected = index
        }
    }

    Text {
        anchors.centerIn: grid
        visible: overview.appsMode && overview.results.length === 0
        opacity: grid.opacity
        text: "No application matches “" + search.text + "”"
        color: overview.theme.muted
        font.family: overview.theme.font
        font.pixelSize: 16
    }

    // =========================
    // Dock
    // =========================
    Rectangle {
        id: dock

        anchors.horizontalCenter: parent.horizontalCenter
        y: overview.height - height - 30 + (1 - overview.progress) * 110
        width: dockRow.width + 28
        height: 78
        radius: Math.min(overview.theme.radius + 8, height / 2)
        opacity: overview.progress
        color: Qt.alpha(overview.theme.surface, 0.85)
        border.width: 1
        border.color: Qt.alpha(overview.theme.border, 0.95)

        Row {
            id: dockRow

            anchors.centerIn: parent
            spacing: 8

            Repeater {
                model: overview.dock

                DockIcon {
                    required property var modelData

                    label: modelData.entry.name
                    source: overview.icon(modelData.entry.icon)
                    running: modelData.running
                    onClicked: overview.activate(modelData)
                }
            }

            Rectangle {
                anchors.verticalCenter: parent.verticalCenter
                width: 1
                height: 42
                color: overview.theme.border
            }

            DockIcon {
                label: overview.mode === "apps" ? "Workspaces" : "Show applications"
                grid: true
                active: overview.mode === "apps"
                onClicked: overview.modeRequested(overview.mode === "apps" ? "overview" : "apps")
            }
        }
    }

    // window being dragged to another workspace
    Item {
        id: ghostItem

        width: 132
        height: 86
        z: 10
        visible: overview.dragged !== null
        Drag.active: overview.dragged !== null
        Drag.keys: ["wd-window"]
        Drag.hotSpot.x: width / 2
        Drag.hotSpot.y: height / 2

        Rectangle {
            anchors.fill: parent
            radius: Math.max(6, overview.theme.radius / 2)
            color: Qt.alpha(overview.theme.surface, 0.92)
            border.width: 2
            border.color: overview.theme.accent
        }

        IconImage {
            anchors.centerIn: parent
            implicitSize: 44
            source: overview.iconOf(overview.dragged)
        }
    }

    // =========================
    // Components
    // =========================
    component AppTile: Item {
        id: tile

        property var entry
        property bool selected

        signal launched
        signal hovered

        width: 150
        height: 138

        Rectangle {
            anchors.fill: parent
            anchors.margins: 6
            radius: overview.theme.radius
            color: tile.selected ? Qt.alpha(overview.theme.accent, 0.22)
                : (tileMouse.containsMouse ? Qt.alpha(overview.theme.fg, 0.08) : "transparent")
            border.width: tile.selected ? 2 : 0
            border.color: overview.theme.accent

            Behavior on color {
                ColorAnimation {
                    duration: 140
                }
            }
        }

        IconImage {
            id: tileIcon

            anchors.horizontalCenter: parent.horizontalCenter
            y: 18
            implicitSize: 64
            source: overview.icon(tile.entry ? tile.entry.icon : "")
            scale: tileMouse.containsMouse || tile.selected ? 1.1 : 1

            Behavior on scale {
                NumberAnimation {
                    duration: 220
                    easing.type: Easing.OutBack
                }
            }
        }

        Text {
            anchors.top: tileIcon.bottom
            anchors.topMargin: 10
            anchors.horizontalCenter: parent.horizontalCenter
            width: parent.width - 20
            horizontalAlignment: Text.AlignHCenter
            text: tile.entry ? tile.entry.name : ""
            color: overview.theme.fg
            font.family: overview.theme.font
            font.pixelSize: 13
            font.bold: tile.selected
            wrapMode: Text.Wrap
            maximumLineCount: 2
            elide: Text.ElideRight
        }

        MouseArea {
            id: tileMouse

            anchors.fill: parent
            hoverEnabled: true
            cursorShape: Qt.PointingHandCursor
            onClicked: tile.launched()
            onEntered: tile.hovered()
        }
    }

    component DockIcon: Item {
        id: item

        property string label
        property string source
        property bool running
        property bool grid
        property bool active

        signal clicked

        width: 58
        height: 66

        Rectangle {
            anchors.centerIn: parent
            anchors.verticalCenterOffset: -3
            width: 54
            height: 54
            radius: Math.min(overview.theme.radius, 18)
            color: item.active ? Qt.alpha(overview.theme.accent, 0.3)
                : (dockMouse.containsMouse ? Qt.alpha(overview.theme.fg, 0.1) : "transparent")

            Behavior on color {
                ColorAnimation {
                    duration: 140
                }
            }
        }

        IconImage {
            anchors.centerIn: parent
            anchors.verticalCenterOffset: -3
            visible: !item.grid
            implicitSize: 42
            source: item.source
            scale: dockMouse.containsMouse ? 1.18 : 1

            Behavior on scale {
                NumberAnimation {
                    duration: 240
                    easing.type: Easing.OutBack
                }
            }
        }

        // the "show applications" button: a grid of 3 x 3 dots
        Grid {
            anchors.centerIn: parent
            anchors.verticalCenterOffset: -3
            visible: item.grid
            columns: 3
            spacing: 5
            scale: dockMouse.containsMouse ? 1.15 : 1

            Behavior on scale {
                NumberAnimation {
                    duration: 240
                    easing.type: Easing.OutBack
                }
            }

            Repeater {
                model: 9

                Rectangle {
                    width: 6
                    height: 6
                    radius: 3
                    color: item.active ? overview.theme.accent : overview.theme.fg
                }
            }
        }

        Rectangle {
            anchors.horizontalCenter: parent.horizontalCenter
            anchors.bottom: parent.bottom
            visible: item.running
            width: 6
            height: 6
            radius: 3
            color: overview.theme.accent
        }

        // name bubble above the icon
        Rectangle {
            anchors.horizontalCenter: parent.horizontalCenter
            anchors.bottom: parent.top
            anchors.bottomMargin: 14
            width: bubble.implicitWidth + 22
            height: 30
            radius: Math.min(overview.theme.radius, 15)
            color: Qt.alpha(overview.theme.surface, 0.96)
            border.width: 1
            border.color: overview.theme.border
            opacity: dockMouse.containsMouse ? 1 : 0
            visible: opacity > 0

            Behavior on opacity {
                NumberAnimation {
                    duration: 150
                }
            }

            Text {
                id: bubble

                anchors.centerIn: parent
                text: item.label
                color: overview.theme.fg
                font.family: overview.theme.font
                font.pixelSize: 13
            }
        }

        MouseArea {
            id: dockMouse

            anchors.fill: parent
            hoverEnabled: true
            cursorShape: Qt.PointingHandCursor
            onClicked: item.clicked()
        }
    }
}

// wayland-desktop: GNOME-like overview run by quickshell (quickshell -c wayland-desktop, started by wd-style)
// Super: the workspaces with their live windows and a dock, Super again or Super+A: the applications grid, Super a
// third time / Escape / a click on the background: back to the desktop; typing searches the applications at once
// The colors, font, radius and motion follow the active style (~/.config/wayland-desktop/theme.json, copied by wd-style)
// GNOME workspaces: an emptied workspace goes away and the ones after it move down (no hole); a window dropped on the
// "new workspace" card of the overview creates one, and so does Enter or a click on it (the arrows only select a card)
// The lock of better-tty (a shell) and Dev (a getty) is a session lock drawn here (LockScreen.qml, wd-style lock)

import QtQuick
import Quickshell
import Quickshell.Hyprland
import Quickshell.Io
import Quickshell.Wayland

ShellRoot {
    id: root

    // closed, overview or apps
    property string mode: "closed"
    // true from the opening until the end of the closing animation
    property bool shown: false
    // the first moments after Super: a second Super goes straight to the applications (workspaces never shown)
    property bool deciding: false

    // Workspaces first, the windows after: a window of a workspace quickshell doesn't know yet crashes it (0.2)
    function refresh() {
        Hyprland.refreshMonitors();
        Hyprland.refreshWorkspaces();
        toplevelsLater.restart();
    }

    function open(next) {
        root.refresh();
        themeFile.reload();
        root.shown = true;
        root.mode = next;
    }

    function close() {
        root.mode = "closed";
    }

    // GNOME: overview, then applications, then the desktop again; Super twice quickly: the applications at once
    function toggle() {
        if (root.mode === "closed") {
            root.deciding = true;
            decide.restart();
            root.open("overview");
        } else if (root.mode === "overview") {
            root.mode = "apps";
            root.deciding = false;
        } else {
            root.close();
        }
    }

    // a double tap of Super (release to release): long enough for a quick double tap, short enough for a single Super
    Timer {
        id: decide

        interval: 260
        onTriggered: root.deciding = false
    }

    function apps() {
        if (root.mode === "closed")
            root.open("apps");
        else if (root.mode === "apps")
            root.close();
        else
            root.mode = "apps";
    }

    Component.onCompleted: root.refresh()

    Timer {
        id: toplevelsLater

        interval: 120
        onTriggered: Hyprland.refreshToplevels()
    }

    // Super (released alone) and Super+A, straight from Hyprland: no process started at each press. Super is a release
    // bind: Hyprland sends it as "released"; hyprctl dispatch and the touchpad gesture send "pressed" (never both)
    GlobalShortcut {
        appid: "wayland-desktop"
        name: "overview"
        onPressed: root.toggle()
        onReleased: root.toggle()
    }

    GlobalShortcut {
        appid: "wayland-desktop"
        name: "apps"
        onPressed: root.apps()
    }

    // =========================
    // GNOME workspaces
    // =========================
    Connections {
        target: Hyprland

        function onRawEvent(event) {
            if (event.name === "destroyworkspacev2")
                compactLater.restart();
            else if (event.name === "createworkspacev2" || event.name === "openwindow")
                root.refresh();
        }
    }

    Timer {
        id: compactLater

        interval: 250
        onTriggered: clients.running = true
    }

    // the numbered workspaces become 1, 2, 3... again: the windows of a workspace after a hole move down
    Process {
        id: clients

        command: ["hyprctl", "-j", "clients"]
        stdout: StdioCollector {
            onStreamFinished: root.compact(JSON.parse(text))
        }
    }

    function compact(list) {
        const active = Hyprland.focusedWorkspace ? Hyprland.focusedWorkspace.id : 0;
        const ids = [...new Set(list.map(c => c.workspace.id).filter(id => id > 0))].sort((a, b) => a - b);
        let follow = 0;

        ids.forEach((id, index) => {
            const target = index + 1;

            if (id === target)
                return;
            for (const client of list.filter(c => c.workspace.id === id))
                Hyprland.dispatch(`hl.dsp.window.move({ workspace = ${target}, window = "address:${client.address}" })`);
            if (id === active)
                follow = target;
        });
        // an empty active workspace after the last one becomes the one right after it
        if (!follow && active > ids.length + 1 && !ids.includes(active))
            follow = ids.length + 1;
        if (follow)
            Hyprland.dispatch(`hl.dsp.focus({ workspace = ${follow} })`);
        root.refresh();
    }

    // =========================
    // Lock: better-tty and Dev here, the other styles in hyprlock
    // =========================
    property bool locked: false

    function lock() {
        themeFile.reload();
        if (styleTheme.style !== "tty" && styleTheme.style !== "dev") {
            Quickshell.execDetached(["hyprlock"]);
            return;
        }
        root.close();
        root.locked = true;
    }

    IpcHandler {
        target: "lock"

        function lock(): void {
            root.lock();
        }
    }

    WlSessionLock {
        locked: root.locked

        WlSessionLockSurface {
            color: "black"

            LockScreen {
                anchors.fill: parent
                mode: styleTheme.style === "dev" ? "getty" : "shell"
                onUnlocked: root.locked = false
            }
        }
    }

    FileView {
        id: themeFile

        path: Quickshell.env("HOME") + "/.config/wayland-desktop/theme.json"
        watchChanges: true
        onFileChanged: reload()

        adapter: JsonAdapter {
            id: styleTheme

            property string style: "system"
            property string font: "Adwaita Sans"
            property string mono: "JetBrains Mono"
            property int radius: 14
            property string motion: "overshoot"
            property string bg: "#0e1217"
            property string surface: "#151b23"
            property string overlay: "#1c2330"
            property string border: "#2a3441"
            property string fg: "#d6dde7"
            property string muted: "#7b8798"
            property string accent: "#5aa9ff"
            property string accent2: "#5fd38d"
            property string urgent: "#ff6b6b"
            property string accentText: "#0e1217"
        }
    }

    IpcHandler {
        target: "overview"

        function toggle(): void {
            root.toggle();
        }

        function apps(): void {
            root.apps();
        }

        function close(): void {
            root.close();
        }
    }

    Variants {
        model: Quickshell.screens

        // Always there (transparent, clicks and keys go through) so Super only starts the animation: no surface to
        // create at each opening; taken away under a fullscreen window (direct scanout of games and videos)
        PanelWindow {
            id: window

            required property var modelData
            readonly property bool focused: Hyprland.focusedMonitor !== null && Hyprland.focusedMonitor.name === modelData.name
            readonly property bool fullscreen: Hyprland.focusedWorkspace !== null && Hyprland.focusedWorkspace.hasFullscreen

            screen: modelData
            visible: focused && (root.shown || !fullscreen)
            color: "transparent"
            exclusionMode: ExclusionMode.Ignore
            mask: root.shown ? null : passThrough
            WlrLayershell.layer: WlrLayer.Overlay
            WlrLayershell.keyboardFocus: root.shown ? WlrKeyboardFocus.Exclusive : WlrKeyboardFocus.None
            WlrLayershell.namespace: "wd-overview"

            Region {
                id: passThrough
            }

            anchors {
                top: true
                bottom: true
                left: true
                right: true
            }

            Overview {
                anchors.fill: parent
                theme: styleTheme
                mode: root.mode
                deciding: root.deciding
                shown: root.shown && window.visible
                monitor: Hyprland.monitorFor(window.modelData)
                onCloseRequested: root.close()
                onModeRequested: next => root.mode = next
                onHidden: root.shown = false
            }
        }
    }
}

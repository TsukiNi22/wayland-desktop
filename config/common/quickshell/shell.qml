// wayland-desktop: GNOME-like overview run by quickshell (quickshell -c wayland-desktop, started by wd-style)
// Super: the workspaces with their live windows and a dock, Super again or Super+A: the applications grid, Super a
// third time / Escape / a click on the background: back to the desktop; typing searches the applications at once
// The colors, font, radius and motion follow the active style (~/.config/wayland-desktop/theme.json, copied by wd-style)

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

    function open(next) {
        Hyprland.refreshWorkspaces();
        Hyprland.refreshToplevels();
        themeFile.reload();
        root.shown = true;
        root.mode = next;
    }

    function close() {
        root.mode = "closed";
    }

    // GNOME: overview, then applications, then the desktop again
    function toggle() {
        if (root.mode === "closed")
            root.open("overview");
        else if (root.mode === "overview")
            root.mode = "apps";
        else
            root.close();
    }

    function apps() {
        if (root.mode === "closed")
            root.open("apps");
        else if (root.mode === "apps")
            root.close();
        else
            root.mode = "apps";
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

        PanelWindow {
            id: window

            required property var modelData

            screen: modelData
            visible: root.shown && Hyprland.focusedMonitor !== null && Hyprland.focusedMonitor.name === modelData.name
            color: "transparent"
            exclusionMode: ExclusionMode.Ignore
            WlrLayershell.layer: WlrLayer.Overlay
            WlrLayershell.keyboardFocus: WlrKeyboardFocus.Exclusive
            WlrLayershell.namespace: "wd-overview"

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
                shown: window.visible
                monitor: Hyprland.monitorFor(window.modelData)
                onCloseRequested: root.close()
                onModeRequested: next => root.mode = next
                onHidden: root.shown = false
            }
        }
    }
}

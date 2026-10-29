// wayland-desktop help: every key and control in one card (Super+F1, wd-style help), grouped, filtered as you type;
// Escape, Super+F1 or a click around it closes it (opened by shell.qml on the focused screen, colors of the style)

import QtQuick
import Quickshell
import Quickshell.Wayland

PanelWindow {
    id: help

    required property var theme

    signal closeRequested

    readonly property string query: filter.text.trim().toLowerCase()
    // [keys, what it does]: the keys of a combination joined by "+", choices by " / "
    readonly property var groups: [
        { title: "Overview", items: [
            ["Super", "workspaces and their windows"],
            ["Super Super / Super+A", "applications (type to search)"],
            ["← / → / Enter", "pick a workspace, go there (the last card creates one)"],
            ["drag", "move a window to another workspace"],
            ["middle click", "close a window"],
            ["Escape", "back, then close"],
            ["4 fingers up", "overview (touchpad)"],
        ] },
        { title: "Windows", items: [
            ["Super+Return / Super+Q", "terminal"],
            ["Super+R", "launcher"],
            ["Super+E", "files"],
            ["Super+C", "close the window"],
            ["Super+F", "fullscreen"],
            ["Super+V", "floating"],
            ["Super+J", "split direction"],
            ["Super+arrows", "focus a neighbour (Shift: move the window)"],
            ["Alt+Tab", "next window (Shift: previous)"],
            ["Super+drag / right drag", "move / resize a window"],
        ] },
        { title: "Workspaces", items: [
            ["Super+1 … 0", "go to a workspace (Shift: send the window)"],
            ["Ctrl+Alt+← / →", "previous / next (Shift: with the window)"],
            ["Super+Page Up / Down", "previous / next"],
            ["Super+Tab", "the last workspace"],
            ["Super+S", "scratchpad (Shift: send the window)"],
            ["Super+wheel", "next / previous workspace"],
            ["3 fingers sideways", "switch workspace (touchpad)"],
        ] },
        { title: "Styles", items: [
            ["Super+Shift+W", "style menu"],
            ["Super+Alt+W", "next style"],
            ["Super+Shift+B", "live / still wallpaper"],
            ["Super+Shift+C", "animated / normal cursor"],
            ["sticky note (Miku)", "MIKU MIKU BEAM"],
        ] },
        { title: "Radio", items: [
            ["Super+Shift+M", "show / hide the small radio"],
            ["⏮ ▶ ⏭ ■", "previous, play / pause, next, stop"],
            ["⟳", "loop the track (also while stopped)"],
            ["⤓", "save the track as an mp3, then offline"],
            ["folder", "open ~/Music/wd-radio/<style>: its .mp3 and online.md"],
            ["wd-style radio", "list, add, remove, offline, show, hide"],
        ] },
        { title: "Session", items: [
            ["Super+L", "lock"],
            ["Super+X", "power menu"],
            ["Super+N", "last notification again (Shift: dismiss all)"],
            ["Print", "screenshot of a zone (Shift: the screen)"],
            ["Super+M", "quit Hyprland"],
            ["Super+F1", "this help"],
        ] },
    ]

    color: "transparent"
    exclusionMode: ExclusionMode.Ignore
    WlrLayershell.layer: WlrLayer.Overlay
    WlrLayershell.keyboardFocus: WlrKeyboardFocus.Exclusive
    WlrLayershell.namespace: "wd-help"

    anchors {
        top: true
        bottom: true
        left: true
        right: true
    }

    // the caps of a line of keys: each key, a "/" between two choices
    function caps(text) {
        const list = [];

        String(text).split(" / ").forEach((choice, i) => {
            if (i)
                list.push("/");
            for (const key of choice.split("+"))
                list.push(key);
        });
        return list;
    }

    function matches(item) {
        return !help.query || (item[0] + " " + item[1]).toLowerCase().includes(help.query);
    }

    Rectangle {
        anchors.fill: parent
        color: Qt.alpha(help.theme.bg, 0.55)
        opacity: card.opacity

        MouseArea {
            anchors.fill: parent
            onClicked: help.closeRequested()
        }
    }

    Rectangle {
        id: card

        anchors.centerIn: parent
        width: Math.min(1240, parent.width - 80)
        height: Math.min(parent.height - 80, content.implicitHeight + 56)
        radius: help.theme.radius + 4
        color: Qt.alpha(help.theme.surface, 0.97)
        border.width: 1
        border.color: help.theme.border
        opacity: 0
        scale: 0.96
        Component.onCompleted: {
            opacity = 1;
            scale = 1;
            filter.forceActiveFocus();
        }

        Behavior on opacity {
            NumberAnimation {
                duration: 160
            }
        }

        Behavior on scale {
            NumberAnimation {
                duration: 200
                easing.type: Easing.OutCubic
            }
        }

        // clicks on the card stay on it
        MouseArea {
            anchors.fill: parent
        }

        Column {
            id: content

            anchors.fill: parent
            anchors.margins: 28
            spacing: 18

            Item {
                width: parent.width
                height: 40

                Text {
                    anchors.verticalCenter: parent.verticalCenter
                    text: "wayland-desktop · controls"
                    color: help.theme.fg
                    font.family: help.theme.font
                    font.pixelSize: 22
                    font.bold: true
                }

                Rectangle {
                    anchors.right: parent.right
                    anchors.verticalCenter: parent.verticalCenter
                    width: 320
                    height: 38
                    radius: Math.min(help.theme.radius, 19)
                    color: Qt.alpha(help.theme.bg, 0.6)
                    border.width: filter.activeFocus ? 2 : 1
                    border.color: filter.activeFocus ? help.theme.accent : help.theme.border

                    TextInput {
                        id: filter

                        anchors.fill: parent
                        anchors.leftMargin: 14
                        anchors.rightMargin: 14
                        verticalAlignment: TextInput.AlignVCenter
                        color: help.theme.fg
                        font.family: help.theme.font
                        font.pixelSize: 14
                        clip: true
                        Keys.onPressed: event => {
                            if (event.key === Qt.Key_Escape) {
                                if (filter.text)
                                    filter.text = "";
                                else
                                    help.closeRequested();
                                event.accepted = true;
                            }
                        }
                    }

                    Text {
                        anchors.left: parent.left
                        anchors.leftMargin: 14
                        anchors.verticalCenter: parent.verticalCenter
                        visible: !filter.text
                        text: "Type to filter  ·  Esc to close"
                        color: help.theme.muted
                        font.family: help.theme.font
                        font.pixelSize: 14
                    }
                }
            }

            Text {
                visible: !help.groups.some(group => group.items.some(item => help.matches(item)))
                text: "No key or control matches \u201c" + filter.text + "\u201d"
                color: help.theme.muted
                font.family: help.theme.font
                font.pixelSize: 14
            }

            Flow {
                width: parent.width
                spacing: 26

                Repeater {
                    model: help.groups

                    Column {
                        id: group

                        required property var modelData
                        readonly property var shown: modelData.items.filter(item => help.matches(item))

                        width: (content.width - 52) / 3
                        spacing: 9
                        visible: shown.length > 0

                        Text {
                            text: group.modelData.title.toUpperCase()
                            color: help.theme.accent
                            font.family: help.theme.mono
                            font.pixelSize: 12
                            font.bold: true
                            font.letterSpacing: 1.5
                        }

                        Repeater {
                            model: group.shown

                            Row {
                                id: line

                                required property var modelData

                                width: group.width
                                spacing: 12

                                // the keys: caps joined by "+", choices by "/"
                                Flow {
                                    width: group.width * 0.46
                                    spacing: 4

                                    Repeater {
                                        model: help.caps(line.modelData[0])

                                        Rectangle {
                                            required property string modelData
                                            readonly property bool joiner: modelData === "/"

                                            width: joiner ? 10 : keyText.implicitWidth + 14
                                            height: 24
                                            radius: 6
                                            color: joiner ? "transparent" : Qt.alpha(help.theme.fg, 0.08)
                                            border.width: joiner ? 0 : 1
                                            border.color: Qt.alpha(help.theme.fg, 0.18)

                                            Text {
                                                id: keyText

                                                anchors.centerIn: parent
                                                text: parent.modelData
                                                color: parent.joiner ? help.theme.muted : help.theme.fg
                                                font.family: help.theme.mono
                                                font.pixelSize: 12
                                            }
                                        }
                                    }
                                }

                                Text {
                                    width: group.width * 0.54 - 12
                                    anchors.verticalCenter: parent.verticalCenter
                                    text: line.modelData[1]
                                    color: help.theme.muted
                                    font.family: help.theme.font
                                    font.pixelSize: 13
                                    wrapMode: Text.WordWrap
                                }
                            }
                        }
                    }
                }
            }
        }
    }
}

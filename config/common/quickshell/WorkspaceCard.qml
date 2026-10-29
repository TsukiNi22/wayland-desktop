// wayland-desktop overview: one workspace, its wallpaper and its windows (live copies) at their real place
// click: go to the workspace or focus the window, middle click: close the window, drag: move it to another workspace

import QtQuick
import Quickshell
import Quickshell.Wayland
import Quickshell.Widgets

Item {
    id: card

    required property var host
    required property var theme
    required property int workspaceId
    required property int order

    readonly property var windows: overview.windowsOf(workspaceId)
    readonly property bool active: overview.activeWorkspace === workspaceId
    readonly property bool fresh: windows.length === 0 && !active
    readonly property real ratio: width / overview.screenWidth
    readonly property real originX: overview.monitor ? overview.monitor.x : 0
    readonly property real originY: overview.monitor ? overview.monitor.y : 0
    // staggered entrance: each card starts a little after the previous one
    readonly property real entrance: Math.max(0, Math.min(1, overview.progress * 1.5 - order * 0.1))

    height: width * overview.screenHeight / overview.screenWidth + 30
    opacity: entrance
    scale: (0.82 + 0.18 * entrance) * (cardMouse.containsMouse || drop.containsDrag ? 1.04 : 1)

    Behavior on scale {
        NumberAnimation {
            duration: 200
            easing.type: Easing.OutCubic
        }
    }

    transform: Translate {
        y: (1 - card.entrance) * 50
    }

    // halo of the active workspace
    Rectangle {
        anchors.fill: frame
        anchors.margins: -6
        radius: card.theme.radius + 6
        color: "transparent"
        border.width: 6
        border.color: Qt.alpha(card.theme.accent, 0.25)
        visible: card.active
    }

    ClippingRectangle {
        id: frame

        width: parent.width
        height: parent.height - 30
        radius: card.theme.radius
        color: card.theme.bg
        border.width: card.active || drop.containsDrag ? 2 : 1
        border.color: drop.containsDrag ? card.theme.accent2 : (card.active ? card.theme.accent : Qt.alpha(card.theme.fg, 0.15))

        Image {
            anchors.fill: parent
            source: card.host.wallpaper
            sourceSize.width: 640
            fillMode: Image.PreserveAspectCrop
            asynchronous: true
            opacity: card.fresh ? 0.35 : 0.95
        }

        MouseArea {
            id: cardMouse

            anchors.fill: parent
            hoverEnabled: true
            cursorShape: Qt.PointingHandCursor
            onClicked: card.host.goTo(card.workspaceId)
        }

        Text {
            anchors.centerIn: parent
            visible: card.fresh
            text: "+"
            color: card.theme.fg
            opacity: 0.8
            font.family: card.theme.font
            font.pixelSize: Math.max(24, frame.height * 0.3)
        }

        Repeater {
            model: card.windows

            Item {
                id: thumb

                required property var modelData
                readonly property var ipc: modelData.lastIpcObject
                readonly property bool placed: !!(ipc && ipc.at && ipc.size)

                x: placed ? (ipc.at[0] - card.originX) * card.ratio : frame.width * 0.15
                y: placed ? (ipc.at[1] - card.originY) * card.ratio : frame.height * 0.15
                width: placed ? Math.max(12, ipc.size[0] * card.ratio) : frame.width * 0.7
                height: placed ? Math.max(12, ipc.size[1] * card.ratio) : frame.height * 0.7
                opacity: card.host.dragged === modelData ? 0.35 : 1

                ClippingRectangle {
                    anchors.fill: parent
                    radius: Math.max(3, card.theme.radius * card.ratio * 1.5)
                    color: Qt.alpha(card.theme.surface, 0.95)
                    border.width: thumbMouse.containsMouse ? 2 : 0
                    border.color: card.theme.accent

                    ScreencopyView {
                        id: copy

                        anchors.fill: parent
                        captureSource: card.host.shown ? thumb.modelData.wayland : null
                        live: true
                    }

                    IconImage {
                        anchors.centerIn: parent
                        visible: !copy.hasContent
                        implicitSize: Math.min(parent.width, parent.height) * 0.45
                        source: card.host.iconOf(thumb.modelData)
                    }
                }

                IconImage {
                    anchors.horizontalCenter: parent.horizontalCenter
                    anchors.verticalCenter: parent.bottom
                    visible: copy.hasContent && parent.height > 40
                    implicitSize: Math.min(28, parent.width * 0.4)
                    source: card.host.iconOf(thumb.modelData)
                }

                MouseArea {
                    id: thumbMouse

                    property bool dragging: drag.active
                    // the ghost of the overview follows the mouse from where the window was taken
                    readonly property Item ghostTarget: card.host.ghost

                    anchors.fill: parent
                    acceptedButtons: Qt.LeftButton | Qt.MiddleButton
                    hoverEnabled: true
                    cursorShape: Qt.PointingHandCursor
                    drag.target: ghostTarget
                    drag.threshold: 8

                    onEntered: card.host.hoveredTitle = thumb.modelData.title
                    onExited: card.host.hoveredTitle = ""
                    onPressed: mouse => {
                        const point = thumb.mapToItem(card.host, mouse.x, mouse.y);

                        if (ghostTarget) {
                            ghostTarget.x = point.x - ghostTarget.width / 2;
                            ghostTarget.y = point.y - ghostTarget.height / 2;
                        }
                    }
                    onDraggingChanged: {
                        if (dragging) {
                            card.host.dragged = thumb.modelData;
                            return;
                        }
                        if (ghostTarget)
                            ghostTarget.Drag.drop();
                        card.host.dragged = null;
                    }
                    onClicked: mouse => {
                        if (mouse.button === Qt.MiddleButton)
                            card.host.closeWindow(thumb.modelData);
                        else
                            card.host.focusWindow(thumb.modelData);
                    }
                }
            }
        }
    }

    DropArea {
        id: drop

        anchors.fill: frame
        keys: ["wd-window"]
        onDropped: card.host.moveDragged(card.workspaceId)
    }

    Text {
        anchors.horizontalCenter: parent.horizontalCenter
        anchors.bottom: parent.bottom
        text: card.fresh ? "New workspace" : "Workspace " + card.workspaceId
        color: card.active ? card.theme.accent : card.theme.muted
        font.family: card.theme.font
        font.pixelSize: 13
        font.bold: card.active
    }
}

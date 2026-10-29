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

    // its windows: the same list (and the same live copies) as long as they are the same windows
    readonly property var windowList: overview.windowsOf(workspaceId)
    property var windows: []
    onWindowListChanged: {
        if (windowList.length !== windows.length || windowList.some((w, i) => w !== windows[i]))
            windows = windowList;
    }
    Component.onCompleted: windows = windowList
    readonly property bool active: overview.activeWorkspace === workspaceId
    // picked with the arrows: Enter goes there (the mouse has its own thinner border: a card appearing under a still
    // pointer is not picked)
    readonly property bool picked: overview.picked === order
    readonly property bool fresh: windows.length === 0 && !active
    readonly property real ratio: width / overview.screenWidth
    readonly property real originX: overview.monitor ? overview.monitor.x : 0
    readonly property real originY: overview.monitor ? overview.monitor.y : 0
    // staggered entrance: each card starts a little after the previous one
    readonly property real entrance: Math.max(0, Math.min(1, overview.progress * 1.5 - order * 0.1))

    height: width * overview.screenHeight / overview.screenWidth + 30
    // no zoom on hover (it made the live copies flicker): the border shows it
    opacity: entrance
    scale: 0.82 + 0.18 * entrance

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
        border.width: card.picked || drop.containsDrag ? 3 : (card.active || cardMouse.containsMouse ? 2 : 1)
        border.color: drop.containsDrag ? card.theme.accent2 : (card.picked || card.active || cardMouse.containsMouse
            ? card.theme.accent : Qt.alpha(card.theme.fg, 0.15))

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
                // a window is placed from the corner of its own monitor
                readonly property real fromX: modelData.monitor ? modelData.monitor.x : card.originX
                readonly property real fromY: modelData.monitor ? modelData.monitor.y : card.originY

                x: placed ? (ipc.at[0] - fromX) * card.ratio : frame.width * 0.15
                y: placed ? (ipc.at[1] - fromY) * card.ratio : frame.height * 0.15
                width: placed ? Math.max(12, ipc.size[0] * card.ratio) : frame.width * 0.7
                height: placed ? Math.max(12, ipc.size[1] * card.ratio) : frame.height * 0.7
                // hidden until Hyprland gave its place (no jump), dimmed while dragged
                opacity: !placed ? 0 : (card.host.dragged === modelData ? 0.35 : 1)

                Behavior on opacity {
                    NumberAnimation {
                        duration: 180
                    }
                }

                ClippingRectangle {
                    anchors.fill: parent
                    radius: Math.max(3, card.theme.radius * card.ratio * 1.5)
                    color: Qt.alpha(card.theme.surface, 0.95)
                    border.width: thumbMouse.containsMouse ? 2 : 0
                    border.color: card.theme.accent

                    ScreencopyView {
                        id: copy

                        anchors.fill: parent
                        // one copy per opening (live copies cost and flickered)
                        captureSource: card.host.shown ? thumb.modelData.wayland : null
                        live: false
                        onCaptureSourceChanged: {
                            if (captureSource)
                                captureFrame();
                        }
                        opacity: hasContent ? 1 : 0

                        Behavior on opacity {
                            NumberAnimation {
                                duration: 220
                            }
                        }
                    }

                    IconImage {
                        anchors.centerIn: parent
                        visible: !copy.hasContent
                        // never 0: an icon without size is drawn at the size of its SVG (huge, slow)
                        implicitSize: Math.max(16, Math.min(parent.width, parent.height) * 0.45)
                        source: card.host.iconOf(thumb.modelData)
                    }
                }

                IconImage {
                    anchors.horizontalCenter: parent.horizontalCenter
                    anchors.verticalCenter: parent.bottom
                    visible: copy.hasContent && parent.height > 40
                    implicitSize: Math.max(12, Math.min(28, parent.width * 0.4))
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
        color: card.active || card.picked ? card.theme.accent : card.theme.muted
        font.family: card.theme.font
        font.pixelSize: 13
        font.bold: card.active || card.picked
    }
}

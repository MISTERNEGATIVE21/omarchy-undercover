import QtMultimedia
import QtQuick
import Quickshell
import Quickshell.Wayland

// Wayland Overlay-layer video surface for Omarchy Undercover macOS Aerial Screen Saver.
// Sits above all windows on WlrLayer.Overlay.
// When inactive, the window is unmapped and transparent with zero decoding overhead.
// When active, the aerial video fades in smoothly over black.
// Any real keypress or pointer movement dismisses the screensaver back to the desktop.
PanelWindow {
    id: surface

    required property var modelData
    property var owner: null
    property string clipUrl: ""
    property bool active: false
    readonly property bool shouldPlay: active && clipUrl !== ""
    property int pendingSeek: -1
    property bool primed: false
    property bool canDismiss: false
    property bool mapped: false

    screen: modelData
    visible: surface.mapped
    color: surface.active ? "black" : "transparent"
    updatesEnabled: true

    WlrLayershell.namespace: "omarchy-mac-screensaver"
    WlrLayershell.layer: WlrLayer.Overlay
    WlrLayershell.keyboardFocus: surface.active ? WlrKeyboardFocus.Exclusive : WlrKeyboardFocus.None
    exclusionMode: ExclusionMode.Ignore

    anchors {
        top: true
        bottom: true
        left: true
        right: true
    }

    Timer {
        id: dismissGraceTimer
        interval: 800
        repeat: false
        onTriggered: {
            surface.canDismiss = true;
        }
    }

    function sync() {
        if (shouldPlay) {
            var src = clipUrl;
            if (src && !src.startsWith("file://") && !src.startsWith("http://") && !src.startsWith("https://")) {
                src = "file://" + src;
            }
            if (player.source.toString() !== src && player.source.toString() !== clipUrl) {
                player.source = src;
            }
            if (player.playbackState !== MediaPlayer.PlayingState) {
                player.play();
            }
        } else if (player.playbackState === MediaPlayer.PlayingState) {
            player.pause();
        }
    }

    function requestDismiss() {
        if (surface.owner && typeof surface.owner.dismissScreensaver === "function") {
            surface.owner.dismissScreensaver();
        }
    }

    onClipUrlChanged: {
        if (clipUrl === "") {
            player.stop();
            player.source = "";
        } else if (active) {
            var src = clipUrl;
            if (src && !src.startsWith("file://") && !src.startsWith("http://") && !src.startsWith("https://")) {
                src = "file://" + src;
            }
            player.source = src;
            sync();
        }
    }

    onActiveChanged: {
        surface.primed = false;
        surface.canDismiss = false;
        dismissGraceTimer.stop();
        if (surface.active) {
            surface.mapped = true;
            unmapTimer.stop();
            dismissGraceTimer.start();
            sync();
        } else {
            sync();
            unmapTimer.restart();
        }
    }

    Component.onCompleted: {
        if (surface.active) {
            sync();
        }
    }

    Component.onDestruction: {
        player.stop();
        player.source = "";
    }

    Timer {
        id: unmapTimer
        interval: 260
        onTriggered: {
            if (!surface.active) {
                surface.mapped = false;
                player.stop();
            }
        }
    }

    Item {
        id: fadeRoot
        anchors.fill: parent
        opacity: surface.active ? 1.0 : 0.0

        Behavior on opacity {
            NumberAnimation {
                duration: 250
                easing.type: Easing.InOutQuad
            }
        }

        VideoOutput {
            id: videoOut
            anchors.fill: parent
            fillMode: VideoOutput.PreserveAspectCrop
        }
    }

    MediaPlayer {
        id: player
        videoOutput: videoOut
        loops: MediaPlayer.Infinite
        audioOutput: null // Always mute screensaver audio

        onSeekableChanged: {
            if (player.seekable && surface.pendingSeek >= 0) {
                player.position = surface.pendingSeek;
                surface.pendingSeek = -1;
            }
        }

        onErrorOccurred: function(err, str) {
            if (err !== MediaPlayer.NoError) {
                console.warn("omarchy-undercover: screensaver player error:", str);
                if (surface.active) {
                    surface.requestDismiss();
                }
            }
        }
    }

    // Input catcher: keypresses or pointer movements dismiss the screensaver
    Item {
        anchors.fill: parent
        visible: surface.active
        focus: surface.active

        Keys.onPressed: function(event) {
            if (surface.canDismiss) {
                surface.requestDismiss();
                event.accepted = true;
            }
        }

        MouseArea {
            anchors.fill: parent
            hoverEnabled: true
            property real lastX: 0
            property real lastY: 0

            onPositionChanged: function(mouse) {
                if (!surface.canDismiss) {
                    lastX = mouse.x;
                    lastY = mouse.y;
                    return;
                }
                if (!surface.primed) {
                    surface.primed = true;
                    lastX = mouse.x;
                    lastY = mouse.y;
                    return;
                }
                // 15px jitter filter to avoid false triggers
                if (Math.abs(mouse.x - lastX) > 15 || Math.abs(mouse.y - lastY) > 15) {
                    surface.requestDismiss();
                }
                lastX = mouse.x;
                lastY = mouse.y;
            }

            onPressed: {
                if (surface.canDismiss) surface.requestDismiss();
            }
            onClicked: {
                if (surface.canDismiss) surface.requestDismiss();
            }
        }
    }
}

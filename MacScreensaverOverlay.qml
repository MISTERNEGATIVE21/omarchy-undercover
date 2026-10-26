import QtMultimedia
import QtQuick
import QtQuick.Layouts
import Quickshell
import Quickshell.Wayland

// Wayland Overlay-layer video surface for Omarchy Undercover macOS Aerial Screen Saver.
// Sits above windows on WlrLayer.Overlay as a visual screen saver.
// When active, the aerial video loops continuously.
// Any user interaction (moving mouse, clicking, pressing any key) immediately wakes the display
// and dismisses the visual screensaver back to the active desktop session.
// True session locking and PAM authentication are strictly owned by omarchy.lock (ext-session-lock-v1).
PanelWindow {
    id: surface

    property var owner: null
    property string clipUrl: ""
    property bool active: false
    property bool isPreview: false
    property bool armed: false

    Timer {
        id: armingTimer
        interval: 800
        repeat: false
        onTriggered: {
            surface.armed = true;
        }
    }

    readonly property bool shouldPlay: active && clipUrl !== ""
    readonly property string effectiveSource: {
        var s = surface.clipUrl;
        if (!s || s === "") return "";
        if (!s.startsWith("file://") && !s.startsWith("http://") && !s.startsWith("https://")) {
            return "file://" + s;
        }
        return s;
    }
    property string currentTime: ""
    property string currentDate: ""

    visible: surface.active
    color: "#000000"
    updatesEnabled: true

    WlrLayershell.namespace: "omarchy-mac-screensaver"
    WlrLayershell.layer: WlrLayer.Overlay
    WlrLayershell.keyboardFocus: surface.active ? WlrKeyboardFocus.OnDemand : WlrKeyboardFocus.None
    exclusionMode: ExclusionMode.Ignore

    anchors {
        top: true
        bottom: true
        left: true
        right: true
    }

    function updateClock() {
        var d = new Date();
        var h = d.getHours();
        var m = d.getMinutes();
        var mStr = m < 10 ? "0" + m : m;
        surface.currentTime = h + ":" + mStr;

        var days = ["Sunday", "Monday", "Tuesday", "Wednesday", "Thursday", "Friday", "Saturday"];
        var months = ["January", "February", "March", "April", "May", "June", "July", "August", "September", "October", "November", "December"];
        surface.currentDate = days[d.getDay()] + ", " + months[d.getMonth()] + " " + d.getDate();
    }

    Timer {
        interval: 1000
        running: surface.active
        repeat: true
        triggeredOnStart: true
        onTriggered: surface.updateClock()
    }

    function sync() {
        if (shouldPlay) {
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
        } else if (active) {
            sync();
        }
    }

    onActiveChanged: {
        if (surface.active) {
            surface.armed = false;
            armingTimer.restart();
            inputArea.primed = false;
            surface.updateClock();
            player.play();
            sync();
            inputCatcher.forceActiveFocus();
        } else {
            surface.armed = false;
            armingTimer.stop();
            inputArea.primed = false;
            player.stop();
        }
    }

    Component.onCompleted: {
        surface.updateClock();
        if (surface.active) {
            surface.armed = false;
            armingTimer.restart();
            inputArea.primed = false;
            player.play();
            sync();
            inputCatcher.forceActiveFocus();
        }
    }

    Component.onDestruction: {
        player.stop();
    }

    // Instant Backdrop: Authentic macOS Tahoe HDR wallpaper (Prevents black flash while video decodes)
    Image {
        id: bgFallback
        anchors.fill: parent
        fillMode: Image.PreserveAspectCrop
        source: "file://" + (surface.owner ? surface.owner.pluginDir : "") + "/assets/wallpapers/macOS-Tahoe-Dark.jpg"
        asynchronous: true
        smooth: true
    }

    // Video Layer: Loops continuously
    VideoOutput {
        id: videoOut
        anchors.fill: parent
        fillMode: VideoOutput.PreserveAspectCrop
        visible: player.playbackState === MediaPlayer.PlayingState
    }

    MediaPlayer {
        id: player
        videoOutput: videoOut
        loops: MediaPlayer.Infinite
        audioOutput: null // Always mute screensaver audio
        source: surface.shouldPlay ? surface.effectiveSource : ""

        onMediaStatusChanged: {
            if (surface.shouldPlay) {
                if (mediaStatus === MediaPlayer.LoadedMedia || mediaStatus === MediaPlayer.BufferedMedia) {
                    if (player.playbackState !== MediaPlayer.PlayingState) {
                        player.play();
                    }
                } else if (mediaStatus === MediaPlayer.EndOfMedia) {
                    if (player.loops !== MediaPlayer.Infinite) {
                        player.setPosition(0);
                        player.play();
                    }
                }
            }
        }

        onPlaybackStateChanged: {
            if (surface.shouldPlay && playbackState === MediaPlayer.StoppedState && player.error === MediaPlayer.NoError) {
                retryTimer.restart();
            }
        }

        onErrorOccurred: function(err, str) {
            // Suppress infinite reload loop on missing video and let the authentic wallpaper backdrop display
            if (err !== MediaPlayer.ResourceError && err !== MediaPlayer.FormatError) {
                if (surface.shouldPlay) retryTimer.restart();
            }
        }
    }

    Timer {
        id: retryTimer
        interval: 1000
        repeat: false
        onTriggered: {
            if (surface.shouldPlay && surface.effectiveSource !== "") {
                var src = surface.effectiveSource;
                player.source = "";
                player.source = src;
                player.play();
            }
        }
    }

    Timer {
        id: playWatchdog
        interval: 3000
        running: surface.active && player.error === MediaPlayer.NoError
        repeat: true
        onTriggered: {
            if (surface.shouldPlay && player.playbackState !== MediaPlayer.PlayingState) {
                player.play();
            }
        }
    }

    // Top Clock & Date Section (Authentic macOS Sonoma / Sequoia / Tahoe Aerial screensaver style)
    ColumnLayout {
        id: clockCol
        anchors.top: parent.top
        anchors.topMargin: surface.height * 0.12
        anchors.horizontalCenter: parent.horizontalCenter
        spacing: 6
        visible: surface.active

        Text {
            Layout.alignment: Qt.AlignHCenter
            text: surface.currentDate
            font.family: "SF Pro Display, -apple-system, sans-serif"
            font.pixelSize: 22
            font.weight: Font.Normal
            color: "#f5f5f7"
            style: Text.Raised
            styleColor: Qt.rgba(0, 0, 0, 0.45)
        }

        Text {
            Layout.alignment: Qt.AlignHCenter
            text: surface.currentTime
            font.family: "SF Pro Display, -apple-system, sans-serif"
            font.pixelSize: 88
            font.weight: Font.Thin
            color: "#ffffff"
            style: Text.Raised
            styleColor: Qt.rgba(0, 0, 0, 0.45)
        }
    }

    // Preview Mode Exit Button (Top Right)
    Rectangle {
        visible: surface.active && surface.isPreview
        anchors.top: parent.top
        anchors.right: parent.right
        anchors.margins: 28
        implicitWidth: 110
        implicitHeight: 30
        radius: 15
        color: Qt.rgba(0, 0, 0, 0.45)
        border.color: Qt.rgba(255, 255, 255, 0.3)
        border.width: 1

        Text {
            anchors.centerIn: parent
            text: "Exit Preview"
            font.family: "SF Pro Text, -apple-system, sans-serif"
            font.pixelSize: 12
            font.weight: Font.DemiBold
            color: "#ffffff"
        }

        MouseArea {
            anchors.fill: parent
            cursorShape: Qt.PointingHandCursor
            onClicked: surface.requestDismiss()
        }
    }

    // Screensaver Unobtrusive Hint Pill
    Rectangle {
        anchors.bottom: parent.bottom
        anchors.bottomMargin: 40
        anchors.horizontalCenter: parent.horizontalCenter
        implicitWidth: hintText.implicitWidth + 28
        implicitHeight: 32
        radius: 16
        color: Qt.rgba(0, 0, 0, 0.45)
        border.color: Qt.rgba(255, 255, 255, 0.2)
        border.width: 1
        visible: surface.active

        Text {
            id: hintText
            anchors.centerIn: parent
            text: surface.isPreview ? "Press any key to exit preview" : "Move mouse or press any key to wake"
            font.family: "SF Pro Text, -apple-system, sans-serif"
            font.pixelSize: 12
            font.weight: Font.Medium
            color: Qt.rgba(255, 255, 255, 0.85)
        }
    }

    // Input Catcher: Any user activity dismisses visual screensaver to active desktop.
    // True session locking is enforced compositor-side by omarchy.lock (ext-session-lock-v1).
    Item {
        id: inputCatcher
        anchors.fill: parent
        enabled: surface.active
        visible: surface.active
        focus: surface.active

        Keys.onPressed: function(event) {
            if (surface.armed) {
                surface.requestDismiss();
                event.accepted = true;
            }
        }

        MouseArea {
            id: inputArea
            anchors.fill: parent
            hoverEnabled: true
            property real lastX: 0
            property real lastY: 0
            property bool primed: false

            onPositionChanged: function(mouse) {
                if (!surface.active) return;
                if (!primed) {
                    primed = true;
                    lastX = mouse.x;
                    lastY = mouse.y;
                    return;
                }
                // Dismiss only once armed (past 800ms grace period) and motion exceeds threshold (25px)
                if (surface.armed && (Math.abs(mouse.x - lastX) > 25 || Math.abs(mouse.y - lastY) > 25)) {
                    surface.requestDismiss();
                }
                lastX = mouse.x;
                lastY = mouse.y;
            }

            onPressed: {
                if (surface.armed) {
                    surface.requestDismiss();
                }
            }
        }
    }
}

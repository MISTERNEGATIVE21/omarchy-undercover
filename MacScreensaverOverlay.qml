import QtMultimedia
import QtQuick
import QtQuick.Layouts
import Quickshell
import Quickshell.Wayland
import Quickshell.Services.Pam

// Wayland Overlay-layer video surface for Omarchy Undercover macOS Aerial Screen Saver.
// Sits above all windows on WlrLayer.Overlay.
// When active, the aerial video loops continuously.
// When user moves mouse or presses a key, the macOS lock screen interface appears OVER the playing video.
// The video keeps playing continuously until the correct password is typed and verified via PAM.
PanelWindow {
    id: surface

    property var owner: null
    property string clipUrl: ""
    property bool active: false
    property bool isPreview: false
    property bool locked: false
    property bool startLocked: false

    readonly property bool shouldPlay: active && clipUrl !== ""
    readonly property string effectiveSource: {
        var s = surface.clipUrl;
        if (!s || s === "") return "";
        if (!s.startsWith("file://") && !s.startsWith("http://") && !s.startsWith("https://")) {
            return "file://" + s;
        }
        return s;
    }
    property string pendingPassword: ""
    property bool authenticating: false
    property string failureMessage: ""
    property string currentTime: ""
    property string currentDate: ""

    visible: surface.active
    color: "#000000"
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
        surface.failureMessage = "";
        surface.pendingPassword = "";
        surface.authenticating = false;
        surface.locked = false;
        if (surface.owner && typeof surface.owner.dismissScreensaver === "function") {
            surface.owner.dismissScreensaver();
        }
    }

    function respondToPasswordPrompt() {
        if (!surface.authenticating || !passwordPam.active || !passwordPam.responseRequired) return;
        passwordPam.respond(surface.pendingPassword);
    }

    function submitPassword() {
        var p = pwdInput.text;
        if (surface.authenticating || p.length === 0) return;

        surface.failureMessage = "";
        surface.pendingPassword = p;
        surface.authenticating = true;

        if (!passwordPam.start()) {
            handleAuthFailure();
            return;
        }

        Qt.callLater(surface.respondToPasswordPrompt);
    }

    function handleAuthFailure() {
        surface.authenticating = false;
        surface.pendingPassword = "";
        pwdInput.text = "";
        surface.failureMessage = "Incorrect Password";
        shakeAnim.start();
        pwdInput.forceActiveFocus();
    }

    function handleAuthSuccess() {
        surface.authenticating = false;
        surface.pendingPassword = "";
        pwdInput.text = "";
        surface.failureMessage = "";
        surface.requestDismiss();
    }

    PamContext {
        id: passwordPam
        config: "omarchy-lock-password"
        user: Quickshell.env("USER")

        onResponseRequiredChanged: surface.respondToPasswordPrompt()
        onPamMessage: surface.respondToPasswordPrompt()

        onCompleted: function(result) {
            if (result === PamResult.Success) {
                surface.handleAuthSuccess();
            } else {
                surface.handleAuthFailure();
            }
        }

        onError: function(err) {
            surface.handleAuthFailure();
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
            surface.failureMessage = "";
            surface.pendingPassword = "";
            surface.authenticating = false;
            surface.locked = surface.startLocked;
            surface.updateClock();
            player.play();
            sync();
            if (surface.locked) {
                Qt.callLater(function() { pwdInput.forceActiveFocus(); });
            }
        } else {
            surface.locked = false;
            player.stop();
        }
    }

    Component.onCompleted: {
        surface.updateClock();
        if (surface.active) {
            surface.locked = surface.startLocked;
            player.play();
            sync();
            if (surface.locked) {
                Qt.callLater(function() { pwdInput.forceActiveFocus(); });
            }
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
        source: surface.effectiveSource

        onMediaStatusChanged: {
            if (surface.shouldPlay) {
                if (mediaStatus === MediaPlayer.LoadedMedia || mediaStatus === MediaPlayer.BufferedMedia) {
                    if (player.playbackState !== MediaPlayer.PlayingState) {
                        player.play();
                    }
                } else if (mediaStatus === MediaPlayer.EndOfMedia) {
                    player.setPosition(0);
                    player.play();
                }
            }
        }

        onPlaybackStateChanged: {
            if (surface.shouldPlay && playbackState === MediaPlayer.StoppedState) {
                retryTimer.restart();
            }
        }

        onErrorOccurred: function(err, str) {
            console.warn("omarchy-undercover: screensaver player error: " + err + " - " + str);
            retryTimer.restart();
        }
    }

    Timer {
        id: retryTimer
        interval: 350
        repeat: false
        onTriggered: {
            if (surface.shouldPlay) {
                var src = surface.effectiveSource;
                player.source = "";
                player.source = src;
                player.play();
            }
        }
    }

    Timer {
        id: playWatchdog
        interval: 1500
        running: surface.active
        repeat: true
        onTriggered: {
            if (surface.shouldPlay && player.playbackState !== MediaPlayer.PlayingState) {
                player.play();
            }
        }
    }

    // Input Catcher (Screensaver Mode): Transitions to Lock Screen on any mouse move or keypress
    Item {
        id: inputCatcher
        anchors.fill: parent
        enabled: surface.active && !surface.locked
        visible: surface.active && !surface.locked
        focus: surface.active && !surface.locked

        Keys.onPressed: function(event) {
            if (surface.isPreview && (event.key === Qt.Key_Escape)) {
                surface.requestDismiss();
                event.accepted = true;
                return;
            }
            if (!surface.locked) {
                surface.locked = true;
                pwdInput.forceActiveFocus();
            }
            event.accepted = true;
        }

        MouseArea {
            anchors.fill: parent
            hoverEnabled: true
            property real lastX: 0
            property real lastY: 0
            property bool primed: false

            onPositionChanged: function(mouse) {
                if (!primed) {
                    primed = true;
                    lastX = mouse.x;
                    lastY = mouse.y;
                    return;
                }
                // 15px motion threshold
                if (Math.abs(mouse.x - lastX) > 15 || Math.abs(mouse.y - lastY) > 15) {
                    if (!surface.locked) {
                        surface.locked = true;
                        pwdInput.forceActiveFocus();
                    }
                }
                lastX = mouse.x;
                lastY = mouse.y;
            }

            onPressed: {
                if (!surface.locked) {
                    surface.locked = true;
                    pwdInput.forceActiveFocus();
                }
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

            Text {
                id: hintText
                anchors.centerIn: parent
                text: surface.isPreview ? "Press any key to unlock • Esc to exit preview" : "Press any key or click to unlock"
                font.family: "SF Pro Text, -apple-system, sans-serif"
                font.pixelSize: 12
                font.weight: Font.Medium
                color: Qt.rgba(255, 255, 255, 0.85)
            }
        }
    }

    // macOS Lock Screen Overlay (Plays OVER the running video!)
    Rectangle {
        id: lockOverlay
        anchors.fill: parent
        visible: surface.active && opacity > 0.01
        opacity: surface.locked ? 1.0 : 0.0
        color: Qt.rgba(0, 0, 0, 0.42) // Frosted dark vignette over the aerial video

        Behavior on opacity {
            NumberAnimation {
                duration: 350
                easing.type: Easing.OutCubic
            }
        }

        // Click anywhere to focus password field
        MouseArea {
            anchors.fill: parent
            onClicked: pwdInput.forceActiveFocus()
        }

        // Preview Mode Exit Button (Top Right)
        Rectangle {
            visible: surface.isPreview
            anchors.top: parent.top
            anchors.right: parent.right
            anchors.margins: 28
            implicitWidth: 110; implicitHeight: 30; radius: 15
            color: Qt.rgba(255, 255, 255, 0.2)
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

        // Top Clock & Date Section (Authentic macOS Sonoma / Sequoia / Tahoe lock style)
        ColumnLayout {
            id: clockCol
            anchors.top: parent.top
            anchors.topMargin: surface.height * 0.12
            anchors.horizontalCenter: parent.horizontalCenter
            spacing: 6

            transform: Translate {
                y: surface.locked ? 0 : -20
                Behavior on y {
                    NumberAnimation {
                        duration: 380
                        easing.type: Easing.OutCubic
                    }
                }
            }

            Text {
                Layout.alignment: Qt.AlignHCenter
                text: surface.currentDate
                font.family: "SF Pro Display, -apple-system, sans-serif"
                font.pixelSize: 22
                font.weight: Font.Normal
                color: "#f5f5f7"
                style: Text.Raised
                styleColor: Qt.rgba(0, 0, 0, 0.4)
            }

            Text {
                Layout.alignment: Qt.AlignHCenter
                text: surface.currentTime
                font.family: "SF Pro Display, -apple-system, sans-serif"
                font.pixelSize: 88
                font.weight: Font.Thin
                color: "#ffffff"
                style: Text.Raised
                styleColor: Qt.rgba(0, 0, 0, 0.4)
            }
        }

        // Center User Profile & Password Capsule
        Item {
            id: userCard
            anchors.centerIn: parent
            width: 320
            height: 260

            transform: Translate {
                y: surface.locked ? 0 : 25
                Behavior on y {
                    NumberAnimation {
                        duration: 380
                        easing.type: Easing.OutCubic
                    }
                }
            }

            ColumnLayout {
                anchors.fill: parent
                spacing: 14

                // User Avatar Circle
                Rectangle {
                    Layout.alignment: Qt.AlignHCenter
                    width: 76; height: 76; radius: 38
                    color: Qt.rgba(255, 255, 255, 0.22)
                    border.color: Qt.rgba(255, 255, 255, 0.45)
                    border.width: 1.5

                    Text {
                        anchors.centerIn: parent
                        text: "👤"
                        font.pixelSize: 36
                    }
                }

                // Username
                Text {
                    Layout.alignment: Qt.AlignHCenter
                    text: Quickshell.env("USER") || "User"
                    font.family: "SF Pro Display, -apple-system, sans-serif"
                    font.pixelSize: 18
                    font.weight: Font.DemiBold
                    color: "#ffffff"
                    style: Text.Raised
                    styleColor: Qt.rgba(0, 0, 0, 0.4)
                }

                // Password Input Capsule with Shake Animation
                Item {
                    id: pwdWrapper
                    Layout.alignment: Qt.AlignHCenter
                    width: 240
                    height: 36

                    SequentialAnimation {
                        id: shakeAnim
                        NumberAnimation { target: pwdContainer; property: "x"; to: -16; duration: 45; easing.type: Easing.OutQuad }
                        NumberAnimation { target: pwdContainer; property: "x"; to: 16; duration: 45; easing.type: Easing.InOutQuad }
                        NumberAnimation { target: pwdContainer; property: "x"; to: -12; duration: 45; easing.type: Easing.InOutQuad }
                        NumberAnimation { target: pwdContainer; property: "x"; to: 12; duration: 45; easing.type: Easing.InOutQuad }
                        NumberAnimation { target: pwdContainer; property: "x"; to: -6; duration: 45; easing.type: Easing.InOutQuad }
                        NumberAnimation { target: pwdContainer; property: "x"; to: 6; duration: 45; easing.type: Easing.InOutQuad }
                        NumberAnimation { target: pwdContainer; property: "x"; to: 0; duration: 45; easing.type: Easing.OutQuad }
                    }

                    Rectangle {
                        id: pwdContainer
                        width: parent.width
                        height: parent.height
                        x: 0; y: 0
                        radius: 18
                        color: Qt.rgba(0, 0, 0, 0.45)
                        border.color: pwdInput.activeFocus ? "#3b82f6" : Qt.rgba(255, 255, 255, 0.4)
                        border.width: pwdInput.activeFocus ? 1.5 : 1

                        RowLayout {
                            anchors.fill: parent
                            anchors.leftMargin: 14
                            anchors.rightMargin: 6
                            spacing: 6

                            TextInput {
                                id: pwdInput
                                Layout.fillWidth: true
                                verticalAlignment: TextInput.AlignVCenter
                                font.family: "SF Pro Text, -apple-system, sans-serif"
                                font.pixelSize: 13
                                color: "#ffffff"
                                echoMode: TextInput.Password
                                passwordCharacter: "•"
                                clip: true
                                selectByMouse: true
                                focus: surface.locked

                                Text {
                                    visible: !pwdInput.text && !pwdInput.inputMethodComposing
                                    text: "Enter Password"
                                    anchors.fill: parent
                                    verticalAlignment: Text.AlignVCenter
                                    font.family: "SF Pro Text, -apple-system, sans-serif"
                                    font.pixelSize: 12
                                    color: Qt.rgba(255, 255, 255, 0.5)
                                }

                                Keys.onReturnPressed: surface.submitPassword()
                                Keys.onEnterPressed: surface.submitPassword()
                                Keys.onEscapePressed: {
                                    if (surface.isPreview) {
                                        surface.requestDismiss();
                                    } else {
                                        surface.locked = false;
                                        surface.failureMessage = "";
                                        surface.pendingPassword = "";
                                        pwdInput.text = "";
                                    }
                                }
                            }

                            // Submit Arrow Button
                            Rectangle {
                                width: 24; height: 24; radius: 12
                                color: pwdInput.text.length > 0 ? (surface.authenticating ? Qt.rgba(255, 255, 255, 0.2) : "#ffffff") : "transparent"
                                visible: pwdInput.text.length > 0

                                Behavior on color { ColorAnimation { duration: 150 } }

                                Text {
                                    anchors.centerIn: parent
                                    text: surface.authenticating ? "…" : "➜"
                                    font.pixelSize: 12
                                    font.weight: Font.Bold
                                    color: surface.authenticating ? "#ffffff" : "#1c1c1e"
                                }

                                MouseArea {
                                    anchors.fill: parent
                                    cursorShape: Qt.PointingHandCursor
                                    onClicked: surface.submitPassword()
                                }
                            }
                        }
                    }
                }

                // Failure message
                Text {
                    Layout.alignment: Qt.AlignHCenter
                    visible: surface.failureMessage !== ""
                    text: surface.failureMessage
                    font.family: "SF Pro Text, -apple-system, sans-serif"
                    font.pixelSize: 11
                    font.weight: Font.Medium
                    color: "#ff6961"
                }
            }
        }
    }
}

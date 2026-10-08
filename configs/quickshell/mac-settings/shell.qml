import Quickshell
import Quickshell.Wayland
import Quickshell.Hyprland
import Quickshell.Io
import QtQuick
import QtQuick.Layouts
import QtQuick.Controls
import QtMultimedia

ShellRoot {
  FloatingWindow {
    id: settingsWin
    title: "System Settings"

    property bool isMaximized: false
    readonly property real normalWidth: Math.min(960, (Quickshell.screens[0] ? Quickshell.screens[0].width - 40 : 960))
    readonly property real normalHeight: Math.min(620, (Quickshell.screens[0] ? Quickshell.screens[0].height - 60 : 620))

    implicitWidth: isMaximized ? (Quickshell.screens[0] ? Quickshell.screens[0].width - 20 : 1200) : normalWidth
    implicitHeight: isMaximized ? (Quickshell.screens[0] ? Quickshell.screens[0].height - 60 : 800) : normalHeight
    minimumSize: Qt.size(Math.min(760, (Quickshell.screens[0] ? Quickshell.screens[0].width - 40 : 760)), Math.min(480, (Quickshell.screens[0] ? Quickshell.screens[0].height - 60 : 480)))
    color: "transparent"

    Component.onCompleted: {
      raiseTimer.start()
      screensaverStatusProc.running = true
    }

    Timer {
      id: raiseTimer
      interval: 60
      running: true
      repeat: false
      onTriggered: {
        Quickshell.execDetached([
          "bash", "-c",
          "hyprctl dispatch 'hl.dsp.focus({ window = \"title:^System Settings$\" })' 2>/dev/null || hyprctl dispatch focuswindow 'title:^System Settings$' 2>/dev/null || true; " +
          "hyprctl dispatch 'hl.dsp.window.alter_zorder({ mode = \"top\" })' 2>/dev/null || hyprctl dispatch alterzorder top 2>/dev/null || true; " +
          "hyprctl dispatch 'hl.dsp.window.bring_to_top()' 2>/dev/null || hyprctl dispatch bringactivetotop 2>/dev/null || true"
        ])
      }
    }

    property string homeDir: Quickshell.env("HOME")
    property string userName: Quickshell.env("USER") || "User"
    property bool isDark: true
    property bool isTransparent: true
    property string activeAccent: "007aff"
    property int currentCategory: 0
    property string searchQuery: ""
    property real sidebarWidth: 250

    // Authentic macOS Sequoia Dynamic Accent Colors
    readonly property color accentColor: {
      if (activeAccent && activeAccent.length === 6) {
        return "#" + activeAccent
      }
      return isDark ? "#0a84ff" : "#007aff"
    }

    readonly property color accentTextColor: {
      var c = settingsWin.accentColor
      var lum = 0.299 * c.r + 0.587 * c.g + 0.114 * c.b
      return lum > 0.55 ? "#000000" : "#ffffff"
    }

    readonly property color windowBg: isDark
      ? (isTransparent ? Qt.rgba(0.12, 0.13, 0.16, 0.96) : "#1c1d22")
      : (isTransparent ? Qt.rgba(0.95, 0.95, 0.97, 0.96) : "#f1f1f4")
    readonly property color sidebarBg: isDark
      ? Qt.rgba(0, 0, 0, 0.28)
      : (isTransparent ? Qt.rgba(0.90, 0.91, 0.94, 0.70) : "#e8e9ed")
    readonly property color cardBg: isDark
      ? Qt.rgba(1, 1, 1, 0.08)
      : "#ffffff"
    readonly property color cardBorder: isDark
      ? Qt.rgba(1, 1, 1, 0.12)
      : Qt.rgba(0, 0, 0, 0.11)
    readonly property color textPrimary: isDark ? "#ffffff" : "#1d1d1f"
    readonly property color textSecondary: isDark ? Qt.rgba(1, 1, 1, 0.78) : "#515154"
    readonly property color separatorColor: isDark ? Qt.rgba(1, 1, 1, 0.10) : Qt.rgba(0, 0, 0, 0.10)

    property int volumeLevel: 75
    property int brightnessLevel: 80
    property bool wifiEnabled: true
    property string wifiSsid: "Connected"
    property bool btEnabled: true
    property bool autohideActive: false
    property int dockSize: 52
    property int maxDockItems: 24
    property int dockTransparency: 76
    property string dockPosition: "bottom"
    property int windowGaps: 8
    property int windowRounding: 10
    property string currentDisguise: "mac-dark"
    property string currentWallpaper: "macOS-Tahoe-Dark.jpg"
    property string pluginDir: Quickshell.env("OMARCHY_PLUGIN_DIR") || (settingsWin.homeDir + "/.config/omarchy/plugins/omarchy-undercover")

    function runCmd(cmd) {
      Quickshell.execDetached(["bash", "-c", cmd])
    }

    function saveSetting(key, val) {
      var cmd = "mkdir -p " + settingsWin.pluginDir + " && " +
                "touch " + settingsWin.pluginDir + "/settings.conf && " +
                "if grep -q '^" + key + "=' " + settingsWin.pluginDir + "/settings.conf; then " +
                "  sed -i 's/^" + key + "=.*/" + key + "=" + val + "/' " + settingsWin.pluginDir + "/settings.conf; " +
                "else " +
                "  echo '" + key + "=" + val + "' >> " + settingsWin.pluginDir + "/settings.conf; " +
                "fi"
      runCmd(cmd)
    }

    // Dock Items Arrangement & Pinned Apps Management
    property var defaultDockApps: [
      { id: "finder", name: "Finder", icon: "finder.svg" },
      { id: "launchpad", name: "Launchpad", icon: "launchpad.svg" },
      { id: "safari", name: "Safari", icon: "safari.svg" },
      { id: "messages", name: "Messages", icon: "messages.svg" },
      { id: "mail", name: "Mail", icon: "mail.svg" },
      { id: "maps", name: "Maps", icon: "maps.svg" },
      { id: "photos", name: "Photos", icon: "photos.svg" },
      { id: "calendar", name: "Calendar", icon: "calendar.svg" },
      { id: "notes", name: "Notes", icon: "notes.svg" },
      { id: "reminders", name: "Reminders", icon: "reminders.svg" },
      { id: "music", name: "Music", icon: "music.svg" },
      { id: "antigravity", name: "Antigravity IDE", icon: "antigravity-ide.svg" },
      { id: "terminal", name: "Terminal", icon: "terminal.svg" },
      { id: "settings", name: "System Settings", icon: "settings.svg" },
      { id: "appstore", name: "App Store", icon: "appstore.svg" }
    ]

    property var dockAppsList: [
      { id: "finder", name: "Finder", icon: "finder.svg" },
      { id: "launchpad", name: "Launchpad", icon: "launchpad.svg" },
      { id: "safari", name: "Safari", icon: "safari.svg" },
      { id: "messages", name: "Messages", icon: "messages.svg" },
      { id: "mail", name: "Mail", icon: "mail.svg" },
      { id: "maps", name: "Maps", icon: "maps.svg" },
      { id: "photos", name: "Photos", icon: "photos.svg" },
      { id: "calendar", name: "Calendar", icon: "calendar.svg" },
      { id: "notes", name: "Notes", icon: "notes.svg" },
      { id: "reminders", name: "Reminders", icon: "reminders.svg" },
      { id: "music", name: "Music", icon: "music.svg" },
      { id: "antigravity", name: "Antigravity IDE", icon: "antigravity-ide.svg" },
      { id: "terminal", name: "Terminal", icon: "terminal.svg" },
      { id: "settings", name: "System Settings", icon: "settings.svg" },
      { id: "appstore", name: "App Store", icon: "appstore.svg" }
    ]
    property var dockPinsState: ({})

    function loadDockDefaults(jsonStr) {
      try {
        var d = JSON.parse(jsonStr)
        if (d && d.mac_pins) dockPinsState = d.mac_pins
        if (d && d.mac_dock_order && d.mac_dock_order.length > 0) {
          var ordered = []
          var map = {}
          for (var i = 0; i < defaultDockApps.length; i++) {
            map[defaultDockApps[i].id] = defaultDockApps[i]
          }
          for (var j = 0; j < d.mac_dock_order.length; j++) {
            var item = map[d.mac_dock_order[j]]
            if (item) {
              ordered.push(item)
              delete map[d.mac_dock_order[j]]
            }
          }
          for (var k = 0; k < defaultDockApps.length; k++) {
            if (map[defaultDockApps[k].id]) {
              ordered.push(defaultDockApps[k])
            }
          }
          dockAppsList = ordered
        }
      } catch(e) {}
    }

    function moveDockApp(fromIdx, toIdx) {
      if (toIdx < 0 || toIdx >= dockAppsList.length) return
      var arr = dockAppsList.slice()
      var item = arr.splice(fromIdx, 1)[0]
      arr.splice(toIdx, 0, item)
      dockAppsList = arr
      saveDockConfig()
    }

    function toggleDockApp(appId, enabled) {
      var pins = Object.assign({}, dockPinsState)
      pins[appId] = enabled
      dockPinsState = pins
      saveDockConfig()
    }

    function resetDockApps() {
      dockAppsList = defaultDockApps.slice()
      dockPinsState = {}
      saveDockConfig()
    }

    function saveDockConfig() {
      var order = []
      for (var i = 0; i < dockAppsList.length; i++) {
        order.push(dockAppsList[i].id)
      }
      var obj = { mac_dock_order: order, mac_pins: dockPinsState }
      var jsonStr = JSON.stringify(obj)
      var cmd = "mkdir -p '" + settingsWin.pluginDir + "' && printf '%s\\n' '" + jsonStr.replace(/'/g, "'\\''") + "' > '" + settingsWin.pluginDir + "/defaults.json'"
      runCmd(cmd)
    }

    FileView {
      id: settingsDefaultsFile
      path: settingsWin.pluginDir + "/defaults.json"
      watchChanges: true
      onLoaded: settingsWin.loadDockDefaults(text())
      onFileChanged: { reload(); settingsWin.loadDockDefaults(text()); }
    }

    // macOS Aerial Screensaver Integration
    property bool screensaverEnabled: true
    property int screensaverTimeout: 300
    property string screensaverActiveVideo: ""
    property var screensaverInstalledClips: []
    property var screensaverCatalog: []
    property string screensaverDownloadingId: ""
    property string screensaverStatusText: ""

    Process {
      id: screensaverStatusProc
      command: [settingsWin.pluginDir + "/scripts/omarchy-mac-screensaver", "--status"]
      stdout: StdioCollector {
        onStreamFinished: {
          try {
            var data = JSON.parse(text)
            settingsWin.screensaverEnabled = data.enabled
            settingsWin.screensaverTimeout = data.timeout
            settingsWin.screensaverActiveVideo = data.active_clip || ""
            settingsWin.screensaverInstalledClips = data.installed_clips || []
            settingsWin.screensaverCatalog = data.catalog || []
          } catch(e) {
            console.warn("mac-settings: screensaver status parse error:", e)
          }
        }
      }
    }

    Process {
      id: screensaverDownloadProc
      onExited: function(code) {
        settingsWin.screensaverDownloadingId = ""
        screensaverStatusProc.running = true
      }
    }

    function refreshScreensaverData() {
      screensaverStatusProc.running = true
    }

    function downloadScreensaverClip(cid) {
      settingsWin.screensaverDownloadingId = cid
      screensaverDownloadProc.command = [settingsWin.pluginDir + "/scripts/omarchy-mac-screensaver", "--download", cid]
      screensaverDownloadProc.running = true
    }

    function setScreensaverActiveClip(path) {
      settingsWin.screensaverActiveVideo = path
      runCmd(settingsWin.pluginDir + "/scripts/omarchy-mac-screensaver --set '" + path + "'")
      screensaverStatusProc.running = true
    }

    function setScreensaverTimeoutSec(sec) {
      settingsWin.screensaverTimeout = sec
      runCmd(settingsWin.pluginDir + "/scripts/omarchy-mac-screensaver --timeout " + sec)
    }

    function toggleScreensaver(on) {
      settingsWin.screensaverEnabled = on
      runCmd(settingsWin.pluginDir + "/scripts/omarchy-mac-screensaver --toggle " + (on ? "on" : "off"))
    }

    AudioService {
      id: audioService
    }

    SettingsService {
      id: settingsService
    }

    property int audioBalance: 50
    property bool micTesting: false

    function applyBalance(b) {
      settingsWin.audioBalance = b
      var master = audioService.masterVolume
      var left = master
      var right = master
      if (b < 50) {
        var r = b / 50.0
        right = Math.round(master * r)
      } else if (b > 50) {
        var r = (100 - b) / 50.0
        left = Math.round(master * r)
      }
      runCmd("pactl set-sink-volume @DEFAULT_SINK@ " + left + "% " + right + "%")
    }

    function getAudioDeviceIcon(desc, name, isSource) {
      var d = ((desc || "") + " " + (name || "")).toLowerCase()
      if (isSource) {
        if (d.indexOf("headset") !== -1 || d.indexOf("airpods") !== -1) return "🎧"
        if (d.indexOf("webcam") !== -1 || d.indexOf("camera") !== -1) return "📷"
        return "🎙️"
      }
      if (d.indexOf("airpods") !== -1 || d.indexOf("headphone") !== -1 || d.indexOf("headset") !== -1) return "🎧"
      if (d.indexOf("hdmi") !== -1 || d.indexOf("displayport") !== -1 || d.indexOf("tv") !== -1) return "📺"
      if (d.indexOf("blue") !== -1) return "📶"
      return "🔊"
    }

    function getAudioDeviceType(desc, name, isSource) {
      var d = ((desc || "") + " " + (name || "")).toLowerCase()
      if (isSource) {
        if (d.indexOf("usb") !== -1) return "USB Audio"
        if (d.indexOf("bluetooth") !== -1 || d.indexOf("bluez") !== -1) return "Bluetooth"
        if (d.indexOf("headset") !== -1 || d.indexOf("headphone") !== -1) return "Headset Microphone"
        if (d.indexOf("webcam") !== -1 || d.indexOf("camera") !== -1) return "Webcam Microphone"
        return "Built-in Microphone"
      }
      if (d.indexOf("usb") !== -1) return "USB Audio"
      if (d.indexOf("bluetooth") !== -1 || d.indexOf("bluez") !== -1) return "Bluetooth"
      if (d.indexOf("headphone") !== -1 || d.indexOf("headset") !== -1) return "Headphone Port"
      if (d.indexOf("hdmi") !== -1 || d.indexOf("displayport") !== -1) return "DisplayPort / HDMI"
      return "Built-in Speakers"
    }

    function getAudioAppIcon(stream) {
      var n = ((stream.binary || "") + " " + (stream.app_name || "") + " " + (stream.name || "")).toLowerCase()
      if (n.indexOf("firefox") !== -1 || n.indexOf("chrome") !== -1 || n.indexOf("browser") !== -1 || n.indexOf("brave") !== -1) return "🌐"
      if (n.indexOf("spotify") !== -1 || n.indexOf("music") !== -1 || n.indexOf("amberol") !== -1) return "🎵"
      if (n.indexOf("discord") !== -1 || n.indexOf("slack") !== -1 || n.indexOf("telegram") !== -1) return "💬"
      if (n.indexOf("vlc") !== -1 || n.indexOf("mpv") !== -1 || n.indexOf("video") !== -1) return "🎬"
      if (n.indexOf("game") !== -1 || n.indexOf("steam") !== -1) return "🎮"
      return "🎚️"
    }

    // Page watcher for direct navigation to sound, display, battery, etc.
    FileView {
      path: (Quickshell.env("XDG_RUNTIME_DIR") || "/tmp") + "/omarchy-settings-page"
      watchChanges: true
      onLoaded: {
        var p = text().trim()
        if (p === "sound" || p === "5") {
          settingsWin.currentCategory = 5
        } else if (p === "display" || p === "displays" || p === "8") {
          settingsWin.currentCategory = 8
        } else if (p === "battery" || p === "power" || p === "9") {
          settingsWin.currentCategory = 9
        } else if (p === "wifi" || p === "network" || p === "3") {
          settingsWin.currentCategory = 3
        } else if (p === "bluetooth" || p === "4") {
          settingsWin.currentCategory = 4
        } else if (p === "trackpad" || p === "mouse" || p === "10") {
          settingsWin.currentCategory = 10
        }
      }
      onFileChanged: {
        reload()
        var p = text().trim()
        if (p === "sound" || p === "5") {
          settingsWin.currentCategory = 5
        } else if (p === "display" || p === "displays" || p === "8") {
          settingsWin.currentCategory = 8
        } else if (p === "battery" || p === "power" || p === "9") {
          settingsWin.currentCategory = 9
        } else if (p === "wifi" || p === "network" || p === "3") {
          settingsWin.currentCategory = 3
        } else if (p === "bluetooth" || p === "4") {
          settingsWin.currentCategory = 4
        } else if (p === "trackpad" || p === "mouse" || p === "10") {
          settingsWin.currentCategory = 10
        }
      }
    }

    // Reactive Watcher on State
    FileView {
      id: stateWatcher
      path: settingsWin.pluginDir + "/state"
      watchChanges: true
      onLoaded: {
        var s = text().trim()
        settingsWin.currentDisguise = s || "mac-dark"
        settingsWin.isDark = (s.indexOf("light") === -1)
      }
      onFileChanged: {
        reload()
        var s = text().trim()
        settingsWin.currentDisguise = s || "mac-dark"
        settingsWin.isDark = (s.indexOf("light") === -1)
      }
    }

    // Reactive Watcher on settings.conf
    FileView {
      id: settingsWatcher
      path: settingsWin.pluginDir + "/settings.conf"
      watchChanges: true
      onLoaded: {
        var s = text()
        settingsWin.autohideActive = (s.indexOf("AUTOHIDE=true") !== -1)
        settingsWin.isTransparent = (s.indexOf("BAR_TRANSPARENT=false") === -1)
        var m = s.match(/ACCENT=([0-9a-fA-F]+)/)
        if (m && m[1]) settingsWin.activeAccent = m[1]
        var md = s.match(/DOCK_SIZE=([0-9]+)/)
        if (md && md[1]) settingsWin.dockSize = parseInt(md[1])
        var mm = s.match(/DOCK_MAX_ITEMS=([0-9]+)/)
        if (mm && mm[1]) settingsWin.maxDockItems = parseInt(mm[1])
        var dt = s.match(/DOCK_TRANSPARENCY=([0-9]+)/)
        if (dt && dt[1]) settingsWin.dockTransparency = Math.max(10, Math.min(100, parseInt(dt[1])))
        var mg = s.match(/WINDOW_GAPS=([0-9]+)/)
        if (mg && mg[1]) settingsWin.windowGaps = parseInt(mg[1])
        var mr = s.match(/WINDOW_ROUNDING=([0-9]+)/)
        if (mr && mr[1]) settingsWin.windowRounding = parseInt(mr[1])
      }
      onFileChanged: {
        reload()
        var s = text()
        settingsWin.autohideActive = (s.indexOf("AUTOHIDE=true") !== -1)
        settingsWin.isTransparent = (s.indexOf("BAR_TRANSPARENT=false") === -1)
        var m = s.match(/ACCENT=([0-9a-fA-F]+)/)
        if (m && m[1]) settingsWin.activeAccent = m[1]
        var md = s.match(/DOCK_SIZE=([0-9]+)/)
        if (md && md[1]) settingsWin.dockSize = parseInt(md[1])
        var mm = s.match(/DOCK_MAX_ITEMS=([0-9]+)/)
        if (mm && mm[1]) settingsWin.maxDockItems = parseInt(mm[1])
        var dt = s.match(/DOCK_TRANSPARENCY=([0-9]+)/)
        if (dt && dt[1]) settingsWin.dockTransparency = Math.max(10, Math.min(100, parseInt(dt[1])))
        var mg = s.match(/WINDOW_GAPS=([0-9]+)/)
        if (mg && mg[1]) settingsWin.windowGaps = parseInt(mg[1])
        var mr = s.match(/WINDOW_ROUNDING=([0-9]+)/)
        if (mr && mr[1]) settingsWin.windowRounding = parseInt(mr[1])
      }
    }

    // Background Hardware State Poller
    Process {
      id: hwPoller
      command: ["bash", "-c",
        "wpctl get-volume @DEFAULT_AUDIO_SINK@ 2>/dev/null | awk '{print int($2*100)}' || echo 70; " +
        "brightnessctl -m 2>/dev/null | cut -d, -f4 | tr -d '%' || echo 80; " +
        "nmcli -t -f WIFI g 2>/dev/null || echo 'enabled'; " +
        "nmcli -t -f active,ssid dev wifi 2>/dev/null | grep '^yes:' | cut -d: -f2 || echo 'Wi-Fi'; " +
        "bluetoothctl show 2>/dev/null | grep -q 'Powered: yes' && echo '1' || echo '0'"
      ]
      stdout: SplitParser {
        onRead: function(data) {
          var parts = data.trim().split("\n")
          if (parts.length >= 5) {
            var v = parseInt(parts[0]); if (!isNaN(v)) settingsWin.volumeLevel = v
            var b = parseInt(parts[1]); if (!isNaN(b)) settingsWin.brightnessLevel = b
            settingsWin.wifiEnabled = (parts[2].indexOf("enabled") !== -1)
            if (parts[3]) settingsWin.wifiSsid = parts[3]
            settingsWin.btEnabled = (parts[4] === "1")
          }
        }
      }
    }

    Timer {
      interval: 3500
      running: true
      repeat: true
      triggeredOnStart: true
      onTriggered: {
        if (!hwPoller.running) hwPoller.running = true
      }
    }

    // Main macOS Glass Container
    Rectangle {
      id: windowBox
      anchors.fill: parent
      radius: 14
      color: settingsWin.windowBg
      border.color: settingsWin.cardBorder
      border.width: 1
      clip: true

      ColumnLayout {
        anchors.fill: parent
        spacing: 0

        // ==========================================
        // 1. TOP macOS TITLEBAR WITH DRAG & CONTROLS
        // ==========================================
        Rectangle {
          id: titleBar
          Layout.fillWidth: true
          implicitHeight: 52
          color: "transparent"

          // Window Dragging & Maximizing on Double-Click
          MouseArea {
            anchors.fill: parent
            z: 0
            onPressed: settingsWin.startSystemMove()
            onDoubleClicked: settingsWin.runCmd("hyprctl dispatch fullscreen 1")
          }

          RowLayout {
            anchors.fill: parent
            anchors.leftMargin: 18
            anchors.rightMargin: 18
            spacing: 14
            z: 1

            // Authentic Traffic Lights on Top-Left
            RowLayout {
              spacing: 8

              // Close (Red)
              Rectangle {
                width: 13; height: 13; radius: 6.5
                color: closeM.containsMouse ? "#ff5f57" : (settingsWin.isDark ? "#ff5f57" : "#ff5f56")
                border.color: Qt.rgba(0, 0, 0, 0.20)
                border.width: 0.5

                Text {
                  anchors.centerIn: parent
                  text: "✕"
                  font.pixelSize: 8
                  font.bold: true
                  visible: closeM.containsMouse
                  color: "#4a0002"
                }

                MouseArea {
                  id: closeM
                  anchors.fill: parent
                  hoverEnabled: true
                  cursorShape: Qt.PointingHandCursor
                  onClicked: Qt.quit()
                }
              }

              // Minimize (Yellow)
              Rectangle {
                width: 13; height: 13; radius: 6.5
                color: minM.containsMouse ? "#febc2e" : (settingsWin.isDark ? "#febc2e" : "#ffbd2e")
                border.color: Qt.rgba(0, 0, 0, 0.20)
                border.width: 0.5

                Text {
                  anchors.centerIn: parent
                  text: "—"
                  font.pixelSize: 8
                  font.bold: true
                  visible: minM.containsMouse
                  color: "#593b00"
                }

                MouseArea {
                  id: minM
                  anchors.fill: parent
                  hoverEnabled: true
                  cursorShape: Qt.PointingHandCursor
                  onClicked: settingsWin.runCmd("omarchy-undercover-minimize 2>/dev/null || hyprctl dispatch movetoworkspacesilent special:minimized 2>/dev/null || true")
                }
              }

              // Zoom / Fullscreen (Green)
              Rectangle {
                width: 13; height: 13; radius: 6.5
                color: zoomM.containsMouse ? "#28c840" : (settingsWin.isDark ? "#28c840" : "#27c93f")
                border.color: Qt.rgba(0, 0, 0, 0.20)
                border.width: 0.5

                Text {
                  anchors.centerIn: parent
                  text: settingsWin.isMaximized ? "—" : "+"
                  font.pixelSize: 9
                  font.bold: true
                  visible: zoomM.containsMouse
                  color: "#004709"
                }

                MouseArea {
                  id: zoomM
                  anchors.fill: parent
                  hoverEnabled: true
                  cursorShape: Qt.PointingHandCursor
                  onClicked: {
                    settingsWin.isMaximized = !settingsWin.isMaximized
                    settingsWin.runCmd("hyprctl dispatch fullscreen 1 2>/dev/null || true")
                  }
                }
              }
            }

            // Window Title
            Text {
              Layout.leftMargin: 8
              text: "System Settings"
              font.family: "SF Pro Display, -apple-system, Segoe UI, sans-serif"
              font.pixelSize: 13
              font.weight: Font.DemiBold
              color: settingsWin.textPrimary
            }

            Item { Layout.fillWidth: true }

            // Mode Badge
            Rectangle {
              implicitWidth: badgeRow.implicitWidth + 16
              implicitHeight: 26
              radius: 13
              color: Qt.rgba(settingsWin.accentColor.r, settingsWin.accentColor.g, settingsWin.accentColor.b, 0.14)
              border.color: Qt.rgba(settingsWin.accentColor.r, settingsWin.accentColor.g, settingsWin.accentColor.b, 0.35)
              border.width: 1

              RowLayout {
                id: badgeRow
                anchors.centerIn: parent
                spacing: 6
                Image {
                  width: 12; height: 12
                  source: "file://" + settingsWin.pluginDir + "/assets/icons/apple-logo.svg"
                  fillMode: Image.PreserveAspectFit
                }
                Text {
                  text: "macOS Tahoe"
                  font.family: "SF Pro Text, -apple-system, sans-serif"
                  font.pixelSize: 11
                  font.weight: Font.Medium
                  color: settingsWin.accentColor
                }
              }
            }
          }
        }

        Rectangle {
          Layout.fillWidth: true
          height: 1
          color: settingsWin.separatorColor
        }

        // ==========================================
        // 2. MAIN SPLIT VIEW (Sidebar + Splitter + Content)
        // ==========================================
        RowLayout {
          Layout.fillWidth: true
          Layout.fillHeight: true
          spacing: 0

          // ------------------------------------------
          // LEFT NAVIGATION SIDEBAR (Resizable Width)
          // ------------------------------------------
          Rectangle {
            id: sidebarBox
            Layout.preferredWidth: settingsWin.sidebarWidth
            Layout.minimumWidth: 220
            Layout.maximumWidth: 380
            Layout.fillHeight: true
            color: settingsWin.sidebarBg

            ColumnLayout {
              anchors.fill: parent
              anchors.margins: 14
              spacing: 12

              // Apple Account Header Card
              Rectangle {
                Layout.fillWidth: true
                implicitHeight: 56
                radius: 8
                color: settingsWin.cardBg
                border.color: settingsWin.cardBorder
                border.width: 1

                RowLayout {
                  anchors.fill: parent
                  anchors.leftMargin: 12
                  anchors.rightMargin: 12
                  spacing: 10

                  Rectangle {
                    width: 36; height: 36; radius: 18
                    color: settingsWin.accentColor
                    Text {
                      anchors.centerIn: parent
                      text: settingsWin.userName.charAt(0).toUpperCase()
                      font.family: "SF Pro Text, -apple-system, sans-serif"
                      font.pixelSize: 15
                      font.bold: true
                      color: "#ffffff"
                    }
                  }

                  ColumnLayout {
                    Layout.fillWidth: true
                    spacing: 1
                    Text {
                      text: settingsWin.userName
                      font.family: "SF Pro Text, -apple-system, sans-serif"
                      font.pixelSize: 12
                      font.weight: Font.DemiBold
                      color: settingsWin.textPrimary
                      elide: Text.ElideRight
                      Layout.fillWidth: true
                    }
                    Text {
                      text: "Apple Account, iCloud & Media"
                      font.family: "SF Pro Text, -apple-system, sans-serif"
                      font.pixelSize: 10
                      color: settingsWin.textSecondary
                      elide: Text.ElideRight
                      Layout.fillWidth: true
                    }
                  }
                }
              }

              // Search Box
              Rectangle {
                Layout.fillWidth: true
                implicitHeight: 32
                radius: 7
                color: searchInput.activeFocus
                       ? (settingsWin.isDark ? Qt.rgba(1, 1, 1, 0.12) : "#ffffff")
                       : (settingsWin.isDark ? Qt.rgba(1, 1, 1, 0.08) : "#ffffff")
                border.color: searchInput.activeFocus ? settingsWin.accentColor : (settingsWin.isDark ? Qt.rgba(1, 1, 1, 0.12) : Qt.rgba(0, 0, 0, 0.12))
                border.width: 1

                RowLayout {
                  anchors.fill: parent
                  anchors.leftMargin: 8
                  anchors.rightMargin: 8
                  spacing: 7

                  Image {
                    width: 13; height: 13
                    source: "file://" + settingsWin.pluginDir + "/assets/icons/mac-settings/search.svg"
                    fillMode: Image.PreserveAspectFit
                    opacity: 0.6
                  }

                  TextInput {
                    id: searchInput
                    Layout.fillWidth: true
                    font.family: "SF Pro Text, -apple-system, sans-serif"
                    font.pixelSize: 12
                    color: settingsWin.textPrimary
                    clip: true
                    Text {
                      visible: !searchInput.text
                      text: "Search"
                      font.family: "SF Pro Text, -apple-system, sans-serif"
                      font.pixelSize: 12
                      color: settingsWin.textSecondary
                    }
                    onTextChanged: settingsWin.searchQuery = text.toLowerCase()
                  }
                }
              }

              // Sidebar Categories List with Vector Squircle Badges
              property var categories: [
                { id: 0, iconBg: "#007aff", icon: "appearance.svg", name: "Appearance" },
                { id: 1, iconBg: "#5856d6", icon: "dock.svg", name: "Desktop & Dock" },
                { id: 8, iconBg: "#007aff", icon: "display.svg", name: "Displays" },
                { id: 2, iconBg: "#34c759", icon: "wallpaper.svg", name: "Wallpaper" },
                { id: 11, iconBg: "#ff9500", icon: "screensaver.svg", name: "Screen Saver" },
                { id: 3, iconBg: "#007aff", icon: "wifi.svg", name: "Wi-Fi" },
                { id: 4, iconBg: "#007aff", icon: "bluetooth.svg", name: "Bluetooth" },
                { id: 5, iconBg: "#ff2d55", icon: "sound.svg", name: "Sound" },
                { id: 9, iconBg: "#34c759", icon: "battery.svg", name: "Battery" },
                { id: 10, iconBg: "#5856d6", icon: "trackpad.svg", name: "Trackpad & Mouse" },
                { id: 6, iconBg: "#af52de", icon: "disguise.svg", name: "Undercover Disguise" },
                { id: 7, iconBg: "#8e8e93", icon: "general.svg", name: "General & About" }
              ]

              ListView {
                Layout.fillWidth: true
                Layout.fillHeight: true
                clip: true
                spacing: 3
                model: parent.categories

                delegate: Rectangle {
                  width: parent ? parent.width : 220
                  implicitHeight: 36
                  radius: 7

                  readonly property bool isSelected: settingsWin.currentCategory === modelData.id
                  visible: (!settingsWin.searchQuery) || (modelData.name.toLowerCase().indexOf(settingsWin.searchQuery) !== -1)
                  height: visible ? implicitHeight : 0

                  color: isSelected
                         ? settingsWin.accentColor
                         : (catMouse.containsMouse ? (settingsWin.isDark ? Qt.rgba(1, 1, 1, 0.08) : Qt.rgba(0, 0, 0, 0.06)) : "transparent")

                  RowLayout {
                    anchors.fill: parent
                    anchors.leftMargin: 8
                    anchors.rightMargin: 8
                    spacing: 10

                    // Colorful Squircle Icon Badge
                    Rectangle {
                      width: 24; height: 24; radius: 6
                      color: isSelected ? Qt.rgba(1, 1, 1, 0.25) : modelData.iconBg

                      Image {
                        anchors.centerIn: parent
                        width: 14; height: 14
                        source: "file://" + settingsWin.pluginDir + "/assets/icons/mac-settings/" + modelData.icon
                        fillMode: Image.PreserveAspectFit
                      }
                    }

                    Text {
                      Layout.fillWidth: true
                      text: modelData.name
                      font.family: "SF Pro Text, -apple-system, sans-serif"
                      font.pixelSize: 12
                      font.weight: isSelected ? Font.DemiBold : Font.Normal
                      color: isSelected ? "#ffffff" : settingsWin.textPrimary
                      elide: Text.ElideRight
                    }

                    Text {
                      text: "›"
                      font.pixelSize: 14
                      color: isSelected ? Qt.rgba(1, 1, 1, 0.8) : Qt.rgba(settingsWin.textSecondary.r, settingsWin.textSecondary.g, settingsWin.textSecondary.b, 0.4)
                    }
                  }

                  MouseArea {
                    id: catMouse
                    anchors.fill: parent
                    hoverEnabled: true
                    cursorShape: Qt.PointingHandCursor
                    onClicked: settingsWin.currentCategory = modelData.id
                  }
                }
              }
            }
          }

          // ------------------------------------------
          // DRAGGABLE SIDEBAR SPLITTER
          // ------------------------------------------
          Rectangle {
            id: splitterBar
            Layout.fillHeight: true
            implicitWidth: 1
            color: splitterMouse.containsMouse || splitterMouse.pressed
                   ? settingsWin.accentColor
                   : settingsWin.separatorColor

            MouseArea {
              id: splitterMouse
              anchors.centerIn: parent
              width: 8
              height: parent.height
              hoverEnabled: true
              cursorShape: Qt.SizeHorCursor

              drag.target: null
              onPositionChanged: function(mouse) {
                if (pressed) {
                  var newW = settingsWin.sidebarWidth + mouse.x
                  if (newW >= 200 && newW <= 380) {
                    settingsWin.sidebarWidth = newW
                  }
                }
              }
            }
          }

          // ------------------------------------------
          // RIGHT CONTENT VIEW (Responsive Cards)
          // ------------------------------------------
          Flickable {
            id: rightScroller
            Layout.fillWidth: true
            Layout.fillHeight: true
            contentWidth: width
            contentHeight: contentCol.implicitHeight + 48
            clip: true
            boundsBehavior: Flickable.StopAtBounds

            ScrollBar.vertical: ScrollBar {
              anchors.top: parent.top
              anchors.right: parent.right
              anchors.bottom: parent.bottom
              active: rightScroller.moving || rightScroller.flicking
              policy: ScrollBar.AsNeeded
            }

            ColumnLayout {
              id: contentCol
              anchors.left: parent.left
              anchors.right: parent.right
              anchors.leftMargin: 28
              anchors.rightMargin: 28
              anchors.top: parent.top
              anchors.topMargin: 20
              spacing: 18

              Item { implicitHeight: 4 }

              // Dynamic Category Title
              Text {
                text: {
                  switch(settingsWin.currentCategory) {
                    case 0: return "Appearance"
                    case 1: return "Desktop & Dock"
                    case 2: return "Wallpaper"
                    case 3: return "Wi-Fi"
                    case 4: return "Bluetooth"
                    case 5: return "Sound"
                    case 6: return "Undercover Disguise Transformation"
                    case 7: return "General & About This Mac"
                    case 8: return "Displays"
                    case 9: return "Battery"
                    case 10: return "Trackpad & Mouse"
                    case 11: return "Screen Saver"
                    default: return "System Settings"
                  }
                }
                font.family: "SF Pro Display, -apple-system, sans-serif"
                font.pixelSize: 22
                font.weight: Font.Bold
                color: settingsWin.textPrimary
              }

              // ==========================================
              // TAB 0: APPEARANCE
              // ==========================================
              ColumnLayout {
                visible: settingsWin.currentCategory === 0
                Layout.fillWidth: true
                spacing: 16

                // Light / Dark Theme Selection
                Rectangle {
                  Layout.fillWidth: true
                  implicitHeight: 160
                  radius: 10
                  color: settingsWin.cardBg
                  border.color: settingsWin.cardBorder
                  border.width: 1

                  RowLayout {
                    anchors.centerIn: parent
                    spacing: 36

                    // Light Card Option
                    ColumnLayout {
                      spacing: 8
                      Layout.alignment: Qt.AlignHCenter

                      Rectangle {
                        width: 140; height: 92; radius: 8
                        color: "#f5f5f7"
                        border.color: !settingsWin.isDark ? settingsWin.accentColor : Qt.rgba(0, 0, 0, 0.15)
                        border.width: !settingsWin.isDark ? 2.5 : 1
                        clip: true

                        // Light Desktop Preview
                        Image {
                          anchors.fill: parent
                          source: "file://" + settingsWin.pluginDir + "/assets/wallpapers/macOS-Tahoe-Light.jpg"
                          fillMode: Image.PreserveAspectCrop
                          opacity: 0.85
                        }

                        // Mini Light Window
                        Rectangle {
                          width: 110; height: 56; radius: 5
                          color: Qt.rgba(1, 1, 1, 0.94)
                          border.color: Qt.rgba(0, 0, 0, 0.1)
                          anchors.centerIn: parent

                          // Traffic Lights
                          Row {
                            anchors.top: parent.top; anchors.left: parent.left; anchors.margins: 4
                            spacing: 3
                            Rectangle { width: 4; height: 4; radius: 2; color: "#ff5f57" }
                            Rectangle { width: 4; height: 4; radius: 2; color: "#febc2e" }
                            Rectangle { width: 4; height: 4; radius: 2; color: "#28c840" }
                          }
                          // Mini Sidebar
                          Rectangle {
                            anchors.top: parent.top; anchors.bottom: parent.bottom; anchors.left: parent.left
                            anchors.topMargin: 12
                            width: 24
                            color: Qt.rgba(0, 0, 0, 0.05)
                          }
                        }

                        // Mini Dock
                        Rectangle {
                          anchors.bottom: parent.bottom; anchors.bottomMargin: 2
                          anchors.horizontalCenter: parent.horizontalCenter
                          width: 50; height: 5; radius: 2.5
                          color: Qt.rgba(255, 255, 255, 0.75)
                        }

                        MouseArea {
                          anchors.fill: parent
                          cursorShape: Qt.PointingHandCursor
                          onClicked: settingsWin.runCmd("omarchy-undercover -mac-light")
                        }
                      }

                      RowLayout {
                        Layout.alignment: Qt.AlignHCenter
                        spacing: 4
                        Rectangle {
                          width: 12; height: 12; radius: 6
                          color: !settingsWin.isDark ? settingsWin.accentColor : "transparent"
                          border.color: !settingsWin.isDark ? settingsWin.accentColor : settingsWin.textSecondary
                          border.width: 1.5
                          Rectangle {
                            anchors.centerIn: parent
                            width: 4; height: 4; radius: 2
                            color: "#ffffff"
                            visible: !settingsWin.isDark
                          }
                        }
                        Text {
                          text: "Light"
                          font.family: "SF Pro Text, -apple-system, sans-serif"
                          font.pixelSize: 12
                          font.bold: !settingsWin.isDark
                          color: settingsWin.textPrimary
                        }
                      }
                    }

                    // Dark Card Option
                    ColumnLayout {
                      spacing: 8
                      Layout.alignment: Qt.AlignHCenter

                      Rectangle {
                        width: 140; height: 92; radius: 8
                        color: "#1e1e24"
                        border.color: settingsWin.isDark ? settingsWin.accentColor : Qt.rgba(255, 255, 255, 0.15)
                        border.width: settingsWin.isDark ? 2.5 : 1
                        clip: true

                        // Dark Desktop Preview
                        Image {
                          anchors.fill: parent
                          source: "file://" + settingsWin.pluginDir + "/assets/wallpapers/macOS-Tahoe-Dark.jpg"
                          fillMode: Image.PreserveAspectCrop
                          opacity: 0.85
                        }

                        // Mini Dark Window
                        Rectangle {
                          width: 110; height: 56; radius: 5
                          color: Qt.rgba(0.12, 0.12, 0.15, 0.94)
                          border.color: Qt.rgba(255, 255, 255, 0.1)
                          anchors.centerIn: parent

                          // Traffic Lights
                          Row {
                            anchors.top: parent.top; anchors.left: parent.left; anchors.margins: 4
                            spacing: 3
                            Rectangle { width: 4; height: 4; radius: 2; color: "#ff5f57" }
                            Rectangle { width: 4; height: 4; radius: 2; color: "#febc2e" }
                            Rectangle { width: 4; height: 4; radius: 2; color: "#28c840" }
                          }
                          // Mini Sidebar
                          Rectangle {
                            anchors.top: parent.top; anchors.bottom: parent.bottom; anchors.left: parent.left
                            anchors.topMargin: 12
                            width: 24
                            color: Qt.rgba(1, 1, 1, 0.05)
                          }
                        }

                        // Mini Dock
                        Rectangle {
                          anchors.bottom: parent.bottom; anchors.bottomMargin: 2
                          anchors.horizontalCenter: parent.horizontalCenter
                          width: 50; height: 5; radius: 2.5
                          color: Qt.rgba(0, 0, 0, 0.65)
                        }

                        MouseArea {
                          anchors.fill: parent
                          cursorShape: Qt.PointingHandCursor
                          onClicked: settingsWin.runCmd("omarchy-undercover -mac")
                        }
                      }

                      RowLayout {
                        Layout.alignment: Qt.AlignHCenter
                        spacing: 4
                        Rectangle {
                          width: 12; height: 12; radius: 6
                          color: settingsWin.isDark ? settingsWin.accentColor : "transparent"
                          border.color: settingsWin.isDark ? settingsWin.accentColor : settingsWin.textSecondary
                          border.width: 1.5
                          Rectangle {
                            anchors.centerIn: parent
                            width: 4; height: 4; radius: 2
                            color: "#ffffff"
                            visible: settingsWin.isDark
                          }
                        }
                        Text {
                          text: "Dark"
                          font.family: "SF Pro Text, -apple-system, sans-serif"
                          font.pixelSize: 12
                          font.bold: settingsWin.isDark
                          color: settingsWin.textPrimary
                        }
                      }
                    }
                  }
                }

                // Desktop Camouflage & Disguise Selection in Appearance
                Rectangle {
                  Layout.fillWidth: true
                  implicitHeight: disguiseCol.implicitHeight + 28
                  radius: 10
                  color: settingsWin.cardBg
                  border.color: settingsWin.cardBorder
                  border.width: 1

                  ColumnLayout {
                    id: disguiseCol
                    anchors.fill: parent
                    anchors.margins: 16
                    spacing: 12

                    RowLayout {
                      Layout.fillWidth: true
                      Text {
                        text: "Desktop Camouflage & Disguise"
                        font.family: "SF Pro Text, -apple-system, sans-serif"
                        font.pixelSize: 13
                        font.weight: Font.DemiBold
                        color: settingsWin.textPrimary
                      }
                      Item { Layout.fillWidth: true }
                      Text {
                        text: "Select a disguise preset"
                        font.family: "SF Pro Text, -apple-system, sans-serif"
                        font.pixelSize: 11
                        color: settingsWin.textSecondary
                      }
                    }

                    GridLayout {
                      Layout.fillWidth: true
                      columns: rightScroller.width > 620 ? 3 : 2
                      rowSpacing: 10
                      columnSpacing: 10

                      property var presets: [
                        { id: "mac-dark", name: "macOS Tahoe (Dark)", icon: "apple-logo.svg", isWin: false, cmd: "omarchy-undercover -mac" },
                        { id: "mac-light", name: "macOS Tahoe (Light)", icon: "apple-logo.svg", isWin: false, cmd: "omarchy-undercover -mac-light" },
                        { id: "mac-sequoia-dark", name: "macOS Sequoia (Dark)", icon: "apple-logo.svg", isWin: false, cmd: "omarchy-undercover -mac-sequoia" },
                        { id: "mac-sequoia-light", name: "macOS Sequoia (Light)", icon: "apple-logo.svg", isWin: false, cmd: "omarchy-undercover -mac-sequoia-light" },
                        { id: "win11-dark", name: "Windows 11 (Dark)", icon: "start.svg", isWin: true, cmd: "omarchy-undercover -w11" },
                        { id: "win11-light", name: "Windows 11 (Light)", icon: "start.svg", isWin: true, cmd: "omarchy-undercover -w11-light" },
                        { id: "omarchy", name: "Omarchy Default", icon: "disguise.svg", isWin: false, cmd: "omarchy-undercover --disable" }
                      ]

                      Repeater {
                        model: parent.presets
                        Rectangle {
                          Layout.fillWidth: true
                          implicitHeight: 52
                          radius: 8
                          color: (settingsWin.currentDisguise === modelData.id)
                                 ? Qt.rgba(settingsWin.accentColor.r, settingsWin.accentColor.g, settingsWin.accentColor.b, 0.15)
                                 : (disgMouse.containsMouse ? (settingsWin.isDark ? Qt.rgba(1, 1, 1, 0.08) : Qt.rgba(0, 0, 0, 0.05)) : (settingsWin.isDark ? Qt.rgba(1, 1, 1, 0.03) : Qt.rgba(0, 0, 0, 0.03)))
                          border.color: (settingsWin.currentDisguise === modelData.id) ? settingsWin.accentColor : settingsWin.cardBorder
                          border.width: (settingsWin.currentDisguise === modelData.id) ? 2 : 1

                          RowLayout {
                            anchors.fill: parent
                            anchors.margins: 10
                            spacing: 10

                            Image {
                              Layout.preferredWidth: 18
                              Layout.preferredHeight: 18
                              width: 18; height: 18
                              source: "file://" + settingsWin.pluginDir + "/assets/icons/" + (modelData.isWin ? "win11/" : "") + (modelData.icon === "disguise.svg" ? "win11-settings/" : "") + modelData.icon
                              fillMode: Image.PreserveAspectFit
                            }

                            ColumnLayout {
                              Layout.fillWidth: true
                              spacing: 1
                              Text {
                                text: modelData.name
                                font.family: "SF Pro Text, -apple-system, sans-serif"
                                font.pixelSize: 11
                                font.weight: (settingsWin.currentDisguise === modelData.id) ? Font.Bold : Font.Normal
                                color: settingsWin.textPrimary
                                elide: Text.ElideRight
                              }
                              Text {
                                text: (settingsWin.currentDisguise === modelData.id) ? "Active Disguise" : "Click to switch"
                                font.family: "SF Pro Text, -apple-system, sans-serif"
                                font.pixelSize: 9
                                color: (settingsWin.currentDisguise === modelData.id) ? settingsWin.accentColor : settingsWin.textSecondary
                              }
                            }
                          }

                          MouseArea {
                            id: disgMouse
                            anchors.fill: parent
                            hoverEnabled: true
                            cursorShape: Qt.PointingHandCursor
                            onClicked: settingsWin.runCmd(modelData.cmd)
                          }
                        }
                      }
                    }
                  }
                }

                // Accent Color Inset Card
                Rectangle {
                  Layout.fillWidth: true
                  implicitHeight: 64
                  radius: 10
                  color: settingsWin.cardBg
                  border.color: settingsWin.cardBorder
                  border.width: 1

                  RowLayout {
                    anchors.fill: parent
                    anchors.margins: 16
                    Text {
                      text: "Accent color"
                      font.family: "SF Pro Text, -apple-system, sans-serif"
                      font.pixelSize: 13
                      color: settingsWin.textPrimary
                    }
                    Item { Layout.fillWidth: true }

                    RowLayout {
                      spacing: 8
                      property var swatches: ["007aff", "5856d6", "af52de", "ff2d55", "ff9500", "ffcc00", "34c759", "8e8e93"]

                      Repeater {
                        model: parent.swatches
                        Rectangle {
                          width: 22; height: 22; radius: 11
                          color: "#" + modelData
                          border.color: settingsWin.activeAccent.toLowerCase() === modelData.toLowerCase() ? "#ffffff" : "transparent"
                          border.width: 2

                          MouseArea {
                            anchors.fill: parent
                            cursorShape: Qt.PointingHandCursor
                            onClicked: {
                              settingsWin.activeAccent = modelData
                              settingsWin.saveSetting("ACCENT", modelData)
                              settingsWin.runCmd("omarchy-undercover --reload")
                            }
                          }
                        }
                      }
                    }
                  }
                }

                // Transparency & Glass Inset Card
                Rectangle {
                  Layout.fillWidth: true
                  implicitHeight: 64
                  radius: 10
                  color: settingsWin.cardBg
                  border.color: settingsWin.cardBorder
                  border.width: 1

                  RowLayout {
                    anchors.fill: parent
                    anchors.margins: 16
                    ColumnLayout {
                      spacing: 2
                      Text {
                        text: "Liquid Glass & Menu Bar Transparency"
                        font.family: "SF Pro Text, -apple-system, sans-serif"
                        font.pixelSize: 13
                        font.weight: Font.DemiBold
                        color: settingsWin.textPrimary
                      }
                      Text {
                        text: "Apply authentic frosted glass blur across top bar & surfaces"
                        font.family: "SF Pro Text, -apple-system, sans-serif"
                        font.pixelSize: 11
                        color: settingsWin.textSecondary
                      }
                    }
                    Item { Layout.fillWidth: true }

                    // Pill Switch
                    Rectangle {
                      width: 38; height: 22; radius: 11
                      color: settingsWin.isTransparent ? "#34c759" : (settingsWin.isDark ? "#39393d" : "#e5e5ea")

                      Rectangle {
                        width: 18; height: 18; radius: 9
                        x: settingsWin.isTransparent ? 18 : 2
                        anchors.verticalCenter: parent.verticalCenter
                        color: "#ffffff"
                        Behavior on x { NumberAnimation { duration: 120; easing.type: Easing.OutQuad } }
                      }

                      MouseArea {
                        anchors.fill: parent
                        cursorShape: Qt.PointingHandCursor
                        onClicked: {
                          var next = !settingsWin.isTransparent
                          settingsWin.isTransparent = next
                          settingsWin.saveSetting("BAR_TRANSPARENT", next ? "true" : "false")
                          settingsWin.runCmd("omarchy-undercover --transparent " + (next ? "true" : "false"))
                        }
                      }
                    }
                  }
                }

                // Window Gaps, Rounding, Motion & Effects
                Rectangle {
                  Layout.fillWidth: true
                  implicitHeight: windowFxCol.implicitHeight + 28
                  radius: 10
                  color: settingsWin.cardBg
                  border.color: settingsWin.cardBorder
                  border.width: 1

                  ColumnLayout {
                    id: windowFxCol
                    anchors.fill: parent
                    anchors.margins: 16
                    spacing: 12

                    // Window Gaps Row
                    RowLayout {
                      Layout.fillWidth: true
                      Text {
                        text: "Desktop Window Gaps (" + settingsService.windowGaps + "px)"
                        font.family: "SF Pro Text, -apple-system, sans-serif"
                        font.pixelSize: 12
                        color: settingsWin.textPrimary
                      }
                      Item { Layout.fillWidth: true }
                      Slider {
                        from: 0; to: 30; stepSize: 1
                        value: settingsService.windowGaps
                        onMoved: {
                          var v = Math.round(value)
                          settingsWin.windowGaps = v
                          settingsService.setWindowGaps(v)
                          settingsWin.saveSetting("WINDOW_GAPS", v)
                        }
                      }
                    }

                    Rectangle { Layout.fillWidth: true; height: 1; color: settingsWin.separatorColor }

                    // Window Corner Rounding Row
                    RowLayout {
                      Layout.fillWidth: true
                      Text {
                        text: "Window Corner Radius (" + settingsService.windowRounding + "px)"
                        font.family: "SF Pro Text, -apple-system, sans-serif"
                        font.pixelSize: 12
                        color: settingsWin.textPrimary
                      }
                      Item { Layout.fillWidth: true }
                      Slider {
                        from: 0; to: 24; stepSize: 1
                        value: settingsService.windowRounding
                        onMoved: {
                          var v = Math.round(value)
                          settingsWin.windowRounding = v
                          settingsService.setWindowRounding(v)
                          settingsWin.saveSetting("WINDOW_ROUNDING", v)
                        }
                      }
                    }

                    Rectangle { Layout.fillWidth: true; height: 1; color: settingsWin.separatorColor }

                    // Window Animations Toggle
                    RowLayout {
                      Layout.fillWidth: true
                      ColumnLayout {
                        spacing: 2
                        Text {
                          text: "Window Animations & Motion"
                          font.family: "SF Pro Text, -apple-system, sans-serif"
                          font.pixelSize: 12
                          font.weight: Font.DemiBold
                          color: settingsWin.textPrimary
                        }
                        Text {
                          text: "Fluid opening, closing, and workspace sliding animations"
                          font.family: "SF Pro Text, -apple-system, sans-serif"
                          font.pixelSize: 11
                          color: settingsWin.textSecondary
                        }
                      }
                      Item { Layout.fillWidth: true }

                      Rectangle {
                        width: 38; height: 22; radius: 11
                        color: settingsService.animationsEnabled ? "#34c759" : (settingsWin.isDark ? "#39393d" : "#e5e5ea")
                        Rectangle {
                          width: 18; height: 18; radius: 9
                          x: settingsService.animationsEnabled ? 18 : 2
                          anchors.verticalCenter: parent.verticalCenter
                          color: "#ffffff"
                          Behavior on x { NumberAnimation { duration: 120; easing.type: Easing.OutQuad } }
                        }
                        MouseArea {
                          anchors.fill: parent
                          cursorShape: Qt.PointingHandCursor
                          onClicked: {
                            settingsService.setAnimationsEnabled(!settingsService.animationsEnabled)
                          }
                        }
                      }
                    }

                    Rectangle { Layout.fillWidth: true; height: 1; color: settingsWin.separatorColor }

                    // Window Blur & Transparency Toggle
                    RowLayout {
                      Layout.fillWidth: true
                      ColumnLayout {
                        spacing: 2
                        Text {
                          text: "Window Blur & Acrylic Effects"
                          font.family: "SF Pro Text, -apple-system, sans-serif"
                          font.pixelSize: 12
                          font.weight: Font.DemiBold
                          color: settingsWin.textPrimary
                        }
                        Text {
                          text: "Enable backdrop blur on transparent windows and surfaces"
                          font.family: "SF Pro Text, -apple-system, sans-serif"
                          font.pixelSize: 11
                          color: settingsWin.textSecondary
                        }
                      }
                      Item { Layout.fillWidth: true }

                      Rectangle {
                        width: 38; height: 22; radius: 11
                        color: settingsService.blurEnabled ? "#34c759" : (settingsWin.isDark ? "#39393d" : "#e5e5ea")
                        Rectangle {
                          width: 18; height: 18; radius: 9
                          x: settingsService.blurEnabled ? 18 : 2
                          anchors.verticalCenter: parent.verticalCenter
                          color: "#ffffff"
                          Behavior on x { NumberAnimation { duration: 120; easing.type: Easing.OutQuad } }
                        }
                        MouseArea {
                          anchors.fill: parent
                          cursorShape: Qt.PointingHandCursor
                          onClicked: {
                            settingsService.setBlurEnabled(!settingsService.blurEnabled)
                          }
                        }
                      }
                    }
                  }
                }
              }

              // ==========================================
              // TAB 1: DESKTOP & DOCK
              // ==========================================
              ColumnLayout {
                visible: settingsWin.currentCategory === 1
                Layout.fillWidth: true
                spacing: 16

                Rectangle {
                  Layout.fillWidth: true
                  implicitHeight: 220
                  radius: 10
                  color: settingsWin.cardBg
                  border.color: settingsWin.cardBorder
                  border.width: 1

                  ColumnLayout {
                    anchors.fill: parent
                    anchors.margins: 16
                    spacing: 14

                    // Dock Size Slider
                    RowLayout {
                      Layout.fillWidth: true
                      Text {
                        text: "Dock Size (" + settingsWin.dockSize + "px)"
                        font.family: "SF Pro Text, -apple-system, sans-serif"
                        font.pixelSize: 12
                        color: settingsWin.textPrimary
                      }
                      Item { Layout.fillWidth: true }
                      Slider {
                        from: 36; to: 72; stepSize: 2
                        value: settingsWin.dockSize
                        onMoved: {
                          settingsWin.dockSize = Math.round(value)
                          settingsWin.saveSetting("DOCK_SIZE", settingsWin.dockSize)
                          settingsWin.runCmd("omarchy-undercover --reload")
                        }
                      }
                    }

                    Rectangle { Layout.fillWidth: true; height: 1; color: settingsWin.separatorColor }

                    // Max Dock Items Slider
                    RowLayout {
                      Layout.fillWidth: true
                      Text {
                        text: "Max Dock Items (" + settingsWin.maxDockItems + ")"
                        font.family: "SF Pro Text, -apple-system, sans-serif"
                        font.pixelSize: 12
                        color: settingsWin.textPrimary
                      }
                      Item { Layout.fillWidth: true }
                      Slider {
                        from: 4; to: 56; stepSize: 1
                        value: settingsWin.maxDockItems
                        onMoved: {
                          settingsWin.maxDockItems = Math.round(value)
                          settingsWin.saveSetting("DOCK_MAX_ITEMS", settingsWin.maxDockItems)
                          settingsWin.runCmd("omarchy-undercover --reload")
                        }
                      }
                    }

                    Rectangle { Layout.fillWidth: true; height: 1; color: settingsWin.separatorColor }

                    // Dock Transparency Slider
                    RowLayout {
                      Layout.fillWidth: true
                      Text {
                        text: "Dock Transparency (" + settingsWin.dockTransparency + "%)"
                        font.family: "SF Pro Text, -apple-system, sans-serif"
                        font.pixelSize: 12
                        color: settingsWin.textPrimary
                      }
                      Item { Layout.fillWidth: true }
                      Slider {
                        from: 10; to: 100; stepSize: 1
                        value: settingsWin.dockTransparency
                        onMoved: {
                          settingsWin.dockTransparency = Math.round(value)
                          settingsWin.saveSetting("DOCK_TRANSPARENCY", settingsWin.dockTransparency)
                          settingsWin.runCmd("omarchy-undercover --reload")
                        }
                      }
                    }

                    Rectangle { Layout.fillWidth: true; height: 1; color: settingsWin.separatorColor }

                    // Auto-hide Dock Toggle
                    RowLayout {
                      Layout.fillWidth: true
                      ColumnLayout {
                        spacing: 2
                        Text {
                          text: "Automatically hide and show the Dock"
                          font.family: "SF Pro Text, -apple-system, sans-serif"
                          font.pixelSize: 12
                          font.weight: Font.DemiBold
                          color: settingsWin.textPrimary
                        }
                        Text {
                          text: "Reveal smoothly when cursor hovers screen edge"
                          font.family: "SF Pro Text, -apple-system, sans-serif"
                          font.pixelSize: 11
                          color: settingsWin.textSecondary
                        }
                      }
                      Item { Layout.fillWidth: true }

                      Rectangle {
                        width: 38; height: 22; radius: 11
                        color: settingsWin.autohideActive ? "#34c759" : (settingsWin.isDark ? "#39393d" : "#e5e5ea")
                        Rectangle {
                          width: 18; height: 18; radius: 9
                          x: settingsWin.autohideActive ? 18 : 2
                          anchors.verticalCenter: parent.verticalCenter
                          color: "#ffffff"
                          Behavior on x { NumberAnimation { duration: 120; easing.type: Easing.OutQuad } }
                        }
                        MouseArea {
                          anchors.fill: parent
                          cursorShape: Qt.PointingHandCursor
                          onClicked: {
                            var next = !settingsWin.autohideActive
                            settingsWin.autohideActive = next
                            settingsWin.saveSetting("AUTOHIDE", next ? "true" : "false")
                            settingsWin.runCmd("omarchy-undercover-autohide " + (next ? "--start" : "--stop"))
                          }
                        }
                      }
                    }

                    Rectangle { Layout.fillWidth: true; height: 1; color: settingsWin.separatorColor }

                    // Restart Dock Helper Button
                    RowLayout {
                      Layout.fillWidth: true
                      Text {
                        text: "Restart macOS Dynamic Dock"
                        font.family: "SF Pro Text, -apple-system, sans-serif"
                        font.pixelSize: 12
                        color: settingsWin.textPrimary
                      }
                      Item { Layout.fillWidth: true }
                      Button {
                        text: "Restart Dock"
                        onClicked: settingsWin.runCmd("pkill -f 'quickshell.*mac-dock' && nohup quickshell -p " + settingsWin.pluginDir + "/configs/quickshell/mac-dock >/dev/null 2>&1 &")
                      }
                    }

                    Rectangle { Layout.fillWidth: true; height: 1; color: settingsWin.separatorColor }

                    // Keyboard Shortcuts
                    RowLayout {
                      Layout.fillWidth: true
                      ColumnLayout {
                        spacing: 2
                        Text {
                          text: "macOS Sequoia Keyboard Shortcuts"
                          font.family: "SF Pro Text, -apple-system, sans-serif"
                          font.pixelSize: 12
                          font.weight: Font.DemiBold
                          color: settingsWin.textPrimary
                        }
                        Text {
                          text: "Configure Spotlight (Cmd+Space), Mission Control, and tiling keys"
                          font.family: "SF Pro Text, -apple-system, sans-serif"
                          font.pixelSize: 11
                          color: settingsWin.textSecondary
                        }
                      }
                      Item { Layout.fillWidth: true }
                      Button {
                        text: "Customize Shortcuts"
                        onClicked: settingsWin.runCmd("omarchy-undercover-settings --legacy -s")
                      }
                    }
                  }
                }

                // Dock Items & Arrangement Manager Card
                Rectangle {
                  Layout.fillWidth: true
                  implicitHeight: dockItemsCol.implicitHeight + 28
                  radius: 10
                  color: settingsWin.cardBg
                  border.color: settingsWin.cardBorder
                  border.width: 1

                  ColumnLayout {
                    id: dockItemsCol
                    anchors.fill: parent
                    anchors.margins: 16
                    spacing: 12

                    RowLayout {
                      Layout.fillWidth: true
                      spacing: 12

                      Image {
                        Layout.preferredWidth: 20
                        Layout.preferredHeight: 20
                        source: "file://" + settingsWin.pluginDir + "/assets/icons/mac-settings/dock.svg"
                        fillMode: Image.PreserveAspectFit
                      }

                      ColumnLayout {
                        Layout.fillWidth: true
                        spacing: 2
                        Text {
                          text: "Dock Applications & Arrangement"
                          font.family: "SF Pro Text, -apple-system, sans-serif"
                          font.pixelSize: 13
                          font.weight: Font.DemiBold
                          color: settingsWin.textPrimary
                        }
                        Text {
                          text: "Arrange order with ▲ / ▼ or toggle switches to show, hide, or remove apps from the Dock"
                          font.family: "SF Pro Text, -apple-system, sans-serif"
                          font.pixelSize: 11
                          color: settingsWin.textSecondary
                        }
                      }

                      Button {
                        text: "Reset Defaults"
                        onClicked: settingsWin.resetDockApps()
                      }
                    }

                    Rectangle { Layout.fillWidth: true; height: 1; color: settingsWin.separatorColor }

                    Repeater {
                      model: settingsWin.dockAppsList

                      RowLayout {
                        Layout.fillWidth: true
                        spacing: 10

                        // App Icon
                        Rectangle {
                          width: 28; height: 28; radius: 6
                          color: settingsWin.isDark ? Qt.rgba(1, 1, 1, 0.06) : Qt.rgba(0, 0, 0, 0.04)

                          Image {
                            anchors.centerIn: parent
                            width: 20; height: 20
                            source: "file://" + settingsWin.pluginDir + "/assets/icons/mac-dock/" + modelData.icon
                            fillMode: Image.PreserveAspectFit
                          }
                        }

                        // App Name
                        Text {
                          Layout.fillWidth: true
                          text: modelData.name
                          font.family: "SF Pro Text, -apple-system, sans-serif"
                          font.pixelSize: 12
                          font.weight: Font.Medium
                          color: (settingsWin.dockPinsState[modelData.id] === false) ? settingsWin.textSecondary : settingsWin.textPrimary
                          opacity: (settingsWin.dockPinsState[modelData.id] === false) ? 0.6 : 1.0
                        }

                        // Move Up Button
                        Rectangle {
                          width: 26; height: 26; radius: 5
                          color: upMouse.containsMouse ? (settingsWin.isDark ? Qt.rgba(1, 1, 1, 0.12) : Qt.rgba(0, 0, 0, 0.08)) : "transparent"
                          border.color: settingsWin.cardBorder
                          border.width: 1
                          enabled: index > 0

                          Text {
                            anchors.centerIn: parent
                            text: "▲"
                            font.pixelSize: 10
                            color: parent.enabled ? settingsWin.textPrimary : settingsWin.textSecondary
                            opacity: parent.enabled ? 1.0 : 0.3
                          }

                          MouseArea {
                            id: upMouse
                            anchors.fill: parent
                            hoverEnabled: true
                            cursorShape: Qt.PointingHandCursor
                            onClicked: settingsWin.moveDockApp(index, index - 1)
                          }
                        }

                        // Move Down Button
                        Rectangle {
                          width: 26; height: 26; radius: 5
                          color: dnMouse.containsMouse ? (settingsWin.isDark ? Qt.rgba(1, 1, 1, 0.12) : Qt.rgba(0, 0, 0, 0.08)) : "transparent"
                          border.color: settingsWin.cardBorder
                          border.width: 1
                          enabled: index < (settingsWin.dockAppsList.length - 1)

                          Text {
                            anchors.centerIn: parent
                            text: "▼"
                            font.pixelSize: 10
                            color: parent.enabled ? settingsWin.textPrimary : settingsWin.textSecondary
                            opacity: parent.enabled ? 1.0 : 0.3
                          }

                          MouseArea {
                            id: dnMouse
                            anchors.fill: parent
                            hoverEnabled: true
                            cursorShape: Qt.PointingHandCursor
                            onClicked: settingsWin.moveDockApp(index, index + 1)
                          }
                        }

                        // Toggle / Remove Pill Switch
                        Rectangle {
                          width: 38; height: 22; radius: 11
                          color: (settingsWin.dockPinsState[modelData.id] !== false) ? "#34c759" : (settingsWin.isDark ? "#39393d" : "#e5e5ea")

                          Rectangle {
                            width: 18; height: 18; radius: 9
                            x: (settingsWin.dockPinsState[modelData.id] !== false) ? 18 : 2
                            anchors.verticalCenter: parent.verticalCenter
                            color: "#ffffff"
                            Behavior on x { NumberAnimation { duration: 120; easing.type: Easing.OutQuad } }
                          }

                          MouseArea {
                            anchors.fill: parent
                            cursorShape: Qt.PointingHandCursor
                            onClicked: {
                              var cur = (settingsWin.dockPinsState[modelData.id] !== false)
                              settingsWin.toggleDockApp(modelData.id, !cur)
                            }
                          }
                        }
                      }
                    }
                  }
                }
              }

              // ==========================================
              // TAB 2: WALLPAPER
              // ==========================================
              ColumnLayout {
                visible: settingsWin.currentCategory === 2
                Layout.fillWidth: true
                spacing: 16

                // Hero Desktop Display Preview Card
                Rectangle {
                  Layout.fillWidth: true
                  implicitHeight: 240
                  radius: 12
                  color: settingsWin.cardBg
                  border.color: settingsWin.cardBorder
                  border.width: 1

                  RowLayout {
                    anchors.fill: parent
                    anchors.margins: 18
                    spacing: 24

                    // Display Mockup
                    ColumnLayout {
                      spacing: 0
                      Layout.alignment: Qt.AlignVCenter

                      // Monitor Bezel
                      Rectangle {
                        width: 240
                        height: 150
                        radius: 8
                        color: settingsWin.isDark ? "#141418" : "#242429"
                        border.color: settingsWin.isDark ? Qt.rgba(1, 1, 1, 0.15) : Qt.rgba(0, 0, 0, 0.25)
                        border.width: 4
                        clip: true

                        // Screen Inner
                        Rectangle {
                          anchors.fill: parent
                          anchors.margins: 3
                          radius: 5
                          clip: true

                          Image {
                            anchors.fill: parent
                            source: "file://" + settingsWin.pluginDir + "/assets/wallpapers/" + settingsWin.currentWallpaper
                            fillMode: Image.PreserveAspectCrop
                            asynchronous: true
                            smooth: true
                          }

                          // Mini macOS Menu Bar
                          Rectangle {
                            anchors.top: parent.top
                            anchors.left: parent.left
                            anchors.right: parent.right
                            height: 10
                            color: Qt.rgba(0, 0, 0, 0.35)

                            RowLayout {
                              anchors.fill: parent
                              anchors.leftMargin: 6
                              anchors.rightMargin: 6

                              Image {
                                width: 6; height: 6
                                source: "file://" + settingsWin.pluginDir + "/assets/icons/apple-logo.svg"
                                fillMode: Image.PreserveAspectFit
                              }
                              Item { Layout.fillWidth: true }
                              Text {
                                text: "10:09"
                                font.family: "SF Pro Text, -apple-system, sans-serif"
                                font.pixelSize: 6
                                font.weight: Font.Bold
                                color: "#ffffff"
                              }
                            }
                          }

                          // Mini Frosted Glass Dock
                          Rectangle {
                            anchors.bottom: parent.bottom
                            anchors.bottomMargin: 3
                            anchors.horizontalCenter: parent.horizontalCenter
                            width: 80
                            height: 10
                            radius: 5
                            color: Qt.rgba(1, 1, 1, 0.35)
                            border.color: Qt.rgba(255, 255, 255, 0.5)
                            border.width: 0.5

                            Row {
                              anchors.centerIn: parent
                              spacing: 3
                              Repeater {
                                model: ["#007aff", "#34c759", "#ff9500", "#ff2d55", "#af52de", "#5856d6"]
                                Rectangle {
                                  width: 5; height: 5; radius: 2.5
                                  color: modelData
                                }
                              }
                            }
                          }
                        }
                      }

                      // Display Stand
                      Rectangle {
                        Layout.alignment: Qt.AlignHCenter
                        width: 40
                        height: 10
                        radius: 2
                        color: settingsWin.isDark ? "#2c2c34" : "#b0b0b8"
                      }
                      Rectangle {
                        Layout.alignment: Qt.AlignHCenter
                        width: 68
                        height: 3
                        radius: 1.5
                        color: settingsWin.isDark ? "#383842" : "#9c9ca4"
                      }
                    }

                    // Metadata & Quick Actions
                    ColumnLayout {
                      Layout.fillWidth: true
                      spacing: 8
                      Layout.alignment: Qt.AlignVCenter

                      Text {
                        text: {
                          var name = settingsWin.currentWallpaper.replace(/\.(jpg|jpeg|png)$/, "").replace(/_/g, " ").replace(/-/g, " ")
                          return name
                        }
                        font.family: "SF Pro Display, -apple-system, sans-serif"
                        font.pixelSize: 18
                        font.weight: Font.Bold
                        color: settingsWin.textPrimary
                      }

                      Text {
                        text: "Authentic Ultra-High Dynamic Range 6K macOS & Windows vista wallpaper. Configured for your primary display."
                        font.family: "SF Pro Text, -apple-system, sans-serif"
                        font.pixelSize: 12
                        color: settingsWin.textSecondary
                        wrapMode: Text.WordWrap
                        Layout.fillWidth: true
                      }

                      RowLayout {
                        spacing: 6
                        Rectangle {
                          implicitWidth: 80; implicitHeight: 22; radius: 11
                          color: Qt.rgba(settingsWin.accentColor.r, settingsWin.accentColor.g, settingsWin.accentColor.b, 0.15)
                          border.color: settingsWin.accentColor
                          Text { anchors.centerIn: parent; text: "6K HDR"; font.pixelSize: 10; font.bold: true; color: settingsWin.accentColor }
                        }
                        Rectangle {
                          implicitWidth: 90; implicitHeight: 22; radius: 11
                          color: settingsWin.isDark ? Qt.rgba(1, 1, 1, 0.08) : Qt.rgba(0, 0, 0, 0.05)
                          Text { anchors.centerIn: parent; text: "P3 Wide Color"; font.pixelSize: 10; color: settingsWin.textPrimary }
                        }
                        Rectangle {
                          implicitWidth: 100; implicitHeight: 22; radius: 11
                          color: settingsWin.isDark ? Qt.rgba(1, 1, 1, 0.08) : Qt.rgba(0, 0, 0, 0.05)
                          Text { anchors.centerIn: parent; text: "6016 × 3384"; font.pixelSize: 10; color: settingsWin.textSecondary }
                        }
                      }
                    }
                  }
                }

                Text {
                  text: "All Wallpapers & Vistas"
                  font.family: "SF Pro Text, -apple-system, sans-serif"
                  font.pixelSize: 14
                  font.weight: Font.DemiBold
                  color: settingsWin.textPrimary
                }

                GridLayout {
                  Layout.fillWidth: true
                  columns: rightScroller.width > 650 ? 4 : (rightScroller.width > 480 ? 3 : 2)
                  rowSpacing: 14
                  columnSpacing: 14

                  property var walls: [
                    { name: "macOS Tahoe Dark", file: "macOS-Tahoe-Dark.jpg" },
                    { name: "macOS Tahoe Light", file: "macOS-Tahoe-Light.jpg" },
                    { name: "macOS Sequoia Dark", file: "macOS-Sequoia-Dark.jpg" },
                    { name: "macOS Sequoia Light", file: "macOS-Sequoia-Light.jpg" },
                    { name: "macOS Sonoma Dark", file: "Sonoma-dark.jpg" },
                    { name: "macOS Sonoma Light", file: "Sonoma-light.jpg" },
                    { name: "macOS Ventura Dark", file: "Ventura-dark.jpg" },
                    { name: "macOS Monterey", file: "Monterey-dark.jpg" },
                    { name: "macOS Big Sur", file: "WhiteSur-dark.jpg" },
                    { name: "Windows 11 Bloom Dark", file: "win11_bloom_dark.jpg" },
                    { name: "Windows 11 Bloom Light", file: "win11_bloom_light.jpg" },
                    { name: "iOS 18 Beams Dark", file: "ios18_dark.jpg" },
                    { name: "iOS 18 Beams Light", file: "ios18_light.jpg" }
                  ]

                  Repeater {
                    model: parent.walls
                    Rectangle {
                      Layout.fillWidth: true
                      implicitHeight: 120
                      radius: 9
                      color: settingsWin.cardBg
                      border.color: (settingsWin.currentWallpaper === modelData.file) ? settingsWin.accentColor : (wallMouse.containsMouse ? settingsWin.accentColor : settingsWin.cardBorder)
                      border.width: (settingsWin.currentWallpaper === modelData.file) ? 2.5 : (wallMouse.containsMouse ? 2 : 1)
                      clip: true

                      ColumnLayout {
                        anchors.fill: parent
                        spacing: 0

                        Rectangle {
                          Layout.fillWidth: true
                          Layout.fillHeight: true
                          color: settingsWin.isDark ? "#18181b" : "#e5e5ea"
                          clip: true

                          Image {
                            anchors.fill: parent
                            source: "file://" + settingsWin.pluginDir + "/assets/wallpapers/" + modelData.file
                            fillMode: Image.PreserveAspectCrop
                            asynchronous: true
                            smooth: true
                          }

                          // Active Wallpaper Checkmark Badge
                          Rectangle {
                            visible: settingsWin.currentWallpaper === modelData.file
                            anchors.top: parent.top
                            anchors.right: parent.right
                            anchors.margins: 6
                            width: 20; height: 20; radius: 10
                            color: settingsWin.accentColor
                            border.color: "#ffffff"
                            border.width: 1.5

                            Text {
                              anchors.centerIn: parent
                              text: "✓"
                              font.pixelSize: 11
                              font.bold: true
                              color: "#ffffff"
                            }
                          }
                        }

                        Rectangle {
                          Layout.fillWidth: true
                          implicitHeight: 28
                          color: settingsWin.cardBg

                          Text {
                            anchors.fill: parent
                            anchors.leftMargin: 8
                            anchors.rightMargin: 8
                            verticalAlignment: Text.AlignVCenter
                            text: modelData.name
                            font.family: "SF Pro Text, -apple-system, sans-serif"
                            font.pixelSize: 11
                            font.weight: Font.DemiBold
                            color: settingsWin.textPrimary
                            elide: Text.ElideRight
                          }
                        }
                      }

                      MouseArea {
                        id: wallMouse
                        anchors.fill: parent
                        hoverEnabled: true
                        cursorShape: Qt.PointingHandCursor
                        onClicked: {
                          settingsWin.currentWallpaper = modelData.file
                          settingsWin.saveSetting("WALLPAPER", modelData.file)
                          settingsWin.runCmd(settingsWin.pluginDir + "/scripts/omarchy-undercover-wallpaper -s '" + modelData.file + "'")
                        }
                      }
                    }
                  }
                }
              }

              // ==========================================
              // TAB 11: SCREEN SAVER
              // ==========================================
              ColumnLayout {
                visible: settingsWin.currentCategory === 11
                Layout.fillWidth: true
                spacing: 16

                // Header
                ColumnLayout {
                  spacing: 3
                  Text {
                    text: "Screen Saver"
                    font.family: "SF Pro Display, -apple-system, sans-serif"
                    font.pixelSize: 22
                    font.weight: Font.Bold
                    color: settingsWin.textPrimary
                  }
                  Text {
                    text: "High-definition video screensaver with YouTube downloader and aerial presets."
                    font.family: "SF Pro Text, -apple-system, sans-serif"
                    font.pixelSize: 13
                    color: settingsWin.textSecondary
                  }
                }

                // Clean 16:9 Live Preview Card (Decluttered: no fake iMac stand or bulky bezels)
                Rectangle {
                  Layout.fillWidth: true
                  implicitHeight: 220
                  radius: 12
                  color: "#000000"
                  border.color: settingsWin.cardBorder
                  border.width: 1
                  clip: true

                  // High-Res Poster Backdrop Fallback
                  Image {
                    anchors.fill: parent
                    source: "file://" + settingsWin.pluginDir + "/assets/wallpapers/macOS-Tahoe-Dark.jpg"
                    fillMode: Image.PreserveAspectCrop
                    visible: settingsWin.screensaverActiveVideo === "" || previewPlayer.playbackState !== MediaPlayer.PlayingState
                    opacity: (settingsWin.screensaverActiveVideo === "") ? 1.0 : 0.75
                    asynchronous: true
                    smooth: true
                  }

                  // Video Output Component
                  VideoOutput {
                    id: previewVideoOut
                    anchors.fill: parent
                    fillMode: VideoOutput.PreserveAspectCrop
                    visible: settingsWin.screensaverActiveVideo !== ""
                  }

                  MediaPlayer {
                    id: previewPlayer
                    videoOutput: previewVideoOut
                    loops: MediaPlayer.Infinite
                    audioOutput: null
                    source: {
                      if (!settingsWin.screensaverActiveVideo) return ""
                      var s = settingsWin.screensaverActiveVideo
                      if (!s.startsWith("file://") && !s.startsWith("http://") && !s.startsWith("https://")) {
                        return "file://" + s
                      }
                      return s
                    }

                    onSourceChanged: {
                      if (source.toString() !== "") {
                        play()
                      }
                    }

                    Component.onCompleted: {
                      if (settingsWin.screensaverActiveVideo !== "") play()
                    }
                  }

                  // Live Status Pill Tag
                  Rectangle {
                    anchors.top: parent.top
                    anchors.left: parent.left
                    anchors.margins: 10
                    radius: 5
                    color: Qt.rgba(0, 0, 0, 0.65)
                    height: 22
                    implicitWidth: scText.implicitWidth + 16

                    Text {
                      id: scText
                      anchors.centerIn: parent
                      text: settingsWin.screensaverActiveVideo !== "" ? "● LIVE VIDEO ACTIVE" : "SAMPLE PREVIEW"
                      font.family: "SF Pro Text, -apple-system, sans-serif"
                      font.pixelSize: 9
                      font.weight: Font.Bold
                      color: settingsWin.screensaverActiveVideo !== "" ? "#34c759" : "#ffffff"
                    }
                  }

                  // Floating Glass Bottom Toolbar
                  Rectangle {
                    anchors.bottom: parent.bottom
                    anchors.left: parent.left
                    anchors.right: parent.right
                    height: 42
                    color: Qt.rgba(0, 0, 0, 0.72)

                    RowLayout {
                      anchors.fill: parent
                      anchors.leftMargin: 12
                      anchors.rightMargin: 12
                      spacing: 10

                      Rectangle {
                        width: 28; height: 28; radius: 14
                        color: Qt.rgba(1, 1, 1, 0.2)
                        Text {
                          anchors.centerIn: parent
                          text: (previewPlayer.playbackState === MediaPlayer.PlayingState && settingsWin.screensaverActiveVideo !== "") ? "⏸" : "▶"
                          font.pixelSize: 12
                          color: "#ffffff"
                        }
                        MouseArea {
                          anchors.fill: parent
                          cursorShape: Qt.PointingHandCursor
                          onClicked: {
                            if (previewPlayer.playbackState === MediaPlayer.PlayingState) {
                              previewPlayer.pause()
                            } else {
                              if (settingsWin.screensaverActiveVideo !== "") {
                                if (previewPlayer.source.toString() === "") {
                                  var s = settingsWin.screensaverActiveVideo
                                  previewPlayer.source = s.startsWith("file://") ? s : "file://" + s
                                }
                                previewPlayer.play()
                              }
                            }
                          }
                        }
                      }

                      Text {
                        Layout.fillWidth: true
                        text: {
                          if (!settingsWin.screensaverActiveVideo) return "Sonoma Horizon Aerial (1080p)"
                          var parts = settingsWin.screensaverActiveVideo.split("/")
                          var fn = parts[parts.length - 1].replace(/\.(mp4|webm)$/, "").replace(/_/g, " ")
                          return fn.charAt(0).toUpperCase() + fn.slice(1)
                        }
                        font.family: "SF Pro Text, -apple-system, sans-serif"
                        font.pixelSize: 11
                        font.weight: Font.DemiBold
                        color: "#ffffff"
                        elide: Text.ElideRight
                      }

                      Rectangle {
                        implicitWidth: 120; implicitHeight: 26
                        radius: 13
                        color: settingsWin.accentColor

                        Text {
                          anchors.centerIn: parent
                          text: "Fullscreen Preview"
                          font.family: "SF Pro Text, -apple-system, sans-serif"
                          font.pixelSize: 10
                          font.weight: Font.Bold
                          color: "#ffffff"
                        }

                        MouseArea {
                          anchors.fill: parent
                          cursorShape: Qt.PointingHandCursor
                          onClicked: {
                            previewPlayer.pause()
                            settingsWin.runCmd("qs -p /usr/share/omarchy/shell ipc call omarchy-undercover-service previewScreensaver 2>/dev/null || qs ipc call omarchy-undercover-service previewScreensaver 2>/dev/null || " + settingsWin.pluginDir + "/scripts/omarchy-mac-screensaver --preview")
                          }
                        }
                      }

                      Rectangle {
                        implicitWidth: 125; implicitHeight: 26
                        radius: 13
                        color: Qt.rgba(255, 255, 255, 0.2)
                        border.color: Qt.rgba(255, 255, 255, 0.3)
                        border.width: 1

                        Text {
                          anchors.centerIn: parent
                          text: "Preview Lock Screen"
                          font.family: "SF Pro Text, -apple-system, sans-serif"
                          font.pixelSize: 10
                          font.weight: Font.Bold
                          color: "#ffffff"
                        }

                        MouseArea {
                          anchors.fill: parent
                          cursorShape: Qt.PointingHandCursor
                          onClicked: {
                            previewPlayer.pause()
                            settingsWin.runCmd("qs -p /usr/share/omarchy/shell ipc call omarchy-undercover-service previewLockscreen 2>/dev/null || qs ipc call omarchy-undercover-service previewLockscreen 2>/dev/null || " + settingsWin.pluginDir + "/scripts/omarchy-mac-screensaver --preview-lock")
                          }
                        }
                      }
                    }
                  }
                }

                // Preferences Card (Enable Toggle & Inactivity Timeout)
                Rectangle {
                  Layout.fillWidth: true
                  implicitHeight: prefCol.implicitHeight + 28
                  radius: 10
                  color: settingsWin.cardBg
                  border.color: settingsWin.cardBorder
                  border.width: 1

                  ColumnLayout {
                    id: prefCol
                    anchors.fill: parent
                    anchors.margins: 14
                    spacing: 12

                    // Row 1: Enable Toggle
                    RowLayout {
                      Layout.fillWidth: true
                      ColumnLayout {
                        Layout.fillWidth: true
                        spacing: 2
                        Text {
                          text: "Enable Screen Saver"
                          font.family: "SF Pro Text, -apple-system, sans-serif"
                          font.pixelSize: 13
                          font.weight: Font.DemiBold
                          color: settingsWin.textPrimary
                        }
                        Text {
                          text: "Plays fullscreen aerial video when system is idle in macOS mode"
                          font.family: "SF Pro Text, -apple-system, sans-serif"
                          font.pixelSize: 11
                          color: settingsWin.textSecondary
                        }
                      }

                      Rectangle {
                        width: 38; height: 22; radius: 11
                        color: settingsWin.screensaverEnabled ? "#34c759" : (settingsWin.isDark ? "#39393d" : "#e5e5ea")
                        Rectangle {
                          width: 18; height: 18; radius: 9; y: 2
                          x: settingsWin.screensaverEnabled ? 18 : 2
                          color: "#ffffff"
                          Behavior on x { NumberAnimation { duration: 150 } }
                        }
                        MouseArea {
                          anchors.fill: parent
                          cursorShape: Qt.PointingHandCursor
                          onClicked: settingsWin.toggleScreensaver(!settingsWin.screensaverEnabled)
                        }
                      }
                    }

                    Rectangle {
                      Layout.fillWidth: true
                      height: 1
                      color: settingsWin.separatorColor
                    }

                    // Row 2: Inactivity Timeout
                    RowLayout {
                      Layout.fillWidth: true
                      ColumnLayout {
                        Layout.fillWidth: true
                        spacing: 2
                        Text {
                          text: "Start After Inactivity"
                          font.family: "SF Pro Text, -apple-system, sans-serif"
                          font.pixelSize: 13
                          font.weight: Font.DemiBold
                          color: settingsWin.textPrimary
                        }
                        Text {
                          text: "Inactivity time threshold (" + Math.round(settingsWin.screensaverTimeout / 60) + " min)"
                          font.family: "SF Pro Text, -apple-system, sans-serif"
                          font.pixelSize: 11
                          color: settingsWin.textSecondary
                        }
                      }

                      RowLayout {
                        spacing: 4
                        Repeater {
                          model: [
                            { label: "1m", sec: 60 },
                            { label: "2m", sec: 120 },
                            { label: "5m", sec: 300 },
                            { label: "10m", sec: 600 },
                            { label: "15m", sec: 900 },
                            { label: "30m", sec: 1800 }
                          ]

                          Rectangle {
                            width: 38; height: 26; radius: 6
                            readonly property bool isCur: settingsWin.screensaverTimeout === modelData.sec
                            color: isCur ? settingsWin.accentColor : (settingsWin.isDark ? Qt.rgba(1, 1, 1, 0.08) : Qt.rgba(0, 0, 0, 0.05))

                            Text {
                              anchors.centerIn: parent
                              text: modelData.label
                              font.family: "SF Pro Text, -apple-system, sans-serif"
                              font.pixelSize: 11
                              font.weight: isCur ? Font.Bold : Font.Normal
                              color: isCur ? "#ffffff" : settingsWin.textPrimary
                            }

                            MouseArea {
                              anchors.fill: parent
                              cursorShape: Qt.PointingHandCursor
                              onClicked: settingsWin.setScreensaverTimeoutSec(modelData.sec)
                            }
                          }
                        }
                      }
                    }
                  }
                }

                // YouTube & Video URL Downloader Card
                Rectangle {
                  Layout.fillWidth: true
                  implicitHeight: dlCol.implicitHeight + 28
                  radius: 10
                  color: settingsWin.cardBg
                  border.color: settingsWin.cardBorder
                  border.width: 1

                  ColumnLayout {
                    id: dlCol
                    anchors.fill: parent
                    anchors.margins: 14
                    spacing: 12

                    RowLayout {
                      Layout.fillWidth: true
                      ColumnLayout {
                        Layout.fillWidth: true
                        spacing: 2
                        Text {
                          text: "Download from YouTube or Web"
                          font.family: "SF Pro Text, -apple-system, sans-serif"
                          font.pixelSize: 13
                          font.weight: Font.DemiBold
                          color: settingsWin.textPrimary
                        }
                        Text {
                          text: "Paste any YouTube video or direct MP4 link to download and set as screensaver"
                          font.family: "SF Pro Text, -apple-system, sans-serif"
                          font.pixelSize: 11
                          color: settingsWin.textSecondary
                        }
                      }

                      Rectangle {
                        implicitWidth: 130; implicitHeight: 28; radius: 6
                        color: settingsWin.isDark ? Qt.rgba(1, 1, 1, 0.08) : Qt.rgba(0, 0, 0, 0.05)
                        border.color: settingsWin.cardBorder

                        Text {
                          anchors.centerIn: parent
                          text: "📁 Local Video..."
                          font.family: "SF Pro Text, -apple-system, sans-serif"
                          font.pixelSize: 11
                          font.weight: Font.Medium
                          color: settingsWin.textPrimary
                        }

                        MouseArea {
                          anchors.fill: parent
                          cursorShape: Qt.PointingHandCursor
                          onClicked: {
                            settingsWin.runCmd("if command -v zenity &>/dev/null; then f=$(zenity --file-selection --title='Select Screensaver Video' --file-filter='Video Files | *.mp4 *.webm *.mkv'); [[ -n \"$f\" ]] && " + settingsWin.pluginDir + "/scripts/omarchy-mac-screensaver --set \"$f\"; fi")
                          }
                        }
                      }
                    }

                    // URL Input Row with Download Button
                    RowLayout {
                      Layout.fillWidth: true
                      spacing: 8

                      Rectangle {
                        Layout.fillWidth: true
                        height: 34
                        radius: 6
                        color: settingsWin.isDark ? Qt.rgba(0, 0, 0, 0.35) : Qt.rgba(1, 1, 1, 0.8)
                        border.color: urlInput.activeFocus ? settingsWin.accentColor : settingsWin.cardBorder
                        border.width: urlInput.activeFocus ? 2 : 1

                        RowLayout {
                          anchors.fill: parent
                          anchors.leftMargin: 10
                          anchors.rightMargin: 10
                          spacing: 8

                          Text {
                            text: "▶"
                            font.pixelSize: 11
                            color: settingsWin.textSecondary
                          }

                          TextInput {
                            id: urlInput
                            Layout.fillWidth: true
                            font.family: "SF Pro Text, -apple-system, sans-serif"
                            font.pixelSize: 12
                            color: settingsWin.textPrimary
                            clip: true
                            selectByMouse: true

                            Text {
                              visible: !urlInput.text
                              text: "Paste YouTube or video URL (e.g. https://www.youtube.com/watch?v=...)"
                              font.family: "SF Pro Text, -apple-system, sans-serif"
                              font.pixelSize: 11
                              color: settingsWin.textSecondary
                            }
                          }
                        }
                      }

                      Rectangle {
                        id: dlBtn
                        implicitWidth: 120; implicitHeight: 34
                        radius: 6
                        readonly property bool isBusy: settingsWin.screensaverDownloadingId !== ""
                        readonly property bool canDownload: urlInput.text.trim().length > 5 && !dlBtn.isBusy
                        color: dlBtn.canDownload ? settingsWin.accentColor : (settingsWin.isDark ? Qt.rgba(1, 1, 1, 0.08) : Qt.rgba(0, 0, 0, 0.06))

                        Text {
                          anchors.centerIn: parent
                          text: dlBtn.isBusy ? "Downloading…" : "Download & Set"
                          font.family: "SF Pro Text, -apple-system, sans-serif"
                          font.pixelSize: 11
                          font.weight: Font.DemiBold
                          color: dlBtn.canDownload ? "#ffffff" : settingsWin.textSecondary
                        }

                        MouseArea {
                          anchors.fill: parent
                          enabled: dlBtn.canDownload
                          cursorShape: dlBtn.canDownload ? Qt.PointingHandCursor : Qt.ArrowCursor
                          onClicked: {
                            var u = urlInput.text.trim()
                            if (u) {
                              settingsWin.downloadScreensaverClip(u)
                              urlInput.text = ""
                            }
                          }
                        }
                      }
                    }
                  }
                }

                // Curated Aerial Landscapes Presets Section
                ColumnLayout {
                  Layout.fillWidth: true
                  spacing: 12

                  ColumnLayout {
                    spacing: 2
                    Text {
                      text: "Curated Aerial Landscapes"
                      font.family: "SF Pro Text, -apple-system, sans-serif"
                      font.pixelSize: 14
                      font.weight: Font.DemiBold
                      color: settingsWin.textPrimary
                    }
                    Text {
                      text: "1080p aerial drone footage across California, Patagonia, Greenland, and Dubai"
                      font.family: "SF Pro Text, -apple-system, sans-serif"
                      font.pixelSize: 11
                      color: settingsWin.textSecondary
                    }
                  }

                  GridLayout {
                    Layout.fillWidth: true
                    columns: rightScroller.width > 620 ? 2 : 1
                    rowSpacing: 10
                    columnSpacing: 10

                    Repeater {
                      model: settingsWin.screensaverCatalog

                      Rectangle {
                        Layout.fillWidth: true
                        implicitHeight: 140
                        radius: 8
                        color: settingsWin.cardBg
                        readonly property bool isSelected: settingsWin.screensaverActiveVideo === modelData.path && modelData.installed
                        border.color: isSelected ? settingsWin.accentColor : (presetMouse.containsMouse ? settingsWin.accentColor : settingsWin.cardBorder)
                        border.width: isSelected ? 2 : 1
                        clip: true

                        ColumnLayout {
                          anchors.fill: parent
                          spacing: 0

                          // Landscape Thumbnail Banner
                          Rectangle {
                            Layout.fillWidth: true
                            Layout.fillHeight: true
                            color: "#0a0a0c"
                            clip: true

                            Image {
                              anchors.fill: parent
                              source: "file://" + settingsWin.pluginDir + "/assets/wallpapers/" + (modelData.thumbnail || "Sonoma-dark.jpg")
                              fillMode: Image.PreserveAspectCrop
                              asynchronous: true
                              smooth: true
                            }

                            // Location tag
                            Rectangle {
                              anchors.top: parent.top
                              anchors.left: parent.left
                              anchors.margins: 6
                              radius: 4
                              color: Qt.rgba(0, 0, 0, 0.6)
                              height: 18
                              implicitWidth: locText.implicitWidth + 10

                              Text {
                                id: locText
                                anchors.centerIn: parent
                                text: modelData.location
                                font.family: "SF Pro Text, -apple-system, sans-serif"
                                font.pixelSize: 9
                                color: "#ffffff"
                              }
                            }

                            // Tag
                            Rectangle {
                              anchors.top: parent.top
                              anchors.right: parent.right
                              anchors.margins: 6
                              radius: 4
                              color: Qt.rgba(0, 0, 0, 0.6)
                              height: 18
                              implicitWidth: resText.implicitWidth + 10

                              Text {
                                id: resText
                                anchors.centerIn: parent
                                text: modelData.res
                                font.family: "SF Pro Text, -apple-system, sans-serif"
                                font.pixelSize: 9
                                font.weight: Font.Bold
                                color: "#34c759"
                              }
                            }

                            // Active checkmark badge
                            Rectangle {
                              visible: isSelected
                              anchors.bottom: parent.bottom
                              anchors.right: parent.right
                              anchors.margins: 6
                              width: 20; height: 20; radius: 10
                              color: settingsWin.accentColor
                              border.color: "#ffffff"
                              border.width: 1

                              Text {
                                anchors.centerIn: parent
                                text: "✓"
                                font.pixelSize: 11
                                font.bold: true
                                color: "#ffffff"
                              }
                            }
                          }

                          // Caption & Action
                          Rectangle {
                            Layout.fillWidth: true
                            implicitHeight: 46
                            color: settingsWin.cardBg

                            RowLayout {
                              anchors.fill: parent
                              anchors.leftMargin: 10
                              anchors.rightMargin: 10
                              spacing: 8

                              ColumnLayout {
                                Layout.fillWidth: true
                                spacing: 1
                                Text {
                                  text: modelData.name
                                  font.family: "SF Pro Text, -apple-system, sans-serif"
                                  font.pixelSize: 12
                                  font.weight: Font.DemiBold
                                  color: settingsWin.textPrimary
                                  elide: Text.ElideRight
                                }
                                Text {
                                  text: modelData.size + (modelData.installed ? " • Ready" : " • YouTube")
                                  font.family: "SF Pro Text, -apple-system, sans-serif"
                                  font.pixelSize: 10
                                  color: settingsWin.textSecondary
                                }
                              }

                              Rectangle {
                                z: 10
                                implicitWidth: modelData.installed ? (isSelected ? 65 : 75) : 85
                                implicitHeight: 26
                                radius: 13
                                color: isSelected
                                       ? Qt.rgba(settingsWin.accentColor.r, settingsWin.accentColor.g, settingsWin.accentColor.b, 0.15)
                                       : (modelData.installed
                                          ? (settingsWin.isDark ? Qt.rgba(1, 1, 1, 0.1) : Qt.rgba(0, 0, 0, 0.08))
                                          : (settingsWin.screensaverDownloadingId === modelData.id ? Qt.rgba(1, 0.58, 0, 0.15) : settingsWin.accentColor))
                                border.color: isSelected ? settingsWin.accentColor : (settingsWin.screensaverDownloadingId === modelData.id ? "#ff9500" : "transparent")

                                Text {
                                  anchors.centerIn: parent
                                  text: isSelected ? "Active" : (modelData.installed ? "Set Active" : (settingsWin.screensaverDownloadingId === modelData.id ? "Downloading…" : "Download"))
                                  font.family: "SF Pro Text, -apple-system, sans-serif"
                                  font.pixelSize: 10
                                  font.weight: Font.DemiBold
                                  color: isSelected ? settingsWin.accentColor : (modelData.installed ? settingsWin.textPrimary : (settingsWin.screensaverDownloadingId === modelData.id ? "#ff9500" : "#ffffff"))
                                }

                                MouseArea {
                                  anchors.fill: parent
                                  enabled: settingsWin.screensaverDownloadingId !== modelData.id
                                  cursorShape: enabled ? Qt.PointingHandCursor : Qt.ArrowCursor
                                  onClicked: {
                                    if (modelData.installed) {
                                      settingsWin.setScreensaverActiveClip(modelData.path)
                                      var src = modelData.path.startsWith("file://") ? modelData.path : "file://" + modelData.path
                                      previewPlayer.source = src
                                      previewPlayer.play()
                                    } else {
                                      settingsWin.downloadScreensaverClip(modelData.id)
                                    }
                                  }
                                }
                              }
                            }
                          }
                        }

                        MouseArea {
                          id: presetMouse
                          z: 1
                          anchors.fill: parent
                          hoverEnabled: true
                          cursorShape: Qt.PointingHandCursor
                          onClicked: {
                            if (modelData.installed) {
                              settingsWin.setScreensaverActiveClip(modelData.path)
                              var src = modelData.path.startsWith("file://") ? modelData.path : "file://" + modelData.path
                              previewPlayer.source = src
                              previewPlayer.play()
                            } else {
                              settingsWin.downloadScreensaverClip(modelData.id)
                            }
                          }
                        }
                      }
                    }
                  }
                }
              }

              // ==========================================
              // TAB 3: WI-FI
              // ==========================================
              ColumnLayout {
                visible: settingsWin.currentCategory === 3
                Layout.fillWidth: true
                spacing: 16

                // 1. Apple-style Wi-Fi Hero Toggle Card
                Rectangle {
                  Layout.fillWidth: true
                  implicitHeight: 74
                  radius: 10
                  color: settingsWin.cardBg
                  border.color: settingsWin.cardBorder
                  border.width: 1

                  RowLayout {
                    anchors.fill: parent
                    anchors.margins: 16
                    spacing: 14

                    Rectangle {
                      width: 32; height: 32; radius: 8
                      color: "#007aff"
                      Image {
                        anchors.centerIn: parent
                        width: 18; height: 18
                        source: "file://" + settingsWin.pluginDir + "/assets/icons/mac-settings/wifi.svg"
                        fillMode: Image.PreserveAspectFit
                      }
                    }

                    ColumnLayout {
                      Layout.fillWidth: true
                      spacing: 2
                      Text {
                        text: "Wi-Fi"
                        font.family: "SF Pro Text, -apple-system, sans-serif"
                        font.pixelSize: 13
                        font.weight: Font.DemiBold
                        color: settingsWin.textPrimary
                      }
                      Text {
                        text: settingsService.wifiEnabled ? (settingsService.wifiActiveSsid ? "Connected to " + settingsService.wifiActiveSsid : "Looking for networks nearby...") : "Wi-Fi is Off"
                        font.family: "SF Pro Text, -apple-system, sans-serif"
                        font.pixelSize: 11
                        color: settingsWin.textSecondary
                      }
                    }

                    Rectangle {
                      width: 38; height: 22; radius: 11
                      color: settingsService.wifiEnabled ? "#34c759" : (settingsWin.isDark ? "#39393d" : "#e5e5ea")
                      Rectangle {
                        width: 18; height: 18; radius: 9
                        x: settingsService.wifiEnabled ? 18 : 2
                        anchors.verticalCenter: parent.verticalCenter
                        color: "#ffffff"
                        Behavior on x { NumberAnimation { duration: 120; easing.type: Easing.OutQuad } }
                      }
                      MouseArea {
                        anchors.fill: parent
                        cursorShape: Qt.PointingHandCursor
                        onClicked: settingsService.toggleWifi(!settingsService.wifiEnabled)
                      }
                    }
                  }
                }

                // 2. Active Network Card (If Connected)
                Rectangle {
                  visible: settingsService.wifiEnabled && settingsService.wifiActiveSsid !== ""
                  Layout.fillWidth: true
                  implicitHeight: 74
                  radius: 10
                  color: settingsWin.cardBg
                  border.color: settingsWin.cardBorder
                  border.width: 1

                  RowLayout {
                    anchors.fill: parent
                    anchors.margins: 16
                    spacing: 14

                    Text { text: "📶"; font.pixelSize: 22 }

                    ColumnLayout {
                      Layout.fillWidth: true
                      spacing: 2
                      Text {
                        text: settingsService.wifiActiveSsid
                        font.family: "SF Pro Text, -apple-system, sans-serif"
                        font.pixelSize: 13
                        font.weight: Font.DemiBold
                        color: settingsWin.textPrimary
                      }
                      Text {
                        text: "Connected, Secured • Known Network"
                        font.family: "SF Pro Text, -apple-system, sans-serif"
                        font.pixelSize: 11
                        color: "#34c759"
                      }
                    }

                    Rectangle {
                      implicitWidth: 92
                      implicitHeight: 28
                      radius: 6
                      color: disBtnM.containsMouse ? (settingsWin.isDark ? Qt.rgba(1, 1, 1, 0.12) : Qt.rgba(0, 0, 0, 0.08)) : (settingsWin.isDark ? Qt.rgba(1, 1, 1, 0.06) : Qt.rgba(0, 0, 0, 0.04))
                      border.color: settingsWin.cardBorder
                      border.width: 1
                      Text {
                        anchors.centerIn: parent
                        text: "Disconnect"
                        font.family: "SF Pro Text, -apple-system, sans-serif"
                        font.pixelSize: 11
                        color: settingsWin.textPrimary
                      }
                      MouseArea {
                        id: disBtnM
                        anchors.fill: parent
                        hoverEnabled: true
                        cursorShape: Qt.PointingHandCursor
                        onClicked: settingsService.disconnectWifi()
                      }
                    }
                  }
                }

                // 2b. Disconnected Status Card (If Not Connected)
                Rectangle {
                  visible: settingsService.wifiEnabled && settingsService.wifiActiveSsid === ""
                  Layout.fillWidth: true
                  implicitHeight: 64
                  radius: 10
                  color: settingsWin.cardBg
                  border.color: settingsWin.cardBorder
                  border.width: 1

                  RowLayout {
                    anchors.fill: parent
                    anchors.margins: 16
                    spacing: 14

                    Text { text: "󰤭"; font.pixelSize: 22; color: settingsWin.textSecondary }

                    ColumnLayout {
                      Layout.fillWidth: true
                      spacing: 2
                      Text {
                        text: "Not Connected"
                        font.family: "SF Pro Text, -apple-system, sans-serif"
                        font.pixelSize: 13
                        font.weight: Font.DemiBold
                        color: settingsWin.textPrimary
                      }
                      Text {
                        text: "Wi-Fi is on but not connected to any network"
                        font.family: "SF Pro Text, -apple-system, sans-serif"
                        font.pixelSize: 11
                        color: settingsWin.textSecondary
                      }
                    }
                  }
                }

                // 3. Available Networks Card
                Rectangle {
                  visible: settingsService.wifiEnabled
                  Layout.fillWidth: true
                  implicitHeight: netCol.implicitHeight + 28
                  radius: 10
                  color: settingsWin.cardBg
                  border.color: settingsWin.cardBorder
                  border.width: 1

                  ColumnLayout {
                    id: netCol
                    anchors.fill: parent
                    anchors.margins: 16
                    spacing: 12

                    RowLayout {
                      Layout.fillWidth: true
                      Text {
                        text: "Available Networks"
                        font.family: "SF Pro Text, -apple-system, sans-serif"
                        font.pixelSize: 13
                        font.weight: Font.DemiBold
                        color: settingsWin.textPrimary
                        Layout.fillWidth: true
                      }

                      Rectangle {
                        implicitWidth: 84
                        implicitHeight: 28
                        radius: 6
                        color: rescanM.containsMouse ? (settingsWin.isDark ? Qt.rgba(1, 1, 1, 0.14) : Qt.rgba(0, 0, 0, 0.08)) : (settingsWin.isDark ? Qt.rgba(1, 1, 1, 0.06) : Qt.rgba(0, 0, 0, 0.04))
                        border.color: settingsWin.cardBorder
                        border.width: 1
                        Text {
                          anchors.centerIn: parent
                          text: settingsService.wifiScanning ? "Scanning..." : "Rescan"
                          font.family: "SF Pro Text, -apple-system, sans-serif"
                          font.pixelSize: 11
                          color: settingsWin.textPrimary
                        }
                        MouseArea {
                          id: rescanM
                          anchors.fill: parent
                          hoverEnabled: true
                          cursorShape: Qt.PointingHandCursor
                          onClicked: settingsService.scanWifi()
                        }
                      }
                    }

                    Rectangle { Layout.fillWidth: true; height: 1; color: settingsWin.separatorColor }

                    ColumnLayout {
                      Layout.fillWidth: true
                      spacing: 4

                      property string expandedSsid: ""

                      Text {
                        visible: settingsService.wifiNetworks.length === 0
                        text: "No other Wi-Fi networks found nearby. Click Rescan to search."
                        font.family: "SF Pro Text, -apple-system, sans-serif"
                        font.pixelSize: 11
                        color: settingsWin.textSecondary
                      }

                      Repeater {
                        model: settingsService.wifiNetworks
                        delegate: Rectangle {
                          Layout.fillWidth: true
                          implicitHeight: isExpanded ? 84 : 40
                          radius: 7
                          readonly property bool isExpanded: parent.expandedSsid === modelData.ssid
                          color: isExpanded
                                 ? (settingsWin.isDark ? Qt.rgba(0.2, 0.48, 1.0, 0.16) : Qt.rgba(0.0, 0.48, 1.0, 0.08))
                                 : (wifiRowM.containsMouse ? (settingsWin.isDark ? Qt.rgba(1, 1, 1, 0.06) : Qt.rgba(0, 0, 0, 0.04)) : "transparent")

                          ColumnLayout {
                            anchors.fill: parent
                            anchors.margins: 8
                            spacing: 6

                            RowLayout {
                              Layout.fillWidth: true
                              spacing: 10

                              Text { text: "📶"; font.pixelSize: 14 }
                              Text {
                                text: modelData.ssid || "Hidden Network"
                                font.family: "SF Pro Text, -apple-system, sans-serif"
                                font.pixelSize: 12
                                font.weight: modelData.connected ? Font.DemiBold : Font.Normal
                                color: settingsWin.textPrimary
                                Layout.fillWidth: true
                                elide: Text.ElideRight
                              }
                              Text {
                                visible: modelData.security && modelData.security !== "--"
                                text: "🔒"
                                font.pixelSize: 11
                              }
                              Text {
                                visible: Boolean(modelData.connected)
                                text: "✓"
                                font.pixelSize: 12
                                font.weight: Font.Bold
                                color: "#34c759"
                              }
                            }

                            // Password prompt when expanded
                            RowLayout {
                              visible: isExpanded && !Boolean(modelData.connected)
                              Layout.fillWidth: true
                              spacing: 8

                              Rectangle {
                                Layout.fillWidth: true
                                implicitHeight: 28
                                radius: 6
                                color: settingsWin.isDark ? Qt.rgba(0, 0, 0, 0.3) : "#ffffff"
                                border.color: settingsWin.cardBorder
                                border.width: 1

                                TextInput {
                                  id: pwField
                                  anchors.fill: parent
                                  anchors.margins: 6
                                  echoMode: TextInput.Password
                                  font.family: "SF Pro Text, -apple-system, sans-serif"
                                  font.pixelSize: 11
                                  color: settingsWin.textPrimary
                                  clip: true
                                }
                              }

                              Rectangle {
                                implicitWidth: 68
                                implicitHeight: 28
                                radius: 6
                                color: settingsWin.accentColor
                                Text {
                                  anchors.centerIn: parent
                                  text: "Join"
                                  font.family: "SF Pro Text, -apple-system, sans-serif"
                                  font.pixelSize: 11
                                  font.weight: Font.DemiBold
                                  color: "#ffffff"
                                }
                                MouseArea {
                                  anchors.fill: parent
                                  cursorShape: Qt.PointingHandCursor
                                  onClicked: {
                                    settingsService.connectWifi(modelData.ssid, pwField.text)
                                    parent.parent.parent.parent.parent.expandedSsid = ""
                                  }
                                }
                              }
                            }
                          }

                          MouseArea {
                            id: wifiRowM
                            anchors.fill: parent
                            hoverEnabled: true
                            cursorShape: Qt.PointingHandCursor
                            enabled: !isExpanded
                            onClicked: {
                              if (modelData.connected) return
                              if (modelData.security && modelData.security !== "--") {
                                parent.parent.expandedSsid = modelData.ssid
                              } else {
                                settingsService.connectWifi(modelData.ssid, "")
                              }
                            }
                          }
                        }
                      }
                    }
                  }
                }
              }

              // ==========================================
              // TAB 4: BLUETOOTH
              // ==========================================
              ColumnLayout {
                visible: settingsWin.currentCategory === 4
                Layout.fillWidth: true
                spacing: 16

                // 1. Apple-style Bluetooth Hero Toggle Card
                Rectangle {
                  Layout.fillWidth: true
                  implicitHeight: 74
                  radius: 10
                  color: settingsWin.cardBg
                  border.color: settingsWin.cardBorder
                  border.width: 1

                  RowLayout {
                    anchors.fill: parent
                    anchors.margins: 16
                    spacing: 14

                    Rectangle {
                      width: 32; height: 32; radius: 8
                      color: "#007aff"
                      Image {
                        anchors.centerIn: parent
                        width: 18; height: 18
                        source: "file://" + settingsWin.pluginDir + "/assets/icons/mac-settings/bluetooth.svg"
                        fillMode: Image.PreserveAspectFit
                      }
                    }

                    ColumnLayout {
                      Layout.fillWidth: true
                      spacing: 2
                      Text {
                        text: "Bluetooth"
                        font.family: "SF Pro Text, -apple-system, sans-serif"
                        font.pixelSize: 13
                        font.weight: Font.DemiBold
                        color: settingsWin.textPrimary
                      }
                      Text {
                        text: settingsService.btEnabled ? "Now discoverable as \"Omarchy Mac\"" : "Bluetooth is Off"
                        font.family: "SF Pro Text, -apple-system, sans-serif"
                        font.pixelSize: 11
                        color: settingsWin.textSecondary
                      }
                    }

                    Rectangle {
                      width: 38; height: 22; radius: 11
                      color: settingsService.btEnabled ? "#34c759" : (settingsWin.isDark ? "#39393d" : "#e5e5ea")
                      Rectangle {
                        width: 18; height: 18; radius: 9
                        x: settingsService.btEnabled ? 18 : 2
                        anchors.verticalCenter: parent.verticalCenter
                        color: "#ffffff"
                        Behavior on x { NumberAnimation { duration: 120; easing.type: Easing.OutQuad } }
                      }
                      MouseArea {
                        anchors.fill: parent
                        cursorShape: Qt.PointingHandCursor
                        onClicked: settingsService.toggleBluetooth(!settingsService.btEnabled)
                      }
                    }
                  }
                }

                // 2. Devices & Accessories Card
                Rectangle {
                  visible: settingsService.btEnabled
                  Layout.fillWidth: true
                  implicitHeight: btAccCol.implicitHeight + 28
                  radius: 10
                  color: settingsWin.cardBg
                  border.color: settingsWin.cardBorder
                  border.width: 1

                  ColumnLayout {
                    id: btAccCol
                    anchors.fill: parent
                    anchors.margins: 16
                    spacing: 12

                    RowLayout {
                      Layout.fillWidth: true
                      Text {
                        text: "My Devices"
                        font.family: "SF Pro Text, -apple-system, sans-serif"
                        font.pixelSize: 13
                        font.weight: Font.DemiBold
                        color: settingsWin.textPrimary
                        Layout.fillWidth: true
                      }

                      Rectangle {
                        implicitWidth: 104
                        implicitHeight: 28
                        radius: 6
                        color: scanBtM.containsMouse ? (settingsWin.isDark ? Qt.rgba(1, 1, 1, 0.14) : Qt.rgba(0, 0, 0, 0.08)) : (settingsWin.isDark ? Qt.rgba(1, 1, 1, 0.06) : Qt.rgba(0, 0, 0, 0.04))
                        border.color: settingsWin.cardBorder
                        border.width: 1
                        Text {
                          anchors.centerIn: parent
                          text: settingsService.btDiscovering ? "Scanning..." : "Scan for Devices"
                          font.family: "SF Pro Text, -apple-system, sans-serif"
                          font.pixelSize: 11
                          color: settingsWin.textPrimary
                        }
                        MouseArea {
                          id: scanBtM
                          anchors.fill: parent
                          hoverEnabled: true
                          cursorShape: Qt.PointingHandCursor
                          onClicked: settingsService.scanBluetooth()
                        }
                      }
                    }

                    Rectangle { Layout.fillWidth: true; height: 1; color: settingsWin.separatorColor }

                    // Devices List
                    ColumnLayout {
                      Layout.fillWidth: true
                      spacing: 6

                      Text {
                        visible: settingsService.btDevices.length === 0
                        text: "No Bluetooth accessories found nearby. Put your device in pairing mode."
                        font.family: "SF Pro Text, -apple-system, sans-serif"
                        font.pixelSize: 11
                        color: settingsWin.textSecondary
                      }

                      Repeater {
                        model: settingsService.btDevices
                        delegate: Rectangle {
                          Layout.fillWidth: true
                          implicitHeight: 46
                          radius: 7
                          color: settingsWin.isDark ? Qt.rgba(1, 1, 1, 0.04) : Qt.rgba(0, 0, 0, 0.02)

                          RowLayout {
                            anchors.fill: parent
                            anchors.leftMargin: 12
                            anchors.rightMargin: 12
                            spacing: 12

                            Text {
                              text: {
                                var n = (modelData.name || "").toLowerCase()
                                if (n.indexOf("head") !== -1 || n.indexOf("bud") !== -1 || n.indexOf("airpod") !== -1) return "🎧"
                                if (n.indexOf("mouse") !== -1) return "🖱️"
                                if (n.indexOf("key") !== -1) return "⌨️"
                                return "📶"
                              }
                              font.pixelSize: 15
                            }

                            ColumnLayout {
                              Layout.fillWidth: true
                              spacing: 1
                              Text {
                                text: modelData.name || modelData.address || "Bluetooth Accessory"
                                font.family: "SF Pro Text, -apple-system, sans-serif"
                                font.pixelSize: 12
                                font.weight: Font.DemiBold
                                color: settingsWin.textPrimary
                              }
                              Text {
                                text: modelData.connected ? ("Connected" + (modelData.battery !== undefined ? " • " + modelData.battery + "%" : "")) : (modelData.paired ? "Not Connected" : "Nearby Accessory")
                                font.family: "SF Pro Text, -apple-system, sans-serif"
                                font.pixelSize: 10
                                color: modelData.connected ? "#34c759" : settingsWin.textSecondary
                              }
                            }

                            Rectangle {
                              implicitWidth: 84
                              implicitHeight: 26
                              radius: 6
                              color: devBtnM.containsMouse ? (settingsWin.isDark ? Qt.rgba(1, 1, 1, 0.14) : Qt.rgba(0, 0, 0, 0.08)) : (settingsWin.isDark ? Qt.rgba(1, 1, 1, 0.06) : Qt.rgba(0, 0, 0, 0.04))
                              border.color: settingsWin.cardBorder
                              border.width: 1
                              Text {
                                anchors.centerIn: parent
                                text: modelData.connected ? "Disconnect" : "Connect"
                                font.family: "SF Pro Text, -apple-system, sans-serif"
                                font.pixelSize: 11
                                font.weight: Font.DemiBold
                                color: settingsWin.textPrimary
                              }
                              MouseArea {
                                id: devBtnM
                                anchors.fill: parent
                                hoverEnabled: true
                                cursorShape: Qt.PointingHandCursor
                                onClicked: {
                                  if (modelData.connected) {
                                    settingsService.disconnectBluetooth(modelData.address)
                                  } else {
                                    settingsService.connectBluetooth(modelData.address)
                                  }
                                }
                              }
                            }
                          }
                        }
                      }
                    }
                  }
                }
              }

              // ==========================================
              // TAB 5: SOUND
              // ==========================================
              ColumnLayout {
                visible: settingsWin.currentCategory === 5
                Layout.fillWidth: true
                spacing: 16

                Text {
                  text: "Sound"
                  font.family: "SF Pro Text, -apple-system, sans-serif"
                  font.pixelSize: 18
                  font.bold: true
                  color: settingsWin.textPrimary
                }

                // ==========================================
                // SOUND EFFECTS & ALERTS
                // ==========================================
                Rectangle {
                  Layout.fillWidth: true
                  implicitHeight: alertCol.implicitHeight + 28
                  radius: 10
                  color: settingsWin.cardBg
                  border.color: settingsWin.cardBorder
                  border.width: 1

                  ColumnLayout {
                    id: alertCol
                    anchors.fill: parent
                    anchors.margins: 14
                    spacing: 12

                    RowLayout {
                      Layout.fillWidth: true
                      spacing: 12
                      Image {
                        Layout.preferredWidth: 20
                        Layout.preferredHeight: 20
                        source: "file://" + settingsWin.pluginDir + "/assets/icons/mac-settings/sound.svg"
                        fillMode: Image.PreserveAspectFit
                      }
                      ColumnLayout {
                        spacing: 2
                        Text {
                          text: "Alert sound effect"
                          font.family: "SF Pro Text, -apple-system, sans-serif"
                          font.pixelSize: 13
                          font.weight: Font.DemiBold
                          color: settingsWin.textPrimary
                        }
                        Text {
                          text: "Play system ping alert sound"
                          font.family: "SF Pro Text, -apple-system, sans-serif"
                          font.pixelSize: 11
                          color: settingsWin.textSecondary
                        }
                      }
                      Item { Layout.fillWidth: true }
                      Button {
                        text: "Play Ping"
                        onClicked: settingsWin.runCmd("omarchy-play-sound mac-switch")
                      }
                    }
                  }
                }

                // ==========================================
                // OUTPUT SECTION
                // ==========================================
                Text {
                  text: "Output"
                  font.family: "SF Pro Text, -apple-system, sans-serif"
                  font.pixelSize: 14
                  font.weight: Font.DemiBold
                  color: settingsWin.textPrimary
                }

                Rectangle {
                  Layout.fillWidth: true
                  implicitHeight: outputCol.implicitHeight + 28
                  radius: 10
                  color: settingsWin.cardBg
                  border.color: settingsWin.cardBorder
                  border.width: 1

                  ColumnLayout {
                    id: outputCol
                    anchors.fill: parent
                    anchors.margins: 14
                    spacing: 12

                    // Table Header
                    RowLayout {
                      Layout.fillWidth: true
                      Text {
                        text: "Name"
                        font.family: "SF Pro Text, -apple-system, sans-serif"
                        font.pixelSize: 11
                        font.weight: Font.Bold
                        color: settingsWin.textSecondary
                        Layout.fillWidth: true
                      }
                      Text {
                        text: "Type"
                        font.family: "SF Pro Text, -apple-system, sans-serif"
                        font.pixelSize: 11
                        font.weight: Font.Bold
                        color: settingsWin.textSecondary
                        Layout.preferredWidth: 140
                      }
                    }

                    Rectangle { Layout.fillWidth: true; height: 1; color: settingsWin.separatorColor }

                    // Output Sinks Table
                    ColumnLayout {
                      Layout.fillWidth: true
                      spacing: 4

                      Repeater {
                        model: audioService.sinks
                        delegate: Rectangle {
                          Layout.fillWidth: true
                          implicitHeight: 34
                          radius: 6
                          color: modelData.is_default
                                 ? (settingsWin.isDark ? Qt.rgba(0, 122, 255, 0.28) : Qt.rgba(0, 122, 255, 0.15))
                                 : (sinkRowArea.containsMouse ? (settingsWin.isDark ? Qt.rgba(1, 1, 1, 0.08) : Qt.rgba(0, 0, 0, 0.05)) : "transparent")

                          RowLayout {
                            anchors.fill: parent
                            anchors.leftMargin: 8
                            anchors.rightMargin: 8
                            spacing: 8

                            Text {
                              text: settingsWin.getAudioDeviceIcon(modelData.description, modelData.name, false)
                              font.pixelSize: 14
                            }
                            Text {
                              text: modelData.description || modelData.name
                              font.family: "SF Pro Text, -apple-system, sans-serif"
                              font.pixelSize: 12
                              font.weight: modelData.is_default ? Font.DemiBold : Font.Normal
                              color: settingsWin.textPrimary
                              Layout.fillWidth: true
                              elide: Text.ElideRight
                            }
                            Text {
                              text: settingsWin.getAudioDeviceType(modelData.description, modelData.name, false)
                              font.family: "SF Pro Text, -apple-system, sans-serif"
                              font.pixelSize: 11
                              color: settingsWin.textSecondary
                              Layout.preferredWidth: 140
                              elide: Text.ElideRight
                            }
                            Text {
                              visible: modelData.is_default
                              text: "✓"
                              font.pixelSize: 12
                              color: "#007aff"
                              font.weight: Font.Bold
                            }
                          }

                          MouseArea {
                            id: sinkRowArea
                            anchors.fill: parent
                            hoverEnabled: true
                            cursorShape: Qt.PointingHandCursor
                            onClicked: audioService.setDefaultSink(modelData.name)
                          }
                        }
                      }
                    }

                    Rectangle { Layout.fillWidth: true; height: 1; color: settingsWin.separatorColor }

                    // Output Volume Slider Row
                    RowLayout {
                      Layout.fillWidth: true
                      spacing: 12

                      Text {
                        text: "Output volume"
                        font.family: "SF Pro Text, -apple-system, sans-serif"
                        font.pixelSize: 12
                        color: settingsWin.textPrimary
                        Layout.preferredWidth: 110
                      }

                      Rectangle {
                        implicitWidth: 26
                        implicitHeight: 26
                        radius: 5
                        color: spkMuteBtnArea.containsMouse ? (settingsWin.isDark ? Qt.rgba(1, 1, 1, 0.15) : Qt.rgba(0, 0, 0, 0.1)) : "transparent"
                        Text {
                          anchors.centerIn: parent
                          text: audioService.masterMuted ? "🔇" : (audioService.masterVolume === 0 ? "🔈" : (audioService.masterVolume > 50 ? "🔊" : "🔉"))
                          font.pixelSize: 14
                        }
                        MouseArea {
                          id: spkMuteBtnArea
                          anchors.fill: parent
                          hoverEnabled: true
                          cursorShape: Qt.PointingHandCursor
                          onClicked: audioService.toggleMasterMute()
                        }
                      }

                      Slider {
                        id: macOutSlider
                        Layout.fillWidth: true
                        from: 0
                        to: 100
                        stepSize: 1
                        value: audioService.masterVolume
                        onMoved: {
                          settingsWin.volumeLevel = Math.round(value)
                          audioService.setMasterVolume(Math.round(value))
                        }

                        background: Rectangle {
                          x: macOutSlider.leftPadding
                          y: macOutSlider.topPadding + macOutSlider.availableHeight / 2 - height / 2
                          implicitWidth: 160
                          implicitHeight: 6
                          width: macOutSlider.availableWidth
                          height: 6
                          radius: 3
                          color: settingsWin.isDark ? Qt.rgba(1, 1, 1, 0.15) : Qt.rgba(0, 0, 0, 0.12)

                          Rectangle {
                            width: macOutSlider.visualPosition * parent.width
                            height: parent.height
                            color: audioService.masterMuted ? "#8e8e93" : "#007aff"
                            radius: 3
                          }
                        }

                        handle: Rectangle {
                          x: macOutSlider.leftPadding + macOutSlider.visualPosition * (macOutSlider.availableWidth - width)
                          y: macOutSlider.topPadding + macOutSlider.availableHeight / 2 - height / 2
                          implicitWidth: 16
                          implicitHeight: 16
                          radius: 8
                          color: "#ffffff"
                          border.color: Qt.rgba(0, 0, 0, 0.2)
                          border.width: 1
                        }
                      }

                      Text {
                        text: audioService.masterMuted ? "Muted" : (audioService.masterVolume + "%")
                        font.family: "SF Pro Text, -apple-system, sans-serif"
                        font.pixelSize: 11
                        font.weight: Font.DemiBold
                        color: audioService.masterMuted ? "#8e8e93" : settingsWin.textPrimary
                        Layout.preferredWidth: 44
                        horizontalAlignment: Text.AlignRight
                      }
                    }

                    // Stereo Balance Slider Row
                    RowLayout {
                      Layout.fillWidth: true
                      spacing: 12

                      Text {
                        text: "Balance"
                        font.family: "SF Pro Text, -apple-system, sans-serif"
                        font.pixelSize: 12
                        color: settingsWin.textPrimary
                        Layout.preferredWidth: 110
                      }

                      Text {
                        text: "Left"
                        font.family: "SF Pro Text, -apple-system, sans-serif"
                        font.pixelSize: 11
                        color: settingsWin.textSecondary
                      }

                      Slider {
                        id: macBalanceSlider
                        Layout.fillWidth: true
                        from: 0
                        to: 100
                        stepSize: 1
                        value: settingsWin.audioBalance
                        onMoved: settingsWin.applyBalance(Math.round(value))

                        background: Rectangle {
                          x: macBalanceSlider.leftPadding
                          y: macBalanceSlider.topPadding + macBalanceSlider.availableHeight / 2 - height / 2
                          implicitWidth: 160
                          implicitHeight: 6
                          width: macBalanceSlider.availableWidth
                          height: 6
                          radius: 3
                          color: settingsWin.isDark ? Qt.rgba(1, 1, 1, 0.15) : Qt.rgba(0, 0, 0, 0.12)

                          // Center tick marker
                          Rectangle {
                            anchors.horizontalCenter: parent.horizontalCenter
                            width: 2
                            height: 10
                            anchors.verticalCenter: parent.verticalCenter
                            color: settingsWin.textSecondary
                          }
                        }

                        handle: Rectangle {
                          x: macBalanceSlider.leftPadding + macBalanceSlider.visualPosition * (macBalanceSlider.availableWidth - width)
                          y: macBalanceSlider.topPadding + macBalanceSlider.availableHeight / 2 - height / 2
                          implicitWidth: 16
                          implicitHeight: 16
                          radius: 8
                          color: "#ffffff"
                          border.color: Qt.rgba(0, 0, 0, 0.2)
                          border.width: 1
                        }
                      }

                      Text {
                        text: "Right"
                        font.family: "SF Pro Text, -apple-system, sans-serif"
                        font.pixelSize: 11
                        color: settingsWin.textSecondary
                      }
                    }

                    // Speaker Channel Test Row
                    RowLayout {
                      Layout.fillWidth: true
                      spacing: 10

                      Text {
                        text: "Channel test"
                        font.family: "SF Pro Text, -apple-system, sans-serif"
                        font.pixelSize: 12
                        color: settingsWin.textPrimary
                        Layout.preferredWidth: 110
                      }

                      Button {
                        text: "Left"
                        onClicked: audioService.runSpeakerTest("left")
                      }
                      Button {
                        text: "Right"
                        onClicked: audioService.runSpeakerTest("right")
                      }
                      Button {
                        text: "Both Channels"
                        onClicked: audioService.runSpeakerTest("both")
                      }
                      Item { Layout.fillWidth: true }
                    }
                  }
                }

                // ==========================================
                // INPUT (MICROPHONE) SECTION
                // ==========================================
                Text {
                  text: "Input"
                  font.family: "SF Pro Text, -apple-system, sans-serif"
                  font.pixelSize: 14
                  font.weight: Font.DemiBold
                  color: settingsWin.textPrimary
                }

                Rectangle {
                  Layout.fillWidth: true
                  implicitHeight: inputCol.implicitHeight + 28
                  radius: 10
                  color: settingsWin.cardBg
                  border.color: settingsWin.cardBorder
                  border.width: 1

                  ColumnLayout {
                    id: inputCol
                    anchors.fill: parent
                    anchors.margins: 14
                    spacing: 12

                    // Table Header
                    RowLayout {
                      Layout.fillWidth: true
                      Text {
                        text: "Name"
                        font.family: "SF Pro Text, -apple-system, sans-serif"
                        font.pixelSize: 11
                        font.weight: Font.Bold
                        color: settingsWin.textSecondary
                        Layout.fillWidth: true
                      }
                      Text {
                        text: "Type"
                        font.family: "SF Pro Text, -apple-system, sans-serif"
                        font.pixelSize: 11
                        font.weight: Font.Bold
                        color: settingsWin.textSecondary
                        Layout.preferredWidth: 140
                      }
                    }

                    Rectangle { Layout.fillWidth: true; height: 1; color: settingsWin.separatorColor }

                    // Input Sources Table
                    ColumnLayout {
                      Layout.fillWidth: true
                      spacing: 4

                      Repeater {
                        model: audioService.sources
                        delegate: Rectangle {
                          Layout.fillWidth: true
                          implicitHeight: 34
                          radius: 6
                          color: modelData.is_default
                                 ? (settingsWin.isDark ? Qt.rgba(52, 199, 89, 0.25) : Qt.rgba(52, 199, 89, 0.15))
                                 : (sourceRowArea.containsMouse ? (settingsWin.isDark ? Qt.rgba(1, 1, 1, 0.08) : Qt.rgba(0, 0, 0, 0.05)) : "transparent")

                          RowLayout {
                            anchors.fill: parent
                            anchors.leftMargin: 8
                            anchors.rightMargin: 8
                            spacing: 8

                            Text {
                              text: settingsWin.getAudioDeviceIcon(modelData.description, modelData.name, true)
                              font.pixelSize: 13
                            }
                            Text {
                              text: modelData.description || modelData.name
                              font.family: "SF Pro Text, -apple-system, sans-serif"
                              font.pixelSize: 12
                              font.weight: modelData.is_default ? Font.DemiBold : Font.Normal
                              color: settingsWin.textPrimary
                              Layout.fillWidth: true
                              elide: Text.ElideRight
                            }
                            Text {
                              text: settingsWin.getAudioDeviceType(modelData.description, modelData.name, true)
                              font.family: "SF Pro Text, -apple-system, sans-serif"
                              font.pixelSize: 11
                              color: settingsWin.textSecondary
                              Layout.preferredWidth: 140
                              elide: Text.ElideRight
                            }
                            Text {
                              visible: modelData.is_default
                              text: "✓"
                              font.pixelSize: 12
                              color: "#34c759"
                              font.weight: Font.Bold
                            }
                          }

                          MouseArea {
                            id: sourceRowArea
                            anchors.fill: parent
                            hoverEnabled: true
                            cursorShape: Qt.PointingHandCursor
                            onClicked: audioService.setDefaultSource(modelData.name)
                          }
                        }
                      }
                    }

                    Rectangle { Layout.fillWidth: true; height: 1; color: settingsWin.separatorColor }

                    // Input Volume Slider Row
                    RowLayout {
                      Layout.fillWidth: true
                      spacing: 12

                      Text {
                        text: "Input volume"
                        font.family: "SF Pro Text, -apple-system, sans-serif"
                        font.pixelSize: 12
                        color: settingsWin.textPrimary
                        Layout.preferredWidth: 110
                      }

                      Rectangle {
                        implicitWidth: 26
                        implicitHeight: 26
                        radius: 5
                        color: micMuteBtnArea.containsMouse ? (settingsWin.isDark ? Qt.rgba(1, 1, 1, 0.15) : Qt.rgba(0, 0, 0, 0.1)) : "transparent"
                        Text {
                          anchors.centerIn: parent
                          text: audioService.micMuted ? "🔇" : "🎙️"
                          font.pixelSize: 13
                        }
                        MouseArea {
                          id: micMuteBtnArea
                          anchors.fill: parent
                          hoverEnabled: true
                          cursorShape: Qt.PointingHandCursor
                          onClicked: audioService.toggleMicMute()
                        }
                      }

                      Slider {
                        id: macInSlider
                        Layout.fillWidth: true
                        from: 0
                        to: 100
                        stepSize: 1
                        value: audioService.micVolume
                        onMoved: audioService.setMicVolume(Math.round(value))

                        background: Rectangle {
                          x: macInSlider.leftPadding
                          y: macInSlider.topPadding + macInSlider.availableHeight / 2 - height / 2
                          implicitWidth: 160
                          implicitHeight: 6
                          width: macInSlider.availableWidth
                          height: 6
                          radius: 3
                          color: settingsWin.isDark ? Qt.rgba(1, 1, 1, 0.15) : Qt.rgba(0, 0, 0, 0.12)

                          Rectangle {
                            width: macInSlider.visualPosition * parent.width
                            height: parent.height
                            color: audioService.micMuted ? "#8e8e93" : "#34c759"
                            radius: 3
                          }
                        }

                        handle: Rectangle {
                          x: macInSlider.leftPadding + macInSlider.visualPosition * (macInSlider.availableWidth - width)
                          y: macInSlider.topPadding + macInSlider.availableHeight / 2 - height / 2
                          implicitWidth: 16
                          implicitHeight: 16
                          radius: 8
                          color: "#ffffff"
                          border.color: Qt.rgba(0, 0, 0, 0.2)
                          border.width: 1
                        }
                      }

                      Text {
                        text: audioService.micMuted ? "Muted" : (audioService.micVolume + "%")
                        font.family: "SF Pro Text, -apple-system, sans-serif"
                        font.pixelSize: 11
                        font.weight: Font.DemiBold
                        color: audioService.micMuted ? "#8e8e93" : settingsWin.textPrimary
                        Layout.preferredWidth: 44
                        horizontalAlignment: Text.AlignRight
                      }
                    }

                    // Input Level Meter Row
                    RowLayout {
                      Layout.fillWidth: true
                      spacing: 12

                      Text {
                        text: "Input level"
                        font.family: "SF Pro Text, -apple-system, sans-serif"
                        font.pixelSize: 12
                        color: settingsWin.textPrimary
                        Layout.preferredWidth: 110
                      }

                      Rectangle {
                        Layout.fillWidth: true
                        implicitHeight: 16
                        radius: 8
                        color: settingsWin.isDark ? Qt.rgba(1, 1, 1, 0.08) : Qt.rgba(0, 0, 0, 0.06)

                        RowLayout {
                          anchors.fill: parent
                          anchors.margins: 3
                          spacing: 3

                          Repeater {
                            model: 15
                            delegate: Rectangle {
                              Layout.fillWidth: true
                              Layout.fillHeight: true
                              radius: 2
                              color: {
                                var active = settingsWin.micTesting || (!audioService.micMuted && audioService.micVolume > 0 && Math.sin(Date.now() / 200 + index) > 0.1)
                                if (!active) {
                                  return settingsWin.isDark ? Qt.rgba(1, 1, 1, 0.12) : Qt.rgba(0, 0, 0, 0.1)
                                }
                                return index > 12 ? "#ff3b30" : (index > 9 ? "#ff9500" : "#34c759")
                              }
                            }
                          }
                        }
                      }

                      Button {
                        text: settingsWin.micTesting ? "Testing..." : "Test Mic"
                        onClicked: {
                          settingsWin.micTesting = true
                          micStopTimer.restart()
                          settingsWin.runCmd("arecord -d 2 -f cd /tmp/omarchy_mic_test.wav && aplay /tmp/omarchy_mic_test.wav; rm -f /tmp/omarchy_mic_test.wav")
                        }
                      }

                      Timer {
                        id: micStopTimer
                        interval: 4000
                        onTriggered: settingsWin.micTesting = false
                      }
                    }
                  }
                }

                // ==========================================
                // APPLICATION VOLUMES (VOLUME MIXER)
                // ==========================================
                Text {
                  visible: audioService.streams.length > 0
                  text: "Application Volumes"
                  font.family: "SF Pro Text, -apple-system, sans-serif"
                  font.pixelSize: 14
                  font.weight: Font.DemiBold
                  color: settingsWin.textPrimary
                }

                Rectangle {
                  visible: audioService.streams.length > 0
                  Layout.fillWidth: true
                  implicitHeight: appCol.implicitHeight + 28
                  radius: 10
                  color: settingsWin.cardBg
                  border.color: settingsWin.cardBorder
                  border.width: 1

                  ColumnLayout {
                    id: appCol
                    anchors.fill: parent
                    anchors.margins: 14
                    spacing: 12

                    Repeater {
                      model: audioService.streams
                      delegate: ColumnLayout {
                        Layout.fillWidth: true
                        spacing: 6

                        RowLayout {
                          Layout.fillWidth: true
                          spacing: 10

                          Text {
                            text: settingsWin.getAudioAppIcon(modelData)
                            font.pixelSize: 14
                          }
                          Text {
                            text: modelData.app_name || modelData.name || "Application"
                            font.family: "SF Pro Text, -apple-system, sans-serif"
                            font.pixelSize: 12
                            font.weight: Font.DemiBold
                            color: settingsWin.textPrimary
                            Layout.fillWidth: true
                            elide: Text.ElideRight
                          }
                          Rectangle {
                            implicitWidth: 24
                            implicitHeight: 24
                            radius: 4
                            color: appStreamMuteArea.containsMouse ? (settingsWin.isDark ? Qt.rgba(1, 1, 1, 0.15) : Qt.rgba(0, 0, 0, 0.1)) : "transparent"
                            Text {
                              anchors.centerIn: parent
                              text: modelData.muted ? "🔇" : "🔊"
                              font.pixelSize: 11
                            }
                            MouseArea {
                              id: appStreamMuteArea
                              anchors.fill: parent
                              hoverEnabled: true
                              cursorShape: Qt.PointingHandCursor
                              onClicked: audioService.toggleStreamMute(modelData.id)
                            }
                          }
                          Text {
                            text: modelData.muted ? "Muted" : (modelData.volume + "%")
                            font.family: "SF Pro Text, -apple-system, sans-serif"
                            font.pixelSize: 11
                            color: modelData.muted ? "#8e8e93" : settingsWin.textSecondary
                            Layout.preferredWidth: 44
                            horizontalAlignment: Text.AlignRight
                          }
                        }

                        Slider {
                          id: macAppSlider
                          Layout.fillWidth: true
                          Layout.preferredHeight: 18
                          from: 0
                          to: 100
                          stepSize: 1
                          value: modelData.volume
                          onMoved: audioService.setStreamVolume(modelData.id, Math.round(value))

                          background: Rectangle {
                            x: macAppSlider.leftPadding
                            y: macAppSlider.topPadding + macAppSlider.availableHeight / 2 - height / 2
                            implicitWidth: 160
                            implicitHeight: 5
                            width: macAppSlider.availableWidth
                            height: 5
                            radius: 2.5
                            color: settingsWin.isDark ? Qt.rgba(1, 1, 1, 0.15) : Qt.rgba(0, 0, 0, 0.12)

                            Rectangle {
                              width: macAppSlider.visualPosition * parent.width
                              height: parent.height
                              color: modelData.muted ? "#8e8e93" : "#007aff"
                              radius: 2.5
                            }
                          }

                          handle: Rectangle {
                            x: macAppSlider.leftPadding + macAppSlider.visualPosition * (macAppSlider.availableWidth - width)
                            y: macAppSlider.topPadding + macAppSlider.availableHeight / 2 - height / 2
                            implicitWidth: 14
                            implicitHeight: 14
                            radius: 7
                            color: "#ffffff"
                            border.color: Qt.rgba(0, 0, 0, 0.2)
                            border.width: 1
                          }
                        }

                        Rectangle {
                          visible: index < (audioService.streams.length - 1)
                          Layout.fillWidth: true
                          height: 1
                          color: settingsWin.separatorColor
                        }
                      }
                    }
                  }
                }

                // ==========================================
                // SOUND SYSTEM MAINTENANCE & RECOVERY
                // ==========================================
                Text {
                  text: "Sound System Maintenance"
                  font.family: "SF Pro Text, -apple-system, sans-serif"
                  font.pixelSize: 14
                  font.weight: Font.DemiBold
                  color: settingsWin.textPrimary
                }

                Rectangle {
                  Layout.fillWidth: true
                  implicitHeight: recCol.implicitHeight + 28
                  radius: 10
                  color: settingsWin.cardBg
                  border.color: settingsWin.cardBorder
                  border.width: 1

                  RowLayout {
                    id: recCol
                    anchors.fill: parent
                    anchors.margins: 14
                    spacing: 12

                    ColumnLayout {
                      spacing: 3
                      Layout.fillWidth: true

                      Text {
                        text: "Reset Sound System"
                        font.family: "SF Pro Text, -apple-system, sans-serif"
                        font.pixelSize: 13
                        font.weight: Font.DemiBold
                        color: settingsWin.textPrimary
                      }
                      Text {
                        text: "Restart PipeWire and WirePlumber services if audio glitches, freezes, or devices become unresponsive."
                        font.family: "SF Pro Text, -apple-system, sans-serif"
                        font.pixelSize: 11
                        color: settingsWin.textSecondary
                        wrapMode: Text.Wrap
                        Layout.fillWidth: true
                      }
                    }

                    Button {
                      text: "Reset Sound System"
                      onClicked: audioService.runRecovery()
                    }
                  }
                }
              }

              // ==========================================
              // TAB 6: UNDERCOVER DISGUISE TRANSFORMATION
              // ==========================================
              ColumnLayout {
                visible: settingsWin.currentCategory === 6
                Layout.fillWidth: true
                spacing: 14

                Text {
                  text: "Active Desktop Camouflage"
                  font.family: "SF Pro Text, -apple-system, sans-serif"
                  font.pixelSize: 14
                  font.bold: true
                  color: settingsWin.textPrimary
                }

                GridLayout {
                  Layout.fillWidth: true
                  columns: rightScroller.width > 600 ? 2 : 1
                  rowSpacing: 12
                  columnSpacing: 12

                  // macOS Tahoe Dark (Flagship Default)
                  Rectangle {
                    Layout.fillWidth: true
                    implicitHeight: 74
                    radius: 8
                    color: settingsWin.cardBg
                    border.color: (settingsWin.currentDisguise === "mac-dark" || settingsWin.currentDisguise === "mac-tahoe-dark") ? settingsWin.accentColor : settingsWin.cardBorder
                    border.width: (settingsWin.currentDisguise === "mac-dark" || settingsWin.currentDisguise === "mac-tahoe-dark") ? 2 : 1

                    RowLayout {
                      anchors.fill: parent
                      anchors.margins: 14
                      spacing: 12
                      Image {
                        Layout.preferredWidth: 24; Layout.preferredHeight: 24
                        width: 24; height: 24
                        source: "file://" + settingsWin.pluginDir + "/assets/icons/apple-logo.svg"
                        fillMode: Image.PreserveAspectFit
                      }
                      ColumnLayout {
                        Layout.fillWidth: true
                        Text { text: "macOS Tahoe (Dark)" + ((settingsWin.currentDisguise === "mac-dark" || settingsWin.currentDisguise === "mac-tahoe-dark") ? " — Active" : ""); font.family: "SF Pro Text, -apple-system, sans-serif"; font.pixelSize: 12; font.bold: true; color: settingsWin.textPrimary }
                        Text { text: "Alpine vista, frosted glass menu bar, Stage Manager & SF Pro fonts"; font.family: "SF Pro Text, -apple-system, sans-serif"; font.pixelSize: 10; color: settingsWin.textSecondary }
                      }
                    }
                    MouseArea {
                      anchors.fill: parent
                      cursorShape: Qt.PointingHandCursor
                      onClicked: settingsWin.runCmd("omarchy-undercover -mac")
                    }
                  }

                  // macOS Tahoe Light
                  Rectangle {
                    Layout.fillWidth: true
                    implicitHeight: 74
                    radius: 8
                    color: settingsWin.cardBg
                    border.color: (settingsWin.currentDisguise === "mac-light" || settingsWin.currentDisguise === "mac-tahoe-light") ? settingsWin.accentColor : settingsWin.cardBorder
                    border.width: (settingsWin.currentDisguise === "mac-light" || settingsWin.currentDisguise === "mac-tahoe-light") ? 2 : 1

                    RowLayout {
                      anchors.fill: parent
                      anchors.margins: 14
                      spacing: 12
                      Image {
                        Layout.preferredWidth: 24; Layout.preferredHeight: 24
                        width: 24; height: 24
                        source: "file://" + settingsWin.pluginDir + "/assets/icons/apple-logo.svg"
                        fillMode: Image.PreserveAspectFit
                      }
                      ColumnLayout {
                        Layout.fillWidth: true
                        Text { text: "macOS Tahoe (Light)" + ((settingsWin.currentDisguise === "mac-light" || settingsWin.currentDisguise === "mac-tahoe-light") ? " — Active" : ""); font.family: "SF Pro Text, -apple-system, sans-serif"; font.pixelSize: 12; font.bold: true; color: settingsWin.textPrimary }
                        Text { text: "Solar alpine glass menu bar, high vibrancy dock & Stage Manager"; font.family: "SF Pro Text, -apple-system, sans-serif"; font.pixelSize: 10; color: settingsWin.textSecondary }
                      }
                    }
                    MouseArea {
                      anchors.fill: parent
                      cursorShape: Qt.PointingHandCursor
                      onClicked: settingsWin.runCmd("omarchy-undercover -mac-light")
                    }
                  }

                  // macOS Sequoia Dark
                  Rectangle {
                    Layout.fillWidth: true
                    implicitHeight: 74
                    radius: 8
                    color: settingsWin.cardBg
                    border.color: (settingsWin.currentDisguise === "mac-sequoia-dark" || settingsWin.currentDisguise === "mac-sequoia") ? settingsWin.accentColor : settingsWin.cardBorder
                    border.width: (settingsWin.currentDisguise === "mac-sequoia-dark" || settingsWin.currentDisguise === "mac-sequoia") ? 2 : 1

                    RowLayout {
                      anchors.fill: parent
                      anchors.margins: 14
                      spacing: 12
                      Image {
                        Layout.preferredWidth: 24; Layout.preferredHeight: 24
                        width: 24; height: 24
                        source: "file://" + settingsWin.pluginDir + "/assets/icons/apple-logo.svg"
                        fillMode: Image.PreserveAspectFit
                      }
                      ColumnLayout {
                        Layout.fillWidth: true
                        Text { text: "macOS Sequoia (Dark)" + ((settingsWin.currentDisguise === "mac-sequoia-dark" || settingsWin.currentDisguise === "mac-sequoia") ? " — Active" : ""); font.family: "SF Pro Text, -apple-system, sans-serif"; font.pixelSize: 12; font.bold: true; color: settingsWin.textPrimary }
                        Text { text: "Classic Sequoia dark redwood theme, menu bar & dynamic dock"; font.family: "SF Pro Text, -apple-system, sans-serif"; font.pixelSize: 10; color: settingsWin.textSecondary }
                      }
                    }
                    MouseArea {
                      anchors.fill: parent
                      cursorShape: Qt.PointingHandCursor
                      onClicked: settingsWin.runCmd("omarchy-undercover -mac-sequoia")
                    }
                  }

                  // macOS Sequoia Light
                  Rectangle {
                    Layout.fillWidth: true
                    implicitHeight: 74
                    radius: 8
                    color: settingsWin.cardBg
                    border.color: (settingsWin.currentDisguise === "mac-sequoia-light") ? settingsWin.accentColor : settingsWin.cardBorder
                    border.width: (settingsWin.currentDisguise === "mac-sequoia-light") ? 2 : 1

                    RowLayout {
                      anchors.fill: parent
                      anchors.margins: 14
                      spacing: 12
                      Image {
                        Layout.preferredWidth: 24; Layout.preferredHeight: 24
                        width: 24; height: 24
                        source: "file://" + settingsWin.pluginDir + "/assets/icons/apple-logo.svg"
                        fillMode: Image.PreserveAspectFit
                      }
                      ColumnLayout {
                        Layout.fillWidth: true
                        Text { text: "macOS Sequoia (Light)" + (settingsWin.currentDisguise === "mac-sequoia-light" ? " — Active" : ""); font.family: "SF Pro Text, -apple-system, sans-serif"; font.pixelSize: 12; font.bold: true; color: settingsWin.textPrimary }
                        Text { text: "Classic Sequoia solar redwood light glass theme"; font.family: "SF Pro Text, -apple-system, sans-serif"; font.pixelSize: 10; color: settingsWin.textSecondary }
                      }
                    }
                    MouseArea {
                      anchors.fill: parent
                      cursorShape: Qt.PointingHandCursor
                      onClicked: settingsWin.runCmd("omarchy-undercover -mac-sequoia-light")
                    }
                  }

                  // Windows 11 Dark
                  Rectangle {
                    Layout.fillWidth: true
                    implicitHeight: 74
                    radius: 8
                    color: settingsWin.cardBg
                    border.color: (settingsWin.currentDisguise === "win11-dark") ? settingsWin.accentColor : settingsWin.cardBorder
                    border.width: (settingsWin.currentDisguise === "win11-dark") ? 2 : 1

                    RowLayout {
                      anchors.fill: parent
                      anchors.margins: 14
                      spacing: 12
                      Image {
                        Layout.preferredWidth: 22; Layout.preferredHeight: 22
                        width: 22; height: 22
                        source: "file://" + settingsWin.pluginDir + "/assets/icons/win11/start.svg"
                        fillMode: Image.PreserveAspectFit
                      }
                      ColumnLayout {
                        Layout.fillWidth: true
                        Text { text: "Windows 11 Fluent (Dark)" + (settingsWin.currentDisguise === "win11-dark" ? " — Active" : ""); font.family: "SF Pro Text, -apple-system, sans-serif"; font.pixelSize: 12; font.bold: true; color: settingsWin.textPrimary }
                        Text { text: "Centered Mica taskbar, Start Menu & Segoe UI"; font.family: "SF Pro Text, -apple-system, sans-serif"; font.pixelSize: 10; color: settingsWin.textSecondary }
                      }
                    }
                    MouseArea {
                      anchors.fill: parent
                      cursorShape: Qt.PointingHandCursor
                      onClicked: settingsWin.runCmd("omarchy-undercover -w11")
                    }
                  }

                  // Windows 11 Light
                  Rectangle {
                    Layout.fillWidth: true
                    implicitHeight: 74
                    radius: 8
                    color: settingsWin.cardBg
                    border.color: (settingsWin.currentDisguise === "win11-light") ? settingsWin.accentColor : settingsWin.cardBorder
                    border.width: (settingsWin.currentDisguise === "win11-light") ? 2 : 1

                    RowLayout {
                      anchors.fill: parent
                      anchors.margins: 14
                      spacing: 12
                      Image {
                        Layout.preferredWidth: 22; Layout.preferredHeight: 22
                        width: 22; height: 22
                        source: "file://" + settingsWin.pluginDir + "/assets/icons/win11/start.svg"
                        fillMode: Image.PreserveAspectFit
                      }
                      ColumnLayout {
                        Layout.fillWidth: true
                        Text { text: "Windows 11 Fluent (Light)" + (settingsWin.currentDisguise === "win11-light" ? " — Active" : ""); font.family: "SF Pro Text, -apple-system, sans-serif"; font.pixelSize: 12; font.bold: true; color: settingsWin.textPrimary }
                        Text { text: "Solar Light taskbar, Fluent Start & Segoe UI"; font.family: "SF Pro Text, -apple-system, sans-serif"; font.pixelSize: 10; color: settingsWin.textSecondary }
                      }
                    }
                    MouseArea {
                      anchors.fill: parent
                      cursorShape: Qt.PointingHandCursor
                      onClicked: settingsWin.runCmd("omarchy-undercover -w11-light")
                    }
                  }

                  // Restore Default Omarchy Desktop
                  Rectangle {
                    Layout.fillWidth: true
                    implicitHeight: 74
                    radius: 8
                    color: settingsWin.cardBg
                    border.color: (settingsWin.currentDisguise === "omarchy") ? "#34c759" : settingsWin.cardBorder
                    border.width: (settingsWin.currentDisguise === "omarchy") ? 2 : 1

                    RowLayout {
                      anchors.fill: parent
                      anchors.margins: 14
                      spacing: 12
                      Image {
                        Layout.preferredWidth: 22; Layout.preferredHeight: 22
                        width: 22; height: 22
                        source: "file://" + settingsWin.pluginDir + "/assets/icons/win11-settings/disguise.svg"
                        fillMode: Image.PreserveAspectFit
                      }
                      ColumnLayout {
                        Layout.fillWidth: true
                        Text { text: "Restore Default Omarchy Desktop" + (settingsWin.currentDisguise === "omarchy" ? " — Active" : ""); font.family: "SF Pro Text, -apple-system, sans-serif"; font.pixelSize: 12; font.bold: true; color: settingsWin.textPrimary }
                        Text { text: "Revert camouflage, top bar branding, GTK & baseline"; font.family: "SF Pro Text, -apple-system, sans-serif"; font.pixelSize: 10; color: settingsWin.textSecondary }
                      }
                    }
                    MouseArea {
                      anchors.fill: parent
                      cursorShape: Qt.PointingHandCursor
                      onClicked: settingsWin.runCmd("omarchy-undercover --disable")
                    }
                  }
                }
              }

              // ==========================================
              // TAB 7: GENERAL & ABOUT THIS MAC
              // ==========================================
              ColumnLayout {
                visible: settingsWin.currentCategory === 7
                Layout.fillWidth: true
                spacing: 14

                Rectangle {
                  Layout.fillWidth: true
                  implicitHeight: 230
                  radius: 10
                  color: settingsWin.cardBg
                  border.color: settingsWin.cardBorder
                  border.width: 1

                  ColumnLayout {
                    anchors.fill: parent
                    anchors.margins: 20
                    spacing: 14

                    RowLayout {
                      spacing: 16
                      Rectangle {
                        width: 50; height: 50; radius: 12
                        color: settingsWin.accentColor
                        Image {
                          anchors.centerIn: parent
                          width: 28; height: 28
                          source: "file://" + settingsWin.pluginDir + "/assets/icons/apple-logo.svg"
                          fillMode: Image.PreserveAspectFit
                        }
                      }
                      ColumnLayout {
                        spacing: 2
                        Text { text: "macOS Sequoia"; font.family: "SF Pro Text, -apple-system, sans-serif"; font.pixelSize: 16; font.bold: true; color: settingsWin.textPrimary }
                        Text { text: "Version 15.1 (Omarchy Undercover Camouflage)"; font.family: "SF Pro Text, -apple-system, sans-serif"; font.pixelSize: 11; color: settingsWin.textSecondary }
                      }
                    }

                    Rectangle { Layout.fillWidth: true; height: 1; color: settingsWin.separatorColor }

                    RowLayout {
                      Layout.fillWidth: true
                      Text { text: "Host Machine"; font.family: "SF Pro Text, -apple-system, sans-serif"; font.pixelSize: 12; color: settingsWin.textSecondary }
                      Item { Layout.fillWidth: true }
                      Text { text: "Omarchy Linux (Hyprland / Quickshell)"; font.family: "SF Pro Text, -apple-system, sans-serif"; font.pixelSize: 12; font.bold: true; color: settingsWin.textPrimary }
                    }

                    RowLayout {
                      Layout.fillWidth: true
                      Text { text: "System Diagnostics"; font.family: "SF Pro Text, -apple-system, sans-serif"; font.pixelSize: 12; color: settingsWin.textSecondary }
                      Item { Layout.fillWidth: true }
                      Button {
                        text: "Run Integrity Check"
                        onClicked: settingsWin.runCmd("omarchy-undercover --verify")
                      }
                    }
                  }
                }

                // ==========================================
                // CREDITS & ACKNOWLEDGMENTS
                // ==========================================
                Rectangle {
                  Layout.fillWidth: true
                  radius: 10
                  color: settingsWin.cardBg
                  border.color: settingsWin.cardBorder
                  border.width: 1
                  implicitHeight: macCreditsCol.implicitHeight + 36

                  ColumnLayout {
                    id: macCreditsCol
                    anchors.fill: parent
                    anchors.margins: 18
                    spacing: 12

                    RowLayout {
                      spacing: 12
                      Text { text: "🌟"; font.pixelSize: 18 }
                      ColumnLayout {
                        spacing: 2
                        Text {
                          text: "Credits & Acknowledgments"
                          font.family: "SF Pro Text, -apple-system, sans-serif"
                          font.pixelSize: 14
                          font.bold: true
                          color: settingsWin.textPrimary
                        }
                        Text {
                          text: "Omarchy Undercover is crafted by misternegative21 and powered by open-source plugins"
                          font.family: "SF Pro Text, -apple-system, sans-serif"
                          font.pixelSize: 11
                          color: settingsWin.textSecondary
                        }
                      }
                    }

                    Rectangle { Layout.fillWidth: true; height: 1; color: settingsWin.separatorColor }

                    // Lead Creator
                    RowLayout {
                      Layout.fillWidth: true
                      spacing: 12
                      Rectangle {
                        width: 30; height: 30; radius: 8
                        color: settingsWin.accentColor
                        Text { anchors.centerIn: parent; text: "👑"; font.pixelSize: 13 }
                      }
                      ColumnLayout {
                        Layout.fillWidth: true
                        spacing: 1
                        Text {
                          text: "misternegative21"
                          font.family: "SF Pro Text, -apple-system, sans-serif"
                          font.pixelSize: 12
                          font.bold: true
                          color: settingsWin.textPrimary
                        }
                        Text {
                          text: "Creator & Lead Developer • Architecture, Camouflage Suite & Multi-Monitor Integration"
                          font.family: "SF Pro Text, -apple-system, sans-serif"
                          font.pixelSize: 11
                          color: settingsWin.textSecondary
                        }
                      }
                    }

                    Rectangle { Layout.fillWidth: true; height: 1; color: settingsWin.separatorColor }

                    Text {
                      text: "Featured Plugin Contributors:"
                      font.family: "SF Pro Text, -apple-system, sans-serif"
                      font.pixelSize: 12
                      font.bold: true
                      color: settingsWin.textPrimary
                    }

                    // crmne
                    RowLayout {
                      Layout.fillWidth: true
                      spacing: 12
                      Text { text: "🖥️"; font.pixelSize: 14 }
                      ColumnLayout {
                        Layout.fillWidth: true
                        spacing: 1
                        Text {
                          text: "crmne (@crmne)"
                          font.family: "SF Pro Text, -apple-system, sans-serif"
                          font.pixelSize: 12
                          font.bold: true
                          color: settingsWin.textPrimary
                        }
                        Text {
                          text: "omarchy-hyprmoncfg — Multi-monitor management, display profiles, VRR & projection"
                          font.family: "SF Pro Text, -apple-system, sans-serif"
                          font.pixelSize: 11
                          color: settingsWin.textSecondary
                        }
                      }
                    }

                    // twiking
                    RowLayout {
                      Layout.fillWidth: true
                      spacing: 12
                      Text { text: "⚙️"; font.pixelSize: 14 }
                      ColumnLayout {
                        Layout.fillWidth: true
                        spacing: 1
                        Text {
                          text: "twiking (@twiking)"
                          font.family: "SF Pro Text, -apple-system, sans-serif"
                          font.pixelSize: 12
                          font.bold: true
                          color: settingsWin.textPrimary
                        }
                        Text {
                          text: "omasettings — Settings architecture & native system configuration patterns"
                          font.family: "SF Pro Text, -apple-system, sans-serif"
                          font.pixelSize: 11
                          color: settingsWin.textSecondary
                        }
                      }
                    }

                    // ssupt
                    RowLayout {
                      Layout.fillWidth: true
                      spacing: 12
                      Text { text: "🔊"; font.pixelSize: 14 }
                      ColumnLayout {
                        Layout.fillWidth: true
                        spacing: 1
                        Text {
                          text: "ssupt (@ssupt)"
                          font.family: "SF Pro Text, -apple-system, sans-serif"
                          font.pixelSize: 12
                          font.bold: true
                          color: settingsWin.textPrimary
                        }
                        Text {
                          text: "omarchy-audio-control — High-performance PipeWire daemon & audio rules engine"
                          font.family: "SF Pro Text, -apple-system, sans-serif"
                          font.pixelSize: 11
                          color: settingsWin.textSecondary
                        }
                      }
                    }

                    // thisisgm
                    RowLayout {
                      Layout.fillWidth: true
                      spacing: 12
                      Text { text: "📁"; font.pixelSize: 14 }
                      ColumnLayout {
                        Layout.fillWidth: true
                        spacing: 1
                        Text {
                          text: "thisisgm (@thisisgm)"
                          font.family: "SF Pro Text, -apple-system, sans-serif"
                          font.pixelSize: 12
                          font.bold: true
                          color: settingsWin.textPrimary
                        }
                        Text {
                          text: "omarchy-flea-filemanager — Lightweight native Flea file manager & desktop shelf"
                          font.family: "SF Pro Text, -apple-system, sans-serif"
                          font.pixelSize: 11
                          color: settingsWin.textSecondary
                        }
                      }
                    }
                  }
                }
              }

              // ==========================================
              // TAB 8: DISPLAYS
              // ==========================================
              ColumnLayout {
                visible: settingsWin.currentCategory === 8
                Layout.fillWidth: true
                spacing: 16

                // 1. Apple-style Monitor Hero Card
                Rectangle {
                  Layout.fillWidth: true
                  implicitHeight: 200
                  radius: 10
                  color: settingsWin.cardBg
                  border.color: settingsWin.cardBorder
                  border.width: 1

                  ColumnLayout {
                    anchors.centerIn: parent
                    spacing: 10

                    // Monitor Bezel Illustration
                    Rectangle {
                      Layout.alignment: Qt.AlignHCenter
                      width: 180
                      height: 110
                      radius: 8
                      color: settingsWin.isDark ? "#1a1a1e" : "#e5e5ea"
                      border.color: settingsWin.isDark ? Qt.rgba(1, 1, 1, 0.2) : Qt.rgba(0, 0, 0, 0.2)
                      border.width: 3

                      // Display Screen Inner
                      Rectangle {
                        anchors.fill: parent
                        anchors.margins: 4
                        radius: 5
                        color: settingsWin.isDark ? "#2c2c30" : "#d1d1d6"
                        clip: true

                        // Wallpaper preview inside Display monitor
                        Image {
                          anchors.fill: parent
                          source: "file://" + settingsWin.pluginDir + "/assets/wallpapers/" + settingsWin.currentWallpaper
                          fillMode: Image.PreserveAspectCrop
                          asynchronous: true
                          smooth: true
                        }

                        // Mac Dock line simulation inside preview
                        Rectangle {
                          anchors.bottom: parent.bottom
                          anchors.bottomMargin: 4
                          anchors.horizontalCenter: parent.horizontalCenter
                          width: 44; height: 4; radius: 2
                          color: Qt.rgba(1, 1, 1, 0.6)
                        }
                      }
                    }

                    // Display Stand
                    Rectangle {
                      Layout.alignment: Qt.AlignHCenter
                      width: 44
                      height: 12
                      radius: 3
                      color: settingsWin.isDark ? "#3a3a40" : "#c7c7cc"
                    }

                    // Display Name and Details
                    ColumnLayout {
                      Layout.alignment: Qt.AlignHCenter
                      spacing: 2
                      Text {
                        Layout.alignment: Qt.AlignHCenter
                        text: {
                          if (settingsService.monitors.length > 0) {
                            var m = settingsService.monitors[0]
                            return m.description || m.name || "Built-in Retina Display"
                          }
                          return "Built-in Retina Display"
                        }
                        font.family: "SF Pro Text, -apple-system, sans-serif"
                        font.pixelSize: 13
                        font.weight: Font.DemiBold
                        color: settingsWin.textPrimary
                      }
                      Text {
                        Layout.alignment: Qt.AlignHCenter
                        text: {
                          if (settingsService.monitors.length > 0) {
                            var m = settingsService.monitors[0]
                            var res = m.resolution || (m.width + "x" + m.height)
                            var hz = m.refreshRate ? Math.round(m.refreshRate) + " Hertz" : "60 Hertz"
                            var sc = m.scale ? " (" + Math.round(m.scale * 100) + "%)" : ""
                            return res + " @ " + hz + sc
                          }
                          return "1920 × 1080 @ 60 Hertz (100%)"
                        }
                        font.family: "SF Pro Text, -apple-system, sans-serif"
                        font.pixelSize: 11
                        color: settingsWin.textSecondary
                      }
                    }
                  }
                }

                // 2. Resolution & Scaling Card
                Rectangle {
                  Layout.fillWidth: true
                  implicitHeight: dispScaleCol.implicitHeight + 28
                  radius: 10
                  color: settingsWin.cardBg
                  border.color: settingsWin.cardBorder
                  border.width: 1

                  ColumnLayout {
                    id: dispScaleCol
                    anchors.fill: parent
                    anchors.margins: 16
                    spacing: 14

                    RowLayout {
                      Layout.fillWidth: true
                      ColumnLayout {
                        spacing: 2
                        Text {
                          text: "Display Scaling"
                          font.family: "SF Pro Text, -apple-system, sans-serif"
                          font.pixelSize: 13
                          font.weight: Font.DemiBold
                          color: settingsWin.textPrimary
                        }
                        Text {
                          text: "Choose scaled text and UI size for comfortable reading"
                          font.family: "SF Pro Text, -apple-system, sans-serif"
                          font.pixelSize: 11
                          color: settingsWin.textSecondary
                        }
                      }
                    }

                    // Apple-style scaling selector pills
                    RowLayout {
                      Layout.fillWidth: true
                      spacing: 10

                      property var scalePresets: [
                        { label: "Larger Text", scale: 1.5, pct: "150%" },
                        { label: "Default", scale: 1.25, pct: "125%" },
                        { label: "Native", scale: 1.0, pct: "100%" },
                        { label: "More Space", scale: 0.8, pct: "80%" }
                      ]

                      Repeater {
                        model: parent.scalePresets
                        delegate: Rectangle {
                          Layout.fillWidth: true
                          implicitHeight: 64
                          radius: 8

                          readonly property bool isSelected: {
                            if (settingsService.monitors.length > 0) {
                              var cur = settingsService.monitors[0].scale || 1.0
                              return Math.abs(cur - modelData.scale) < 0.08
                            }
                            return modelData.scale === 1.0
                          }

                          color: isSelected
                                 ? (settingsWin.isDark ? Qt.rgba(0.2, 0.4, 0.8, 0.3) : Qt.rgba(0.0, 0.48, 1.0, 0.12))
                                 : (scMouse.containsMouse ? (settingsWin.isDark ? Qt.rgba(1, 1, 1, 0.08) : Qt.rgba(0, 0, 0, 0.04)) : "transparent")
                          border.color: isSelected ? settingsWin.accentColor : (settingsWin.isDark ? Qt.rgba(1, 1, 1, 0.15) : Qt.rgba(0, 0, 0, 0.12))
                          border.width: isSelected ? 2 : 1

                          ColumnLayout {
                            anchors.centerIn: parent
                            spacing: 4
                            Text {
                              Layout.alignment: Qt.AlignHCenter
                              text: modelData.label
                              font.family: "SF Pro Text, -apple-system, sans-serif"
                              font.pixelSize: 12
                              font.weight: isSelected ? Font.DemiBold : Font.Normal
                              color: isSelected ? settingsWin.accentColor : settingsWin.textPrimary
                            }
                            Text {
                              Layout.alignment: Qt.AlignHCenter
                              text: modelData.pct
                              font.family: "SF Pro Text, -apple-system, sans-serif"
                              font.pixelSize: 10
                              color: settingsWin.textSecondary
                            }
                          }

                          MouseArea {
                            id: scMouse
                            anchors.fill: parent
                            hoverEnabled: true
                            cursorShape: Qt.PointingHandCursor
                            onClicked: {
                              if (settingsService.monitors.length > 0) {
                                var m = settingsService.monitors[0]
                                var desc = m.description || m.name
                                settingsService.setMonitorScale(desc, modelData.scale)
                              }
                            }
                          }
                        }
                      }
                    }

                    Rectangle { Layout.fillWidth: true; height: 1; color: settingsWin.separatorColor }

                    // Scale Percentage Buttons
                    RowLayout {
                      Layout.fillWidth: true
                      Text {
                        text: "Custom Scale"
                        font.family: "SF Pro Text, -apple-system, sans-serif"
                        font.pixelSize: 12
                        color: settingsWin.textPrimary
                      }
                      Item { Layout.fillWidth: true }

                      property var numScales: [1.0, 1.25, 1.5, 1.75, 2.0]
                      Repeater {
                        model: parent.numScales
                        delegate: Rectangle {
                          implicitWidth: 54; implicitHeight: 28; radius: 6
                          readonly property bool isSelected: {
                            if (settingsService.monitors.length > 0) {
                              var cur = settingsService.monitors[0].scale || 1.0
                              return Math.abs(cur - modelData) < 0.05
                            }
                            return modelData === 1.0
                          }
                          color: isSelected ? settingsWin.accentColor : (numMouse.containsMouse ? (settingsWin.isDark ? Qt.rgba(1, 1, 1, 0.1) : Qt.rgba(0, 0, 0, 0.06)) : (settingsWin.isDark ? Qt.rgba(1, 1, 1, 0.05) : Qt.rgba(0, 0, 0, 0.03)))
                          border.color: isSelected ? settingsWin.accentColor : settingsWin.cardBorder
                          border.width: 1

                          Text {
                            anchors.centerIn: parent
                            text: Math.round(modelData * 100) + "%"
                            font.family: "SF Pro Text, -apple-system, sans-serif"
                            font.pixelSize: 11
                            font.weight: isSelected ? Font.DemiBold : Font.Normal
                            color: isSelected ? "#ffffff" : settingsWin.textPrimary
                          }

                          MouseArea {
                            id: numMouse
                            anchors.fill: parent
                            hoverEnabled: true
                            cursorShape: Qt.PointingHandCursor
                            onClicked: {
                              if (settingsService.monitors.length > 0) {
                                var m = settingsService.monitors[0]
                                var desc = m.description || m.name
                                settingsService.setMonitorScale(desc, modelData)
                              }
                            }
                          }
                        }
                      }
                    }
                  }
                }

                // 3. Refresh Rate & Resolution Card
                Rectangle {
                  Layout.fillWidth: true
                  implicitHeight: dispRateCol.implicitHeight + 28
                  radius: 10
                  color: settingsWin.cardBg
                  border.color: settingsWin.cardBorder
                  border.width: 1

                  ColumnLayout {
                    id: dispRateCol
                    anchors.fill: parent
                    anchors.margins: 16
                    spacing: 12

                    RowLayout {
                      Layout.fillWidth: true
                      ColumnLayout {
                        spacing: 2
                        Text {
                          text: "Active Resolution"
                          font.family: "SF Pro Text, -apple-system, sans-serif"
                          font.pixelSize: 12
                          font.weight: Font.DemiBold
                          color: settingsWin.textPrimary
                        }
                        Text {
                          text: settingsService.monitors.length > 0 ? (settingsService.monitors[0].resolution || "1920x1080") : "1920x1080"
                          font.family: "SF Pro Text, -apple-system, sans-serif"
                          font.pixelSize: 11
                          color: settingsWin.textSecondary
                        }
                      }
                      Item { Layout.fillWidth: true }
                      Text {
                        text: (settingsService.monitors.length > 0 && settingsService.monitors[0].refreshRate ? Math.round(settingsService.monitors[0].refreshRate) + " Hz" : "60 Hz")
                        font.family: "SF Pro Text, -apple-system, sans-serif"
                        font.pixelSize: 12
                        font.bold: true
                        color: settingsWin.accentColor
                      }
                    }

                    Rectangle { Layout.fillWidth: true; height: 1; color: settingsWin.separatorColor }

                    // Refresh Rate Selector Buttons
                    RowLayout {
                      Layout.fillWidth: true
                      Text {
                        text: "Refresh Rate"
                        font.family: "SF Pro Text, -apple-system, sans-serif"
                        font.pixelSize: 12
                        color: settingsWin.textPrimary
                      }
                      Item { Layout.fillWidth: true }

                      property var rates: [60, 75, 120, 144, 165]
                      Repeater {
                        model: parent.rates
                        delegate: Rectangle {
                          implicitWidth: 62; implicitHeight: 28; radius: 6
                          readonly property bool isSelected: {
                            if (settingsService.monitors.length > 0) {
                              var curHz = Math.round(settingsService.monitors[0].refreshRate || 60)
                              return curHz === modelData
                            }
                            return modelData === 60
                          }
                          color: isSelected ? settingsWin.accentColor : (rateMouse.containsMouse ? (settingsWin.isDark ? Qt.rgba(1, 1, 1, 0.1) : Qt.rgba(0, 0, 0, 0.06)) : (settingsWin.isDark ? Qt.rgba(1, 1, 1, 0.05) : Qt.rgba(0, 0, 0, 0.03)))
                          border.color: isSelected ? settingsWin.accentColor : settingsWin.cardBorder
                          border.width: 1

                          Text {
                            anchors.centerIn: parent
                            text: modelData + " Hz"
                            font.family: "SF Pro Text, -apple-system, sans-serif"
                            font.pixelSize: 11
                            font.weight: isSelected ? Font.DemiBold : Font.Normal
                            color: isSelected ? "#ffffff" : settingsWin.textPrimary
                          }

                          MouseArea {
                            id: rateMouse
                            anchors.fill: parent
                            hoverEnabled: true
                            cursorShape: Qt.PointingHandCursor
                            onClicked: {
                              if (settingsService.monitors.length > 0) {
                                var m = settingsService.monitors[0]
                                var desc = m.description || m.name
                                var w = m.width || 1920
                                var h = m.height || 1080
                                settingsService.setMonitorMode(desc, w + "x" + h + "@" + modelData)
                              }
                            }
                          }
                        }
                      }
                    }
                  }
                }

                // 4. Night Shift Card
                Rectangle {
                  Layout.fillWidth: true
                  implicitHeight: nightShiftCol.implicitHeight + 28
                  radius: 10
                  color: settingsWin.cardBg
                  border.color: settingsWin.cardBorder
                  border.width: 1

                  ColumnLayout {
                    id: nightShiftCol
                    anchors.fill: parent
                    anchors.margins: 16
                    spacing: 12

                    RowLayout {
                      Layout.fillWidth: true
                      ColumnLayout {
                        spacing: 2
                        Text {
                          text: "Night Shift"
                          font.family: "SF Pro Text, -apple-system, sans-serif"
                          font.pixelSize: 13
                          font.weight: Font.DemiBold
                          color: settingsWin.textPrimary
                        }
                        Text {
                          text: "Automatically shift colors to the warmer end of the spectrum to reduce eye strain"
                          font.family: "SF Pro Text, -apple-system, sans-serif"
                          font.pixelSize: 11
                          color: settingsWin.textSecondary
                        }
                      }
                      Item { Layout.fillWidth: true }

                      property bool nsActive: false

                      Rectangle {
                        width: 38; height: 22; radius: 11
                        color: parent.nsActive ? "#34c759" : (settingsWin.isDark ? "#39393d" : "#e5e5ea")
                        Rectangle {
                          width: 18; height: 18; radius: 9
                          x: parent.parent.nsActive ? 18 : 2
                          anchors.verticalCenter: parent.verticalCenter
                          color: "#ffffff"
                          Behavior on x { NumberAnimation { duration: 120; easing.type: Easing.OutQuad } }
                        }
                        MouseArea {
                          anchors.fill: parent
                          cursorShape: Qt.PointingHandCursor
                          onClicked: {
                            parent.parent.nsActive = !parent.parent.nsActive
                            settingsService.setHyprOption("nightlight", parent.parent.nsActive ? "on" : "off")
                          }
                        }
                      }
                    }
                  }
                }
              }

              // ==========================================
              // TAB 9: BATTERY
              // ==========================================
              ColumnLayout {
                visible: settingsWin.currentCategory === 9
                Layout.fillWidth: true
                spacing: 16

                // 1. Apple-style Battery Hero Card
                Rectangle {
                  Layout.fillWidth: true
                  implicitHeight: 120
                  radius: 10
                  color: settingsWin.cardBg
                  border.color: settingsWin.cardBorder
                  border.width: 1

                  RowLayout {
                    anchors.fill: parent
                    anchors.margins: 20
                    spacing: 20

                    // Battery Icon Gauge Graphic
                    Rectangle {
                      width: 56; height: 32; radius: 6
                      color: "transparent"
                      border.color: settingsWin.textPrimary
                      border.width: 2.5

                      // Terminal nub
                      Rectangle {
                        anchors.left: parent.right
                        anchors.leftMargin: 2
                        anchors.verticalCenter: parent.verticalCenter
                        width: 4; height: 12; radius: 2
                        color: settingsWin.textPrimary
                      }

                      // Inner Level Fill
                      Rectangle {
                        anchors.left: parent.left
                        anchors.top: parent.top
                        anchors.bottom: parent.bottom
                        anchors.margins: 3
                        width: Math.max(4, (parent.width - 6) * (Math.min(100, Math.max(0, settingsService.batteryPct)) / 100.0))
                        radius: 3
                        color: settingsService.batteryPct <= 20 ? "#ff9f0a" : "#34c759"
                      }

                      // Charging Bolt Indicator
                      Text {
                        visible: settingsService.isCharging
                        anchors.centerIn: parent
                        text: "⚡"
                        font.pixelSize: 14
                      }
                    }

                    ColumnLayout {
                      Layout.fillWidth: true
                      spacing: 4

                      RowLayout {
                        spacing: 8
                        Text {
                          text: settingsService.batteryPct + "%"
                          font.family: "SF Pro Display, -apple-system, sans-serif"
                          font.pixelSize: 28
                          font.weight: Font.Bold
                          color: settingsWin.textPrimary
                        }
                        Rectangle {
                          radius: 4
                          implicitWidth: healthText.implicitWidth + 10
                          implicitHeight: 20
                          color: Qt.rgba(0.2, 0.78, 0.35, 0.15)
                          Text {
                            id: healthText
                            anchors.centerIn: parent
                            text: "Normal"
                            font.family: "SF Pro Text, -apple-system, sans-serif"
                            font.pixelSize: 11
                            font.weight: Font.DemiBold
                            color: "#34c759"
                          }
                        }
                      }

                      Text {
                        text: settingsService.isCharging ? "Power Source: Power Adapter (Charging)" : "Power Source: Battery"
                        font.family: "SF Pro Text, -apple-system, sans-serif"
                        font.pixelSize: 12
                        color: settingsWin.textSecondary
                      }
                    }

                    // Horizontal Progress Meter
                    Rectangle {
                      implicitWidth: 150
                      implicitHeight: 8
                      radius: 4
                      color: settingsWin.isDark ? Qt.rgba(1, 1, 1, 0.12) : Qt.rgba(0, 0, 0, 0.08)

                      Rectangle {
                        width: Math.max(6, parent.width * (Math.min(100, Math.max(0, settingsService.batteryPct)) / 100.0))
                        height: parent.height
                        radius: 4
                        color: settingsService.batteryPct <= 20 ? "#ff9f0a" : "#34c759"
                      }
                    }
                  }
                }

                // 2. Energy Mode (Power Profiles) Card
                Rectangle {
                  Layout.fillWidth: true
                  implicitHeight: energyCol.implicitHeight + 28
                  radius: 10
                  color: settingsWin.cardBg
                  border.color: settingsWin.cardBorder
                  border.width: 1

                  ColumnLayout {
                    id: energyCol
                    anchors.fill: parent
                    anchors.margins: 16
                    spacing: 14

                    ColumnLayout {
                      spacing: 2
                      Text {
                        text: "Energy Mode"
                        font.family: "SF Pro Text, -apple-system, sans-serif"
                        font.pixelSize: 13
                        font.weight: Font.DemiBold
                        color: settingsWin.textPrimary
                      }
                      Text {
                        text: "Optimize energy consumption based on current performance and workflow needs"
                        font.family: "SF Pro Text, -apple-system, sans-serif"
                        font.pixelSize: 11
                        color: settingsWin.textSecondary
                      }
                    }

                    // Apple-style Segmented Control for Power Profiles
                    Rectangle {
                      Layout.fillWidth: true
                      implicitHeight: 38
                      radius: 8
                      color: settingsWin.isDark ? Qt.rgba(1, 1, 1, 0.08) : Qt.rgba(0, 0, 0, 0.06)
                      border.color: settingsWin.cardBorder
                      border.width: 1

                      RowLayout {
                        anchors.fill: parent
                        anchors.margins: 3
                        spacing: 4

                        property var profiles: [
                          { label: "Low Power", id: "power-saver", desc: "Reduces energy usage to increase battery life and operate cooler." },
                          { label: "Automatic", id: "balanced", desc: "Dynamically balances energy usage and system performance for everyday tasks." },
                          { label: "High Power", id: "performance", desc: "Maximizes performance for sustained intensive compute workflows." }
                        ]

                        Repeater {
                          model: parent.profiles
                          delegate: Rectangle {
                            Layout.fillWidth: true
                            Layout.fillHeight: true
                            radius: 6

                            readonly property bool isSelected: settingsService.powerProfile === modelData.id
                            color: isSelected
                                   ? (settingsWin.isDark ? Qt.rgba(1, 1, 1, 0.22) : "#ffffff")
                                   : (profMouse.containsMouse ? (settingsWin.isDark ? Qt.rgba(1, 1, 1, 0.08) : Qt.rgba(0, 0, 0, 0.04)) : "transparent")

                            border.color: isSelected ? (settingsWin.isDark ? Qt.rgba(1, 1, 1, 0.15) : Qt.rgba(0, 0, 0, 0.1)) : "transparent"
                            border.width: isSelected ? 1 : 0

                            Text {
                              anchors.centerIn: parent
                              text: modelData.label
                              font.family: "SF Pro Text, -apple-system, sans-serif"
                              font.pixelSize: 12
                              font.weight: isSelected ? Font.DemiBold : Font.Normal
                              color: isSelected ? settingsWin.textPrimary : settingsWin.textSecondary
                            }

                            MouseArea {
                              id: profMouse
                              anchors.fill: parent
                              hoverEnabled: true
                              cursorShape: Qt.PointingHandCursor
                              onClicked: settingsService.setPowerProfile(modelData.id)
                            }
                          }
                        }
                      }
                    }

                    // Profile Description
                    Text {
                      Layout.fillWidth: true
                      text: {
                        switch(settingsService.powerProfile) {
                          case "power-saver": return "Low Power mode reduces system power draw to maximize battery runtime."
                          case "performance": return "High Power mode boosts CPU clocks for intensive compiling and graphics tasks."
                          default: return "Automatic dynamically balances system power and performance for smooth multitasking."
                        }
                      }
                      font.family: "SF Pro Text, -apple-system, sans-serif"
                      font.pixelSize: 11
                      color: settingsWin.textSecondary
                    }

                    Rectangle { Layout.fillWidth: true; height: 1; color: settingsWin.separatorColor }

                    // Battery Health Row
                    RowLayout {
                      Layout.fillWidth: true
                      Text {
                        text: "Battery Condition"
                        font.family: "SF Pro Text, -apple-system, sans-serif"
                        font.pixelSize: 12
                        color: settingsWin.textPrimary
                      }
                      Item { Layout.fillWidth: true }
                      Text {
                        text: "Normal (Maximum Capacity 100%)"
                        font.family: "SF Pro Text, -apple-system, sans-serif"
                        font.pixelSize: 12
                        font.weight: Font.DemiBold
                        color: "#34c759"
                      }
                    }
                  }
                }
              }

              // ==========================================
              // TAB 10: TRACKPAD & MOUSE
              // ==========================================
              ColumnLayout {
                visible: settingsWin.currentCategory === 10
                Layout.fillWidth: true
                spacing: 16

                // 1. Point & Click Card
                Rectangle {
                  Layout.fillWidth: true
                  implicitHeight: pointCol.implicitHeight + 28
                  radius: 10
                  color: settingsWin.cardBg
                  border.color: settingsWin.cardBorder
                  border.width: 1

                  ColumnLayout {
                    id: pointCol
                    anchors.fill: parent
                    anchors.margins: 16
                    spacing: 14

                    Text {
                      text: "Point & Click"
                      font.family: "SF Pro Text, -apple-system, sans-serif"
                      font.pixelSize: 13
                      font.weight: Font.DemiBold
                      color: settingsWin.textPrimary
                    }

                    // Tracking Speed Slider Row
                    RowLayout {
                      Layout.fillWidth: true
                      spacing: 12

                      ColumnLayout {
                        Layout.fillWidth: true
                        spacing: 2
                        Text {
                          text: "Tracking speed"
                          font.family: "SF Pro Text, -apple-system, sans-serif"
                          font.pixelSize: 12
                          font.weight: Font.DemiBold
                          color: settingsWin.textPrimary
                        }
                        Text {
                          text: "Adjust cursor sensitivity and pointer acceleration"
                          font.family: "SF Pro Text, -apple-system, sans-serif"
                          font.pixelSize: 11
                          color: settingsWin.textSecondary
                        }
                      }

                      RowLayout {
                        spacing: 8
                        Text {
                          text: "Slow"
                          font.family: "SF Pro Text, -apple-system, sans-serif"
                          font.pixelSize: 10
                          color: settingsWin.textSecondary
                        }
                        Slider {
                          Layout.preferredWidth: 160
                          from: 1; to: 20; stepSize: 1
                          value: Math.max(1, Math.min(20, Math.round((settingsService.mouseSpeed + 1.0) * 9.5 + 1)))
                          onMoved: {
                            var sens = (value - 10) / 10.0
                            settingsService.mouseSpeed = sens
                            settingsService.setDeviceOption("*", "sensitivity", sens.toFixed(2), "pointer")
                          }
                        }
                        Text {
                          text: "Fast"
                          font.family: "SF Pro Text, -apple-system, sans-serif"
                          font.pixelSize: 10
                          color: settingsWin.textSecondary
                        }
                      }
                    }

                    Rectangle { Layout.fillWidth: true; height: 1; color: settingsWin.separatorColor }

                    // Natural Scrolling Toggle
                    RowLayout {
                      Layout.fillWidth: true
                      ColumnLayout {
                        Layout.fillWidth: true
                        spacing: 2
                        Text {
                          text: "Natural scrolling"
                          font.family: "SF Pro Text, -apple-system, sans-serif"
                          font.pixelSize: 12
                          font.weight: Font.DemiBold
                          color: settingsWin.textPrimary
                        }
                        Text {
                          text: "Content moves in the same direction as your fingers"
                          font.family: "SF Pro Text, -apple-system, sans-serif"
                          font.pixelSize: 11
                          color: settingsWin.textSecondary
                        }
                      }

                      Rectangle {
                        width: 38; height: 22; radius: 11
                        color: settingsService.touchpadNaturalScroll ? "#34c759" : (settingsWin.isDark ? "#39393d" : "#e5e5ea")
                        Rectangle {
                          width: 18; height: 18; radius: 9
                          x: settingsService.touchpadNaturalScroll ? 18 : 2
                          anchors.verticalCenter: parent.verticalCenter
                          color: "#ffffff"
                          Behavior on x { NumberAnimation { duration: 120; easing.type: Easing.OutQuad } }
                        }
                        MouseArea {
                          anchors.fill: parent
                          cursorShape: Qt.PointingHandCursor
                          onClicked: {
                            var next = !settingsService.touchpadNaturalScroll
                            settingsService.touchpadNaturalScroll = next
                            settingsService.setDeviceOption("*", "natural_scroll", next ? "true" : "false", "touchpad")
                          }
                        }
                      }
                    }

                    Rectangle { Layout.fillWidth: true; height: 1; color: settingsWin.separatorColor }

                    // Tap to Click Toggle
                    RowLayout {
                      Layout.fillWidth: true
                      ColumnLayout {
                        Layout.fillWidth: true
                        spacing: 2
                        Text {
                          text: "Tap to click"
                          font.family: "SF Pro Text, -apple-system, sans-serif"
                          font.pixelSize: 12
                          font.weight: Font.DemiBold
                          color: settingsWin.textPrimary
                        }
                        Text {
                          text: "Tap on trackpad with one finger instead of pressing down"
                          font.family: "SF Pro Text, -apple-system, sans-serif"
                          font.pixelSize: 11
                          color: settingsWin.textSecondary
                        }
                      }

                      Rectangle {
                        width: 38; height: 22; radius: 11
                        color: settingsService.touchpadTapToClick ? "#34c759" : (settingsWin.isDark ? "#39393d" : "#e5e5ea")
                        Rectangle {
                          width: 18; height: 18; radius: 9
                          x: settingsService.touchpadTapToClick ? 18 : 2
                          anchors.verticalCenter: parent.verticalCenter
                          color: "#ffffff"
                          Behavior on x { NumberAnimation { duration: 120; easing.type: Easing.OutQuad } }
                        }
                        MouseArea {
                          anchors.fill: parent
                          cursorShape: Qt.PointingHandCursor
                          onClicked: {
                            var next = !settingsService.touchpadTapToClick
                            settingsService.touchpadTapToClick = next
                            settingsService.setDeviceOption("*", "tap-to-click", next ? "true" : "false", "touchpad")
                          }
                        }
                      }
                    }
                  }
                }

                // 2. Scroll & Zoom Gestures Card
                Rectangle {
                  Layout.fillWidth: true
                  implicitHeight: scrollCol.implicitHeight + 28
                  radius: 10
                  color: settingsWin.cardBg
                  border.color: settingsWin.cardBorder
                  border.width: 1

                  ColumnLayout {
                    id: scrollCol
                    anchors.fill: parent
                    anchors.margins: 16
                    spacing: 12

                    Text {
                      text: "Scroll & Zoom Gestures"
                      font.family: "SF Pro Text, -apple-system, sans-serif"
                      font.pixelSize: 13
                      font.weight: Font.DemiBold
                      color: settingsWin.textPrimary
                    }

                    RowLayout {
                      Layout.fillWidth: true
                      ColumnLayout {
                        spacing: 2
                        Text { text: "Zoom in or out"; font.family: "SF Pro Text, -apple-system, sans-serif"; font.pixelSize: 12; font.weight: Font.DemiBold; color: settingsWin.textPrimary }
                        Text { text: "Pinch with two fingers"; font.family: "SF Pro Text, -apple-system, sans-serif"; font.pixelSize: 11; color: settingsWin.textSecondary }
                      }
                      Item { Layout.fillWidth: true }
                      Text { text: "Supported"; font.family: "SF Pro Text, -apple-system, sans-serif"; font.pixelSize: 11; color: "#34c759" }
                    }

                    Rectangle { Layout.fillWidth: true; height: 1; color: settingsWin.separatorColor }

                    RowLayout {
                      Layout.fillWidth: true
                      ColumnLayout {
                        spacing: 2
                        Text { text: "Mission Control swipe"; font.family: "SF Pro Text, -apple-system, sans-serif"; font.pixelSize: 12; font.weight: Font.DemiBold; color: settingsWin.textPrimary }
                        Text { text: "Swipe up with three or four fingers"; font.family: "SF Pro Text, -apple-system, sans-serif"; font.pixelSize: 11; color: settingsWin.textSecondary }
                      }
                      Item { Layout.fillWidth: true }
                      Text { text: "Super + W"; font.family: "SF Pro Text, -apple-system, sans-serif"; font.pixelSize: 11; font.weight: Font.DemiBold; color: settingsWin.accentColor }
                    }

                    Rectangle { Layout.fillWidth: true; height: 1; color: settingsWin.separatorColor }

                    RowLayout {
                      Layout.fillWidth: true
                      ColumnLayout {
                        spacing: 2
                        Text { text: "Switch between full-screen apps"; font.family: "SF Pro Text, -apple-system, sans-serif"; font.pixelSize: 12; font.weight: Font.DemiBold; color: settingsWin.textPrimary }
                        Text { text: "Swipe left or right with three fingers"; font.family: "SF Pro Text, -apple-system, sans-serif"; font.pixelSize: 11; color: settingsWin.textSecondary }
                      }
                      Item { Layout.fillWidth: true }
                      Text { text: "Workspace Swipe"; font.family: "SF Pro Text, -apple-system, sans-serif"; font.pixelSize: 11; font.weight: Font.DemiBold; color: settingsWin.accentColor }
                    }
                  }
                }
              }

              Item { implicitHeight: 24 }
            }
          }
        }
      }

      // ==========================================
      // BOTTOM-RIGHT WINDOW RESIZE GRIP
      // ==========================================
      Rectangle {
        id: resizeCorner
        width: 18; height: 18
        anchors.right: parent.right
        anchors.bottom: parent.bottom
        color: "transparent"

        Canvas {
          anchors.fill: parent
          onPaint: {
            var ctx = getContext("2d")
            ctx.strokeStyle = settingsWin.isDark ? Qt.rgba(1, 1, 1, 0.3) : Qt.rgba(0, 0, 0, 0.3)
            ctx.lineWidth = 1.2
            ctx.beginPath()
            ctx.moveTo(14, 6); ctx.lineTo(6, 14)
            ctx.moveTo(14, 10); ctx.lineTo(10, 14)
            ctx.stroke()
          }
        }

        MouseArea {
          id: resizeMouse
          anchors.fill: parent
          hoverEnabled: true
          cursorShape: Qt.SizeFDiagCursor

          property real startX: 0
          property real startY: 0
          property real startW: 0
          property real startH: 0

          onPressed: function(mouse) {
            startX = mouse.x
            startY = mouse.y
            startW = settingsWin.width
            startH = settingsWin.height
            if (typeof settingsWin.startSystemResize === "function") {
              settingsWin.startSystemResize(Qt.BottomEdge | Qt.RightEdge)
            }
          }

          onPositionChanged: function(mouse) {
            if (pressed) {
              var newW = startW + (mouse.x - startX)
              var newH = startH + (mouse.y - startY)
              if (newW >= 860) settingsWin.implicitWidth = newW
              if (newH >= 560) settingsWin.implicitHeight = newH
            }
          }
        }
      }
    }
  }
}

import Quickshell
import Quickshell.Wayland
import Quickshell.Hyprland
import Quickshell.Io
import QtQuick
import QtQuick.Layouts
import QtQuick.Controls

ShellRoot {
  FloatingWindow {
    id: settingsWin
    title: "Settings"

    implicitWidth: Math.min(960, (Quickshell.screens[0] ? Quickshell.screens[0].width - 40 : 960))
    implicitHeight: Math.min(620, (Quickshell.screens[0] ? Quickshell.screens[0].height - 60 : 620))
    minimumSize: Qt.size(Math.min(760, (Quickshell.screens[0] ? Quickshell.screens[0].width - 40 : 760)), Math.min(480, (Quickshell.screens[0] ? Quickshell.screens[0].height - 60 : 480)))
    color: "transparent"

    Component.onCompleted: {
      raiseTimer.start()
    }

    Timer {
      id: raiseTimer
      interval: 60
      running: true
      repeat: false
      onTriggered: {
        Quickshell.execDetached([
          "bash", "-c",
          "hyprctl dispatch 'hl.dsp.focus({ window = \"title:^Settings$\" })' 2>/dev/null || hyprctl dispatch focuswindow 'title:^Settings$' 2>/dev/null || true; " +
          "hyprctl dispatch 'hl.dsp.window.alter_zorder({ mode = \"top\" })' 2>/dev/null || hyprctl dispatch alterzorder top 2>/dev/null || true; " +
          "hyprctl dispatch 'hl.dsp.window.bring_to_top()' 2>/dev/null || hyprctl dispatch bringactivetotop 2>/dev/null || true"
        ])
      }
    }

    property string homeDir: Quickshell.env("HOME")
    property string userName: Quickshell.env("USER") || "User"
    property string currentDisguise: "win11-dark"
    property bool isDark: true
    property bool isTransparent: true
    property string activeAccent: "60cdff"
    property int currentCategory: 0
    property string searchQuery: ""
    property real sidebarWidth: 260

    // Authentic Windows 11 Dynamic Fluent Accent
    readonly property color accentColor: {
      if (activeAccent && activeAccent !== "0078d4" && activeAccent !== "60cdff") {
        return "#" + activeAccent
      }
      return isDark ? "#60cdff" : "#0067c0"
    }

    readonly property color accentTextColor: {
      var c = settingsWin.accentColor
      var lum = 0.299 * c.r + 0.587 * c.g + 0.114 * c.b
      return lum > 0.55 ? "#000000" : "#ffffff"
    }

    readonly property color windowBg: isDark
      ? (isTransparent ? Qt.rgba(0.12, 0.13, 0.16, 0.96) : "#1c1d22")
      : (isTransparent ? Qt.rgba(0.95, 0.96, 0.98, 0.96) : "#f0f2f5")
    readonly property color sidebarBg: isDark
      ? Qt.rgba(0, 0, 0, 0.28)
      : (isTransparent ? Qt.rgba(0.90, 0.92, 0.95, 0.70) : "#e8ebf0")
    readonly property color cardBg: isDark
      ? Qt.rgba(1, 1, 1, 0.08)
      : "#ffffff"
    readonly property color cardBorder: isDark
      ? Qt.rgba(1, 1, 1, 0.12)
      : Qt.rgba(0, 0, 0, 0.10)
    readonly property color textPrimary: isDark ? "#ffffff" : "#111111"
    readonly property color textSecondary: isDark ? Qt.rgba(1, 1, 1, 0.78) : "#555555"
    readonly property color separatorColor: isDark ? Qt.rgba(1, 1, 1, 0.10) : Qt.rgba(0, 0, 0, 0.10)

    property int volumeLevel: 70
    property int brightnessLevel: 80
    property bool wifiEnabled: true
    property string wifiSsid: "Connected"
    property bool btEnabled: true
    property bool isAwakeActive: false
    property bool autohideActive: false
    property string taskbarAlign: "center"
    property int windowGaps: 8
    property int windowRounding: 10
    property string systemSubPage: ""
    property real stereoBalance: 0.5
    property string pluginDir: Quickshell.env("OMARCHY_PLUGIN_DIR") || (settingsWin.homeDir + "/.config/omarchy/plugins/omarchy-undercover")

    AudioService {
      id: audioService
    }

    SettingsService {
      id: settingsService
    }

    FileView {
      path: (Quickshell.env("XDG_RUNTIME_DIR") || "/tmp") + "/omarchy-settings-page"
      watchChanges: true
      onLoaded: {
        var p = text().trim()
        if (p === "sound") {
          settingsWin.currentCategory = 0
          settingsWin.systemSubPage = "sound"
        } else if (p === "display") {
          settingsWin.currentCategory = 0
          settingsWin.systemSubPage = "display"
        } else if (p === "power") {
          settingsWin.currentCategory = 0
          settingsWin.systemSubPage = "power"
        } else if (p === "wifi" || p === "network") {
          settingsWin.currentCategory = 2
        } else if (p === "bluetooth") {
          settingsWin.currentCategory = 1
        }
      }
      onFileChanged: {
        reload()
        var p = text().trim()
        if (p === "sound") {
          settingsWin.currentCategory = 0
          settingsWin.systemSubPage = "sound"
        } else if (p === "display") {
          settingsWin.currentCategory = 0
          settingsWin.systemSubPage = "display"
        } else if (p === "power") {
          settingsWin.currentCategory = 0
          settingsWin.systemSubPage = "power"
        } else if (p === "wifi" || p === "network") {
          settingsWin.currentCategory = 2
        } else if (p === "bluetooth") {
          settingsWin.currentCategory = 1
        }
      }
    }

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

    // Reactive Watcher on State
    FileView {
      id: stateWatcher
      path: settingsWin.pluginDir + "/state"
      watchChanges: true
      onLoaded: {
        var s = text().trim()
        settingsWin.currentDisguise = s || "win11-dark"
        settingsWin.isDark = (s.indexOf("light") === -1)
      }
      onFileChanged: {
        reload()
        var s = text().trim()
        settingsWin.currentDisguise = s || "win11-dark"
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
        settingsWin.isTransparent = (s.indexOf("WIN11_TRANSPARENCY=false") === -1 && s.indexOf("BAR_TRANSPARENT=false") === -1)
        if (s.indexOf("ALIGN_LEFT=true") !== -1) settingsWin.taskbarAlign = "left"
        else settingsWin.taskbarAlign = "center"
        var m = s.match(/ACCENT=([0-9a-fA-F]+)/)
        if (m && m[1]) settingsWin.activeAccent = m[1]
        var mg = s.match(/WINDOW_GAPS=([0-9]+)/)
        if (mg && mg[1]) settingsWin.windowGaps = parseInt(mg[1])
        var mr = s.match(/WINDOW_ROUNDING=([0-9]+)/)
        if (mr && mr[1]) settingsWin.windowRounding = parseInt(mr[1])
      }
      onFileChanged: {
        reload()
        var s = text()
        settingsWin.autohideActive = (s.indexOf("AUTOHIDE=true") !== -1)
        settingsWin.isTransparent = (s.indexOf("WIN11_TRANSPARENCY=false") === -1 && s.indexOf("BAR_TRANSPARENT=false") === -1)
        if (s.indexOf("ALIGN_LEFT=true") !== -1) settingsWin.taskbarAlign = "left"
        else settingsWin.taskbarAlign = "center"
        var m = s.match(/ACCENT=([0-9a-fA-F]+)/)
        if (m && m[1]) settingsWin.activeAccent = m[1]
      }
    }

    property var winPins: ({})

    FileView {
      id: defaultsWatcher
      path: settingsWin.pluginDir + "/defaults.json"
      watchChanges: true
      onLoaded: {
        try {
          var d = JSON.parse(text())
          if (d && d.win11_pins) settingsWin.winPins = d.win11_pins
        } catch(e) {}
      }
      onFileChanged: {
        reload()
        try {
          var d = JSON.parse(text())
          if (d && d.win11_pins) settingsWin.winPins = d.win11_pins
        } catch(e) {}
      }
    }

    FileView {
      id: shellJsonWatcher
      path: settingsWin.homeDir + "/.config/omarchy/shell.json"
      watchChanges: true
      onLoaded: {
        try {
          var o = JSON.parse(text())
          if (o && o.bar && o.bar.transparent !== undefined) {
            settingsWin.isTransparent = !!o.bar.transparent
          }
        } catch(e) {}
      }
      onFileChanged: {
        reload()
        try {
          var o = JSON.parse(text())
          if (o && o.bar && o.bar.transparent !== undefined) {
            settingsWin.isTransparent = !!o.bar.transparent
          }
        } catch(e) {}
      }
    }

    function togglePin(pinId, enabled) {
      var next = Object.assign({}, settingsWin.winPins)
      next[pinId] = enabled
      settingsWin.winPins = next
      var cmd = "python3 -c \"import json, os; p = os.path.expanduser('~/.config/omarchy/plugins/omarchy-undercover/defaults.json'); os.makedirs(os.path.dirname(p), exist_ok=True); d = json.load(open(p)) if os.path.exists(p) else {}; d['win11_pins'] = d.get('win11_pins', {}); d['win11_pins']['" + pinId + "'] = " + (enabled ? "True" : "False") + "; json.dump(d, open(p, 'w'), indent=2)\""
      runCmd(cmd)
    }

    // Live Hardware Poller
    Process {
      id: hwPoller
      command: [
        "bash", "-c",
        "vol=$(wpctl get-volume @DEFAULT_AUDIO_SINK@ 2>/dev/null | awk '{print int($2*100)}' || echo '70'); " +
        "bri=$(brightnessctl -m 2>/dev/null | cut -d, -f4 | tr -d '%' || echo '80'); " +
        "wifi=$(nmcli radio wifi 2>/dev/null || echo 'enabled'); " +
        "ssid=$(nmcli -t -f active,ssid dev wifi 2>/dev/null | grep '^yes:' | cut -d: -f2 || echo 'Connected'); " +
        "bt=$(bluetoothctl show 2>/dev/null | grep -q 'Powered: yes' && echo '1' || echo '0'); " +
        "echo \"$vol|$bri|$wifi|$ssid|$bt\""
      ]
      stdout: SplitParser {
        onRead: function(line) {
          if (!line) return
          var parts = line.trim().split("|")
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
      interval: 3000
      running: true
      repeat: true
      triggeredOnStart: true
      onTriggered: {
        if (!hwPoller.running) hwPoller.running = true
      }
    }

    // Main Mica Acrylic Window Container
    Rectangle {
      id: windowBox
      anchors.fill: parent
      radius: 10
      color: settingsWin.windowBg
      border.color: settingsWin.cardBorder
      border.width: 1
      clip: true

      ColumnLayout {
        anchors.fill: parent
        spacing: 0

        // ==========================================
        // 1. TOP WINDOWS 11 TITLEBAR WITH DRAG
        // ==========================================
        Rectangle {
          id: titleBar
          Layout.fillWidth: true
          implicitHeight: 46
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
            anchors.leftMargin: 16
            anchors.rightMargin: 0
            spacing: 12
            z: 1

            // App Icon & Brand
            RowLayout {
              spacing: 8
              Image {
                Layout.preferredWidth: 16
                Layout.preferredHeight: 16
                width: 16; height: 16
                source: "file://" + settingsWin.pluginDir + "/assets/icons/win11/settings.svg"
                fillMode: Image.PreserveAspectFit
              }
              Text {
                text: "Settings"
                font.family: "Segoe UI, sans-serif"
                font.pixelSize: 12
                font.weight: Font.DemiBold
                color: settingsWin.textPrimary
              }
            }

            Item { Layout.fillWidth: true }

            // Windows 11 Caption Buttons
            RowLayout {
              spacing: 0
              Layout.fillHeight: true

              Rectangle {
                implicitWidth: 46
                Layout.fillHeight: true
                color: minMouse.containsMouse ? (settingsWin.isDark ? Qt.rgba(1, 1, 1, 0.10) : Qt.rgba(0, 0, 0, 0.08)) : "transparent"
                Text { anchors.centerIn: parent; text: "—"; font.pixelSize: 10; color: settingsWin.textPrimary }
                MouseArea {
                  id: minMouse
                  anchors.fill: parent
                  hoverEnabled: true
                  cursorShape: Qt.PointingHandCursor
                  onClicked: settingsWin.runCmd("hyprctl dispatch movetoworkspacesilent special:minimized 2>/dev/null || true")
                }
              }

              Rectangle {
                implicitWidth: 46
                Layout.fillHeight: true
                color: maxMouse.containsMouse ? (settingsWin.isDark ? Qt.rgba(1, 1, 1, 0.10) : Qt.rgba(0, 0, 0, 0.08)) : "transparent"
                Text { anchors.centerIn: parent; text: "🗖"; font.pixelSize: 11; color: settingsWin.textPrimary }
                MouseArea {
                  id: maxMouse
                  anchors.fill: parent
                  hoverEnabled: true
                  cursorShape: Qt.PointingHandCursor
                  onClicked: settingsWin.runCmd("hyprctl dispatch fullscreen 1")
                }
              }

              Rectangle {
                implicitWidth: 46
                Layout.fillHeight: true
                color: closeMouse.containsMouse ? "#c42b1c" : "transparent"
                Text {
                  anchors.centerIn: parent
                  text: "✕"
                  font.pixelSize: 10
                  font.weight: Font.DemiBold
                  color: closeMouse.containsMouse ? "#ffffff" : settingsWin.textPrimary
                }
                MouseArea {
                  id: closeMouse
                  anchors.fill: parent
                  hoverEnabled: true
                  cursorShape: Qt.PointingHandCursor
                  onClicked: Qt.quit()
                }
              }
            }
          }
        }

        // ==========================================
        // 2. MAIN SPLIT VIEW (Sidebar + Content)
        // ==========================================
        RowLayout {
          Layout.fillWidth: true
          Layout.fillHeight: true
          spacing: 0

          // ------------------------------------------
          // LEFT NAVIGATION SIDEBAR (Resizable)
          // ------------------------------------------
          Rectangle {
            id: sidebarBox
            Layout.preferredWidth: settingsWin.sidebarWidth
            Layout.minimumWidth: 230
            Layout.maximumWidth: 380
            Layout.fillHeight: true
            color: settingsWin.sidebarBg
            border.width: 0

            ColumnLayout {
              anchors.fill: parent
              anchors.margins: 14
              spacing: 12

              // User Profile Capsule
              RowLayout {
                Layout.fillWidth: true
                spacing: 12

                Rectangle {
                  width: 44
                  height: 44
                  radius: 22
                  color: settingsWin.accentColor
                  Text {
                    anchors.centerIn: parent
                    text: settingsWin.userName.charAt(0).toUpperCase()
                    font.family: "Segoe UI, sans-serif"
                    font.pixelSize: 18
                    font.bold: true
                    color: settingsWin.isDark ? "#000000" : "#ffffff"
                  }
                }

                ColumnLayout {
                  Layout.fillWidth: true
                  spacing: 1
                  Text {
                    text: settingsWin.userName
                    font.family: "Segoe UI, sans-serif"
                    font.pixelSize: 13
                    font.weight: Font.DemiBold
                    color: settingsWin.textPrimary
                    elide: Text.ElideRight
                    Layout.fillWidth: true
                  }
                  Text {
                    text: "Local Account • Administrator"
                    font.family: "Segoe UI, sans-serif"
                    font.pixelSize: 11
                    color: settingsWin.textSecondary
                    elide: Text.ElideRight
                    Layout.fillWidth: true
                  }
                }
              }

              // Search Box
              Rectangle {
                Layout.fillWidth: true
                implicitHeight: 34
                radius: 6
                color: searchInput.activeFocus
                       ? (settingsWin.isDark ? Qt.rgba(1, 1, 1, 0.12) : "#ffffff")
                       : (settingsWin.isDark ? Qt.rgba(1, 1, 1, 0.08) : "#ffffff")
                border.color: searchInput.activeFocus ? settingsWin.accentColor : (settingsWin.isDark ? Qt.rgba(1, 1, 1, 0.14) : Qt.rgba(0, 0, 0, 0.14))
                border.width: searchInput.activeFocus ? 2 : 1

                RowLayout {
                  anchors.fill: parent
                  anchors.leftMargin: 10
                  anchors.rightMargin: 10
                  spacing: 8

                  Image {
                    Layout.preferredWidth: 14
                    Layout.preferredHeight: 14
                    width: 14; height: 14
                    source: "file://" + settingsWin.pluginDir + "/assets/icons/win11-settings/search.svg"
                    fillMode: Image.PreserveAspectFit
                    opacity: 0.8
                  }

                  TextInput {
                    id: searchInput
                    Layout.fillWidth: true
                    font.family: "Segoe UI, sans-serif"
                    font.pixelSize: 12
                    color: settingsWin.textPrimary
                    clip: true
                    Text {
                      visible: !searchInput.text
                      text: "Find a setting"
                      font.family: "Segoe UI, sans-serif"
                      font.pixelSize: 12
                      color: settingsWin.textSecondary
                    }
                    onTextChanged: settingsWin.searchQuery = text.toLowerCase()
                  }
                }
              }

              // Navigation Categories with Fluent SVGs
              property var categories: [
                { id: 0, icon: "system.svg", name: "System" },
                { id: 1, icon: "devices.svg", name: "Bluetooth & devices" },
                { id: 2, icon: "network.svg", name: "Network & internet" },
                { id: 3, icon: "personalization.svg", name: "Personalization" },
                { id: 4, icon: "tools.svg", name: "PowerToys & Tools" },
                { id: 5, icon: "disguise.svg", name: "Undercover Disguise" },
                { id: 6, icon: "update.svg", name: "Windows Update & Health" }
              ]

              ListView {
                Layout.fillWidth: true
                Layout.fillHeight: true
                clip: true
                spacing: 3
                model: parent.categories

                delegate: Rectangle {
                  width: parent ? parent.width : 240
                  implicitHeight: 38
                  radius: 6

                  readonly property bool isSelected: settingsWin.currentCategory === modelData.id
                  visible: (!settingsWin.searchQuery) || (modelData.name.toLowerCase().indexOf(settingsWin.searchQuery) !== -1)
                  height: visible ? implicitHeight : 0

                  color: isSelected
                         ? (settingsWin.isDark ? Qt.rgba(1, 1, 1, 0.10) : Qt.rgba(0, 0, 0, 0.07))
                         : (catMouse.containsMouse
                            ? (settingsWin.isDark ? Qt.rgba(1, 1, 1, 0.05) : Qt.rgba(0, 0, 0, 0.04))
                            : "transparent")

                  RowLayout {
                    anchors.fill: parent
                    anchors.leftMargin: 12
                    anchors.rightMargin: 12
                    spacing: 12

                    Image {
                      Layout.preferredWidth: 18
                      Layout.preferredHeight: 18
                      width: 18; height: 18
                      source: "file://" + settingsWin.pluginDir + "/assets/icons/win11-settings/" + modelData.icon
                      fillMode: Image.PreserveAspectFit
                    }

                    Text {
                      text: modelData.name
                      font.family: "Segoe UI, sans-serif"
                      font.pixelSize: 12
                      font.weight: isSelected ? Font.DemiBold : Font.Normal
                      color: settingsWin.textPrimary
                      Layout.fillWidth: true
                      elide: Text.ElideRight
                    }

                    Image {
                      Layout.preferredWidth: 10
                      Layout.preferredHeight: 10
                      width: 10; height: 10
                      source: "file://" + settingsWin.pluginDir + "/assets/icons/win11-settings/chevron.svg"
                      fillMode: Image.PreserveAspectFit
                      opacity: 0.4
                    }
                  }

                  // Active Indicator Pill
                  Rectangle {
                    visible: isSelected
                    anchors.left: parent.left
                    anchors.verticalCenter: parent.verticalCenter
                    width: 3
                    height: 18
                    radius: 1.5
                    color: settingsWin.accentColor
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
          // RIGHT CONTENT SCROLLER (Dynamic Scaling)
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
              spacing: 16

              Item { implicitHeight: 4 }

              // Dynamic Category Header with Breadcrumb / Subpage support
              RowLayout {
                Layout.fillWidth: true
                spacing: 12

                Rectangle {
                  visible: settingsWin.currentCategory === 0 && settingsWin.systemSubPage !== ""
                  implicitWidth: 32
                  implicitHeight: 32
                  radius: 6
                  color: backSoundM.containsMouse ? (settingsWin.isDark ? Qt.rgba(1, 1, 1, 0.12) : Qt.rgba(0, 0, 0, 0.08)) : "transparent"
                  Text {
                    anchors.centerIn: parent
                    text: "←"
                    font.family: "Segoe UI, sans-serif"
                    font.pixelSize: 18
                    color: settingsWin.textPrimary
                  }
                  MouseArea {
                    id: backSoundM
                    anchors.fill: parent
                    hoverEnabled: true
                    cursorShape: Qt.PointingHandCursor
                    onClicked: settingsWin.systemSubPage = ""
                  }
                }

                ColumnLayout {
                  spacing: 2
                  Text {
                    visible: settingsWin.currentCategory === 0 && settingsWin.systemSubPage !== ""
                    text: "System > " + (settingsWin.systemSubPage === "sound" ? "Sound" : (settingsWin.systemSubPage === "display" ? "Display" : "Power & battery"))
                    font.family: "Segoe UI, sans-serif"
                    font.pixelSize: 11
                    color: settingsWin.textSecondary
                  }
                  Text {
                    text: {
                      if (settingsWin.currentCategory === 0) {
                        if (settingsWin.systemSubPage === "sound") return "Sound"
                        if (settingsWin.systemSubPage === "display") return "Display"
                        if (settingsWin.systemSubPage === "power") return "Power & battery"
                        return "System"
                      }
                      switch(settingsWin.currentCategory) {
                        case 1: return "Bluetooth & devices"
                        case 2: return "Network & internet"
                        case 3: return "Personalization"
                        case 4: return "PowerToys & Tools (Winux Utilities)"
                        case 5: return "Undercover Disguise Transformation"
                        case 6: return "Windows Update & System Health"
                        default: return "Settings"
                      }
                    }
                    font.family: "Segoe UI, sans-serif"
                    font.pixelSize: 24
                    font.weight: Font.Bold
                    color: settingsWin.textPrimary
                  }
                }
              }

              // ==========================================
              // TAB 0: SYSTEM
              // ==========================================
              ColumnLayout {
                visible: settingsWin.currentCategory === 0
                Layout.fillWidth: true
                spacing: 14

                // ==========================================
                // TAB 0 VIEW 1: SYSTEM OVERVIEW
                // ==========================================
                ColumnLayout {
                  visible: settingsWin.systemSubPage === ""
                  Layout.fillWidth: true
                  spacing: 14

                  // Hero Specs Banner Card
                  Rectangle {
                    Layout.fillWidth: true
                    implicitHeight: 78
                    radius: 8
                    color: settingsWin.cardBg
                    border.color: settingsWin.cardBorder
                    border.width: 1

                    RowLayout {
                      anchors.fill: parent
                      anchors.margins: 16
                      spacing: 16

                      Image {
                        Layout.preferredWidth: 44
                        Layout.preferredHeight: 44
                        width: 44; height: 44
                        source: "file://" + settingsWin.pluginDir + "/assets/icons/win11-settings/system.svg"
                        fillMode: Image.PreserveAspectFit
                      }

                      ColumnLayout {
                        Layout.fillWidth: true
                        spacing: 2
                        Text {
                          text: "Omarchy Workstation PC"
                          font.family: "Segoe UI, sans-serif"
                          font.pixelSize: 14
                          font.weight: Font.DemiBold
                          color: settingsWin.textPrimary
                        }
                        Text {
                          text: "Windows 11 Pro Disguise • Arch Linux Kernel • Wayland Compositor"
                          font.family: "Segoe UI, sans-serif"
                          font.pixelSize: 11
                          color: settingsWin.textSecondary
                        }
                      }

                      Rectangle {
                        implicitWidth: 88
                        implicitHeight: 28
                        radius: 4
                        color: renameM.containsMouse
                               ? (settingsWin.isDark ? Qt.rgba(1, 1, 1, 0.14) : Qt.rgba(0, 0, 0, 0.06))
                               : (settingsWin.isDark ? Qt.rgba(1, 1, 1, 0.08) : "#fbfbfb")
                        border.color: settingsWin.isDark ? Qt.rgba(1, 1, 1, 0.15) : Qt.rgba(0, 0, 0, 0.14)
                        border.width: 1
                        Text {
                          anchors.centerIn: parent
                          text: "Rename"
                          font.family: "Segoe UI, sans-serif"
                          font.pixelSize: 11
                          font.weight: Font.DemiBold
                          color: settingsWin.textPrimary
                        }
                        MouseArea {
                          id: renameM
                          anchors.fill: parent
                          hoverEnabled: true
                          cursorShape: Qt.PointingHandCursor
                          onClicked: settingsWin.runCmd("omarchy-rename-pc 2>/dev/null || true")
                        }
                      }
                    }
                  }

                  // Display Brightness
                  Rectangle {
                    Layout.fillWidth: true
                    implicitHeight: 74
                    radius: 8
                    color: settingsWin.cardBg
                    border.color: settingsWin.cardBorder
                    border.width: 1

                    RowLayout {
                      anchors.fill: parent
                      anchors.margins: 16
                      spacing: 14

                      Image {
                        Layout.preferredWidth: 22
                        Layout.preferredHeight: 22
                        width: 22; height: 22
                        source: "file://" + settingsWin.pluginDir + "/assets/icons/win11-settings/sun.svg"
                        fillMode: Image.PreserveAspectFit
                      }
                      ColumnLayout {
                        Layout.fillWidth: true
                        Text { text: "Display Brightness"; font.family: "Segoe UI, sans-serif"; font.pixelSize: 13; font.weight: Font.DemiBold; color: settingsWin.textPrimary }
                        Text { text: settingsWin.brightnessLevel + "% backlight brightness"; font.family: "Segoe UI, sans-serif"; font.pixelSize: 11; color: settingsWin.textSecondary }
                      }
                      Slider {
                        Layout.preferredWidth: 180
                        from: 5; to: 100
                        value: settingsWin.brightnessLevel
                        onMoved: {
                          settingsWin.brightnessLevel = Math.round(value)
                          settingsWin.runCmd("brightnessctl set " + Math.round(value) + "% >/dev/null 2>&1")
                        }
                      }
                    }
                  }

                  // Sound Subpage Tile (Click to open full System > Sound)
                  Rectangle {
                    Layout.fillWidth: true
                    implicitHeight: 74
                    radius: 8
                    color: soundTileM.containsMouse ? (settingsWin.isDark ? Qt.rgba(1, 1, 1, 0.12) : Qt.rgba(0, 0, 0, 0.04)) : settingsWin.cardBg
                    border.color: settingsWin.cardBorder
                    border.width: 1

                    RowLayout {
                      anchors.fill: parent
                      anchors.margins: 16
                      spacing: 14

                      Image {
                        Layout.preferredWidth: 22
                        Layout.preferredHeight: 22
                        width: 22; height: 22
                        source: "file://" + settingsWin.pluginDir + "/assets/icons/win11-settings/volume.svg"
                        fillMode: Image.PreserveAspectFit
                      }
                      ColumnLayout {
                        Layout.fillWidth: true
                        Text { text: "Sound"; font.family: "Segoe UI, sans-serif"; font.pixelSize: 13; font.weight: Font.DemiBold; color: settingsWin.textPrimary }
                        Text { text: "Volume levels, output, input, sound devices, and volume mixer"; font.family: "Segoe UI, sans-serif"; font.pixelSize: 11; color: settingsWin.textSecondary }
                      }
                      Text {
                        text: audioService.masterVolume + "%"
                        font.family: "Segoe UI, sans-serif"
                        font.pixelSize: 12
                        font.weight: Font.DemiBold
                        color: settingsWin.accentColor
                      }
                      Text { text: "❯"; font.pixelSize: 14; color: settingsWin.textSecondary }
                    }

                    MouseArea {
                      id: soundTileM
                      anchors.fill: parent
                      hoverEnabled: true
                      cursorShape: Qt.PointingHandCursor
                      onClicked: settingsWin.systemSubPage = "sound"
                    }
                  }

                  // Display Subpage Tile
                  Rectangle {
                    Layout.fillWidth: true
                    implicitHeight: 74
                    radius: 8
                    color: dispTileM.containsMouse ? (settingsWin.isDark ? Qt.rgba(1, 1, 1, 0.12) : Qt.rgba(0, 0, 0, 0.04)) : settingsWin.cardBg
                    border.color: settingsWin.cardBorder
                    border.width: 1

                    RowLayout {
                      anchors.fill: parent
                      anchors.margins: 16
                      spacing: 14

                      Image {
                        Layout.preferredWidth: 22
                        Layout.preferredHeight: 22
                        source: "file://" + settingsWin.pluginDir + "/assets/icons/win11-settings/display.svg"
                        fillMode: Image.PreserveAspectFit
                      }
                      ColumnLayout {
                        Layout.fillWidth: true
                        Text { text: "Display"; font.family: "Segoe UI, sans-serif"; font.pixelSize: 13; font.weight: Font.DemiBold; color: settingsWin.textPrimary }
                        Text {
                          text: {
                            if (settingsService.monitors.length > 0) {
                              var m = settingsService.monitors[0]
                              return (m.description || m.name) + " • " + (m.resolution || "1920x1080") + " • Scale " + Math.round((m.scale || 1.0) * 100) + "%"
                            }
                            return "Monitors, scale, resolution, refresh rate, and night light"
                          }
                          font.family: "Segoe UI, sans-serif"
                          font.pixelSize: 11
                          color: settingsWin.textSecondary
                          elide: Text.ElideRight
                        }
                      }
                      Text { text: "❯"; font.pixelSize: 14; color: settingsWin.textSecondary }
                    }

                    MouseArea {
                      id: dispTileM
                      anchors.fill: parent
                      hoverEnabled: true
                      cursorShape: Qt.PointingHandCursor
                      onClicked: settingsWin.systemSubPage = "display"
                    }
                  }

                  // Power & Battery Subpage Tile
                  Rectangle {
                    Layout.fillWidth: true
                    implicitHeight: 74
                    radius: 8
                    color: pwrTileM.containsMouse ? (settingsWin.isDark ? Qt.rgba(1, 1, 1, 0.12) : Qt.rgba(0, 0, 0, 0.04)) : settingsWin.cardBg
                    border.color: settingsWin.cardBorder
                    border.width: 1

                    RowLayout {
                      anchors.fill: parent
                      anchors.margins: 16
                      spacing: 14

                      Image {
                        Layout.preferredWidth: 22
                        Layout.preferredHeight: 22
                        source: "file://" + settingsWin.pluginDir + "/assets/icons/win11-settings/battery.svg"
                        fillMode: Image.PreserveAspectFit
                      }
                      ColumnLayout {
                        Layout.fillWidth: true
                        Text { text: "Power & battery"; font.family: "Segoe UI, sans-serif"; font.pixelSize: 13; font.weight: Font.DemiBold; color: settingsWin.textPrimary }
                        Text {
                          text: (settingsService.batteryPct !== undefined ? (settingsService.batteryPct + "% • ") : "") + (settingsService.isCharging ? "Plugged in" : "On battery") + " • Mode: " + settingsService.powerProfile
                          font.family: "Segoe UI, sans-serif"
                          font.pixelSize: 11
                          color: settingsWin.textSecondary
                        }
                      }
                      Text { text: "❯"; font.pixelSize: 14; color: settingsWin.textSecondary }
                    }

                    MouseArea {
                      id: pwrTileM
                      anchors.fill: parent
                      hoverEnabled: true
                      cursorShape: Qt.PointingHandCursor
                      onClicked: settingsWin.systemSubPage = "power"
                    }
                  }

                  // Window Gaps Tuning
                  Rectangle {
                    Layout.fillWidth: true
                    implicitHeight: 74
                    radius: 8
                    color: settingsWin.cardBg
                    border.color: settingsWin.cardBorder
                    border.width: 1

                    RowLayout {
                      anchors.fill: parent
                      anchors.margins: 16
                      spacing: 14

                      Image {
                        Layout.preferredWidth: 22
                        Layout.preferredHeight: 22
                        width: 22; height: 22
                        source: "file://" + settingsWin.pluginDir + "/assets/icons/win11-settings/gaps.svg"
                        fillMode: Image.PreserveAspectFit
                      }
                      ColumnLayout {
                        Layout.fillWidth: true
                        Text { text: "Desktop Window Gaps"; font.family: "Segoe UI, sans-serif"; font.pixelSize: 13; font.weight: Font.DemiBold; color: settingsWin.textPrimary }
                        Text { text: settingsWin.windowGaps + "px outer spacing"; font.family: "Segoe UI, sans-serif"; font.pixelSize: 11; color: settingsWin.textSecondary }
                      }
                      Slider {
                        Layout.preferredWidth: 180
                        from: 0; to: 24
                        value: settingsWin.windowGaps
                        onMoved: {
                          settingsWin.windowGaps = Math.round(value)
                          settingsWin.saveSetting("WINDOW_GAPS", Math.round(value))
                          settingsWin.runCmd("hyprctl keyword general:gaps_out " + Math.round(value) + " >/dev/null 2>&1; hyprctl keyword general:gaps_in " + Math.round(value / 2) + " >/dev/null 2>&1")
                        }
                      }
                    }
                  }

                  // Window Rounding
                  Rectangle {
                    Layout.fillWidth: true
                    implicitHeight: 74
                    radius: 8
                    color: settingsWin.cardBg
                    border.color: settingsWin.cardBorder
                    border.width: 1

                    RowLayout {
                      anchors.fill: parent
                      anchors.margins: 16
                      spacing: 14

                      Image {
                        Layout.preferredWidth: 22
                        Layout.preferredHeight: 22
                        width: 22; height: 22
                        source: "file://" + settingsWin.pluginDir + "/assets/icons/win11-settings/rounding.svg"
                        fillMode: Image.PreserveAspectFit
                      }
                      ColumnLayout {
                        Layout.fillWidth: true
                        Text { text: "Corner Rounding (Mica Geometry)"; font.family: "Segoe UI, sans-serif"; font.pixelSize: 13; font.weight: Font.DemiBold; color: settingsWin.textPrimary }
                        Text { text: settingsWin.windowRounding + "px corner radius"; font.family: "Segoe UI, sans-serif"; font.pixelSize: 11; color: settingsWin.textSecondary }
                      }
                      Slider {
                        Layout.preferredWidth: 180
                        from: 0; to: 20
                        value: settingsWin.windowRounding
                        onMoved: {
                          settingsWin.windowRounding = Math.round(value)
                          settingsWin.saveSetting("WINDOW_ROUNDING", Math.round(value))
                          settingsWin.runCmd("hyprctl keyword decoration:rounding " + Math.round(value) + " >/dev/null 2>&1")
                        }
                      }
                    }
                  }
                }

                // ==========================================
                // TAB 0 VIEW 2: FULL SYSTEM > SOUND SUBPAGE
                // ==========================================
                ColumnLayout {
                  visible: settingsWin.systemSubPage === "sound"
                  Layout.fillWidth: true
                  spacing: 16

                  // 1. OUTPUT GROUP CARD
                  Rectangle {
                    Layout.fillWidth: true
                    implicitHeight: outCol.implicitHeight + 32
                    radius: 8
                    color: settingsWin.cardBg
                    border.color: settingsWin.cardBorder
                    border.width: 1

                    ColumnLayout {
                      id: outCol
                      anchors.fill: parent
                      anchors.margins: 16
                      spacing: 12

                      RowLayout {
                        Layout.fillWidth: true
                        spacing: 10
                        Text { text: "🔊"; font.pixelSize: 16 }
                        ColumnLayout {
                          Layout.fillWidth: true
                          Text { text: "Output"; font.family: "Segoe UI, sans-serif"; font.pixelSize: 13; font.weight: Font.DemiBold; color: settingsWin.textPrimary }
                          Text { text: "Choose where to play sound. Apps might have their own settings."; font.family: "Segoe UI, sans-serif"; font.pixelSize: 11; color: settingsWin.textSecondary }
                        }
                      }

                      Repeater {
                        model: audioService.sinks
                        delegate: Rectangle {
                          Layout.fillWidth: true
                          implicitHeight: 40
                          radius: 6
                          color: modelData.isDefault
                                 ? (settingsWin.isDark ? Qt.rgba(0, 120, 212, 0.22) : Qt.rgba(0, 120, 212, 0.12))
                                 : (devMouse.containsMouse ? (settingsWin.isDark ? Qt.rgba(1, 1, 1, 0.08) : Qt.rgba(0, 0, 0, 0.04)) : "transparent")
                          border.color: modelData.isDefault ? settingsWin.accentColor : "transparent"
                          border.width: 1

                          RowLayout {
                            anchors.fill: parent
                            anchors.leftMargin: 12
                            anchors.rightMargin: 12
                            spacing: 10

                            Rectangle {
                              implicitWidth: 16; implicitHeight: 16; radius: 8
                              color: "transparent"
                              border.color: modelData.isDefault ? settingsWin.accentColor : (settingsWin.isDark ? Qt.rgba(1, 1, 1, 0.4) : Qt.rgba(0, 0, 0, 0.3))
                              border.width: 2
                              Rectangle {
                                visible: modelData.isDefault
                                anchors.centerIn: parent
                                width: 8; height: 8; radius: 4
                                color: settingsWin.accentColor
                              }
                            }

                            Text { text: modelData.type; font.pixelSize: 15 }
                            Text {
                              text: modelData.description || modelData.name
                              font.family: "Segoe UI, sans-serif"
                              font.pixelSize: 12
                              font.weight: modelData.isDefault ? Font.DemiBold : Font.Normal
                              color: settingsWin.textPrimary
                              Layout.fillWidth: true
                              elide: Text.ElideRight
                            }
                            Text {
                              visible: modelData.isDefault
                              text: "Default"
                              font.family: "Segoe UI, sans-serif"
                              font.pixelSize: 10
                              color: settingsWin.accentColor
                            }
                          }

                          MouseArea {
                            id: devMouse
                            anchors.fill: parent
                            hoverEnabled: true
                            cursorShape: Qt.PointingHandCursor
                            onClicked: audioService.setDefaultSink(modelData.name)
                          }
                        }
                      }

                      Rectangle { Layout.fillWidth: true; height: 1; color: settingsWin.separatorColor }

                      RowLayout {
                        Layout.fillWidth: true
                        spacing: 14
                        Text { text: "Volume"; font.family: "Segoe UI, sans-serif"; font.pixelSize: 12; font.weight: Font.DemiBold; color: settingsWin.textPrimary }
                        Slider {
                          Layout.fillWidth: true
                          from: 0; to: 100
                          value: audioService.masterVolume
                          onMoved: audioService.setMasterVolume(value)
                        }
                        Text {
                          text: audioService.masterVolume + "%"
                          font.family: "Segoe UI, sans-serif"
                          font.pixelSize: 12
                          color: settingsWin.accentColor
                        }
                      }

                      RowLayout {
                        Layout.fillWidth: true
                        spacing: 14
                        Text { text: "Left / Right channel balance"; font.family: "Segoe UI, sans-serif"; font.pixelSize: 12; color: settingsWin.textPrimary; Layout.preferredWidth: 160 }
                        Text { text: "L"; font.family: "Segoe UI, sans-serif"; font.pixelSize: 11; color: settingsWin.textSecondary }
                        Slider {
                          Layout.fillWidth: true
                          from: 0.0; to: 1.0
                          value: settingsWin.stereoBalance
                          onMoved: {
                            settingsWin.stereoBalance = value
                            var left = Math.round(audioService.masterVolume * (1.0 - Math.max(0, (value - 0.5) * 2)))
                            var right = Math.round(audioService.masterVolume * (1.0 - Math.max(0, (0.5 - value) * 2)))
                            audioService.runCmd("pactl set-sink-volume @DEFAULT_AUDIO_SINK@ " + left + "% " + right + "% >/dev/null 2>&1")
                          }
                        }
                        Text { text: "R"; font.family: "Segoe UI, sans-serif"; font.pixelSize: 11; color: settingsWin.textSecondary }
                      }

                      RowLayout {
                        Layout.fillWidth: true
                        Text {
                          text: "Test channel identification"
                          font.family: "Segoe UI, sans-serif"
                          font.pixelSize: 12
                          color: settingsWin.textPrimary
                          Layout.fillWidth: true
                        }
                        Rectangle {
                          implicitWidth: 110; implicitHeight: 28; radius: 4
                          color: testBtnM.containsMouse ? (settingsWin.isDark ? Qt.rgba(1, 1, 1, 0.14) : Qt.rgba(0, 0, 0, 0.06)) : (settingsWin.isDark ? Qt.rgba(1, 1, 1, 0.08) : "#fbfbfb")
                          border.color: settingsWin.isDark ? Qt.rgba(1, 1, 1, 0.15) : Qt.rgba(0, 0, 0, 0.14)
                          border.width: 1
                          RowLayout {
                            anchors.centerIn: parent
                            spacing: 6
                            Text { text: "▶"; font.pixelSize: 10; color: settingsWin.textPrimary }
                            Text { text: "Test Speaker"; font.family: "Segoe UI, sans-serif"; font.pixelSize: 11; font.weight: Font.DemiBold; color: settingsWin.textPrimary }
                          }
                          MouseArea {
                            id: testBtnM
                            anchors.fill: parent
                            hoverEnabled: true
                            cursorShape: Qt.PointingHandCursor
                            onClicked: audioService.runSpeakerTest()
                          }
                        }
                      }
                    }
                  }

                  // 2. INPUT GROUP CARD
                  Rectangle {
                    Layout.fillWidth: true
                    implicitHeight: inCol.implicitHeight + 32
                    radius: 8
                    color: settingsWin.cardBg
                    border.color: settingsWin.cardBorder
                    border.width: 1

                    ColumnLayout {
                      id: inCol
                      anchors.fill: parent
                      anchors.margins: 16
                      spacing: 12

                      RowLayout {
                        Layout.fillWidth: true
                        spacing: 10
                        Text { text: "🎙️"; font.pixelSize: 16 }
                        ColumnLayout {
                          Layout.fillWidth: true
                          Text { text: "Input"; font.family: "Segoe UI, sans-serif"; font.pixelSize: 13; font.weight: Font.DemiBold; color: settingsWin.textPrimary }
                          Text { text: "Choose a device for speaking or recording"; font.family: "Segoe UI, sans-serif"; font.pixelSize: 11; color: settingsWin.textSecondary }
                        }
                      }

                      Repeater {
                        model: audioService.sources
                        delegate: Rectangle {
                          Layout.fillWidth: true
                          implicitHeight: 40
                          radius: 6
                          color: modelData.isDefault
                                 ? (settingsWin.isDark ? Qt.rgba(0, 120, 212, 0.22) : Qt.rgba(0, 120, 212, 0.12))
                                 : (srcMouse.containsMouse ? (settingsWin.isDark ? Qt.rgba(1, 1, 1, 0.08) : Qt.rgba(0, 0, 0, 0.04)) : "transparent")
                          border.color: modelData.isDefault ? settingsWin.accentColor : "transparent"
                          border.width: 1

                          RowLayout {
                            anchors.fill: parent
                            anchors.leftMargin: 12
                            anchors.rightMargin: 12
                            spacing: 10

                            Rectangle {
                              implicitWidth: 16; implicitHeight: 16; radius: 8
                              color: "transparent"
                              border.color: modelData.isDefault ? settingsWin.accentColor : (settingsWin.isDark ? Qt.rgba(1, 1, 1, 0.4) : Qt.rgba(0, 0, 0, 0.3))
                              border.width: 2
                              Rectangle {
                                visible: modelData.isDefault
                                anchors.centerIn: parent
                                width: 8; height: 8; radius: 4
                                color: settingsWin.accentColor
                              }
                            }

                            Text { text: modelData.type; font.pixelSize: 15 }
                            Text {
                              text: modelData.description || modelData.name
                              font.family: "Segoe UI, sans-serif"
                              font.pixelSize: 12
                              font.weight: modelData.isDefault ? Font.DemiBold : Font.Normal
                              color: settingsWin.textPrimary
                              Layout.fillWidth: true
                              elide: Text.ElideRight
                            }
                            Text {
                              visible: modelData.isDefault
                              text: "Default"
                              font.family: "Segoe UI, sans-serif"
                              font.pixelSize: 10
                              color: settingsWin.accentColor
                            }
                          }

                          MouseArea {
                            id: srcMouse
                            anchors.fill: parent
                            hoverEnabled: true
                            cursorShape: Qt.PointingHandCursor
                            onClicked: audioService.setDefaultSource(modelData.name)
                          }
                        }
                      }

                      Rectangle { Layout.fillWidth: true; height: 1; color: settingsWin.separatorColor }

                      RowLayout {
                        Layout.fillWidth: true
                        spacing: 14
                        Text { text: "Input volume"; font.family: "Segoe UI, sans-serif"; font.pixelSize: 12; font.weight: Font.DemiBold; color: settingsWin.textPrimary }
                        Slider {
                          Layout.fillWidth: true
                          from: 0; to: 100
                          value: audioService.micVolume
                          onMoved: audioService.setMicVolume(value)
                        }
                        Text {
                          text: audioService.micVolume + "%"
                          font.family: "Segoe UI, sans-serif"
                          font.pixelSize: 12
                          color: settingsWin.accentColor
                        }
                      }

                      RowLayout {
                        Layout.fillWidth: true
                        spacing: 14
                        Text {
                          text: "Test your microphone"
                          font.family: "Segoe UI, sans-serif"
                          font.pixelSize: 12
                          color: settingsWin.textPrimary
                          Layout.preferredWidth: 160
                        }
                        Rectangle {
                          Layout.fillWidth: true
                          implicitHeight: 8
                          radius: 4
                          color: settingsWin.isDark ? Qt.rgba(1, 1, 1, 0.12) : Qt.rgba(0, 0, 0, 0.10)
                          Rectangle {
                            width: parent.width * (audioService.micMuted ? 0 : (audioService.micVolume / 100.0))
                            height: parent.height
                            radius: 4
                            color: settingsWin.accentColor
                          }
                        }
                        Rectangle {
                          implicitWidth: 100; implicitHeight: 28; radius: 4
                          color: testMicM.containsMouse ? (settingsWin.isDark ? Qt.rgba(1, 1, 1, 0.14) : Qt.rgba(0, 0, 0, 0.06)) : (settingsWin.isDark ? Qt.rgba(1, 1, 1, 0.08) : "#fbfbfb")
                          border.color: settingsWin.isDark ? Qt.rgba(1, 1, 1, 0.15) : Qt.rgba(0, 0, 0, 0.14)
                          border.width: 1
                          Text {
                            anchors.centerIn: parent
                            text: "Start test"
                            font.family: "Segoe UI, sans-serif"
                            font.pixelSize: 11
                            font.weight: Font.DemiBold
                            color: settingsWin.textPrimary
                          }
                          MouseArea {
                            id: testMicM
                            anchors.fill: parent
                            hoverEnabled: true
                            cursorShape: Qt.PointingHandCursor
                            onClicked: {
                              audioService.runCmd("timeout 4s parecord /tmp/omarchy-mic-test.wav && paplay /tmp/omarchy-mic-test.wav &")
                            }
                          }
                        }
                      }
                    }
                  }

                  // 3. ADVANCED VOLUME MIXER
                  Rectangle {
                    Layout.fillWidth: true
                    implicitHeight: mixCol.implicitHeight + 32
                    radius: 8
                    color: settingsWin.cardBg
                    border.color: settingsWin.cardBorder
                    border.width: 1

                    ColumnLayout {
                      id: mixCol
                      anchors.fill: parent
                      anchors.margins: 16
                      spacing: 12

                      RowLayout {
                        Layout.fillWidth: true
                        spacing: 10
                        Text { text: "🎚️"; font.pixelSize: 16 }
                        ColumnLayout {
                          Layout.fillWidth: true
                          Text { text: "Volume mixer"; font.family: "Segoe UI, sans-serif"; font.pixelSize: 13; font.weight: Font.DemiBold; color: settingsWin.textPrimary }
                          Text { text: "Apps volume and per-application output destinations"; font.family: "Segoe UI, sans-serif"; font.pixelSize: 11; color: settingsWin.textSecondary }
                        }
                      }

                      Text {
                        visible: audioService.streams.length === 0
                        text: "No applications are currently playing audio."
                        font.family: "Segoe UI, sans-serif"
                        font.pixelSize: 11
                        color: settingsWin.textSecondary
                      }

                      Repeater {
                        model: audioService.streams
                        delegate: Rectangle {
                          Layout.fillWidth: true
                          implicitHeight: 50
                          radius: 6
                          color: settingsWin.isDark ? Qt.rgba(1, 1, 1, 0.05) : Qt.rgba(0, 0, 0, 0.03)

                          RowLayout {
                            anchors.fill: parent
                            anchors.leftMargin: 12
                            anchors.rightMargin: 12
                            spacing: 12

                            Text { text: "🎵"; font.pixelSize: 14 }
                            Text {
                              text: modelData.name
                              font.family: "Segoe UI, sans-serif"
                              font.pixelSize: 12
                              font.weight: Font.DemiBold
                              color: settingsWin.textPrimary
                              Layout.preferredWidth: 160
                              elide: Text.ElideRight
                            }

                            Slider {
                              Layout.fillWidth: true
                              from: 0; to: 100
                              value: modelData.volume
                              onMoved: audioService.setStreamVolume(modelData.index, value)
                            }

                            Text {
                              text: modelData.volume + "%"
                              font.family: "Segoe UI, sans-serif"
                              font.pixelSize: 11
                              color: settingsWin.accentColor
                              Layout.preferredWidth: 40
                            }

                            Rectangle {
                              implicitWidth: 26; implicitHeight: 26; radius: 4
                              color: appMuteM.containsMouse ? (settingsWin.isDark ? Qt.rgba(1, 1, 1, 0.12) : Qt.rgba(0, 0, 0, 0.08)) : "transparent"
                              Text {
                                anchors.centerIn: parent
                                text: modelData.muted ? "󰝟" : "󰕾"
                                font.pixelSize: 13
                                color: modelData.muted ? "#ff5f56" : (settingsWin.isDark ? "#ffffff" : "#1a1a1a")
                              }
                              MouseArea {
                                id: appMuteM
                                anchors.fill: parent
                                hoverEnabled: true
                                cursorShape: Qt.PointingHandCursor
                                onClicked: audioService.toggleStreamMute(modelData.index)
                              }
                            }
                          }
                        }
                      }
                    }
                  }

                  // 4. TROUBLESHOOT & RECOVERY
                  Rectangle {
                    Layout.fillWidth: true
                    implicitHeight: 74
                    radius: 8
                    color: settingsWin.cardBg
                    border.color: settingsWin.cardBorder
                    border.width: 1

                    RowLayout {
                      anchors.fill: parent
                      anchors.margins: 16
                      spacing: 14

                      Text { text: "🛠️"; font.pixelSize: 20 }
                      ColumnLayout {
                        Layout.fillWidth: true
                        Text { text: "Restart Audio Services"; font.family: "Segoe UI, sans-serif"; font.pixelSize: 13; font.weight: Font.DemiBold; color: settingsWin.textPrimary }
                        Text { text: "Resets PipeWire and WirePlumber if audio streams stall or lock up"; font.family: "Segoe UI, sans-serif"; font.pixelSize: 11; color: settingsWin.textSecondary }
                      }
                      Rectangle {
                        implicitWidth: 120; implicitHeight: 28; radius: 4
                        color: recBtnM.containsMouse ? (settingsWin.isDark ? Qt.rgba(1, 1, 1, 0.14) : Qt.rgba(0, 0, 0, 0.06)) : (settingsWin.isDark ? Qt.rgba(1, 1, 1, 0.08) : "#fbfbfb")
                        border.color: settingsWin.isDark ? Qt.rgba(1, 1, 1, 0.15) : Qt.rgba(0, 0, 0, 0.14)
                        border.width: 1
                        Text {
                          anchors.centerIn: parent
                          text: "Restart Services"
                          font.family: "Segoe UI, sans-serif"
                          font.pixelSize: 11
                          font.weight: Font.DemiBold
                          color: settingsWin.textPrimary
                        }
                        MouseArea {
                          id: recBtnM
                          anchors.fill: parent
                          hoverEnabled: true
                          cursorShape: Qt.PointingHandCursor
                          onClicked: audioService.runRecovery()
                        }
                      }
                    }
                  }
                }

                // ==========================================
                // TAB 0 VIEW 3: FULL SYSTEM > DISPLAY SUBPAGE
                // ==========================================
                ColumnLayout {
                  visible: settingsWin.systemSubPage === "display"
                  Layout.fillWidth: true
                  spacing: 16

                  // 1. MONITOR ARRANGEMENT DIAGRAM
                  Rectangle {
                    Layout.fillWidth: true
                    implicitHeight: 140
                    radius: 8
                    color: settingsWin.cardBg
                    border.color: settingsWin.cardBorder
                    border.width: 1

                    ColumnLayout {
                      anchors.fill: parent
                      anchors.margins: 16
                      spacing: 12

                      RowLayout {
                        Layout.fillWidth: true
                        Text {
                          text: "Select a display below to change its settings"
                          font.family: "Segoe UI, sans-serif"
                          font.pixelSize: 12
                          color: settingsWin.textSecondary
                          Layout.fillWidth: true
                        }
                        Text {
                          text: settingsService.monitors.length + (settingsService.monitors.length === 1 ? " display connected" : " displays connected")
                          font.family: "Segoe UI, sans-serif"
                          font.pixelSize: 11
                          color: settingsWin.accentColor
                        }
                      }

                      // Visual Monitor Diagram Box
                      RowLayout {
                        Layout.alignment: Qt.AlignHCenter
                        spacing: 14

                        Repeater {
                          model: settingsService.monitors.length > 0 ? settingsService.monitors : [{ description: "Primary Display", resolution: "1920x1080", scale: 1.0 }]
                          delegate: Rectangle {
                            implicitWidth: 130
                            implicitHeight: 74
                            radius: 6
                            color: settingsWin.isDark ? Qt.rgba(0.18, 0.22, 0.28, 0.9) : Qt.rgba(0.85, 0.90, 0.96, 0.9)
                            border.color: settingsWin.accentColor
                            border.width: 2

                            ColumnLayout {
                              anchors.centerIn: parent
                              spacing: 2
                              Text {
                                text: String(index + 1)
                                font.family: "Segoe UI, sans-serif"
                                font.pixelSize: 18
                                font.weight: Font.Bold
                                color: settingsWin.textPrimary
                                Layout.alignment: Qt.AlignHCenter
                              }
                              Text {
                                text: modelData.description || modelData.name || "Display"
                                font.family: "Segoe UI, sans-serif"
                                font.pixelSize: 10
                                color: settingsWin.textSecondary
                                elide: Text.ElideRight
                                Layout.maximumWidth: 110
                                Layout.alignment: Qt.AlignHCenter
                              }
                            }
                          }
                        }
                      }
                    }
                  }

                  // 2. SCALE & LAYOUT CARD
                  Rectangle {
                    Layout.fillWidth: true
                    implicitHeight: scaleCol.implicitHeight + 28
                    radius: 8
                    color: settingsWin.cardBg
                    border.color: settingsWin.cardBorder
                    border.width: 1

                    ColumnLayout {
                      id: scaleCol
                      anchors.fill: parent
                      anchors.margins: 16
                      spacing: 14

                      RowLayout {
                        Layout.fillWidth: true
                        ColumnLayout {
                          spacing: 2
                          Layout.fillWidth: true
                          Text { text: "Scale"; font.family: "Segoe UI, sans-serif"; font.pixelSize: 13; font.weight: Font.DemiBold; color: settingsWin.textPrimary }
                          Text { text: "Change the size of text, apps, and other items"; font.family: "Segoe UI, sans-serif"; font.pixelSize: 11; color: settingsWin.textSecondary }
                        }
                      }

                      // Scale Option Pills
                      RowLayout {
                        spacing: 8
                        property var scales: [
                          { label: "100%", val: 1.0 },
                          { label: "125%", val: 1.25 },
                          { label: "150%", val: 1.5 },
                          { label: "175%", val: 1.75 },
                          { label: "200%", val: 2.0 }
                        ]

                        Repeater {
                          model: parent.scales
                          delegate: Rectangle {
                            implicitWidth: 64
                            implicitHeight: 32
                            radius: 4
                            readonly property bool isSelected: {
                              if (settingsService.monitors.length > 0) {
                                return Math.abs((settingsService.monitors[0].scale || 1.0) - modelData.val) < 0.05
                              }
                              return modelData.val === 1.0
                            }
                            color: isSelected
                                   ? (settingsWin.isDark ? Qt.rgba(0.38, 0.80, 1.0, 0.20) : Qt.rgba(0, 0.40, 0.75, 0.15))
                                   : (scaleMouse.containsMouse ? (settingsWin.isDark ? Qt.rgba(1, 1, 1, 0.1) : Qt.rgba(0, 0, 0, 0.06)) : "transparent")
                            border.color: isSelected ? settingsWin.accentColor : settingsWin.cardBorder
                            border.width: 1

                            Text {
                              anchors.centerIn: parent
                              text: modelData.label
                              font.family: "Segoe UI, sans-serif"
                              font.pixelSize: 12
                              font.weight: isSelected ? Font.DemiBold : Font.Normal
                              color: isSelected ? settingsWin.accentColor : settingsWin.textPrimary
                            }

                            MouseArea {
                              id: scaleMouse
                              anchors.fill: parent
                              hoverEnabled: true
                              cursorShape: Qt.PointingHandCursor
                              onClicked: {
                                if (settingsService.monitors.length > 0) {
                                  var monDesc = settingsService.monitors[0].description || settingsService.monitors[0].name
                                  settingsService.setMonitorScale(monDesc, modelData.val)
                                }
                              }
                            }
                          }
                        }
                      }

                      Rectangle { Layout.fillWidth: true; height: 1; color: settingsWin.separatorColor }

                      // Display Resolution Row
                      RowLayout {
                        Layout.fillWidth: true
                        ColumnLayout {
                          spacing: 2
                          Layout.fillWidth: true
                          Text { text: "Display resolution"; font.family: "Segoe UI, sans-serif"; font.pixelSize: 13; font.weight: Font.DemiBold; color: settingsWin.textPrimary }
                          Text {
                            text: (settingsService.monitors.length > 0 ? (settingsService.monitors[0].resolution || "1920x1080") : "1920x1080") + " (Active resolution)"
                            font.family: "Segoe UI, sans-serif"
                            font.pixelSize: 11
                            color: settingsWin.textSecondary
                          }
                        }
                        Text {
                          text: settingsService.monitors.length > 0 ? (settingsService.monitors[0].resolution || "1920x1080") : "1920x1080"
                          font.family: "Segoe UI, sans-serif"
                          font.pixelSize: 12
                          font.weight: Font.DemiBold
                          color: settingsWin.accentColor
                        }
                      }
                    }
                  }

                  // 3. NIGHT LIGHT CARD
                  Rectangle {
                    Layout.fillWidth: true
                    implicitHeight: 74
                    radius: 8
                    color: settingsWin.cardBg
                    border.color: settingsWin.cardBorder
                    border.width: 1

                    RowLayout {
                      anchors.fill: parent
                      anchors.margins: 16
                      spacing: 14

                      Image {
                        Layout.preferredWidth: 22
                        Layout.preferredHeight: 22
                        source: "file://" + settingsWin.pluginDir + "/assets/icons/win11-settings/moon.svg"
                        fillMode: Image.PreserveAspectFit
                      }
                      ColumnLayout {
                        Layout.fillWidth: true
                        Text { text: "Night light"; font.family: "Segoe UI, sans-serif"; font.pixelSize: 13; font.weight: Font.DemiBold; color: settingsWin.textPrimary }
                        Text { text: "Use warmer colors to help reduce eye strain and sleep better"; font.family: "Segoe UI, sans-serif"; font.pixelSize: 11; color: settingsWin.textSecondary }
                      }

                      Rectangle {
                        implicitWidth: 44
                        implicitHeight: 22
                        radius: 11
                        color: nlSwitchMouse.containsMouse ? (nlSwitchActive ? (settingsWin.isDark ? "#48b7eb" : "#005a9e") : (settingsWin.isDark ? Qt.rgba(1, 1, 1, 0.25) : Qt.rgba(0, 0, 0, 0.2))) : (nlSwitchActive ? settingsWin.accentColor : (settingsWin.isDark ? Qt.rgba(1, 1, 1, 0.18) : Qt.rgba(0, 0, 0, 0.15)))

                        property bool nlSwitchActive: false

                        Rectangle {
                          x: parent.nlSwitchActive ? parent.width - width - 3 : 3
                          anchors.verticalCenter: parent.verticalCenter
                          implicitWidth: 16
                          implicitHeight: 16
                          radius: 8
                          color: "#ffffff"
                          Behavior on x { NumberAnimation { duration: 120 } }
                        }

                        MouseArea {
                          id: nlSwitchMouse
                          anchors.fill: parent
                          cursorShape: Qt.PointingHandCursor
                          onClicked: {
                            parent.nlSwitchActive = !parent.nlSwitchActive
                            settingsService.setHyprOption("nightlight", parent.nlSwitchActive ? "on" : "off")
                          }
                        }
                      }
                    }
                  }
                }

                // ==========================================
                // TAB 0 VIEW 4: FULL SYSTEM > POWER & BATTERY SUBPAGE
                // ==========================================
                ColumnLayout {
                  visible: settingsWin.systemSubPage === "power"
                  Layout.fillWidth: true
                  spacing: 16

                  // 1. BATTERY HERO STATUS CARD
                  Rectangle {
                    Layout.fillWidth: true
                    implicitHeight: 96
                    radius: 8
                    color: settingsWin.cardBg
                    border.color: settingsWin.cardBorder
                    border.width: 1

                    RowLayout {
                      anchors.fill: parent
                      anchors.margins: 18
                      spacing: 16

                      Text { text: settingsService.isCharging ? "⚡" : "🔋"; font.pixelSize: 32 }

                      ColumnLayout {
                        Layout.fillWidth: true
                        spacing: 3
                        Text {
                          text: settingsService.batteryPct + "%"
                          font.family: "Segoe UI, sans-serif"
                          font.pixelSize: 24
                          font.weight: Font.Bold
                          color: settingsWin.textPrimary
                        }
                        Text {
                          text: settingsService.isCharging ? "Plugged in, charging" : "Discharging on battery power"
                          font.family: "Segoe UI, sans-serif"
                          font.pixelSize: 11
                          color: settingsWin.textSecondary
                        }
                      }

                      // Battery Level Meter Bar
                      Rectangle {
                        implicitWidth: 140
                        implicitHeight: 12
                        radius: 6
                        color: settingsWin.isDark ? Qt.rgba(1, 1, 1, 0.12) : Qt.rgba(0, 0, 0, 0.08)

                        Rectangle {
                          width: Math.max(8, parent.width * (settingsService.batteryPct / 100.0))
                          height: parent.height
                          radius: 6
                          color: settingsService.batteryPct > 20 ? settingsWin.accentColor : "#ff453a"
                        }
                      }
                    }
                  }

                  // 2. POWER MODE CARD
                  Rectangle {
                    Layout.fillWidth: true
                    implicitHeight: pwrModeCol.implicitHeight + 28
                    radius: 8
                    color: settingsWin.cardBg
                    border.color: settingsWin.cardBorder
                    border.width: 1

                    ColumnLayout {
                      id: pwrModeCol
                      anchors.fill: parent
                      anchors.margins: 16
                      spacing: 14

                      Text {
                        text: "Power mode"
                        font.family: "Segoe UI, sans-serif"
                        font.pixelSize: 13
                        font.weight: Font.DemiBold
                        color: settingsWin.textPrimary
                      }
                      Text {
                        text: "Optimize your PC based on performance and battery usage"
                        font.family: "Segoe UI, sans-serif"
                        font.pixelSize: 11
                        color: settingsWin.textSecondary
                      }

                      ColumnLayout {
                        Layout.fillWidth: true
                        spacing: 6

                        property var modes: [
                          { id: "power-saver", label: "Best power efficiency", desc: "Reduces performance to extend battery life" },
                          { id: "balanced", label: "Balanced", desc: "Automatically balances energy and performance" },
                          { id: "performance", label: "Best performance", desc: "Maximizes system speed and responsiveness" }
                        ]

                        Repeater {
                          model: parent.modes
                          delegate: Rectangle {
                            Layout.fillWidth: true
                            implicitHeight: 44
                            radius: 6
                            readonly property bool isSelected: settingsService.powerProfile === modelData.id
                            color: isSelected
                                   ? (settingsWin.isDark ? Qt.rgba(0.38, 0.80, 1.0, 0.14) : Qt.rgba(0, 0.40, 0.75, 0.08))
                                   : (pwrRowMouse.containsMouse ? (settingsWin.isDark ? Qt.rgba(1, 1, 1, 0.06) : Qt.rgba(0, 0, 0, 0.03)) : "transparent")
                            border.color: isSelected ? settingsWin.accentColor : "transparent"
                            border.width: 1

                            RowLayout {
                              anchors.fill: parent
                              anchors.leftMargin: 12
                              anchors.rightMargin: 12
                              spacing: 12

                              Rectangle {
                                implicitWidth: 16
                                implicitHeight: 16
                                radius: 8
                                color: "transparent"
                                border.color: isSelected ? settingsWin.accentColor : (settingsWin.isDark ? Qt.rgba(1, 1, 1, 0.4) : Qt.rgba(0, 0, 0, 0.3))
                                border.width: 1.5

                                Rectangle {
                                  anchors.centerIn: parent
                                  implicitWidth: 8
                                  implicitHeight: 8
                                  radius: 4
                                  color: settingsWin.accentColor
                                  visible: isSelected
                                }
                              }

                              ColumnLayout {
                                Layout.fillWidth: true
                                spacing: 1
                                Text {
                                  text: modelData.label
                                  font.family: "Segoe UI, sans-serif"
                                  font.pixelSize: 12
                                  font.weight: isSelected ? Font.DemiBold : Font.Normal
                                  color: settingsWin.textPrimary
                                }
                                Text {
                                  text: modelData.desc
                                  font.family: "Segoe UI, sans-serif"
                                  font.pixelSize: 10
                                  color: settingsWin.textSecondary
                                }
                              }
                            }

                            MouseArea {
                              id: pwrRowMouse
                              anchors.fill: parent
                              hoverEnabled: true
                              cursorShape: Qt.PointingHandCursor
                              onClicked: settingsService.setPowerProfile(modelData.id)
                            }
                          }
                        }
                      }
                    }
                  }

                  // 3. SCREEN AND SLEEP TIMEOUTS
                  Rectangle {
                    Layout.fillWidth: true
                    implicitHeight: 74
                    radius: 8
                    color: settingsWin.cardBg
                    border.color: settingsWin.cardBorder
                    border.width: 1

                    RowLayout {
                      anchors.fill: parent
                      anchors.margins: 16
                      spacing: 14

                      Image {
                        Layout.preferredWidth: 22
                        Layout.preferredHeight: 22
                        source: "file://" + settingsWin.pluginDir + "/assets/icons/win11-settings/idle.svg"
                        fillMode: Image.PreserveAspectFit
                      }
                      ColumnLayout {
                        Layout.fillWidth: true
                        Text { text: "Screen and sleep"; font.family: "Segoe UI, sans-serif"; font.pixelSize: 13; font.weight: Font.DemiBold; color: settingsWin.textPrimary }
                        Text { text: "Turn off screen and lock workstation after inactivity"; font.family: "Segoe UI, sans-serif"; font.pixelSize: 11; color: settingsWin.textSecondary }
                      }
                      Rectangle {
                        implicitWidth: 90
                        implicitHeight: 28
                        radius: 4
                        color: settingsWin.isDark ? Qt.rgba(1, 1, 1, 0.08) : Qt.rgba(0, 0, 0, 0.05)
                        border.color: settingsWin.cardBorder
                        border.width: 1
                        Text {
                          anchors.centerIn: parent
                          text: "10 minutes"
                          font.family: "Segoe UI, sans-serif"
                          font.pixelSize: 11
                          color: settingsWin.textPrimary
                        }
                      }
                    }
                  }
                }
              }

              // ==========================================
              // TAB 1: BLUETOOTH & DEVICES
              // ==========================================
              ColumnLayout {
                visible: settingsWin.currentCategory === 1
                Layout.fillWidth: true
                spacing: 14

                Rectangle {
                  Layout.fillWidth: true
                  implicitHeight: 68
                  radius: 8
                  color: settingsWin.cardBg
                  border.color: settingsWin.cardBorder
                  border.width: 1
                  RowLayout {
                    anchors.fill: parent
                    anchors.margins: 16
                    spacing: 14
                    Image {
                      Layout.preferredWidth: 22
                      Layout.preferredHeight: 22
                      width: 22; height: 22
                      source: "file://" + settingsWin.pluginDir + "/assets/icons/win11-settings/devices.svg"
                      fillMode: Image.PreserveAspectFit
                    }
                    Text { text: "Bluetooth Radio Power"; font.family: "Segoe UI, sans-serif"; font.pixelSize: 13; font.weight: Font.DemiBold; color: settingsWin.textPrimary; Layout.fillWidth: true }
                    Switch {
                      checked: settingsWin.btEnabled
                      onToggled: {
                        settingsWin.btEnabled = checked
                        settingsWin.runCmd("bluetoothctl power " + (checked ? "on" : "off"))
                      }
                    }
                  }
                }

                Rectangle {
                  Layout.fillWidth: true
                  implicitHeight: 46
                  radius: 6
                  color: settingsWin.accentColor
                  Text {
                    anchors.centerIn: parent
                    text: "Open Advanced Bluetooth Manager"; font.family: "Segoe UI, sans-serif"; font.pixelSize: 12; font.weight: Font.DemiBold
                    color: settingsWin.isDark ? "#000000" : "#ffffff"
                  }
                  MouseArea {
                    anchors.fill: parent
                    cursorShape: Qt.PointingHandCursor
                    onClicked: settingsWin.runCmd("omarchy-win11-bluetooth || blueman-manager")
                  }
                }
              }

              // ==========================================
              // TAB 2: NETWORK & INTERNET
              // ==========================================
              ColumnLayout {
                visible: settingsWin.currentCategory === 2
                Layout.fillWidth: true
                spacing: 14

                Rectangle {
                  Layout.fillWidth: true
                  implicitHeight: 68
                  radius: 8
                  color: settingsWin.cardBg
                  border.color: settingsWin.cardBorder
                  border.width: 1
                  RowLayout {
                    anchors.fill: parent
                    anchors.margins: 16
                    spacing: 14
                    Image {
                      Layout.preferredWidth: 22
                      Layout.preferredHeight: 22
                      width: 22; height: 22
                      source: "file://" + settingsWin.pluginDir + "/assets/icons/win11-settings/network.svg"
                      fillMode: Image.PreserveAspectFit
                    }
                    ColumnLayout {
                      Layout.fillWidth: true
                      Text { text: "Wi-Fi Connection"; font.family: "Segoe UI, sans-serif"; font.pixelSize: 13; font.weight: Font.DemiBold; color: settingsWin.textPrimary }
                      Text { text: settingsWin.wifiEnabled ? settingsWin.wifiSsid : "Wi-Fi is turned off"; textFormat: Text.PlainText; font.family: "Segoe UI, sans-serif"; font.pixelSize: 11; color: settingsWin.textSecondary }
                    }
                    Switch {
                      checked: settingsWin.wifiEnabled
                      onToggled: {
                        settingsWin.wifiEnabled = checked
                        settingsWin.runCmd("nmcli radio wifi " + (checked ? "on" : "off"))
                      }
                    }
                  }
                }

                Rectangle {
                  Layout.fillWidth: true
                  implicitHeight: 46
                  radius: 6
                  color: settingsWin.accentColor
                  Text {
                    anchors.centerIn: parent
                    text: "Scan & Connect to Wi-Fi Networks"; font.family: "Segoe UI, sans-serif"; font.pixelSize: 12; font.weight: Font.DemiBold
                    color: settingsWin.isDark ? "#000000" : "#ffffff"
                  }
                  MouseArea {
                    anchors.fill: parent
                    cursorShape: Qt.PointingHandCursor
                    onClicked: settingsWin.runCmd("omarchy-win11-wifi || nm-connection-editor")
                  }
                }
              }

              // ==========================================
              // TAB 3: PERSONALIZATION
              // ==========================================
              ColumnLayout {
                visible: settingsWin.currentCategory === 3
                Layout.fillWidth: true
                spacing: 16

                // Select a theme to apply (Windows 11 Authentic Theme Gallery)
                Rectangle {
                  Layout.fillWidth: true
                  implicitHeight: themeCol.implicitHeight + 28
                  radius: 8
                  color: settingsWin.cardBg
                  border.color: settingsWin.cardBorder
                  border.width: 1

                  ColumnLayout {
                    id: themeCol
                    anchors.fill: parent
                    anchors.margins: 16
                    spacing: 12

                    RowLayout {
                      Layout.fillWidth: true
                      Text {
                        text: "Select a theme to apply"
                        font.family: "Segoe UI, sans-serif"
                        font.pixelSize: 13
                        font.weight: Font.DemiBold
                        color: settingsWin.textPrimary
                      }
                      Item { Layout.fillWidth: true }
                      Text {
                        text: "Desktop Camouflage & Presets"
                        font.family: "Segoe UI, sans-serif"
                        font.pixelSize: 11
                        color: settingsWin.textSecondary
                      }
                    }

                    GridLayout {
                      Layout.fillWidth: true
                      columns: 2
                      rowSpacing: 10
                      columnSpacing: 10

                      property var themes: [
                        { id: "win11-dark", name: "Windows 11 (Dark)", sub: "Mica Dark & Centered Taskbar", icon: "start.svg", isWin: true, cmd: "omarchy-undercover -w11" },
                        { id: "win11-light", name: "Windows 11 (Light)", sub: "Fluent Light & Solar Taskbar", icon: "sun.svg", isWin: false, cmd: "omarchy-undercover -w11-light" },
                        { id: "mac-dark", name: "macOS Sequoia (Dark)", sub: "Dark Menu Bar & Frosted Dock", icon: "apple-logo.svg", isWin: false, cmd: "omarchy-undercover -mac" },
                        { id: "mac-light", name: "macOS Sequoia (Light)", sub: "Light Glass Bar & Solar Dock", icon: "apple-logo.svg", isWin: false, cmd: "omarchy-undercover -mac-light" },
                        { id: "omarchy", name: "Omarchy Default", sub: "Linux Baseline Hyprland Bar", icon: "disguise.svg", isWin: false, cmd: "omarchy-undercover --disable" }
                      ]

                      Repeater {
                        model: parent.themes
                        Rectangle {
                          Layout.fillWidth: true
                          implicitHeight: 64
                          radius: 6
                          color: (settingsWin.currentDisguise === modelData.id)
                                 ? (settingsWin.isDark ? Qt.rgba(0.38, 0.80, 1.0, 0.12) : Qt.rgba(0, 0.40, 0.75, 0.08))
                                 : (themeMouse.containsMouse ? (settingsWin.isDark ? Qt.rgba(1, 1, 1, 0.08) : Qt.rgba(0, 0, 0, 0.04)) : (settingsWin.isDark ? Qt.rgba(1, 1, 1, 0.03) : Qt.rgba(0, 0, 0, 0.02)))
                          border.color: (settingsWin.currentDisguise === modelData.id) ? settingsWin.accentColor : settingsWin.cardBorder
                          border.width: (settingsWin.currentDisguise === modelData.id) ? 2 : 1

                          RowLayout {
                            anchors.fill: parent
                            anchors.margins: 10
                            spacing: 12

                            // Desktop Thumbnail Preview Box
                            Rectangle {
                              Layout.preferredWidth: 40
                              Layout.preferredHeight: 40
                              radius: 5
                              color: modelData.id.indexOf("light") !== -1 ? "#f3f3f5" : (modelData.id === "omarchy" ? "#18181b" : "#202020")
                              border.color: settingsWin.cardBorder
                              border.width: 1

                              Image {
                                anchors.centerIn: parent
                                width: 22; height: 22
                                source: "file://" + settingsWin.pluginDir + "/assets/icons/" + (modelData.isWin ? "win11/" : (modelData.icon === "apple-logo.svg" ? "" : "win11-settings/")) + modelData.icon
                                fillMode: Image.PreserveAspectFit
                              }
                            }

                            ColumnLayout {
                              Layout.fillWidth: true
                              spacing: 2
                              Text {
                                text: modelData.name
                                font.family: "Segoe UI, sans-serif"
                                font.pixelSize: 12
                                font.weight: (settingsWin.currentDisguise === modelData.id) ? Font.DemiBold : Font.Normal
                                color: settingsWin.textPrimary
                                elide: Text.ElideRight
                              }
                              Text {
                                text: (settingsWin.currentDisguise === modelData.id) ? "Active Theme • " + modelData.sub : modelData.sub
                                font.family: "Segoe UI, sans-serif"
                                font.pixelSize: 10
                                color: (settingsWin.currentDisguise === modelData.id) ? settingsWin.accentColor : settingsWin.textSecondary
                                elide: Text.ElideRight
                              }
                            }

                            Rectangle {
                              visible: settingsWin.currentDisguise === modelData.id
                              Layout.preferredWidth: 20
                              Layout.preferredHeight: 20
                              radius: 10
                              color: settingsWin.accentColor
                              Text {
                                anchors.centerIn: parent
                                text: "✓"
                                font.pixelSize: 11
                                font.bold: true
                                color: settingsWin.isDark ? "#000000" : "#ffffff"
                              }
                            }
                          }

                          MouseArea {
                            id: themeMouse
                            anchors.fill: parent
                            hoverEnabled: true
                            cursorShape: Qt.PointingHandCursor
                            onClicked: {
                              settingsWin.runCmd(modelData.cmd)
                            }
                          }
                        }
                      }
                    }
                  }
                }

                // Dark / Light Theme Switch
                Rectangle {
                  Layout.fillWidth: true
                  implicitHeight: 68
                  radius: 8
                  color: settingsWin.cardBg
                  border.color: settingsWin.cardBorder
                  border.width: 1
                  RowLayout {
                    anchors.fill: parent
                    anchors.margins: 16
                    spacing: 14
                    Image {
                      Layout.preferredWidth: 22
                      Layout.preferredHeight: 22
                      width: 22; height: 22
                      source: "file://" + settingsWin.pluginDir + "/assets/icons/win11-settings/personalization.svg"
                      fillMode: Image.PreserveAspectFit
                    }
                    ColumnLayout {
                      Layout.fillWidth: true
                      Text { text: "Color Mode"; font.family: "Segoe UI, sans-serif"; font.pixelSize: 13; font.weight: Font.DemiBold; color: settingsWin.textPrimary }
                      Text { text: settingsWin.isDark ? "Windows 11 Dark Mode" : "Windows 11 Light Mode"; font.family: "Segoe UI, sans-serif"; font.pixelSize: 11; color: settingsWin.textSecondary }
                    }
                    Switch {
                      checked: settingsWin.isDark
                      onToggled: {
                        settingsWin.isDark = checked
                        settingsWin.runCmd("omarchy-undercover " + (checked ? "-w11" : "-w11-light"))
                      }
                    }
                  }
                }

                // Accent Color Palette
                Rectangle {
                  Layout.fillWidth: true
                  implicitHeight: 96
                  radius: 8
                  color: settingsWin.cardBg
                  border.color: settingsWin.cardBorder
                  border.width: 1

                  ColumnLayout {
                    anchors.fill: parent
                    anchors.margins: 16
                    spacing: 10
                    Text { text: "Windows 11 Accent Color"; font.family: "Segoe UI, sans-serif"; font.pixelSize: 13; font.weight: Font.DemiBold; color: settingsWin.textPrimary }
                    RowLayout {
                      spacing: 12
                      property var palette: ["0078d4", "60cdff", "00b7c3", "107c41", "8764b8", "c42b1c", "e81123", "486860"]
                      Repeater {
                        model: parent.palette
                        Rectangle {
                          width: 32; height: 32; radius: 16
                          color: "#" + modelData
                          border.color: (settingsWin.activeAccent.toLowerCase() === modelData.toLowerCase()) ? (settingsWin.isDark ? "#ffffff" : "#000000") : "transparent"
                          border.width: 2
                          Text {
                            visible: settingsWin.activeAccent.toLowerCase() === modelData.toLowerCase()
                            anchors.centerIn: parent
                            text: "✓"
                            color: "#ffffff"
                            font.bold: true
                            font.pixelSize: 14
                          }
                          MouseArea {
                            anchors.fill: parent
                            cursorShape: Qt.PointingHandCursor
                            onClicked: {
                              settingsWin.activeAccent = modelData
                              settingsWin.saveSetting("ACCENT", modelData)
                              settingsWin.runCmd("hyprctl keyword general:col.active_border '0xff" + modelData + "' >/dev/null 2>&1")
                            }
                          }
                        }
                      }
                    }
                  }
                }

                // Taskbar Alignment
                Rectangle {
                  Layout.fillWidth: true
                  implicitHeight: 68
                  radius: 8
                  color: settingsWin.cardBg
                  border.color: settingsWin.cardBorder
                  border.width: 1
                  RowLayout {
                    anchors.fill: parent
                    anchors.margins: 16
                    spacing: 14
                    Image {
                      Layout.preferredWidth: 22
                      Layout.preferredHeight: 22
                      width: 22; height: 22
                      source: "file://" + settingsWin.pluginDir + "/assets/icons/win11-settings/system.svg"
                      fillMode: Image.PreserveAspectFit
                    }
                    ColumnLayout {
                      Layout.fillWidth: true
                      Text { text: "Taskbar Alignment"; font.family: "Segoe UI, sans-serif"; font.pixelSize: 13; font.weight: Font.DemiBold; color: settingsWin.textPrimary }
                      Text { text: settingsWin.taskbarAlign === "center" ? "Centered Taskbar (Windows 11)" : "Left Aligned Taskbar (Classic)"; font.family: "Segoe UI, sans-serif"; font.pixelSize: 11; color: settingsWin.textSecondary }
                    }
                    Rectangle {
                      implicitWidth: 104
                      implicitHeight: 30
                      radius: 4
                      color: settingsWin.accentColor
                      Text {
                        anchors.centerIn: parent
                        text: "Switch Align"
                        font.family: "Segoe UI, sans-serif"
                        font.pixelSize: 11
                        font.weight: Font.DemiBold
                        color: settingsWin.accentTextColor
                      }
                      MouseArea {
                        anchors.fill: parent
                        cursorShape: Qt.PointingHandCursor
                        onClicked: {
                          var next = (settingsWin.taskbarAlign === "center" ? "left" : "center")
                          settingsWin.taskbarAlign = next
                          settingsWin.saveSetting("ALIGN_LEFT", next === "left" ? "true" : "false")
                          settingsWin.runCmd("omarchy-undercover --align-" + next)
                        }
                      }
                    }
                  }
                }

                // Taskbar Auto-Hide
                Rectangle {
                  Layout.fillWidth: true
                  implicitHeight: 68
                  radius: 8
                  color: settingsWin.cardBg
                  border.color: settingsWin.cardBorder
                  border.width: 1
                  RowLayout {
                    anchors.fill: parent
                    anchors.margins: 16
                    spacing: 14
                    Image {
                      Layout.preferredWidth: 22
                      Layout.preferredHeight: 22
                      width: 22; height: 22
                      source: "file://" + settingsWin.pluginDir + "/assets/icons/win11-settings/system.svg"
                      fillMode: Image.PreserveAspectFit
                    }
                    ColumnLayout {
                      Layout.fillWidth: true
                      Text { text: "Automatically hide the taskbar"; font.family: "Segoe UI, sans-serif"; font.pixelSize: 13; font.weight: Font.DemiBold; color: settingsWin.textPrimary }
                      Text { text: settingsWin.autohideActive ? "Hides smoothly after mouse exits taskbar region" : "Taskbar remains permanently visible"; font.family: "Segoe UI, sans-serif"; font.pixelSize: 11; color: settingsWin.textSecondary }
                    }
                    Switch {
                      checked: settingsWin.autohideActive
                      onToggled: {
                        settingsWin.autohideActive = checked
                        settingsWin.saveSetting("AUTOHIDE", checked ? "true" : "false")
                        settingsWin.runCmd("omarchy-undercover-autohide --toggle")
                      }
                    }
                  }
                }

                // Transparent Taskbar
                Rectangle {
                  Layout.fillWidth: true
                  implicitHeight: 68
                  radius: 8
                  color: settingsWin.cardBg
                  border.color: settingsWin.cardBorder
                  border.width: 1
                  RowLayout {
                    anchors.fill: parent
                    anchors.margins: 16
                    spacing: 14
                    Image {
                      Layout.preferredWidth: 22
                      Layout.preferredHeight: 22
                      width: 22; height: 22
                      source: "file://" + settingsWin.pluginDir + "/assets/icons/win11-settings/personalization.svg"
                      fillMode: Image.PreserveAspectFit
                    }
                    ColumnLayout {
                      Layout.fillWidth: true
                      Text { text: "Transparent Taskbar"; font.family: "Segoe UI, sans-serif"; font.pixelSize: 13; font.weight: Font.DemiBold; color: settingsWin.textPrimary }
                      Text { text: settingsWin.isTransparent ? "Frosted acrylic transparency enabled (clear wallpaper blur)" : "Solid Fluent taskbar plate (opaque Windows 11 surface)"; font.family: "Segoe UI, sans-serif"; font.pixelSize: 11; color: settingsWin.textSecondary }
                    }
                    Switch {
                      checked: settingsWin.isTransparent
                      onToggled: {
                        settingsWin.isTransparent = checked
                        settingsWin.saveSetting("BAR_TRANSPARENT", checked ? "true" : "false")
                        settingsWin.saveSetting("WIN11_TRANSPARENCY", checked ? "true" : "false")
                        settingsWin.runCmd("omarchy bar transparent " + (checked ? "true" : "false") + " || omarchy-undercover --taskbar-transparent " + (checked ? "true" : "false"))
                      }
                    }
                  }
                }

                // Taskbar Items & Pinned Icons Management
                Rectangle {
                  Layout.fillWidth: true
                  implicitHeight: taskbarItemsCol.implicitHeight + 28
                  radius: 8
                  color: settingsWin.cardBg
                  border.color: settingsWin.cardBorder
                  border.width: 1

                  ColumnLayout {
                    id: taskbarItemsCol
                    anchors.fill: parent
                    anchors.margins: 16
                    spacing: 12

                    RowLayout {
                      Layout.fillWidth: true
                      spacing: 12
                      Image {
                        Layout.preferredWidth: 22
                        Layout.preferredHeight: 22
                        width: 22; height: 22
                        source: "file://" + settingsWin.pluginDir + "/assets/icons/win11-settings/personalization.svg"
                        fillMode: Image.PreserveAspectFit
                      }
                      ColumnLayout {
                        Layout.fillWidth: true
                        Text { text: "Taskbar Pinned Items"; font.family: "Segoe UI, sans-serif"; font.pixelSize: 13; font.weight: Font.DemiBold; color: settingsWin.textPrimary }
                        Text { text: "Show, hide, or disable specific buttons and icons on the taskbar"; font.family: "Segoe UI, sans-serif"; font.pixelSize: 11; color: settingsWin.textSecondary }
                      }
                    }

                    Rectangle { Layout.fillWidth: true; height: 1; color: settingsWin.cardBorder }

                    Repeater {
                      model: [
                        { id: "start", name: "Start Button", desc: "Windows Start menu and application launcher", icon: "start.svg" },
                        { id: "taskview", name: "Task View", desc: "Desktops & virtual workspaces switcher", icon: "taskview.svg" },
                        { id: "explorer", name: "File Explorer", desc: "Files and folders manager", icon: "explorer.svg" },
                        { id: "browser", name: "Microsoft Edge", desc: "Web browser and web apps", icon: "microsoft-edge.svg" },
                        { id: "antigravity", name: "Antigravity IDE", desc: "Code editor and workspace", icon: "antigravity-ide.svg" },
                        { id: "terminal", name: "Terminal", desc: "Command line shell environment", icon: "terminal.svg" },
                        { id: "notepad", name: "Notepad", desc: "Text editor and notes", icon: "notepad.svg" },
                        { id: "settings", name: "Settings", desc: "System settings and camouflage controller", icon: "settings.svg" },
                        { id: "running_apps", name: "Open Applications", desc: "Show active and background running windows", icon: "taskview.svg" }
                      ]

                      RowLayout {
                        Layout.fillWidth: true
                        spacing: 12

                        Image {
                          Layout.preferredWidth: 20
                          Layout.preferredHeight: 20
                          width: 20; height: 20
                          source: "file://" + settingsWin.pluginDir + "/assets/icons/win11/" + modelData.icon
                          fillMode: Image.PreserveAspectFit
                        }

                        ColumnLayout {
                          Layout.fillWidth: true
                          Text { text: modelData.name; font.family: "Segoe UI, sans-serif"; font.pixelSize: 12; font.weight: Font.DemiBold; color: settingsWin.textPrimary }
                          Text { text: modelData.desc; font.family: "Segoe UI, sans-serif"; font.pixelSize: 10; color: settingsWin.textSecondary }
                        }

                        Switch {
                          checked: (settingsWin.winPins[modelData.id] !== false)
                          onToggled: {
                            settingsWin.togglePin(modelData.id, checked)
                          }
                        }
                      }
                    }
                  }
                }

                // Visual Effects & Window Styling Card
                Rectangle {
                  Layout.fillWidth: true
                  implicitHeight: fxCol.implicitHeight + 28
                  radius: 8
                  color: settingsWin.cardBg
                  border.color: settingsWin.cardBorder
                  border.width: 1

                  ColumnLayout {
                    id: fxCol
                    anchors.fill: parent
                    anchors.margins: 16
                    spacing: 14

                    Text {
                      text: "Visual Effects & Window Styling"
                      font.family: "Segoe UI, sans-serif"
                      font.pixelSize: 13
                      font.weight: Font.DemiBold
                      color: settingsWin.textPrimary
                    }
                    Text {
                      text: "Configure transparency, window animations, corner curvature, and desktop gaps"
                      font.family: "Segoe UI, sans-serif"
                      font.pixelSize: 11
                      color: settingsWin.textSecondary
                    }

                    // Transparency effects row
                    RowLayout {
                      Layout.fillWidth: true
                      ColumnLayout {
                        Layout.fillWidth: true
                        spacing: 2
                        Text { text: "Transparency effects"; font.family: "Segoe UI, sans-serif"; font.pixelSize: 12; font.weight: Font.DemiBold; color: settingsWin.textPrimary }
                        Text { text: "Windows and surfaces appear translucent with background blur"; font.family: "Segoe UI, sans-serif"; font.pixelSize: 10; color: settingsWin.textSecondary }
                      }
                      Switch {
                        checked: settingsService.blurEnabled
                        onToggled: settingsService.setHyprOption("decoration:blur:enabled", checked ? "true" : "false")
                      }
                    }

                    Rectangle { Layout.fillWidth: true; height: 1; color: settingsWin.separatorColor }

                    // Animation effects row
                    RowLayout {
                      Layout.fillWidth: true
                      ColumnLayout {
                        Layout.fillWidth: true
                        spacing: 2
                        Text { text: "Animation effects"; font.family: "Segoe UI, sans-serif"; font.pixelSize: 12; font.weight: Font.DemiBold; color: settingsWin.textPrimary }
                        Text { text: "Animate windows opening, closing, and workspace transitions"; font.family: "Segoe UI, sans-serif"; font.pixelSize: 10; color: settingsWin.textSecondary }
                      }
                      Switch {
                        checked: settingsService.animationsEnabled
                        onToggled: settingsService.setHyprOption("animations:enabled", checked ? "true" : "false")
                      }
                    }

                    Rectangle { Layout.fillWidth: true; height: 1; color: settingsWin.separatorColor }

                    // Corner Rounding Slider
                    RowLayout {
                      Layout.fillWidth: true
                      spacing: 12
                      ColumnLayout {
                        Layout.fillWidth: true
                        spacing: 2
                        Text { text: "Corner Rounding (" + settingsService.windowRounding + "px)"; font.family: "Segoe UI, sans-serif"; font.pixelSize: 12; font.weight: Font.DemiBold; color: settingsWin.textPrimary }
                        Text { text: "Adjust curvature radius for window borders and popups"; font.family: "Segoe UI, sans-serif"; font.pixelSize: 10; color: settingsWin.textSecondary }
                      }
                      Slider {
                        Layout.preferredWidth: 160
                        from: 0; to: 24; stepSize: 1
                        value: settingsService.windowRounding
                        onMoved: {
                          settingsService.windowRounding = Math.round(value)
                          settingsService.setHyprOption("decoration:rounding", Math.round(value))
                        }
                      }
                    }

                    Rectangle { Layout.fillWidth: true; height: 1; color: settingsWin.separatorColor }

                    // Window Gaps Slider
                    RowLayout {
                      Layout.fillWidth: true
                      spacing: 12
                      ColumnLayout {
                        Layout.fillWidth: true
                        spacing: 2
                        Text { text: "Desktop Window Gaps (" + settingsService.windowGaps + "px)"; font.family: "Segoe UI, sans-serif"; font.pixelSize: 12; font.weight: Font.DemiBold; color: settingsWin.textPrimary }
                        Text { text: "Adjust outer and inner margins between tiled windows"; font.family: "Segoe UI, sans-serif"; font.pixelSize: 10; color: settingsWin.textSecondary }
                      }
                      Slider {
                        Layout.preferredWidth: 160
                        from: 0; to: 30; stepSize: 1
                        value: settingsService.windowGaps
                        onMoved: {
                          settingsService.windowGaps = Math.round(value)
                          settingsService.setHyprOption("general:gaps_in", Math.round(value))
                          settingsService.setHyprOption("general:gaps_out", Math.round(value * 1.5))
                        }
                      }
                    }
                  }
                }
              }

              // ==========================================
              // TAB 4: POWERTOYS & TOOLS
              // ==========================================
              ColumnLayout {
                visible: settingsWin.currentCategory === 4
                Layout.fillWidth: true
                spacing: 14

                // FancyZones / Snap Layouts
                Rectangle {
                  Layout.fillWidth: true
                  implicitHeight: 76
                  radius: 8
                  color: settingsWin.cardBg
                  border.color: settingsWin.cardBorder
                  border.width: 1

                  RowLayout {
                    anchors.fill: parent
                    anchors.margins: 16
                    spacing: 14
                    Image {
                      Layout.preferredWidth: 22
                      Layout.preferredHeight: 22
                      width: 22; height: 22
                      source: "file://" + settingsWin.pluginDir + "/assets/icons/win11-settings/gaps.svg"
                      fillMode: Image.PreserveAspectFit
                    }
                    ColumnLayout {
                      Layout.fillWidth: true
                      Text { text: "FancyZones / Snap Assist (Win + Z)"; font.family: "Segoe UI, sans-serif"; font.pixelSize: 13; font.weight: Font.DemiBold; color: settingsWin.textPrimary }
                      Text { text: "Instant quadrant tiling, 50/50 splits, and 3-column layouts"; font.family: "Segoe UI, sans-serif"; font.pixelSize: 11; color: settingsWin.textSecondary }
                    }
                    Rectangle {
                      implicitWidth: 96
                      implicitHeight: 30
                      radius: 4
                      color: settingsWin.accentColor
                      Text { anchors.centerIn: parent; text: "Snap Menu"; font.family: "Segoe UI, sans-serif"; font.pixelSize: 11; font.weight: Font.DemiBold; color: settingsWin.accentTextColor }
                      MouseArea {
                        anchors.fill: parent
                        cursorShape: Qt.PointingHandCursor
                        onClicked: settingsWin.runCmd("omarchy-undercover-snap menu")
                      }
                    }
                  }
                }

                // PowerToys Awake
                Rectangle {
                  Layout.fillWidth: true
                  implicitHeight: 76
                  radius: 8
                  color: settingsWin.cardBg
                  border.color: settingsWin.cardBorder
                  border.width: 1
                  RowLayout {
                    anchors.fill: parent
                    anchors.margins: 16
                    spacing: 14
                    Image {
                      Layout.preferredWidth: 22
                      Layout.preferredHeight: 22
                      width: 22; height: 22
                      source: "file://" + settingsWin.pluginDir + "/assets/icons/win11-settings/sun.svg"
                      fillMode: Image.PreserveAspectFit
                    }
                    ColumnLayout {
                      Layout.fillWidth: true
                      Text { text: "PowerToys Awake"; font.family: "Segoe UI, sans-serif"; font.pixelSize: 13; font.weight: Font.DemiBold; color: settingsWin.textPrimary }
                      Text { text: settingsWin.isAwakeActive ? "Awake active: prevents screen lock and standby" : "Standard power-saving and screensaver timers active"; font.family: "Segoe UI, sans-serif"; font.pixelSize: 11; color: settingsWin.textSecondary }
                    }
                    Switch {
                      checked: settingsWin.isAwakeActive
                      onToggled: {
                        settingsWin.isAwakeActive = checked
                        settingsWin.runCmd("omarchy toggle idle 2>/dev/null || true")
                      }
                    }
                  }
                }

                // PowerToys ColorPicker
                Rectangle {
                  Layout.fillWidth: true
                  implicitHeight: 76
                  radius: 8
                  color: settingsWin.cardBg
                  border.color: settingsWin.cardBorder
                  border.width: 1
                  RowLayout {
                    anchors.fill: parent
                    anchors.margins: 16
                    spacing: 14
                    Image {
                      Layout.preferredWidth: 22
                      Layout.preferredHeight: 22
                      width: 22; height: 22
                      source: "file://" + settingsWin.pluginDir + "/assets/icons/win11-settings/personalization.svg"
                      fillMode: Image.PreserveAspectFit
                    }
                    ColumnLayout {
                      Layout.fillWidth: true
                      Text { text: "PowerToys Color Picker (Win + Shift + C)"; font.family: "Segoe UI, sans-serif"; font.pixelSize: 13; font.weight: Font.DemiBold; color: settingsWin.textPrimary }
                      Text { text: "Inspect pixel colors on screen and copy HEX code to clipboard"; font.family: "Segoe UI, sans-serif"; font.pixelSize: 11; color: settingsWin.textSecondary }
                    }
                    Rectangle {
                      implicitWidth: 96
                      implicitHeight: 30
                      radius: 4
                      color: settingsWin.accentColor
                      Text { anchors.centerIn: parent; text: "Pick Color"; font.family: "Segoe UI, sans-serif"; font.pixelSize: 11; font.weight: Font.DemiBold; color: settingsWin.accentTextColor }
                      MouseArea {
                        anchors.fill: parent
                        cursorShape: Qt.PointingHandCursor
                        onClicked: settingsWin.runCmd("hyprpicker -a || wl-color-picker")
                      }
                    }
                  }
                }

                // PowerToys Always on Top
                Rectangle {
                  Layout.fillWidth: true
                  implicitHeight: 76
                  radius: 8
                  color: settingsWin.cardBg
                  border.color: settingsWin.cardBorder
                  border.width: 1
                  RowLayout {
                    anchors.fill: parent
                    anchors.margins: 16
                    spacing: 14
                    Image {
                      Layout.preferredWidth: 22
                      Layout.preferredHeight: 22
                      width: 22; height: 22
                      source: "file://" + settingsWin.pluginDir + "/assets/icons/win11-settings/tools.svg"
                      fillMode: Image.PreserveAspectFit
                    }
                    ColumnLayout {
                      Layout.fillWidth: true
                      Text { text: "PowerToys Always on Top (Win + Ctrl + T)"; font.family: "Segoe UI, sans-serif"; font.pixelSize: 13; font.weight: Font.DemiBold; color: settingsWin.textPrimary }
                      Text { text: "Pins the active window on top of all other application windows"; font.family: "Segoe UI, sans-serif"; font.pixelSize: 11; color: settingsWin.textSecondary }
                    }
                    Rectangle {
                      implicitWidth: 96
                      implicitHeight: 30
                      radius: 4
                      color: settingsWin.accentColor
                      Text { anchors.centerIn: parent; text: "Toggle Pin"; font.family: "Segoe UI, sans-serif"; font.pixelSize: 11; font.weight: Font.DemiBold; color: settingsWin.accentTextColor }
                      MouseArea {
                        anchors.fill: parent
                        cursorShape: Qt.PointingHandCursor
                        onClicked: settingsWin.runCmd("hyprctl dispatch pin active")
                      }
                    }
                  }
                }

                // Keyboard Shortcuts & Keybindings
                Rectangle {
                  Layout.fillWidth: true
                  implicitHeight: 76
                  radius: 8
                  color: settingsWin.cardBg
                  border.color: settingsWin.cardBorder
                  border.width: 1
                  RowLayout {
                    anchors.fill: parent
                    anchors.margins: 16
                    spacing: 14
                    Image {
                      Layout.preferredWidth: 22
                      Layout.preferredHeight: 22
                      width: 22; height: 22
                      source: "file://" + settingsWin.pluginDir + "/assets/icons/win11-settings/tools.svg"
                      fillMode: Image.PreserveAspectFit
                    }
                    ColumnLayout {
                      Layout.fillWidth: true
                      Text { text: "Keyboard Shortcuts & Keybindings"; font.family: "Segoe UI, sans-serif"; font.pixelSize: 13; font.weight: Font.DemiBold; color: settingsWin.textPrimary }
                      Text { text: "Customize Windows 11 & macOS keybindings with built-in Omarchy conflict protection"; font.family: "Segoe UI, sans-serif"; font.pixelSize: 11; color: settingsWin.textSecondary }
                    }
                    Rectangle {
                      implicitWidth: 115
                      implicitHeight: 30
                      radius: 4
                      color: settingsWin.accentColor
                      Text { anchors.centerIn: parent; text: "Configure Keys"; font.family: "Segoe UI, sans-serif"; font.pixelSize: 11; font.weight: Font.DemiBold; color: settingsWin.accentTextColor }
                      MouseArea {
                        anchors.fill: parent
                        cursorShape: Qt.PointingHandCursor
                        onClicked: settingsWin.runCmd("omarchy-undercover-settings --legacy -s")
                      }
                    }
                  }
                }
              }

              // ==========================================
              // TAB 5: UNDERCOVER DISGUISE PRESETS
              // ==========================================
              ColumnLayout {
                visible: settingsWin.currentCategory === 5
                Layout.fillWidth: true
                spacing: 14

                Text { text: "1-Click Desktop Camouflage Presets"; font.family: "Segoe UI, sans-serif"; font.pixelSize: 14; font.weight: Font.DemiBold; color: settingsWin.textPrimary }

                GridLayout {
                  Layout.fillWidth: true
                  columns: rightScroller.width > 600 ? 2 : 1
                  rowSpacing: 12
                  columnSpacing: 12

                  // Windows 11 Dark
                  Rectangle {
                    Layout.fillWidth: true
                    implicitHeight: 74
                    radius: 8
                    color: (settingsWin.currentDisguise === "win11-dark")
                           ? (settingsWin.isDark ? Qt.rgba(0.38, 0.80, 1.0, 0.12) : Qt.rgba(0, 0.40, 0.75, 0.08))
                           : (w11DarkM.containsMouse ? (settingsWin.isDark ? Qt.rgba(1, 1, 1, 0.08) : Qt.rgba(0, 0, 0, 0.04)) : settingsWin.cardBg)
                    border.color: (settingsWin.currentDisguise === "win11-dark") ? settingsWin.accentColor : settingsWin.cardBorder
                    border.width: (settingsWin.currentDisguise === "win11-dark") ? 2 : 1

                    RowLayout {
                      anchors.fill: parent
                      anchors.margins: 14
                      spacing: 12
                      Image {
                        Layout.preferredWidth: 24; Layout.preferredHeight: 24
                        width: 24; height: 24
                        source: "file://" + settingsWin.pluginDir + "/assets/icons/win11/start.svg"
                        fillMode: Image.PreserveAspectFit
                      }
                      ColumnLayout {
                        Layout.fillWidth: true
                        Text { text: "Windows 11 Fluent (Dark)" + (settingsWin.currentDisguise === "win11-dark" ? " — Active" : ""); font.family: "Segoe UI, sans-serif"; font.pixelSize: 13; font.weight: Font.DemiBold; color: settingsWin.textPrimary }
                        Text { text: "Mica Acrylic taskbar, Fluent icons & fonts"; font.family: "Segoe UI, sans-serif"; font.pixelSize: 11; color: settingsWin.textSecondary }
                      }
                    }
                    MouseArea {
                      id: w11DarkM
                      anchors.fill: parent
                      hoverEnabled: true
                      cursorShape: Qt.PointingHandCursor
                      onClicked: settingsWin.runCmd("omarchy-undercover -w11")
                    }
                  }

                  // Windows 11 Light
                  Rectangle {
                    Layout.fillWidth: true
                    implicitHeight: 74
                    radius: 8
                    color: (settingsWin.currentDisguise === "win11-light")
                           ? (settingsWin.isDark ? Qt.rgba(0.38, 0.80, 1.0, 0.12) : Qt.rgba(0, 0.40, 0.75, 0.08))
                           : (w11LightM.containsMouse ? (settingsWin.isDark ? Qt.rgba(1, 1, 1, 0.08) : Qt.rgba(0, 0, 0, 0.04)) : settingsWin.cardBg)
                    border.color: (settingsWin.currentDisguise === "win11-light") ? settingsWin.accentColor : settingsWin.cardBorder
                    border.width: (settingsWin.currentDisguise === "win11-light") ? 2 : 1

                    RowLayout {
                      anchors.fill: parent
                      anchors.margins: 14
                      spacing: 12
                      Image {
                        Layout.preferredWidth: 24; Layout.preferredHeight: 24
                        width: 24; height: 24
                        source: "file://" + settingsWin.pluginDir + "/assets/icons/win11-settings/sun.svg"
                        fillMode: Image.PreserveAspectFit
                      }
                      ColumnLayout {
                        Layout.fillWidth: true
                        Text { text: "Windows 11 Fluent (Light)" + (settingsWin.currentDisguise === "win11-light" ? " — Active" : ""); font.family: "Segoe UI, sans-serif"; font.pixelSize: 13; font.weight: Font.DemiBold; color: settingsWin.textPrimary }
                        Text { text: "Solar Light taskbar with Fluent styling"; font.family: "Segoe UI, sans-serif"; font.pixelSize: 11; color: settingsWin.textSecondary }
                      }
                    }
                    MouseArea {
                      id: w11LightM
                      anchors.fill: parent
                      hoverEnabled: true
                      cursorShape: Qt.PointingHandCursor
                      onClicked: settingsWin.runCmd("omarchy-undercover -w11-light")
                    }
                  }

                  // macOS Sequoia Dark
                  Rectangle {
                    Layout.fillWidth: true
                    implicitHeight: 74
                    radius: 8
                    color: (settingsWin.currentDisguise === "mac-dark")
                           ? (settingsWin.isDark ? Qt.rgba(0.38, 0.80, 1.0, 0.12) : Qt.rgba(0, 0.40, 0.75, 0.08))
                           : (macDarkM.containsMouse ? (settingsWin.isDark ? Qt.rgba(1, 1, 1, 0.08) : Qt.rgba(0, 0, 0, 0.04)) : settingsWin.cardBg)
                    border.color: (settingsWin.currentDisguise === "mac-dark") ? settingsWin.accentColor : settingsWin.cardBorder
                    border.width: (settingsWin.currentDisguise === "mac-dark") ? 2 : 1

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
                        Text { text: "macOS Sequoia (Dark)" + (settingsWin.currentDisguise === "mac-dark" ? " — Active" : ""); font.family: "Segoe UI, sans-serif"; font.pixelSize: 13; font.weight: Font.DemiBold; color: settingsWin.textPrimary }
                        Text { text: "Dark menu bar, dynamic dock & SF Pro typography"; font.family: "Segoe UI, sans-serif"; font.pixelSize: 11; color: settingsWin.textSecondary }
                      }
                    }
                    MouseArea {
                      id: macDarkM
                      anchors.fill: parent
                      hoverEnabled: true
                      cursorShape: Qt.PointingHandCursor
                      onClicked: settingsWin.runCmd("omarchy-undercover -mac")
                    }
                  }

                  // macOS Sequoia Light
                  Rectangle {
                    Layout.fillWidth: true
                    implicitHeight: 74
                    radius: 8
                    color: (settingsWin.currentDisguise === "mac-light")
                           ? (settingsWin.isDark ? Qt.rgba(0.38, 0.80, 1.0, 0.12) : Qt.rgba(0, 0.40, 0.75, 0.08))
                           : (macLightM.containsMouse ? (settingsWin.isDark ? Qt.rgba(1, 1, 1, 0.08) : Qt.rgba(0, 0, 0, 0.04)) : settingsWin.cardBg)
                    border.color: (settingsWin.currentDisguise === "mac-light") ? settingsWin.accentColor : settingsWin.cardBorder
                    border.width: (settingsWin.currentDisguise === "mac-light") ? 2 : 1

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
                        Text { text: "macOS Sequoia (Light)" + (settingsWin.currentDisguise === "mac-light" ? " — Active" : ""); font.family: "Segoe UI, sans-serif"; font.pixelSize: 13; font.weight: Font.DemiBold; color: settingsWin.textPrimary }
                        Text { text: "Solar light glass menu bar & high vibrancy dock"; font.family: "Segoe UI, sans-serif"; font.pixelSize: 11; color: settingsWin.textSecondary }
                      }
                    }
                    MouseArea {
                      id: macLightM
                      anchors.fill: parent
                      hoverEnabled: true
                      cursorShape: Qt.PointingHandCursor
                      onClicked: settingsWin.runCmd("omarchy-undercover -mac-light")
                    }
                  }

                  // Restore Default Omarchy
                  Rectangle {
                    Layout.fillWidth: true
                    implicitHeight: 74
                    radius: 8
                    color: (settingsWin.currentDisguise === "omarchy")
                           ? (settingsWin.isDark ? Qt.rgba(0.38, 0.80, 1.0, 0.12) : Qt.rgba(0, 0.40, 0.75, 0.08))
                           : (omarchyM.containsMouse ? (settingsWin.isDark ? Qt.rgba(1, 1, 1, 0.08) : Qt.rgba(0, 0, 0, 0.04)) : settingsWin.cardBg)
                    border.color: (settingsWin.currentDisguise === "omarchy") ? "#34c759" : settingsWin.cardBorder
                    border.width: (settingsWin.currentDisguise === "omarchy") ? 2 : 1
                    RowLayout {
                      anchors.fill: parent
                      anchors.margins: 14
                      spacing: 12
                      Image {
                        Layout.preferredWidth: 24; Layout.preferredHeight: 24
                        width: 24; height: 24
                        source: "file://" + settingsWin.pluginDir + "/assets/icons/win11-settings/disguise.svg"
                        fillMode: Image.PreserveAspectFit
                      }
                      ColumnLayout {
                        Layout.fillWidth: true
                        Text { text: "Restore Default Omarchy" + (settingsWin.currentDisguise === "omarchy" ? " — Active" : ""); font.family: "Segoe UI, sans-serif"; font.pixelSize: 13; font.weight: Font.DemiBold; color: settingsWin.textPrimary }
                        Text { text: "Deactivate camouflage and restore baseline"; font.family: "Segoe UI, sans-serif"; font.pixelSize: 11; color: settingsWin.textSecondary }
                      }
                    }
                    MouseArea {
                      id: omarchyM
                      anchors.fill: parent
                      hoverEnabled: true
                      cursorShape: Qt.PointingHandCursor
                      onClicked: settingsWin.runCmd("omarchy-undercover --disable")
                    }
                  }
                }
              }

              // ==========================================
              // TAB 6: WINDOWS UPDATE & SYSTEM HEALTH
              // ==========================================
              ColumnLayout {
                visible: settingsWin.currentCategory === 6
                Layout.fillWidth: true
                spacing: 14

                Rectangle {
                  Layout.fillWidth: true
                  implicitHeight: 88
                  radius: 8
                  color: settingsWin.cardBg
                  border.color: settingsWin.cardBorder
                  border.width: 1
                  RowLayout {
                    anchors.fill: parent
                    anchors.margins: 18
                    spacing: 16
                    Image {
                      Layout.preferredWidth: 28
                      Layout.preferredHeight: 28
                      width: 28; height: 28
                      source: "file://" + settingsWin.pluginDir + "/assets/icons/win11-settings/shield.svg"
                      fillMode: Image.PreserveAspectFit
                    }
                    ColumnLayout {
                      Layout.fillWidth: true
                      Text { text: "You're up to date"; font.family: "Segoe UI, sans-serif"; font.pixelSize: 14; font.weight: Font.DemiBold; color: settingsWin.textPrimary }
                      Text { text: "Omarchy Undercover v5.0.0 • Omarchy Shell Plugin Protocol v1"; font.family: "Segoe UI, sans-serif"; font.pixelSize: 11; color: settingsWin.textSecondary }
                    }
                    Rectangle {
                      implicitWidth: 130
                      implicitHeight: 34
                      radius: 4
                      color: settingsWin.accentColor
                      Text {
                        anchors.centerIn: parent
                        text: "Check for updates"
                        font.family: "Segoe UI, sans-serif"
                        font.pixelSize: 12
                        font.weight: Font.DemiBold
                        color: settingsWin.accentTextColor
                      }
                      MouseArea {
                        anchors.fill: parent
                        cursorShape: Qt.PointingHandCursor
                        onClicked: settingsWin.runCmd("xdg-terminal-exec -e bash -c 'omarchy update; read -p \"Press Enter to close\"'")
                      }
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

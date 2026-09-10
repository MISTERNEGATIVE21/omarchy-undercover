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

    implicitWidth: 980
    implicitHeight: 640
    minimumSize: Qt.size(820, 520)
    color: "transparent"

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

    function runCmd(cmd) {
      Quickshell.execDetached(["bash", "-c", cmd])
    }

    function saveSetting(key, val) {
      var cmd = "mkdir -p " + homeDir + "/.config/omarchy-undercover && " +
                "touch " + homeDir + "/.config/omarchy-undercover/settings.conf && " +
                "if grep -q '^" + key + "=' " + homeDir + "/.config/omarchy-undercover/settings.conf; then " +
                "  sed -i 's/^" + key + "=.*/" + key + "=" + val + "/' " + homeDir + "/.config/omarchy-undercover/settings.conf; " +
                "else " +
                "  echo '" + key + "=" + val + "' >> " + homeDir + "/.config/omarchy-undercover/settings.conf; " +
                "fi"
      runCmd(cmd)
    }

    // Reactive Watcher on State
    FileView {
      id: stateWatcher
      path: settingsWin.homeDir + "/.config/omarchy-undercover/state"
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
      path: settingsWin.homeDir + "/.config/omarchy-undercover/settings.conf"
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
      path: settingsWin.homeDir + "/.config/omarchy-undercover/defaults.json"
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
      var cmd = "python3 -c \"import json, os; p = os.path.expanduser('~/.config/omarchy-undercover/defaults.json'); os.makedirs(os.path.dirname(p), exist_ok=True); d = json.load(open(p)) if os.path.exists(p) else {}; d['win11_pins'] = d.get('win11_pins', {}); d['win11_pins']['" + pinId + "'] = " + (enabled ? "True" : "False") + "; json.dump(d, open(p, 'w'), indent=2)\""
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
                source: "file://" + settingsWin.homeDir + "/.local/share/icons/win11/settings.svg"
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
                    source: "file://" + settingsWin.homeDir + "/.local/share/icons/win11-settings/search.svg"
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
                      source: "file://" + settingsWin.homeDir + "/.local/share/icons/win11-settings/" + modelData.icon
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
                      source: "file://" + settingsWin.homeDir + "/.local/share/icons/win11-settings/chevron.svg"
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

              // Dynamic Category Header
              Text {
                text: {
                  switch(settingsWin.currentCategory) {
                    case 0: return "System"
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

              // ==========================================
              // TAB 0: SYSTEM
              // ==========================================
              ColumnLayout {
                visible: settingsWin.currentCategory === 0
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
                      source: "file://" + settingsWin.homeDir + "/.local/share/icons/win11-settings/system.svg"
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
                      source: "file://" + settingsWin.homeDir + "/.local/share/icons/win11-settings/sun.svg"
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

                // Master Volume
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
                      source: "file://" + settingsWin.homeDir + "/.local/share/icons/win11-settings/volume.svg"
                      fillMode: Image.PreserveAspectFit
                    }
                    ColumnLayout {
                      Layout.fillWidth: true
                      Text { text: "Master Volume"; font.family: "Segoe UI, sans-serif"; font.pixelSize: 13; font.weight: Font.DemiBold; color: settingsWin.textPrimary }
                      Text { text: settingsWin.volumeLevel + "% output level"; font.family: "Segoe UI, sans-serif"; font.pixelSize: 11; color: settingsWin.textSecondary }
                    }
                    Slider {
                      Layout.preferredWidth: 180
                      from: 0; to: 100
                      value: settingsWin.volumeLevel
                      onMoved: {
                        settingsWin.volumeLevel = Math.round(value)
                        settingsWin.runCmd("wpctl set-volume @DEFAULT_AUDIO_SINK@ " + (Math.round(value) / 100.0) + " >/dev/null 2>&1")
                      }
                    }
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
                      source: "file://" + settingsWin.homeDir + "/.local/share/icons/win11-settings/gaps.svg"
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
                      source: "file://" + settingsWin.homeDir + "/.local/share/icons/win11-settings/rounding.svg"
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
                      source: "file://" + settingsWin.homeDir + "/.local/share/icons/win11-settings/devices.svg"
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
                    onClicked: settingsWin.runCmd("omarchy-bluetooth-manager || blueman-manager")
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
                      source: "file://" + settingsWin.homeDir + "/.local/share/icons/win11-settings/network.svg"
                      fillMode: Image.PreserveAspectFit
                    }
                    ColumnLayout {
                      Layout.fillWidth: true
                      Text { text: "Wi-Fi Connection"; font.family: "Segoe UI, sans-serif"; font.pixelSize: 13; font.weight: Font.DemiBold; color: settingsWin.textPrimary }
                      Text { text: settingsWin.wifiEnabled ? settingsWin.wifiSsid : "Wi-Fi is turned off"; font.family: "Segoe UI, sans-serif"; font.pixelSize: 11; color: settingsWin.textSecondary }
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
                    onClicked: settingsWin.runCmd("omarchy-wifi-manager || nm-connection-editor")
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
                                source: "file://" + settingsWin.homeDir + "/.local/share/icons/" + (modelData.isWin ? "win11/" : (modelData.icon === "apple-logo.svg" ? "" : "win11-settings/")) + modelData.icon
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
                      source: "file://" + settingsWin.homeDir + "/.local/share/icons/win11-settings/personalization.svg"
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
                      source: "file://" + settingsWin.homeDir + "/.local/share/icons/win11-settings/system.svg"
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
                      source: "file://" + settingsWin.homeDir + "/.local/share/icons/win11-settings/system.svg"
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
                      source: "file://" + settingsWin.homeDir + "/.local/share/icons/win11-settings/personalization.svg"
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
                        source: "file://" + settingsWin.homeDir + "/.local/share/icons/win11-settings/personalization.svg"
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
                          source: "file://" + settingsWin.homeDir + "/.local/share/icons/win11/" + modelData.icon
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
                      source: "file://" + settingsWin.homeDir + "/.local/share/icons/win11-settings/gaps.svg"
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
                      source: "file://" + settingsWin.homeDir + "/.local/share/icons/win11-settings/sun.svg"
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
                      source: "file://" + settingsWin.homeDir + "/.local/share/icons/win11-settings/personalization.svg"
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
                      source: "file://" + settingsWin.homeDir + "/.local/share/icons/win11-settings/tools.svg"
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
                        source: "file://" + settingsWin.homeDir + "/.local/share/icons/win11/start.svg"
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
                        source: "file://" + settingsWin.homeDir + "/.local/share/icons/win11-settings/sun.svg"
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
                        source: "file://" + settingsWin.homeDir + "/.local/share/icons/apple-logo.svg"
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
                        source: "file://" + settingsWin.homeDir + "/.local/share/icons/apple-logo.svg"
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
                        source: "file://" + settingsWin.homeDir + "/.local/share/icons/win11-settings/disguise.svg"
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
                      source: "file://" + settingsWin.homeDir + "/.local/share/icons/win11-settings/shield.svg"
                      fillMode: Image.PreserveAspectFit
                    }
                    ColumnLayout {
                      Layout.fillWidth: true
                      Text { text: "You're up to date"; font.family: "Segoe UI, sans-serif"; font.pixelSize: 14; font.weight: Font.DemiBold; color: settingsWin.textPrimary }
                      Text { text: "Omarchy Undercover v4.0.0 • Omarchy Shell Plugin Protocol v1"; font.family: "Segoe UI, sans-serif"; font.pixelSize: 11; color: settingsWin.textSecondary }
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

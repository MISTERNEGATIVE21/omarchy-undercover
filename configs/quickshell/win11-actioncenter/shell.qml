import Quickshell
import Quickshell.Wayland
import Quickshell.Hyprland
import Quickshell.Io
import QtQuick
import QtQuick.Layouts
import QtQuick.Controls

ShellRoot {
  PanelWindow {
    id: actionCenterWindow
    screen: Quickshell.screens[0]

    anchors {
      bottom: true
      right: true
    }
    margins {
      bottom: 10
      right: 12
    }

    WlrLayershell.layer: WlrLayer.Overlay
    WlrLayershell.namespace: "omarchy-menu"
    WlrLayershell.keyboardFocus: WlrKeyboardFocus.OnDemand
    exclusiveZone: 0
    color: "transparent"

    implicitWidth: Math.min(380, (screen ? screen.width : 1280) - 24)
    implicitHeight: Math.min(500, (screen ? screen.height : 720) - 70)

    property string homeDir: Quickshell.env("HOME")
    property bool isDark: true
    property string currentView: "main" // "main" | "wifi" | "bluetooth"

    // Hardware states
    property bool wifiEnabled: true
    property bool btEnabled: true
    property bool airplaneMode: false
    property bool nightLightEnabled: false
    property bool batterySaverEnabled: false
    property int volumeVal: 70
    property int micVal: 70
    property bool micMuted: false
    property int brightnessVal: 80
    property int batteryPct: 90
    property bool isCharging: false
    property string wifiSsid: "Connected"
    property string btDevice: "Connected"

    // Wi-Fi Sub-Page State
    property var networks: []
    property bool isScanningWifi: false
    property string wifiSearchText: ""
    property string connectingSsid: ""
    property string wifiPasswordInput: ""

    // Bluetooth Sub-Page State
    property var btDevices: []
    property bool isScanningBt: false
    property string btSearchText: ""

    // Fluent Design Colors
    readonly property color cardBg: isDark ? Qt.rgba(0.12, 0.13, 0.17, 0.94) : Qt.rgba(0.96, 0.96, 0.98, 0.96)
    readonly property color cardBorder: isDark ? Qt.rgba(1, 1, 1, 0.14) : Qt.rgba(0, 0, 0, 0.12)
    readonly property color innerCardBg: isDark ? Qt.rgba(1, 1, 1, 0.08) : "#ffffff"
    readonly property color innerCardBorder: isDark ? Qt.rgba(1, 1, 1, 0.12) : Qt.rgba(0, 0, 0, 0.10)
    readonly property color textPrimary: isDark ? "#ffffff" : "#111111"
    readonly property color textSecondary: isDark ? Qt.rgba(1, 1, 1, 0.74) : "#555555"
    readonly property color textMuted: isDark ? Qt.rgba(1, 1, 1, 0.52) : "#777777"
    readonly property color accentColor: isDark ? "#0078d4" : "#0067c0"
    readonly property color accentBorder: isDark ? "#60cdff" : "#005a9e"
    readonly property color hoverBg: isDark ? Qt.rgba(1, 1, 1, 0.08) : Qt.rgba(0, 0, 0, 0.05)

    readonly property var filteredNetworks: {
      var q = actionCenterWindow.wifiSearchText.toLowerCase().trim()
      var result = []
      for (var i = 0; i < actionCenterWindow.networks.length; i++) {
        var n = actionCenterWindow.networks[i]
        if (!n.ssid || n.ssid.length === 0) continue
        if (!q ||
            n.ssid.toLowerCase().indexOf(q) !== -1 ||
            (n.security && n.security.toLowerCase().indexOf(q) !== -1)) {
          result.push(n)
        }
      }
      result.sort(function(a, b) {
        if (a.inUse && !b.inUse) return -1
        if (!a.inUse && b.inUse) return 1
        return (b.signal || 0) - (a.signal || 0)
      })
      return result
    }

    readonly property var filteredBtDevices: {
      var q = actionCenterWindow.btSearchText.toLowerCase().trim()
      var result = []
      for (var i = 0; i < actionCenterWindow.btDevices.length; i++) {
        var d = actionCenterWindow.btDevices[i]
        if ((d.name && d.name.toLowerCase().indexOf(q) !== -1) || (d.mac && d.mac.toLowerCase().indexOf(q) !== -1)) {
          result.push(d)
        }
      }
      result.sort(function(a, b) {
        if (a.connected && !b.connected) return -1
        if (!a.connected && b.connected) return 1
        return (a.name || "").localeCompare(b.name || "")
      })
      return result
    }

    function getSignalIcon(sig) {
      if (sig >= 75) return "󰤨"
      if (sig >= 50) return "󰤥"
      if (sig >= 25) return "󰤢"
      return "󰤟"
    }

    function triggerWifiScan() {
      actionCenterWindow.isScanningWifi = true
      actionCenterWindow.networks = []
      if (!wifiScanPoller.running) wifiScanPoller.running = true
    }

    function triggerBtScan() {
      actionCenterWindow.isScanningBt = true
      actionCenterWindow.btDevices = []
      if (!btScanPoller.running) btScanPoller.running = true
    }

    Shortcut {
      sequence: "Escape"
      onActivated: {
        if (actionCenterWindow.currentView !== "main") {
          actionCenterWindow.currentView = "main"
        } else {
          Qt.quit()
        }
      }
    }

    function runCmd(cmd) {
      Quickshell.execDetached(["bash", "-c", cmd])
    }

    Process {
      id: wifiConnectProc
      property string secret: ""
      stdinEnabled: true
      onStarted: {
        if (secret) {
          write(secret + "\n")
          secret = ""
        }
      }
      onExited: {
        actionCenterWindow.triggerWifiScan()
      }
    }

    function connectWifi(ssid, password) {
      if (typeof ssid !== "string" || ssid.length === 0 || ssid.length > 32 || /[\x00-\x1f]/.test(ssid)) {
        return
      }
      if (wifiConnectProc.running) wifiConnectProc.running = false
      wifiConnectProc.secret = (typeof password === "string") ? password : ""
      wifiConnectProc.command = ["omarchy-wifi-dbus", "connect", ssid]
      wifiConnectProc.running = true
    }

    // Reactive Theme Poller
    FileView {
      id: stateWatcher
      path: actionCenterWindow.homeDir + "/.config/omarchy-undercover/state"
      watchChanges: true
      onLoaded: {
        var s = text().trim()
        actionCenterWindow.isDark = (s.indexOf("light") === -1)
      }
      onFileChanged: {
        reload()
        var s = text().trim()
        actionCenterWindow.isDark = (s.indexOf("light") === -1)
      }
    }

    // Live Hardware State Poller
    Process {
      id: statePoller
      command: [
        "bash", "-c",
        "wifi=$(nmcli radio wifi 2>/dev/null || echo 'disabled'); " +
        "bt=$(bluetoothctl show 2>/dev/null | grep -q 'Powered: yes' && echo '1' || echo '0'); " +
        "vol=$(wpctl get-volume @DEFAULT_AUDIO_SINK@ 2>/dev/null | awk '{print int($2*100)}' || echo '70'); " +
        "mic=$(wpctl get-volume @DEFAULT_AUDIO_SOURCE@ 2>/dev/null | awk '{print int($2*100)}' || echo '70'); " +
        "micmut=$(wpctl get-volume @DEFAULT_AUDIO_SOURCE@ 2>/dev/null | grep -qi 'MUTED' && echo '1' || echo '0'); " +
        "bri=$(brightnessctl -m 2>/dev/null | cut -d, -f4 | tr -d '%' || echo '80'); " +
        "bat=$(cat /sys/class/power_supply/BAT*/capacity 2>/dev/null | head -1 || echo '90'); " +
        "chg=$(cat /sys/class/power_supply/BAT*/status 2>/dev/null | head -1 || echo 'Discharging'); " +
        "ssid=$(nmcli -t -f active,ssid dev wifi 2>/dev/null | grep '^yes:' | cut -d: -f2 || echo 'Connected'); " +
        "echo \"$wifi|$bt|$vol|$mic|$micmut|$bri|$bat|$chg|$ssid\""
      ]
      stdout: SplitParser {
        onRead: function(line) {
          if (!line) return
          var p = line.trim().split("|")
          if (p.length >= 9) {
            actionCenterWindow.wifiEnabled = (p[0].indexOf("enabled") !== -1)
            actionCenterWindow.btEnabled = (p[1] === "1")
            var v = parseInt(p[2]); if (!isNaN(v)) actionCenterWindow.volumeVal = Math.max(0, Math.min(100, v))
            var m = parseInt(p[3]); if (!isNaN(m)) actionCenterWindow.micVal = Math.max(0, Math.min(100, m))
            actionCenterWindow.micMuted = (p[4] === "1")
            var b = parseInt(p[5]); if (!isNaN(b)) actionCenterWindow.brightnessVal = Math.max(5, Math.min(100, b))
            var bt = parseInt(p[6]); if (!isNaN(bt)) actionCenterWindow.batteryPct = Math.max(1, Math.min(100, bt))
            actionCenterWindow.isCharging = (p[7].toLowerCase().indexOf("charg") !== -1)
            if (p[8]) actionCenterWindow.wifiSsid = p[8]
          }
        }
      }
    }

    // Wi-Fi Scan Process
    Process {
      id: wifiScanPoller
      command: ["bash", "-c", "omarchy-wifi-dbus scan"]
      stdout: SplitParser {
        onRead: function(line) {
          var l = String(line).trim()
          if (!l) return
          var parts = l.split(":")
          if (parts.length >= 4) {
            var inUse = (parts[0] === "*")
            var ssid = parts[1]
            var signal = parseInt(parts[2]) || 0
            var security = parts[3]
            var bssid = parts.length >= 5 ? parts.slice(4).join(":") : ""
            if (ssid && ssid.length > 0) {
              if (inUse) actionCenterWindow.wifiSsid = ssid
              var currentList = actionCenterWindow.networks.slice(0)
              var exists = false
              for (var i = 0; i < currentList.length; i++) {
                if (currentList[i].ssid === ssid) {
                  currentList[i].signal = signal
                  currentList[i].inUse = inUse
                  exists = true
                  break
                }
              }
              if (!exists) {
                currentList.push({
                  ssid: ssid,
                  bssid: bssid,
                  signal: signal,
                  security: security,
                  inUse: inUse,
                  isSecured: (security.length > 0 && security !== "--")
                })
              }
              actionCenterWindow.networks = currentList
            }
          }
        }
      }
      onExited: function() {
        actionCenterWindow.isScanningWifi = false
      }
    }

    // Bluetooth Scan Process
    Process {
      id: btScanPoller
      command: ["bash", "-c", "omarchy-bluetooth-dbus scan"]
      stdout: SplitParser {
        onRead: function(line) {
          var l = String(line).trim()
          if (!l) return
          var parts = l.split("|")
          if (parts.length >= 3) {
            var mac = parts[0]
            var connected = (parts[1] === "1")
            var name = parts.slice(2).join("|")
            var currentList = actionCenterWindow.btDevices.slice(0)
            var exists = false
            for (var i = 0; i < currentList.length; i++) {
              if (currentList[i].mac === mac) {
                currentList[i].name = name
                currentList[i].connected = connected
                exists = true
                break
              }
            }
            if (!exists) {
              var low = name.toLowerCase()
              var iconType = "📱"
              if (low.indexOf("headset") !== -1 || low.indexOf("audio") !== -1 || low.indexOf("airpods") !== -1 || low.indexOf("wh-") !== -1 || low.indexOf("buds") !== -1 || low.indexOf("sound") !== -1 || low.indexOf("speaker") !== -1) {
                iconType = "🎧"
              } else if (low.indexOf("mouse") !== -1 || low.indexOf("trackpad") !== -1) {
                iconType = "🖱️"
              } else if (low.indexOf("key") !== -1) {
                iconType = "⌨️"
              } else if (low.indexOf("controller") !== -1 || low.indexOf("xbox") !== -1 || low.indexOf("gamepad") !== -1 || low.indexOf("joy-con") !== -1) {
                iconType = "🎮"
              }
              currentList.push({
                mac: mac,
                name: name,
                connected: connected,
                type: iconType
              })
            }
            actionCenterWindow.btDevices = currentList
          }
        }
      }
      onExited: function() {
        actionCenterWindow.isScanningBt = false
      }
    }

    Timer {
      interval: 2500
      running: true
      repeat: true
      triggeredOnStart: true
      onTriggered: {
        if (!statePoller.running) statePoller.running = true
      }
    }

    // Container
    Rectangle {
      id: bg
      anchors.fill: parent
      radius: 12
      color: actionCenterWindow.cardBg
      border.color: actionCenterWindow.cardBorder
      border.width: 1
      clip: true

      // ==========================================
      // VIEW 1: MAIN ACTION CENTER VIEW
      // ==========================================
      ColumnLayout {
        id: mainView
        visible: actionCenterWindow.currentView === "main"
        anchors.fill: parent
        anchors.margins: 16
        spacing: 14

        // 1. Fluent 6-Toggle Grid
        GridLayout {
          Layout.fillWidth: true
          columns: 2
          rowSpacing: 10
          columnSpacing: 10

          // Wi-Fi Toggle Tile (with in-place chevron navigation)
          Rectangle {
            Layout.fillWidth: true
            implicitHeight: 48
            radius: 6
            color: actionCenterWindow.wifiEnabled ? actionCenterWindow.accentColor : actionCenterWindow.innerCardBg
            border.color: actionCenterWindow.wifiEnabled ? actionCenterWindow.accentBorder : actionCenterWindow.innerCardBorder
            border.width: 1

            RowLayout {
              anchors.fill: parent
              spacing: 0

              // Left part: toggle Wi-Fi radio
              Item {
                Layout.fillWidth: true
                Layout.fillHeight: true

                RowLayout {
                  anchors.fill: parent
                  anchors.leftMargin: 10
                  anchors.rightMargin: 4
                  spacing: 8

                  Text {
                    text: "󰤨"
                    font.pixelSize: 16
                    color: actionCenterWindow.wifiEnabled ? "#ffffff" : actionCenterWindow.textPrimary
                  }

                  ColumnLayout {
                    Layout.fillWidth: true
                    spacing: 0
                    Text {
                      text: "Wi-Fi"
                      font.family: "Segoe UI"
                      font.pixelSize: 11
                      font.bold: true
                      color: actionCenterWindow.wifiEnabled ? "#ffffff" : actionCenterWindow.textPrimary
                    }
                    Text {
                      text: actionCenterWindow.wifiEnabled ? actionCenterWindow.wifiSsid : "Disconnected"
                      font.family: "Segoe UI"
                      font.pixelSize: 9
                      color: actionCenterWindow.wifiEnabled ? Qt.rgba(1, 1, 1, 0.85) : actionCenterWindow.textSecondary
                      elide: Text.ElideRight
                      Layout.fillWidth: true
                    }
                  }
                }

                MouseArea {
                  anchors.fill: parent
                  cursorShape: Qt.PointingHandCursor
                  acceptedButtons: Qt.LeftButton | Qt.RightButton
                  onClicked: function(mouse) {
                    if (mouse.button === Qt.RightButton) {
                      actionCenterWindow.currentView = "wifi"
                      actionCenterWindow.triggerWifiScan()
                    } else {
                      actionCenterWindow.wifiEnabled = !actionCenterWindow.wifiEnabled
                      Quickshell.execDetached(["omarchy-wifi-dbus", actionCenterWindow.wifiEnabled ? "on" : "off"])
                    }
                  }
                }
              }

              // Divider between toggle & chevron
              Rectangle {
                width: 1
                height: 24
                color: actionCenterWindow.wifiEnabled ? Qt.rgba(1, 1, 1, 0.25) : actionCenterWindow.innerCardBorder
              }

              // Right part: chevron -> in-place Wi-Fi menu
              Rectangle {
                implicitWidth: 32
                implicitHeight: 48
                color: wifiChevronMouse.containsMouse ? (actionCenterWindow.wifiEnabled ? Qt.rgba(1, 1, 1, 0.15) : actionCenterWindow.hoverBg) : "transparent"

                Text {
                  anchors.centerIn: parent
                  text: "›"
                  font.pixelSize: 15
                  font.bold: true
                  color: actionCenterWindow.wifiEnabled ? "#ffffff" : actionCenterWindow.textPrimary
                }

                MouseArea {
                  id: wifiChevronMouse
                  anchors.fill: parent
                  hoverEnabled: true
                  cursorShape: Qt.PointingHandCursor
                  onClicked: {
                    actionCenterWindow.currentView = "wifi"
                    actionCenterWindow.triggerWifiScan()
                  }
                }
              }
            }
          }

          // Bluetooth Toggle Tile (with in-place chevron navigation)
          Rectangle {
            Layout.fillWidth: true
            implicitHeight: 48
            radius: 6
            color: actionCenterWindow.btEnabled ? actionCenterWindow.accentColor : actionCenterWindow.innerCardBg
            border.color: actionCenterWindow.btEnabled ? actionCenterWindow.accentBorder : actionCenterWindow.innerCardBorder
            border.width: 1

            RowLayout {
              anchors.fill: parent
              spacing: 0

              // Left part: toggle Bluetooth power
              Item {
                Layout.fillWidth: true
                Layout.fillHeight: true

                RowLayout {
                  anchors.fill: parent
                  anchors.leftMargin: 10
                  anchors.rightMargin: 4
                  spacing: 8

                  Text {
                    text: "󰂯"
                    font.pixelSize: 16
                    color: actionCenterWindow.btEnabled ? "#ffffff" : actionCenterWindow.textPrimary
                  }

                  ColumnLayout {
                    Layout.fillWidth: true
                    spacing: 0
                    Text {
                      text: "Bluetooth"
                      font.family: "Segoe UI"
                      font.pixelSize: 11
                      font.bold: true
                      color: actionCenterWindow.btEnabled ? "#ffffff" : actionCenterWindow.textPrimary
                    }
                    Text {
                      text: actionCenterWindow.btEnabled ? actionCenterWindow.btDevice : "Off"
                      font.family: "Segoe UI"
                      font.pixelSize: 9
                      color: actionCenterWindow.btEnabled ? Qt.rgba(1, 1, 1, 0.85) : actionCenterWindow.textSecondary
                      elide: Text.ElideRight
                      Layout.fillWidth: true
                    }
                  }
                }

                MouseArea {
                  anchors.fill: parent
                  cursorShape: Qt.PointingHandCursor
                  acceptedButtons: Qt.LeftButton | Qt.RightButton
                  onClicked: function(mouse) {
                    if (mouse.button === Qt.RightButton) {
                      actionCenterWindow.currentView = "bluetooth"
                      actionCenterWindow.triggerBtScan()
                    } else {
                      actionCenterWindow.btEnabled = !actionCenterWindow.btEnabled
                      Quickshell.execDetached(["omarchy-bluetooth-dbus", actionCenterWindow.btEnabled ? "on" : "off"])
                    }
                  }
                }
              }

              // Divider between toggle & chevron
              Rectangle {
                width: 1
                height: 24
                color: actionCenterWindow.btEnabled ? Qt.rgba(1, 1, 1, 0.25) : actionCenterWindow.innerCardBorder
              }

              // Right part: chevron -> in-place Bluetooth menu
              Rectangle {
                implicitWidth: 32
                implicitHeight: 48
                color: btChevronMouse.containsMouse ? (actionCenterWindow.btEnabled ? Qt.rgba(1, 1, 1, 0.15) : actionCenterWindow.hoverBg) : "transparent"

                Text {
                  anchors.centerIn: parent
                  text: "›"
                  font.pixelSize: 15
                  font.bold: true
                  color: actionCenterWindow.btEnabled ? "#ffffff" : actionCenterWindow.textPrimary
                }

                MouseArea {
                  id: btChevronMouse
                  anchors.fill: parent
                  hoverEnabled: true
                  cursorShape: Qt.PointingHandCursor
                  onClicked: {
                    actionCenterWindow.currentView = "bluetooth"
                    actionCenterWindow.triggerBtScan()
                  }
                }
              }
            }
          }

          // Airplane Mode Toggle
          Rectangle {
            Layout.fillWidth: true
            implicitHeight: 48
            radius: 6
            color: actionCenterWindow.airplaneMode ? actionCenterWindow.accentColor : actionCenterWindow.innerCardBg
            border.color: actionCenterWindow.airplaneMode ? actionCenterWindow.accentBorder : actionCenterWindow.innerCardBorder
            border.width: 1

            RowLayout {
              anchors.fill: parent
              anchors.leftMargin: 10
              anchors.rightMargin: 8
              spacing: 8
              Text {
                text: "󰀝"
                font.pixelSize: 16
                color: actionCenterWindow.airplaneMode ? "#ffffff" : actionCenterWindow.textPrimary
              }
              ColumnLayout {
                Layout.fillWidth: true
                spacing: 0
                Text {
                  text: "Airplane mode"
                  font.family: "Segoe UI"
                  font.pixelSize: 11
                  font.bold: true
                  color: actionCenterWindow.airplaneMode ? "#ffffff" : actionCenterWindow.textPrimary
                }
                Text {
                  text: actionCenterWindow.airplaneMode ? "On" : "Off"
                  font.family: "Segoe UI"
                  font.pixelSize: 9
                  color: actionCenterWindow.airplaneMode ? Qt.rgba(1, 1, 1, 0.85) : actionCenterWindow.textSecondary
                }
              }
            }

            MouseArea {
              anchors.fill: parent
              cursorShape: Qt.PointingHandCursor
              onClicked: {
                actionCenterWindow.airplaneMode = !actionCenterWindow.airplaneMode
                actionCenterWindow.runCmd("rfkill " + (actionCenterWindow.airplaneMode ? "block all" : "unblock all"))
              }
            }
          }

          // Battery Saver Toggle
          Rectangle {
            Layout.fillWidth: true
            implicitHeight: 48
            radius: 6
            color: actionCenterWindow.batterySaverEnabled ? actionCenterWindow.accentColor : actionCenterWindow.innerCardBg
            border.color: actionCenterWindow.batterySaverEnabled ? actionCenterWindow.accentBorder : actionCenterWindow.innerCardBorder
            border.width: 1

            RowLayout {
              anchors.fill: parent
              anchors.leftMargin: 10
              anchors.rightMargin: 8
              spacing: 8
              Text {
                text: "󰂎"
                font.pixelSize: 16
                color: actionCenterWindow.batterySaverEnabled ? "#ffffff" : actionCenterWindow.textPrimary
              }
              ColumnLayout {
                Layout.fillWidth: true
                spacing: 0
                Text {
                  text: "Battery saver"
                  font.family: "Segoe UI"
                  font.pixelSize: 11
                  font.bold: true
                  color: actionCenterWindow.batterySaverEnabled ? "#ffffff" : actionCenterWindow.textPrimary
                }
                Text {
                  text: actionCenterWindow.batterySaverEnabled ? "Active" : "Off"
                  font.family: "Segoe UI"
                  font.pixelSize: 9
                  color: actionCenterWindow.batterySaverEnabled ? Qt.rgba(1, 1, 1, 0.85) : actionCenterWindow.textSecondary
                }
              }
            }

            MouseArea {
              anchors.fill: parent
              cursorShape: Qt.PointingHandCursor
              onClicked: {
                actionCenterWindow.batterySaverEnabled = !actionCenterWindow.batterySaverEnabled
                actionCenterWindow.runCmd("powerprofilesctl set " + (actionCenterWindow.batterySaverEnabled ? "power-saver" : "balanced") + " 2>/dev/null || true")
              }
            }
          }

          // Night Light Toggle
          Rectangle {
            Layout.fillWidth: true
            implicitHeight: 48
            radius: 6
            color: actionCenterWindow.nightLightEnabled ? actionCenterWindow.accentColor : actionCenterWindow.innerCardBg
            border.color: actionCenterWindow.nightLightEnabled ? actionCenterWindow.accentBorder : actionCenterWindow.innerCardBorder
            border.width: 1

            RowLayout {
              anchors.fill: parent
              anchors.leftMargin: 10
              anchors.rightMargin: 8
              spacing: 8
              Text {
                text: "󰖔"
                font.pixelSize: 16
                color: actionCenterWindow.nightLightEnabled ? "#ffffff" : actionCenterWindow.textPrimary
              }
              ColumnLayout {
                Layout.fillWidth: true
                spacing: 0
                Text {
                  text: "Night light"
                  font.family: "Segoe UI"
                  font.pixelSize: 11
                  font.bold: true
                  color: actionCenterWindow.nightLightEnabled ? "#ffffff" : actionCenterWindow.textPrimary
                }
                Text {
                  text: actionCenterWindow.nightLightEnabled ? "On" : "Off"
                  font.family: "Segoe UI"
                  font.pixelSize: 9
                  color: actionCenterWindow.nightLightEnabled ? Qt.rgba(1, 1, 1, 0.85) : actionCenterWindow.textSecondary
                }
              }
            }

            MouseArea {
              anchors.fill: parent
              cursorShape: Qt.PointingHandCursor
              onClicked: {
                actionCenterWindow.nightLightEnabled = !actionCenterWindow.nightLightEnabled
                actionCenterWindow.runCmd("omarchy toggle nightlight 2>/dev/null || hyprshade toggle blue-light-filter 2>/dev/null || true")
              }
            }
          }

          // Accessibility Toggle
          Rectangle {
            Layout.fillWidth: true
            implicitHeight: 48
            radius: 6
            color: actionCenterWindow.innerCardBg
            border.color: actionCenterWindow.innerCardBorder
            border.width: 1

            RowLayout {
              anchors.fill: parent
              anchors.leftMargin: 10
              anchors.rightMargin: 8
              spacing: 8
              Text {
                text: "󰌵"
                font.pixelSize: 16
                color: actionCenterWindow.textPrimary
              }
              ColumnLayout {
                Layout.fillWidth: true
                spacing: 0
                Text {
                  text: "Accessibility"
                  font.family: "Segoe UI"
                  font.pixelSize: 11
                  font.bold: true
                  color: actionCenterWindow.textPrimary
                }
                Text {
                  text: "Standard"
                  font.family: "Segoe UI"
                  font.pixelSize: 9
                  color: actionCenterWindow.textSecondary
                }
              }
            }

            MouseArea {
              anchors.fill: parent
              cursorShape: Qt.PointingHandCursor
              onClicked: actionCenterWindow.runCmd("omarchy-undercover-settings")
            }
          }
        }

        // 2. Brightness Slider
        RowLayout {
          Layout.fillWidth: true
          spacing: 10

          Text { text: "󰃠"; font.pixelSize: 16; color: actionCenterWindow.textPrimary }

          Rectangle {
            Layout.fillWidth: true
            height: 18
            radius: 9
            color: actionCenterWindow.isDark ? Qt.rgba(1, 1, 1, 0.12) : Qt.rgba(0, 0, 0, 0.08)
            clip: true

            Rectangle {
              width: parent.width * (actionCenterWindow.brightnessVal / 100.0)
              height: parent.height
              radius: 9
              color: actionCenterWindow.isDark ? "#60cdff" : "#0067c0"
            }

            MouseArea {
              anchors.fill: parent
              cursorShape: Qt.PointingHandCursor
              onPositionChanged: function(mouse) {
                var p = Math.max(5, Math.min(100, Math.round((mouse.x / width) * 100)))
                actionCenterWindow.brightnessVal = p
                actionCenterWindow.runCmd("brightnessctl set " + p + "% >/dev/null 2>&1")
              }
              onClicked: function(mouse) {
                var p = Math.max(5, Math.min(100, Math.round((mouse.x / width) * 100)))
                actionCenterWindow.brightnessVal = p
                actionCenterWindow.runCmd("brightnessctl set " + p + "% >/dev/null 2>&1")
              }
            }
          }

          Text {
            text: actionCenterWindow.brightnessVal + "%"
            font.family: "Segoe UI"
            font.pixelSize: 10
            color: actionCenterWindow.textSecondary
          }
        }

        // 3. Volume Slider
        RowLayout {
          Layout.fillWidth: true
          spacing: 10

          Text { text: "󰕾"; font.pixelSize: 16; color: actionCenterWindow.textPrimary }

          Rectangle {
            Layout.fillWidth: true
            height: 18
            radius: 9
            color: actionCenterWindow.isDark ? Qt.rgba(1, 1, 1, 0.12) : Qt.rgba(0, 0, 0, 0.08)
            clip: true

            Rectangle {
              width: parent.width * (actionCenterWindow.volumeVal / 100.0)
              height: parent.height
              radius: 9
              color: actionCenterWindow.isDark ? "#60cdff" : "#0067c0"
            }

            MouseArea {
              anchors.fill: parent
              cursorShape: Qt.PointingHandCursor
              onPositionChanged: function(mouse) {
                var p = Math.max(0, Math.min(100, Math.round((mouse.x / width) * 100)))
                actionCenterWindow.volumeVal = p
                actionCenterWindow.runCmd("wpctl set-volume @DEFAULT_AUDIO_SINK@ " + (p / 100.0) + " >/dev/null 2>&1")
              }
              onClicked: function(mouse) {
                var p = Math.max(0, Math.min(100, Math.round((mouse.x / width) * 100)))
                actionCenterWindow.volumeVal = p
                actionCenterWindow.runCmd("wpctl set-volume @DEFAULT_AUDIO_SINK@ " + (p / 100.0) + " >/dev/null 2>&1")
              }
            }
          }

          Text {
            text: actionCenterWindow.volumeVal + "%"
            font.family: "Segoe UI"
            font.pixelSize: 10
            color: actionCenterWindow.textSecondary
          }
        }

        // 4. Microphone Slider
        RowLayout {
          Layout.fillWidth: true
          spacing: 10

          Text { text: actionCenterWindow.micMuted ? "󰍭" : "󰍬"; font.pixelSize: 16; color: actionCenterWindow.textPrimary }

          Rectangle {
            Layout.fillWidth: true
            height: 18
            radius: 9
            color: actionCenterWindow.isDark ? Qt.rgba(1, 1, 1, 0.12) : Qt.rgba(0, 0, 0, 0.08)
            clip: true

            Rectangle {
              width: parent.width * (actionCenterWindow.micVal / 100.0)
              height: parent.height
              radius: 9
              color: actionCenterWindow.micMuted
                     ? (actionCenterWindow.isDark ? Qt.rgba(1, 1, 1, 0.35) : Qt.rgba(0, 0, 0, 0.35))
                     : (actionCenterWindow.isDark ? "#60cdff" : "#0067c0")
            }

            MouseArea {
              anchors.fill: parent
              cursorShape: Qt.PointingHandCursor
              onPositionChanged: function(mouse) {
                var p = Math.max(0, Math.min(100, Math.round((mouse.x / width) * 100)))
                actionCenterWindow.micVal = p
                actionCenterWindow.micMuted = false
                actionCenterWindow.runCmd("wpctl set-mute @DEFAULT_AUDIO_SOURCE@ 0 && wpctl set-volume @DEFAULT_AUDIO_SOURCE@ " + (p / 100.0) + " >/dev/null 2>&1")
              }
              onClicked: function(mouse) {
                var p = Math.max(0, Math.min(100, Math.round((mouse.x / width) * 100)))
                actionCenterWindow.micVal = p
                actionCenterWindow.micMuted = false
                actionCenterWindow.runCmd("wpctl set-mute @DEFAULT_AUDIO_SOURCE@ 0 && wpctl set-volume @DEFAULT_AUDIO_SOURCE@ " + (p / 100.0) + " >/dev/null 2>&1")
              }
            }
          }

          Text {
            text: actionCenterWindow.micMuted ? "Muted" : actionCenterWindow.micVal + "%"
            font.family: "Segoe UI"
            font.pixelSize: 10
            color: actionCenterWindow.textSecondary
            MouseArea {
              visible: !actionCenterWindow.micMuted
              anchors.fill: parent
              cursorShape: Qt.PointingHandCursor
              onClicked: {
                actionCenterWindow.micMuted = true
                actionCenterWindow.runCmd("wpctl set-mute @DEFAULT_AUDIO_SOURCE@ 1")
              }
            }
          }
        }

        // 5. Footer Bar with Battery & Settings Gear
        Rectangle {
          Layout.fillWidth: true
          implicitHeight: 40
          radius: 6
          color: actionCenterWindow.isDark ? Qt.rgba(0, 0, 0, 0.28) : Qt.rgba(0, 0, 0, 0.04)

          RowLayout {
            anchors.fill: parent
            anchors.leftMargin: 10
            anchors.rightMargin: 10

            RowLayout {
              spacing: 6
              Text {
                text: actionCenterWindow.isCharging ? "󰂄" : "󰁹"
                font.pixelSize: 15
                color: actionCenterWindow.textPrimary
              }
              Text {
                text: actionCenterWindow.batteryPct + "%"
                font.family: "Segoe UI"
                font.pixelSize: 11
                font.bold: true
                color: actionCenterWindow.textPrimary
              }
            }

            Item { Layout.fillWidth: true }

            Text {
              text: "⚙"
              font.pixelSize: 16
              color: actionCenterWindow.textPrimary
              MouseArea {
                anchors.fill: parent
                cursorShape: Qt.PointingHandCursor
                onClicked: {
                  Qt.quit()
                  actionCenterWindow.runCmd("omarchy-undercover-settings")
                }
              }
            }
          }
        }
      }

      // ==========================================
      // VIEW 2: IN-PLACE WI-FI SUB-PAGE
      // ==========================================
      ColumnLayout {
        id: wifiSubView
        visible: actionCenterWindow.currentView === "wifi"
        anchors.fill: parent
        anchors.margins: 14
        spacing: 10

        // Header Row
        RowLayout {
          Layout.fillWidth: true
          implicitHeight: 30
          spacing: 8

          Rectangle {
            implicitWidth: 28
            implicitHeight: 28
            radius: 6
            color: wifiBackMouse.containsMouse ? actionCenterWindow.hoverBg : "transparent"
            Text {
              anchors.centerIn: parent
              text: "←"
              font.pixelSize: 14
              font.bold: true
              color: actionCenterWindow.textPrimary
            }
            MouseArea {
              id: wifiBackMouse
              anchors.fill: parent
              hoverEnabled: true
              cursorShape: Qt.PointingHandCursor
              onClicked: actionCenterWindow.currentView = "main"
            }
          }

          Text {
            text: "Wi-Fi"
            font.family: "Segoe UI, sans-serif"
            font.pixelSize: 14
            font.bold: true
            color: actionCenterWindow.textPrimary
            Layout.fillWidth: true
          }

          Rectangle {
            implicitWidth: 28
            implicitHeight: 28
            radius: 6
            color: wifiScanMouse.containsMouse ? actionCenterWindow.hoverBg : "transparent"
            Text {
              anchors.centerIn: parent
              text: "🔄"
              font.pixelSize: 12
              color: actionCenterWindow.textPrimary
              opacity: actionCenterWindow.isScanningWifi ? 0.4 : 1.0
            }
            MouseArea {
              id: wifiScanMouse
              anchors.fill: parent
              hoverEnabled: true
              cursorShape: Qt.PointingHandCursor
              onClicked: actionCenterWindow.triggerWifiScan()
            }
          }

          Rectangle {
            implicitWidth: 28
            implicitHeight: 28
            radius: 6
            color: wifiCloseMouse.containsMouse ? Qt.rgba(196, 43, 28, 0.16) : "transparent"
            Text {
              anchors.centerIn: parent
              text: "✕"
              font.pixelSize: 12
              color: wifiCloseMouse.containsMouse ? "#c42b1c" : actionCenterWindow.textPrimary
            }
            MouseArea {
              id: wifiCloseMouse
              anchors.fill: parent
              hoverEnabled: true
              cursorShape: Qt.PointingHandCursor
              onClicked: Qt.quit()
            }
          }
        }

        // Wi-Fi Power Switch Card
        Rectangle {
          Layout.fillWidth: true
          implicitHeight: 44
          radius: 8
          color: actionCenterWindow.innerCardBg
          border.color: actionCenterWindow.innerCardBorder
          border.width: 1

          RowLayout {
            anchors.fill: parent
            anchors.leftMargin: 12
            anchors.rightMargin: 12

            ColumnLayout {
              spacing: 1
              Layout.fillWidth: true
              Text {
                text: "Wi-Fi"
                font.family: "Segoe UI, sans-serif"
                font.pixelSize: 12
                font.bold: true
                color: actionCenterWindow.textPrimary
              }
              Text {
                text: actionCenterWindow.wifiEnabled ? "Enabled" : "Disabled"
                font.family: "Segoe UI, sans-serif"
                font.pixelSize: 10
                color: actionCenterWindow.textSecondary
              }
            }

            Rectangle {
              implicitWidth: 42
              implicitHeight: 20
              radius: 10
              color: actionCenterWindow.wifiEnabled ? actionCenterWindow.accentColor : Qt.rgba(0.5, 0.5, 0.5, 0.4)

              Rectangle {
                anchors.verticalCenter: parent.verticalCenter
                x: actionCenterWindow.wifiEnabled ? parent.width - width - 2 : 2
                implicitWidth: 16
                implicitHeight: 16
                radius: 8
                color: "#ffffff"
                Behavior on x { NumberAnimation { duration: 150; easing.type: Easing.OutCubic } }
              }

              MouseArea {
                anchors.fill: parent
                cursorShape: Qt.PointingHandCursor
                onClicked: {
                  var target = !actionCenterWindow.wifiEnabled
                  actionCenterWindow.wifiEnabled = target
                  Quickshell.execDetached(["omarchy-wifi-dbus", target ? "on" : "off"])
                  actionCenterWindow.triggerWifiScan()
                }
              }
            }
          }
        }

        // Search Bar
        Rectangle {
          visible: actionCenterWindow.wifiEnabled
          Layout.fillWidth: true
          implicitHeight: 32
          radius: 6
          color: actionCenterWindow.innerCardBg
          border.color: actionCenterWindow.innerCardBorder
          border.width: 1

          RowLayout {
            anchors.fill: parent
            anchors.leftMargin: 8
            anchors.rightMargin: 8
            spacing: 6

            Text { text: "🔍"; font.pixelSize: 10; color: actionCenterWindow.textMuted }

            TextInput {
              id: acWifiSearch
              Layout.fillWidth: true
              color: actionCenterWindow.textPrimary
              font.family: "Segoe UI, sans-serif"
              font.pixelSize: 11
              clip: true
              onTextChanged: actionCenterWindow.wifiSearchText = text

              Text {
                text: "Search Wi-Fi networks..."
                color: actionCenterWindow.textMuted
                font: acWifiSearch.font
                visible: !acWifiSearch.text && !acWifiSearch.activeFocus
              }
            }

            Rectangle {
              visible: acWifiSearch.text.length > 0
              implicitWidth: 16
              implicitHeight: 16
              radius: 8
              color: actionCenterWindow.isDark ? Qt.rgba(1, 1, 1, 0.16) : Qt.rgba(0, 0, 0, 0.08)
              Text { anchors.centerIn: parent; text: "✕"; font.pixelSize: 8; color: actionCenterWindow.textPrimary }
              MouseArea {
                anchors.fill: parent
                cursorShape: Qt.PointingHandCursor
                onClicked: {
                  acWifiSearch.text = ""
                  actionCenterWindow.wifiSearchText = ""
                }
              }
            }
          }
        }

        // Active Connected Banner
        Rectangle {
          visible: actionCenterWindow.wifiSsid.length > 0 && actionCenterWindow.wifiSsid !== "Connected" && actionCenterWindow.wifiEnabled
          Layout.fillWidth: true
          implicitHeight: 46
          radius: 6
          color: actionCenterWindow.isDark ? Qt.rgba(0, 120, 212, 0.18) : Qt.rgba(0, 103, 192, 0.08)
          border.color: actionCenterWindow.isDark ? "#60cdff" : Qt.rgba(0, 103, 192, 0.35)
          border.width: 1

          RowLayout {
            anchors.fill: parent
            anchors.leftMargin: 10
            anchors.rightMargin: 10
            spacing: 8

            Text { text: "󰤨"; font.pixelSize: 18; color: actionCenterWindow.accentColor }

            ColumnLayout {
              spacing: 1
              Layout.fillWidth: true
              Text {
                text: actionCenterWindow.wifiSsid
                font.family: "Segoe UI, sans-serif"
                font.pixelSize: 11
                font.bold: true
                color: actionCenterWindow.textPrimary
                elide: Text.ElideRight
              }
              Text {
                text: "Connected, secured"
                font.family: "Segoe UI, sans-serif"
                font.pixelSize: 9
                color: actionCenterWindow.textSecondary
              }
            }

            Rectangle {
              implicitWidth: 76
              implicitHeight: 24
              radius: 4
              color: disWifiMouse.containsMouse ? (actionCenterWindow.isDark ? "#d83b01" : "#c42b1c") : (actionCenterWindow.isDark ? Qt.rgba(255, 95, 86, 0.16) : Qt.rgba(196, 43, 28, 0.08))
              border.color: disWifiMouse.containsMouse ? "transparent" : (actionCenterWindow.isDark ? Qt.rgba(255, 95, 86, 0.35) : Qt.rgba(196, 43, 28, 0.35))
              border.width: 1

              Text {
                anchors.centerIn: parent
                text: "Disconnect"
                font.family: "Segoe UI, sans-serif"
                font.pixelSize: 10
                font.bold: true
                color: disWifiMouse.containsMouse ? "#ffffff" : (actionCenterWindow.isDark ? "#ff7b72" : "#c42b1c")
              }
              MouseArea {
                id: disWifiMouse
                anchors.fill: parent
                hoverEnabled: true
                cursorShape: Qt.PointingHandCursor
                onClicked: {
                  Quickshell.execDetached(["omarchy-wifi-dbus", "disconnect"])
                  actionCenterWindow.wifiSsid = "Disconnected"
                  actionCenterWindow.triggerWifiScan()
                }
              }
            }
          }
        }

        // Section Title
        RowLayout {
          visible: actionCenterWindow.wifiEnabled
          Layout.fillWidth: true
          Text {
            text: actionCenterWindow.wifiSearchText.length > 0
              ? "Search Results (" + actionCenterWindow.filteredNetworks.length + ")"
              : "Available Networks"
            font.family: "Segoe UI, sans-serif"
            font.pixelSize: 11
            font.bold: true
            color: actionCenterWindow.textPrimary
            Layout.fillWidth: true
          }
          Text {
            visible: actionCenterWindow.isScanningWifi
            text: "Scanning..."
            font.family: "Segoe UI, sans-serif"
            font.pixelSize: 10
            color: actionCenterWindow.accentColor
          }
        }

        // Networks List
        ScrollView {
          visible: actionCenterWindow.wifiEnabled
          Layout.fillWidth: true
          Layout.fillHeight: true
          clip: true

          ListView {
            id: acWifiList
            width: parent.width
            model: actionCenterWindow.filteredNetworks
            spacing: 3

            delegate: ColumnLayout {
              width: acWifiList.width
              spacing: 3

              Rectangle {
                Layout.fillWidth: true
                implicitHeight: 38
                radius: 5
                color: modelData.inUse
                  ? (actionCenterWindow.isDark ? Qt.rgba(0, 120, 212, 0.16) : Qt.rgba(0, 103, 192, 0.08))
                  : (acNetRowMouse.containsMouse ? actionCenterWindow.hoverBg : "transparent")
                border.color: modelData.inUse ? (actionCenterWindow.isDark ? Qt.rgba(96, 205, 255, 0.30) : Qt.rgba(0, 103, 192, 0.20)) : "transparent"
                border.width: modelData.inUse ? 1 : 0

                RowLayout {
                  anchors.fill: parent
                  anchors.leftMargin: 8
                  anchors.rightMargin: 8
                  spacing: 8

                  Text {
                    text: actionCenterWindow.getSignalIcon(modelData.signal)
                    font.pixelSize: 15
                    color: modelData.inUse ? actionCenterWindow.accentColor : actionCenterWindow.textPrimary
                  }

                  Text {
                    text: modelData.ssid
                    font.family: "Segoe UI, sans-serif"
                    font.pixelSize: 11
                    font.bold: modelData.inUse
                    color: actionCenterWindow.textPrimary
                    elide: Text.ElideRight
                    Layout.fillWidth: true
                  }

                  Rectangle {
                    visible: modelData.inUse
                    implicitWidth: 58
                    implicitHeight: 18
                    radius: 9
                    color: actionCenterWindow.isDark ? Qt.rgba(0, 120, 212, 0.25) : Qt.rgba(0, 103, 192, 0.12)
                    Text {
                      anchors.centerIn: parent
                      text: "Connected"
                      font.family: "Segoe UI, sans-serif"
                      font.pixelSize: 9
                      font.bold: true
                      color: actionCenterWindow.accentColor
                    }
                  }

                  Text {
                    visible: modelData.isSecured && !modelData.inUse
                    text: "🔒"
                    font.pixelSize: 10
                    color: actionCenterWindow.textSecondary
                  }
                }

                MouseArea {
                  id: acNetRowMouse
                  anchors.fill: parent
                  hoverEnabled: true
                  cursorShape: Qt.PointingHandCursor
                  onClicked: {
                    if (modelData.inUse) return
                    if (modelData.isSecured) {
                      actionCenterWindow.connectingSsid = (actionCenterWindow.connectingSsid === modelData.ssid ? "" : modelData.ssid)
                      actionCenterWindow.wifiPasswordInput = ""
                    } else {
                      actionCenterWindow.connectWifi(modelData.ssid, "")
                      actionCenterWindow.triggerWifiScan()
                    }
                  }
                }
              }

              // Inline Password Input Panel
              Rectangle {
                visible: actionCenterWindow.connectingSsid === modelData.ssid
                Layout.fillWidth: true
                implicitHeight: 52
                radius: 5
                color: actionCenterWindow.innerCardBg
                border.color: actionCenterWindow.innerCardBorder
                border.width: 1

                RowLayout {
                  anchors.fill: parent
                  anchors.margins: 6
                  spacing: 6

                  Rectangle {
                    Layout.fillWidth: true
                    implicitHeight: 28
                    radius: 4
                    color: actionCenterWindow.isDark ? Qt.rgba(0, 0, 0, 0.40) : "#ffffff"
                    border.color: actionCenterWindow.isDark ? Qt.rgba(1, 1, 1, 0.20) : Qt.rgba(0, 0, 0, 0.18)
                    border.width: 1

                    TextInput {
                      id: acPwInput
                      anchors.fill: parent
                      anchors.leftMargin: 6
                      anchors.rightMargin: 6
                      echoMode: TextInput.Password
                      font.pixelSize: 11
                      color: actionCenterWindow.textPrimary
                      selectByMouse: true
                      onTextChanged: actionCenterWindow.wifiPasswordInput = text
                      onAccepted: {
                        actionCenterWindow.connectWifi(modelData.ssid, acPwInput.text)
                        acPwInput.text = ""
                        actionCenterWindow.connectingSsid = ""
                        actionCenterWindow.triggerWifiScan()
                      }
                    }
                  }

                  Rectangle {
                    implicitWidth: 64
                    implicitHeight: 28
                    radius: 4
                    color: actionCenterWindow.accentColor
                    Text {
                      anchors.centerIn: parent
                      text: "Connect"
                      color: "#ffffff"
                      font.family: "Segoe UI, sans-serif"
                      font.pixelSize: 10
                      font.bold: true
                    }
                    MouseArea {
                      anchors.fill: parent
                      cursorShape: Qt.PointingHandCursor
                      onClicked: {
                        actionCenterWindow.connectWifi(modelData.ssid, acPwInput.text)
                        acPwInput.text = ""
                        actionCenterWindow.connectingSsid = ""
                        actionCenterWindow.triggerWifiScan()
                      }
                    }
                  }
                }
              }
            }
          }
        }

        // Wi-Fi Settings Link Footer
        Rectangle {
          Layout.fillWidth: true
          implicitHeight: 30
          radius: 5
          color: acWifiSettingsM.containsMouse ? actionCenterWindow.hoverBg : "transparent"
          RowLayout {
            anchors.centerIn: parent
            spacing: 6
            Text { text: "⚙️"; font.pixelSize: 11 }
            Text {
              text: "More Wi-Fi settings"
              font.family: "Segoe UI, sans-serif"
              font.pixelSize: 10
              font.bold: true
              color: actionCenterWindow.accentColor
            }
          }
          MouseArea {
            id: acWifiSettingsM
            anchors.fill: parent
            hoverEnabled: true
            cursorShape: Qt.PointingHandCursor
            onClicked: {
              Qt.quit()
              actionCenterWindow.runCmd("nm-connection-editor || omarchy-undercover-settings")
            }
          }
        }
      }

      // ==========================================
      // VIEW 3: IN-PLACE BLUETOOTH SUB-PAGE
      // ==========================================
      ColumnLayout {
        id: btSubView
        visible: actionCenterWindow.currentView === "bluetooth"
        anchors.fill: parent
        anchors.margins: 14
        spacing: 10

        // Header Row
        RowLayout {
          Layout.fillWidth: true
          implicitHeight: 30
          spacing: 8

          Rectangle {
            implicitWidth: 28
            implicitHeight: 28
            radius: 6
            color: btBackMouse.containsMouse ? actionCenterWindow.hoverBg : "transparent"
            Text {
              anchors.centerIn: parent
              text: "←"
              font.pixelSize: 14
              font.bold: true
              color: actionCenterWindow.textPrimary
            }
            MouseArea {
              id: btBackMouse
              anchors.fill: parent
              hoverEnabled: true
              cursorShape: Qt.PointingHandCursor
              onClicked: actionCenterWindow.currentView = "main"
            }
          }

          Text {
            text: "Bluetooth"
            font.family: "Segoe UI, sans-serif"
            font.pixelSize: 14
            font.bold: true
            color: actionCenterWindow.textPrimary
            Layout.fillWidth: true
          }

          Rectangle {
            implicitWidth: 28
            implicitHeight: 28
            radius: 6
            color: btScanMouse.containsMouse ? actionCenterWindow.hoverBg : "transparent"
            Text {
              anchors.centerIn: parent
              text: "🔄"
              font.pixelSize: 12
              color: actionCenterWindow.textPrimary
              opacity: actionCenterWindow.isScanningBt ? 0.4 : 1.0
            }
            MouseArea {
              id: btScanMouse
              anchors.fill: parent
              hoverEnabled: true
              cursorShape: Qt.PointingHandCursor
              onClicked: actionCenterWindow.triggerBtScan()
            }
          }

          Rectangle {
            implicitWidth: 28
            implicitHeight: 28
            radius: 6
            color: btCloseMouse.containsMouse ? Qt.rgba(196, 43, 28, 0.16) : "transparent"
            Text {
              anchors.centerIn: parent
              text: "✕"
              font.pixelSize: 12
              color: btCloseMouse.containsMouse ? "#c42b1c" : actionCenterWindow.textPrimary
            }
            MouseArea {
              id: btCloseMouse
              anchors.fill: parent
              hoverEnabled: true
              cursorShape: Qt.PointingHandCursor
              onClicked: Qt.quit()
            }
          }
        }

        // Bluetooth Power Switch Card
        Rectangle {
          Layout.fillWidth: true
          implicitHeight: 44
          radius: 8
          color: actionCenterWindow.innerCardBg
          border.color: actionCenterWindow.innerCardBorder
          border.width: 1

          RowLayout {
            anchors.fill: parent
            anchors.leftMargin: 12
            anchors.rightMargin: 12

            ColumnLayout {
              spacing: 1
              Layout.fillWidth: true
              Text {
                text: "Bluetooth"
                font.family: "Segoe UI, sans-serif"
                font.pixelSize: 12
                font.bold: true
                color: actionCenterWindow.textPrimary
              }
              Text {
                text: actionCenterWindow.btEnabled ? "Discoverable and active" : "Turned off"
                font.family: "Segoe UI, sans-serif"
                font.pixelSize: 10
                color: actionCenterWindow.textSecondary
              }
            }

            Rectangle {
              implicitWidth: 42
              implicitHeight: 20
              radius: 10
              color: actionCenterWindow.btEnabled ? actionCenterWindow.accentColor : Qt.rgba(0.5, 0.5, 0.5, 0.4)

              Rectangle {
                anchors.verticalCenter: parent.verticalCenter
                x: actionCenterWindow.btEnabled ? parent.width - width - 2 : 2
                implicitWidth: 16
                implicitHeight: 16
                radius: 8
                color: "#ffffff"
                Behavior on x { NumberAnimation { duration: 150; easing.type: Easing.OutCubic } }
              }

              MouseArea {
                anchors.fill: parent
                cursorShape: Qt.PointingHandCursor
                onClicked: {
                  var target = !actionCenterWindow.btEnabled
                  actionCenterWindow.btEnabled = target
                  Quickshell.execDetached(["omarchy-bluetooth-dbus", target ? "on" : "off"])
                  actionCenterWindow.triggerBtScan()
                }
              }
            }
          }
        }

        // Search Bar
        Rectangle {
          visible: actionCenterWindow.btEnabled
          Layout.fillWidth: true
          implicitHeight: 32
          radius: 6
          color: actionCenterWindow.innerCardBg
          border.color: actionCenterWindow.innerCardBorder
          border.width: 1

          RowLayout {
            anchors.fill: parent
            anchors.leftMargin: 8
            anchors.rightMargin: 8
            spacing: 6

            Text { text: "🔍"; font.pixelSize: 10; color: actionCenterWindow.textMuted }

            TextInput {
              id: acBtSearch
              Layout.fillWidth: true
              color: actionCenterWindow.textPrimary
              font.family: "Segoe UI, sans-serif"
              font.pixelSize: 11
              clip: true
              onTextChanged: actionCenterWindow.btSearchText = text

              Text {
                text: "Search Bluetooth devices..."
                color: actionCenterWindow.textMuted
                font: acBtSearch.font
                visible: !acBtSearch.text && !acBtSearch.activeFocus
              }
            }

            Rectangle {
              visible: acBtSearch.text.length > 0
              implicitWidth: 16
              implicitHeight: 16
              radius: 8
              color: actionCenterWindow.isDark ? Qt.rgba(1, 1, 1, 0.16) : Qt.rgba(0, 0, 0, 0.08)
              Text { anchors.centerIn: parent; text: "✕"; font.pixelSize: 8; color: actionCenterWindow.textPrimary }
              MouseArea {
                anchors.fill: parent
                cursorShape: Qt.PointingHandCursor
                onClicked: {
                  acBtSearch.text = ""
                  actionCenterWindow.btSearchText = ""
                }
              }
            }
          }
        }

        // Section Title
        RowLayout {
          visible: actionCenterWindow.btEnabled
          Layout.fillWidth: true
          Text {
            text: actionCenterWindow.btSearchText.length > 0
              ? "Search Results (" + actionCenterWindow.filteredBtDevices.length + ")"
              : "Paired & Available Devices"
            font.family: "Segoe UI, sans-serif"
            font.pixelSize: 11
            font.bold: true
            color: actionCenterWindow.textPrimary
            Layout.fillWidth: true
          }
          Text {
            visible: actionCenterWindow.isScanningBt
            text: "Scanning..."
            font.family: "Segoe UI, sans-serif"
            font.pixelSize: 10
            color: actionCenterWindow.accentColor
          }
        }

        // Devices List
        ScrollView {
          visible: actionCenterWindow.btEnabled
          Layout.fillWidth: true
          Layout.fillHeight: true
          clip: true

          ListView {
            id: acBtList
            width: parent.width
            model: actionCenterWindow.filteredBtDevices
            spacing: 3

            delegate: Rectangle {
              width: acBtList.width
              implicitHeight: 44
              radius: 5
              color: modelData.connected
                ? (actionCenterWindow.isDark ? Qt.rgba(0, 120, 212, 0.16) : Qt.rgba(0, 103, 192, 0.08))
                : (acDevRowMouse.containsMouse ? actionCenterWindow.hoverBg : "transparent")
              border.color: modelData.connected ? (actionCenterWindow.isDark ? Qt.rgba(96, 205, 255, 0.30) : Qt.rgba(0, 103, 192, 0.20)) : "transparent"
              border.width: modelData.connected ? 1 : 0

              RowLayout {
                anchors.fill: parent
                anchors.leftMargin: 8
                anchors.rightMargin: 8
                spacing: 8

                Text { text: modelData.type; font.pixelSize: 16 }

                ColumnLayout {
                  spacing: 1
                  Layout.fillWidth: true
                  RowLayout {
                    spacing: 4
                    Text {
                      text: modelData.name
                      font.family: "Segoe UI, sans-serif"
                      font.pixelSize: 11
                      font.bold: modelData.connected
                      color: actionCenterWindow.textPrimary
                      elide: Text.ElideRight
                      Layout.maximumWidth: 150
                    }
                    Rectangle {
                      visible: modelData.connected
                      implicitWidth: 54
                      implicitHeight: 16
                      radius: 8
                      color: actionCenterWindow.isDark ? Qt.rgba(0, 120, 212, 0.25) : Qt.rgba(0, 103, 192, 0.12)
                      Text {
                        anchors.centerIn: parent
                        text: "Connected"
                        font.family: "Segoe UI, sans-serif"
                        font.pixelSize: 8
                        font.bold: true
                        color: actionCenterWindow.accentColor
                      }
                    }
                  }
                  Text {
                    text: modelData.mac
                    font.family: "Segoe UI, sans-serif"
                    font.pixelSize: 9
                    color: actionCenterWindow.textMuted
                  }
                }

                Rectangle {
                  implicitWidth: 70
                  implicitHeight: 24
                  radius: 4
                  color: modelData.connected
                    ? (acBtnConnM.containsMouse ? (actionCenterWindow.isDark ? "#d83b01" : "#c42b1c") : (actionCenterWindow.isDark ? Qt.rgba(255, 95, 86, 0.16) : Qt.rgba(196, 43, 28, 0.08)))
                    : (acBtnConnM.containsMouse ? actionCenterWindow.accentColor : actionCenterWindow.innerCardBg)
                  border.color: acBtnConnM.containsMouse ? "transparent" : (modelData.connected ? (actionCenterWindow.isDark ? Qt.rgba(255, 95, 86, 0.35) : Qt.rgba(196, 43, 28, 0.35)) : actionCenterWindow.innerCardBorder)
                  border.width: 1

                  Text {
                    anchors.centerIn: parent
                    text: modelData.connected ? "Disconnect" : "Connect"
                    font.family: "Segoe UI, sans-serif"
                    font.pixelSize: 10
                    font.bold: true
                    color: acBtnConnM.containsMouse ? "#ffffff" : (modelData.connected ? (actionCenterWindow.isDark ? "#ff7b72" : "#c42b1c") : actionCenterWindow.accentColor)
                  }

                  MouseArea {
                    id: acBtnConnM
                    anchors.fill: parent
                    hoverEnabled: true
                    cursorShape: Qt.PointingHandCursor
                    onClicked: {
                      if (modelData.connected) {
                        Quickshell.execDetached(["omarchy-bluetooth-dbus", "disconnect", modelData.mac])
                      } else {
                        Quickshell.execDetached(["omarchy-bluetooth-dbus", "connect", modelData.mac])
                      }
                      actionCenterWindow.triggerBtScan()
                    }
                  }
                }
              }

              MouseArea {
                id: acDevRowMouse
                anchors.fill: parent
                hoverEnabled: true
                cursorShape: Qt.PointingHandCursor
                acceptedButtons: Qt.RightButton
                onClicked: {
                  if (modelData.connected) {
                    Quickshell.execDetached(["omarchy-bluetooth-dbus", "disconnect", modelData.mac])
                    actionCenterWindow.triggerBtScan()
                  }
                }
              }
            }
          }
        }

        // Bluetooth Settings Link Footer
        Rectangle {
          Layout.fillWidth: true
          implicitHeight: 30
          radius: 5
          color: acBtSettingsM.containsMouse ? actionCenterWindow.hoverBg : "transparent"
          RowLayout {
            anchors.centerIn: parent
            spacing: 6
            Text { text: "⚙️"; font.pixelSize: 11 }
            Text {
              text: "More Bluetooth settings"
              font.family: "Segoe UI, sans-serif"
              font.pixelSize: 10
              font.bold: true
              color: actionCenterWindow.accentColor
            }
          }
          MouseArea {
            id: acBtSettingsM
            anchors.fill: parent
            hoverEnabled: true
            cursorShape: Qt.PointingHandCursor
            onClicked: {
              Qt.quit()
              actionCenterWindow.runCmd("blueman-manager || omarchy-undercover-settings")
            }
          }
        }
      }
    }
  }
}

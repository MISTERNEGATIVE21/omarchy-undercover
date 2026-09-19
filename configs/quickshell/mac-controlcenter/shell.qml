import Quickshell
import Quickshell.Wayland
import Quickshell.Hyprland
import Quickshell.Io
import QtQuick
import QtQuick.Layouts
import QtQuick.Controls

ShellRoot {
  PanelWindow {
    id: controlCenterWindow
    screen: Quickshell.screens[0]

    anchors {
      top: true
      right: true
    }
    margins {
      top: 36
      right: 14
    }

    WlrLayershell.layer: WlrLayer.Overlay
    WlrLayershell.namespace: "omarchy-menu"
    WlrLayershell.keyboardFocus: WlrKeyboardFocus.OnDemand
    exclusiveZone: 0
    color: "transparent"

    implicitWidth: 360
    implicitHeight: 600

    property string homeDir: Quickshell.env("HOME")
    property bool isLight: false
    property string currentView: "main" // "main" | "wifi" | "bluetooth"

    // Hardware states
    property bool wifiOn: true
    property bool btOn: true
    property bool dndOn: false
    property int displayBrightness: 85
    property int masterVolume: 70
    property int micLevel: 70
    property bool micMuted: false
    property string wifiSsid: "Wi-Fi"
    property string btDeviceName: "Bluetooth"
    property string musicTitle: "No Track Playing"
    property string musicArtist: "Media Player"
    property bool musicPlaying: false

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

    readonly property var filteredNetworks: {
      var q = controlCenterWindow.wifiSearchText.toLowerCase().trim()
      var result = []
      for (var i = 0; i < controlCenterWindow.networks.length; i++) {
        var n = controlCenterWindow.networks[i]
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
      var q = controlCenterWindow.btSearchText.toLowerCase().trim()
      var result = []
      for (var i = 0; i < controlCenterWindow.btDevices.length; i++) {
        var d = controlCenterWindow.btDevices[i]
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

    function triggerWifiScan() {
      controlCenterWindow.isScanningWifi = true
      controlCenterWindow.networks = []
      if (!wifiScanPoller.running) wifiScanPoller.running = true
    }

    function triggerBtScan() {
      controlCenterWindow.isScanningBt = true
      controlCenterWindow.btDevices = []
      if (!btScanPoller.running) btScanPoller.running = true
    }

    Shortcut {
      sequence: "Escape"
      onActivated: {
        if (controlCenterWindow.currentView !== "main") {
          controlCenterWindow.currentView = "main"
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
        controlCenterWindow.triggerWifiScan()
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
      path: controlCenterWindow.homeDir + "/.config/omarchy-undercover/state"
      watchChanges: true
      onLoaded: {
        var s = text().trim()
        controlCenterWindow.isLight = (s.indexOf("light") !== -1)
      }
      onFileChanged: {
        reload()
        var s = text().trim()
        controlCenterWindow.isLight = (s.indexOf("light") !== -1)
      }
    }

    // Live Hardware State Poller
    Process {
      id: hwPoller
      command: [
        "bash", "-c",
        "wifi=$(nmcli radio wifi 2>/dev/null || echo 'disabled'); " +
        "bt=$(bluetoothctl show 2>/dev/null | grep -q 'Powered: yes' && echo '1' || echo '0'); " +
        "vol=$(wpctl get-volume @DEFAULT_AUDIO_SINK@ 2>/dev/null | awk '{print int($2*100)}' || echo '70'); " +
        "mic=$(wpctl get-volume @DEFAULT_AUDIO_SOURCE@ 2>/dev/null | awk '{print int($2*100)}' || echo '70'); " +
        "micmut=$(wpctl get-volume @DEFAULT_AUDIO_SOURCE@ 2>/dev/null | grep -qi 'MUTED' && echo '1' || echo '0'); " +
        "bri=$(brightnessctl -m 2>/dev/null | cut -d, -f4 | tr -d '%' || echo '85'); " +
        "ssid=$(nmcli -t -f active,ssid dev wifi 2>/dev/null | grep '^yes:' | cut -d: -f2 || echo 'Wi-Fi'); " +
        "track=$(playerctl metadata title 2>/dev/null || echo 'No Track Playing'); " +
        "artist=$(playerctl metadata artist 2>/dev/null || echo 'Media Player'); " +
        "mstatus=$(playerctl status 2>/dev/null || echo 'Stopped'); " +
        "echo \"$wifi|$bt|$vol|$bri|$ssid|$track|$artist|$mstatus|$mic|$micmut\""
      ]
      stdout: SplitParser {
        onRead: function(line) {
          if (!line) return
          var p = line.trim().split("|")
          if (p.length >= 10) {
            controlCenterWindow.wifiOn = (p[0].indexOf("enabled") !== -1)
            controlCenterWindow.btOn = (p[1] === "1")
            var v = parseInt(p[2]); if (!isNaN(v)) controlCenterWindow.masterVolume = Math.max(0, Math.min(100, v))
            var b = parseInt(p[3]); if (!isNaN(b)) controlCenterWindow.displayBrightness = Math.max(5, Math.min(100, b))
            if (p[4]) controlCenterWindow.wifiSsid = p[4]
            if (p[5]) controlCenterWindow.musicTitle = p[5]
            if (p[6]) controlCenterWindow.musicArtist = p[6]
            controlCenterWindow.musicPlaying = (p[7].toLowerCase() === "playing")
            var m = parseInt(p[8]); if (!isNaN(m)) controlCenterWindow.micLevel = Math.max(0, Math.min(100, m))
            controlCenterWindow.micMuted = (p[9] === "1")
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
              if (inUse) controlCenterWindow.wifiSsid = ssid
              var currentList = controlCenterWindow.networks.slice(0)
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
              controlCenterWindow.networks = currentList
            }
          }
        }
      }
      onExited: function() {
        controlCenterWindow.isScanningWifi = false
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
            var currentList = controlCenterWindow.btDevices.slice(0)
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
            controlCenterWindow.btDevices = currentList
          }
        }
      }
      onExited: function() {
        controlCenterWindow.isScanningBt = false
      }
    }

    Timer {
      interval: 2500
      running: true
      repeat: true
      triggeredOnStart: true
      onTriggered: {
        if (!hwPoller.running) hwPoller.running = true
      }
    }

    // Outer Frosted Glass Container
    Rectangle {
      id: bg
      anchors.fill: parent
      radius: 18
      color: controlCenterWindow.isLight ? Qt.rgba(0.96, 0.96, 0.98, 0.88) : Qt.rgba(0.12, 0.12, 0.16, 0.88)
      border.color: controlCenterWindow.isLight ? Qt.rgba(0, 0, 0, 0.10) : Qt.rgba(1, 1, 1, 0.18)
      border.width: 1
      clip: true

      // Top Specular Highlight
      Rectangle {
        anchors.left: parent.left
        anchors.right: parent.right
        anchors.top: parent.top
        anchors.leftMargin: 16
        anchors.rightMargin: 16
        height: 1
        color: Qt.rgba(1, 1, 1, 0.35)
      }

      // ==========================================
      // VIEW 1: MAIN CONTROL CENTER BENTO GRID
      // ==========================================
      ColumnLayout {
        id: mainBentoView
        visible: controlCenterWindow.currentView === "main"
        anchors.fill: parent
        anchors.margins: 14
        spacing: 12

        // Row 1: 2-Column Bento Grid
        RowLayout {
          Layout.fillWidth: true
          spacing: 12

          // Left Bento Box: Wi-Fi & Bluetooth
          Rectangle {
            Layout.fillWidth: true
            implicitHeight: 130
            radius: 14
            color: controlCenterWindow.isLight ? Qt.rgba(1, 1, 1, 0.90) : Qt.rgba(1, 1, 1, 0.08)
            border.color: controlCenterWindow.isLight ? Qt.rgba(0, 0, 0, 0.10) : Qt.rgba(1, 1, 1, 0.12)
            border.width: 1

            ColumnLayout {
              anchors.fill: parent
              anchors.margins: 12
              spacing: 8

              // Wi-Fi Row
              RowLayout {
                Layout.fillWidth: true
                spacing: 10

                Rectangle {
                  width: 34
                  height: 34
                  radius: 17
                  color: controlCenterWindow.wifiOn ? "#007aff" : (controlCenterWindow.isLight ? Qt.rgba(0, 0, 0, 0.08) : Qt.rgba(1, 1, 1, 0.14))

                  Text {
                    anchors.centerIn: parent
                    text: "󰤨"
                    font.pixelSize: 16
                    color: controlCenterWindow.wifiOn ? "#ffffff" : (controlCenterWindow.isLight ? "#1d1d1f" : "#ffffff")
                  }

                  MouseArea {
                    anchors.fill: parent
                    cursorShape: Qt.PointingHandCursor
                    onClicked: {
                      controlCenterWindow.wifiOn = !controlCenterWindow.wifiOn
                      Quickshell.execDetached(["omarchy-wifi-dbus", controlCenterWindow.wifiOn ? "on" : "off"])
                    }
                  }
                }

                Item {
                  Layout.fillWidth: true
                  Layout.fillHeight: true

                  ColumnLayout {
                    anchors.fill: parent
                    spacing: 1

                    Text {
                      text: "Wi-Fi"
                      font.family: "SF Pro Text, -apple-system, sans-serif"
                      font.pixelSize: 12
                      font.bold: true
                      color: controlCenterWindow.isLight ? "#1d1d1f" : "#ffffff"
                    }
                    Text {
                      text: controlCenterWindow.wifiOn ? controlCenterWindow.wifiSsid : "Off"
                      font.family: "SF Pro Text, -apple-system, sans-serif"
                      font.pixelSize: 10
                      color: controlCenterWindow.isLight ? "#515154" : Qt.rgba(1, 1, 1, 0.72)
                      elide: Text.ElideRight
                      Layout.fillWidth: true
                    }
                  }

                  MouseArea {
                    anchors.fill: parent
                    cursorShape: Qt.PointingHandCursor
                    onClicked: {
                      controlCenterWindow.currentView = "wifi"
                      controlCenterWindow.triggerWifiScan()
                    }
                  }
                }

                // In-place chevron navigation
                Text {
                  text: "›"
                  font.pixelSize: 18
                  color: controlCenterWindow.isLight ? Qt.rgba(0, 0, 0, 0.4) : Qt.rgba(1, 1, 1, 0.4)
                  MouseArea {
                    anchors.fill: parent
                    cursorShape: Qt.PointingHandCursor
                    onClicked: {
                      controlCenterWindow.currentView = "wifi"
                      controlCenterWindow.triggerWifiScan()
                    }
                  }
                }
              }

              // Divider
              Rectangle {
                Layout.fillWidth: true
                height: 1
                color: controlCenterWindow.isLight ? Qt.rgba(0, 0, 0, 0.08) : Qt.rgba(1, 1, 1, 0.08)
              }

              // Bluetooth Row
              RowLayout {
                Layout.fillWidth: true
                spacing: 10

                Rectangle {
                  width: 34
                  height: 34
                  radius: 17
                  color: controlCenterWindow.btOn ? "#007aff" : (controlCenterWindow.isLight ? Qt.rgba(0, 0, 0, 0.08) : Qt.rgba(1, 1, 1, 0.14))

                  Text {
                    anchors.centerIn: parent
                    text: "󰂯"
                    font.pixelSize: 16
                    color: controlCenterWindow.btOn ? "#ffffff" : (controlCenterWindow.isLight ? "#1d1d1f" : "#ffffff")
                  }

                  MouseArea {
                    anchors.fill: parent
                    cursorShape: Qt.PointingHandCursor
                    onClicked: {
                      controlCenterWindow.btOn = !controlCenterWindow.btOn
                      Quickshell.execDetached(["omarchy-bluetooth-dbus", controlCenterWindow.btOn ? "on" : "off"])
                    }
                  }
                }

                Item {
                  Layout.fillWidth: true
                  Layout.fillHeight: true

                  ColumnLayout {
                    anchors.fill: parent
                    spacing: 1

                    Text {
                      text: "Bluetooth"
                      font.family: "SF Pro Text, -apple-system, sans-serif"
                      font.pixelSize: 12
                      font.bold: true
                      color: controlCenterWindow.isLight ? "#1d1d1f" : "#ffffff"
                    }
                    Text {
                      text: controlCenterWindow.btOn ? "On" : "Off"
                      font.family: "SF Pro Text, -apple-system, sans-serif"
                      font.pixelSize: 10
                      color: controlCenterWindow.isLight ? "#515154" : Qt.rgba(1, 1, 1, 0.72)
                    }
                  }

                  MouseArea {
                    anchors.fill: parent
                    cursorShape: Qt.PointingHandCursor
                    onClicked: {
                      controlCenterWindow.currentView = "bluetooth"
                      controlCenterWindow.triggerBtScan()
                    }
                  }
                }

                // In-place chevron navigation
                Text {
                  text: "›"
                  font.pixelSize: 18
                  color: controlCenterWindow.isLight ? Qt.rgba(0, 0, 0, 0.4) : Qt.rgba(1, 1, 1, 0.4)
                  MouseArea {
                    anchors.fill: parent
                    cursorShape: Qt.PointingHandCursor
                    onClicked: {
                      controlCenterWindow.currentView = "bluetooth"
                      controlCenterWindow.triggerBtScan()
                    }
                  }
                }
              }
            }
          }

          // Right Bento Stack: AirDrop & Focus
          ColumnLayout {
            Layout.fillWidth: true
            spacing: 10

            // AirDrop Card
            Rectangle {
              Layout.fillWidth: true
              implicitHeight: 60
              radius: 14
              color: controlCenterWindow.isLight ? Qt.rgba(1, 1, 1, 0.90) : Qt.rgba(1, 1, 1, 0.08)
              border.color: controlCenterWindow.isLight ? Qt.rgba(0, 0, 0, 0.10) : Qt.rgba(1, 1, 1, 0.12)
              border.width: 1

              RowLayout {
                anchors.fill: parent
                anchors.margins: 10
                spacing: 10

                Rectangle {
                  width: 30
                  height: 30
                  radius: 15
                  color: "#007aff"
                  Text { anchors.centerIn: parent; text: "󰀲"; font.pixelSize: 14; color: "#ffffff" }
                }

                ColumnLayout {
                  Layout.fillWidth: true
                  spacing: 1
                  Text { text: "AirDrop"; font.pixelSize: 12; font.bold: true; color: controlCenterWindow.isLight ? "#1d1d1f" : "#ffffff" }
                  Text { text: "Contacts Only"; font.pixelSize: 10; color: controlCenterWindow.isLight ? "#515154" : Qt.rgba(1, 1, 1, 0.72) }
                }
              }

              MouseArea {
                anchors.fill: parent
                cursorShape: Qt.PointingHandCursor
                onClicked: controlCenterWindow.runCmd("omarchy-undercover-settings -a")
              }
            }

            // Do Not Disturb / Focus Card
            Rectangle {
              Layout.fillWidth: true
              implicitHeight: 60
              radius: 14
              color: controlCenterWindow.isLight ? Qt.rgba(1, 1, 1, 0.90) : Qt.rgba(1, 1, 1, 0.08)
              border.color: controlCenterWindow.isLight ? Qt.rgba(0, 0, 0, 0.10) : Qt.rgba(1, 1, 1, 0.12)
              border.width: 1

              RowLayout {
                anchors.fill: parent
                anchors.margins: 10
                spacing: 10

                Rectangle {
                  width: 30
                  height: 30
                  radius: 15
                  color: controlCenterWindow.dndOn ? "#5856d6" : (controlCenterWindow.isLight ? Qt.rgba(0, 0, 0, 0.08) : Qt.rgba(1, 1, 1, 0.14))
                  Text { anchors.centerIn: parent; text: "󰂛"; font.pixelSize: 14; color: controlCenterWindow.dndOn ? "#ffffff" : (controlCenterWindow.isLight ? "#1d1d1f" : "#ffffff") }
                }

                ColumnLayout {
                  Layout.fillWidth: true
                  spacing: 1
                  Text { text: "Focus"; font.pixelSize: 12; font.bold: true; color: controlCenterWindow.isLight ? "#1d1d1f" : "#ffffff" }
                  Text { text: controlCenterWindow.dndOn ? "Do Not Disturb" : "Off"; font.pixelSize: 10; color: controlCenterWindow.isLight ? "#515154" : Qt.rgba(1, 1, 1, 0.72) }
                }
              }

              MouseArea {
                anchors.fill: parent
                cursorShape: Qt.PointingHandCursor
                onClicked: {
                  controlCenterWindow.dndOn = !controlCenterWindow.dndOn
                  controlCenterWindow.runCmd("dunstctl set-paused " + (controlCenterWindow.dndOn ? "true" : "false") + " 2>/dev/null || true")
                }
              }
            }
          }
        }

        // Row 2: Display Brightness Slider Card
        Rectangle {
          Layout.fillWidth: true
          implicitHeight: 64
          radius: 14
          color: controlCenterWindow.isLight ? Qt.rgba(1, 1, 1, 0.90) : Qt.rgba(1, 1, 1, 0.08)
          border.color: controlCenterWindow.isLight ? Qt.rgba(0, 0, 0, 0.10) : Qt.rgba(1, 1, 1, 0.12)
          border.width: 1

          ColumnLayout {
            anchors.fill: parent
            anchors.margins: 10
            spacing: 6

            RowLayout {
              Layout.fillWidth: true
              Text { text: "Display"; font.pixelSize: 11; font.bold: true; color: controlCenterWindow.isLight ? "#1d1d1f" : "#ffffff" }
              Item { Layout.fillWidth: true }
              Text { text: controlCenterWindow.displayBrightness + "%"; font.pixelSize: 11; color: controlCenterWindow.isLight ? "#515154" : Qt.rgba(1, 1, 1, 0.72) }
            }

            Rectangle {
              Layout.fillWidth: true
              height: 24
              radius: 12
              color: controlCenterWindow.isLight ? Qt.rgba(0, 0, 0, 0.08) : Qt.rgba(1, 1, 1, 0.14)
              clip: true

              Rectangle {
                width: parent.width * (controlCenterWindow.displayBrightness / 100.0)
                height: parent.height
                radius: 12
                color: controlCenterWindow.isLight ? "#007aff" : "#ffffff"
              }

              Text {
                anchors.left: parent.left
                anchors.leftMargin: 8
                anchors.verticalCenter: parent.verticalCenter
                text: "󰃠"
                font.pixelSize: 13
                color: controlCenterWindow.isLight ? "#ffffff" : (controlCenterWindow.displayBrightness > 15 ? "#1a1a1a" : "#ffffff")
              }

              MouseArea {
                anchors.fill: parent
                cursorShape: Qt.PointingHandCursor
                onPositionChanged: function(mouse) {
                  var p = Math.max(5, Math.min(100, Math.round((mouse.x / width) * 100)))
                  controlCenterWindow.displayBrightness = p
                  controlCenterWindow.runCmd("brightnessctl set " + p + "% >/dev/null 2>&1")
                }
                onClicked: function(mouse) {
                  var p = Math.max(5, Math.min(100, Math.round((mouse.x / width) * 100)))
                  controlCenterWindow.displayBrightness = p
                  controlCenterWindow.runCmd("brightnessctl set " + p + "% >/dev/null 2>&1")
                }
              }
            }
          }
        }

        // Row 3: Sound Volume Slider Card
        Rectangle {
          Layout.fillWidth: true
          implicitHeight: 64
          radius: 14
          color: controlCenterWindow.isLight ? Qt.rgba(1, 1, 1, 0.90) : Qt.rgba(1, 1, 1, 0.08)
          border.color: controlCenterWindow.isLight ? Qt.rgba(0, 0, 0, 0.10) : Qt.rgba(1, 1, 1, 0.12)
          border.width: 1

          ColumnLayout {
            anchors.fill: parent
            anchors.margins: 10
            spacing: 6

            RowLayout {
              Layout.fillWidth: true
              Text { text: "Sound"; font.pixelSize: 11; font.bold: true; color: controlCenterWindow.isLight ? "#1d1d1f" : "#ffffff" }
              Item { Layout.fillWidth: true }
              Text { text: controlCenterWindow.masterVolume + "%"; font.pixelSize: 11; color: controlCenterWindow.isLight ? "#515154" : Qt.rgba(1, 1, 1, 0.72) }
            }

            Rectangle {
              Layout.fillWidth: true
              height: 24
              radius: 12
              color: controlCenterWindow.isLight ? Qt.rgba(0, 0, 0, 0.08) : Qt.rgba(1, 1, 1, 0.14)
              clip: true

              Rectangle {
                width: parent.width * (controlCenterWindow.masterVolume / 100.0)
                height: parent.height
                radius: 12
                color: controlCenterWindow.isLight ? "#007aff" : "#ffffff"
              }

              Text {
                anchors.left: parent.left
                anchors.leftMargin: 8
                anchors.verticalCenter: parent.verticalCenter
                text: "󰕾"
                font.pixelSize: 13
                color: controlCenterWindow.isLight ? "#ffffff" : (controlCenterWindow.masterVolume > 15 ? "#1a1a1a" : "#ffffff")
              }

              MouseArea {
                anchors.fill: parent
                cursorShape: Qt.PointingHandCursor
                onPositionChanged: function(mouse) {
                  var p = Math.max(0, Math.min(100, Math.round((mouse.x / width) * 100)))
                  controlCenterWindow.masterVolume = p
                  controlCenterWindow.runCmd("wpctl set-volume @DEFAULT_AUDIO_SINK@ " + (p / 100.0) + " >/dev/null 2>&1")
                }
                onClicked: function(mouse) {
                  var p = Math.max(0, Math.min(100, Math.round((mouse.x / width) * 100)))
                  controlCenterWindow.masterVolume = p
                  controlCenterWindow.runCmd("wpctl set-volume @DEFAULT_AUDIO_SINK@ " + (p / 100.0) + " >/dev/null 2>&1")
                }
              }
            }
          }
        }

        // Row 4: Microphone Slider Card
        Rectangle {
          Layout.fillWidth: true
          implicitHeight: 64
          radius: 14
          color: controlCenterWindow.isLight ? Qt.rgba(1, 1, 1, 0.90) : Qt.rgba(1, 1, 1, 0.08)
          border.color: controlCenterWindow.isLight ? Qt.rgba(0, 0, 0, 0.10) : Qt.rgba(1, 1, 1, 0.12)
          border.width: 1

          ColumnLayout {
            anchors.fill: parent
            anchors.margins: 10
            spacing: 6

            RowLayout {
              Layout.fillWidth: true
              Text { text: "Microphone"; font.pixelSize: 11; font.bold: true; color: controlCenterWindow.isLight ? "#1d1d1f" : "#ffffff" }
              Item { Layout.fillWidth: true }
              Text { text: controlCenterWindow.micMuted ? "Muted" : controlCenterWindow.micLevel + "%"; font.pixelSize: 11; color: controlCenterWindow.isLight ? "#515154" : Qt.rgba(1, 1, 1, 0.72) }
            }

            Rectangle {
              Layout.fillWidth: true
              height: 24
              radius: 12
              color: controlCenterWindow.isLight ? Qt.rgba(0, 0, 0, 0.08) : Qt.rgba(1, 1, 1, 0.14)
              clip: true

              Rectangle {
                width: parent.width * (controlCenterWindow.micLevel / 100.0)
                height: parent.height
                radius: 12
                color: controlCenterWindow.micMuted ? (controlCenterWindow.isLight ? Qt.rgba(0, 0, 0, 0.35) : Qt.rgba(1, 1, 1, 0.35)) : (controlCenterWindow.isLight ? "#007aff" : "#ffffff")
              }

              Text {
                anchors.left: parent.left
                anchors.leftMargin: 8
                anchors.verticalCenter: parent.verticalCenter
                text: "󰍬"
                font.pixelSize: 13
                color: controlCenterWindow.isLight ? "#ffffff" : (controlCenterWindow.micLevel > 15 ? "#1a1a1a" : "#ffffff")
              }

              MouseArea {
                anchors.fill: parent
                cursorShape: Qt.PointingHandCursor
                onPositionChanged: function(mouse) {
                  var p = Math.max(0, Math.min(100, Math.round((mouse.x / width) * 100)))
                  controlCenterWindow.micLevel = p
                  controlCenterWindow.runCmd("wpctl set-mute @DEFAULT_AUDIO_SOURCE@ 0 && wpctl set-volume @DEFAULT_AUDIO_SOURCE@ " + (p / 100.0) + " >/dev/null 2>&1")
                  controlCenterWindow.micMuted = false
                }
                onClicked: function(mouse) {
                  var p = Math.max(0, Math.min(100, Math.round((mouse.x / width) * 100)))
                  controlCenterWindow.micLevel = p
                  controlCenterWindow.runCmd("wpctl set-mute @DEFAULT_AUDIO_SOURCE@ 0 && wpctl set-volume @DEFAULT_AUDIO_SOURCE@ " + (p / 100.0) + " >/dev/null 2>&1")
                  controlCenterWindow.micMuted = false
                }
              }
            }

            RowLayout {
              Layout.fillWidth: true
              spacing: 8
              Item { Layout.fillWidth: true }
              Text {
                text: controlCenterWindow.micMuted ? "󰍭 Unmute" : "󰍬 Mute"
                font.pixelSize: 11
                color: controlCenterWindow.isLight ? "#515154" : Qt.rgba(1, 1, 1, 0.72)
                MouseArea {
                  anchors.fill: parent
                  cursorShape: Qt.PointingHandCursor
                  onClicked: {
                    controlCenterWindow.micMuted = !controlCenterWindow.micMuted
                    controlCenterWindow.runCmd("wpctl set-mute @DEFAULT_AUDIO_SOURCE@ " + (controlCenterWindow.micMuted ? "1" : "0"))
                  }
                }
              }
            }
          }
        }

        // Row 5: Now Playing / MPRIS Card
        Rectangle {
          Layout.fillWidth: true
          implicitHeight: 74
          radius: 14
          color: controlCenterWindow.isLight ? Qt.rgba(1, 1, 1, 0.70) : Qt.rgba(1, 1, 1, 0.08)
          border.color: controlCenterWindow.isLight ? Qt.rgba(0, 0, 0, 0.06) : Qt.rgba(1, 1, 1, 0.10)
          border.width: 1

          RowLayout {
            anchors.fill: parent
            anchors.margins: 10
            spacing: 12

            Rectangle {
              width: 44
              height: 44
              radius: 8
              color: "#fa2d48"

              Text {
                anchors.centerIn: parent
                text: "󰝚"
                font.pixelSize: 20
                color: "#ffffff"
              }
            }

            ColumnLayout {
              Layout.fillWidth: true
              spacing: 2

              Text {
                text: controlCenterWindow.musicTitle
                font.family: "SF Pro Text, -apple-system, sans-serif"
                font.pixelSize: 12
                font.bold: true
                color: controlCenterWindow.isLight ? "#1a1a1a" : "#ffffff"
                elide: Text.ElideRight
                Layout.fillWidth: true
              }

              Text {
                text: controlCenterWindow.musicArtist
                font.family: "SF Pro Text, -apple-system, sans-serif"
                font.pixelSize: 10
                color: controlCenterWindow.isLight ? Qt.rgba(0, 0, 0, 0.55) : Qt.rgba(1, 1, 1, 0.55)
                elide: Text.ElideRight
                Layout.fillWidth: true
              }
            }

            RowLayout {
              spacing: 6

              Text {
                text: "󰒮"
                font.pixelSize: 18
                color: controlCenterWindow.isLight ? "#1a1a1a" : "#ffffff"
                MouseArea { anchors.fill: parent; cursorShape: Qt.PointingHandCursor; onClicked: controlCenterWindow.runCmd("playerctl previous") }
              }

              Text {
                text: controlCenterWindow.musicPlaying ? "󰏤" : "󰐊"
                font.pixelSize: 22
                color: controlCenterWindow.isLight ? "#1a1a1a" : "#ffffff"
                MouseArea {
                  anchors.fill: parent
                  cursorShape: Qt.PointingHandCursor
                  onClicked: {
                    controlCenterWindow.musicPlaying = !controlCenterWindow.musicPlaying
                    controlCenterWindow.runCmd("playerctl play-pause")
                  }
                }
              }

              Text {
                text: "󰒭"
                font.pixelSize: 18
                color: controlCenterWindow.isLight ? "#1a1a1a" : "#ffffff"
                MouseArea { anchors.fill: parent; cursorShape: Qt.PointingHandCursor; onClicked: controlCenterWindow.runCmd("playerctl next") }
              }
            }
          }
        }
      }

      // ==========================================
      // VIEW 2: IN-PLACE WI-FI SUB-PAGE (macOS)
      // ==========================================
      ColumnLayout {
        id: macWifiSubView
        visible: controlCenterWindow.currentView === "wifi"
        anchors.fill: parent
        anchors.margins: 14
        spacing: 10

        // Header Row
        RowLayout {
          Layout.fillWidth: true
          implicitHeight: 32
          spacing: 8

          Rectangle {
            implicitWidth: 100
            implicitHeight: 26
            radius: 6
            color: macWifiBackM.containsMouse ? (controlCenterWindow.isLight ? Qt.rgba(0, 0, 0, 0.08) : Qt.rgba(1, 1, 1, 0.12)) : "transparent"

            RowLayout {
              anchors.centerIn: parent
              spacing: 4
              Text {
                text: "‹"
                font.family: "SF Pro Text"
                font.pixelSize: 16
                font.bold: true
                color: "#007aff"
              }
              Text {
                text: "Control Center"
                font.family: "SF Pro Text"
                font.pixelSize: 11
                font.bold: true
                color: "#007aff"
              }
            }

            MouseArea {
              id: macWifiBackM
              anchors.fill: parent
              hoverEnabled: true
              cursorShape: Qt.PointingHandCursor
              onClicked: controlCenterWindow.currentView = "main"
            }
          }

          Item { Layout.fillWidth: true }

          // Scan / Refresh
          Rectangle {
            implicitWidth: 26
            implicitHeight: 26
            radius: 13
            color: macWifiRefreshM.containsMouse ? (controlCenterWindow.isLight ? Qt.rgba(0, 0, 0, 0.08) : Qt.rgba(1, 1, 1, 0.12)) : "transparent"
            Text {
              anchors.centerIn: parent
              text: "🔄"
              font.pixelSize: 11
              opacity: controlCenterWindow.isScanningWifi ? 0.4 : 1.0
            }
            MouseArea {
              id: macWifiRefreshM
              anchors.fill: parent
              hoverEnabled: true
              cursorShape: Qt.PointingHandCursor
              onClicked: controlCenterWindow.triggerWifiScan()
            }
          }

          // Wi-Fi Power Switch
          Rectangle {
            implicitWidth: 38
            implicitHeight: 22
            radius: 11
            color: controlCenterWindow.wifiOn ? "#007aff" : Qt.rgba(0.5, 0.5, 0.5, 0.4)

            Rectangle {
              anchors.verticalCenter: parent.verticalCenter
              x: controlCenterWindow.wifiOn ? parent.width - width - 2 : 2
              implicitWidth: 18
              implicitHeight: 18
              radius: 9
              color: "#ffffff"
              Behavior on x { NumberAnimation { duration: 150; easing.type: Easing.OutCubic } }
            }

            MouseArea {
              anchors.fill: parent
              cursorShape: Qt.PointingHandCursor
              onClicked: {
                var target = !controlCenterWindow.wifiOn
                controlCenterWindow.wifiOn = target
                Quickshell.execDetached(["omarchy-wifi-dbus", target ? "on" : "off"])
                controlCenterWindow.triggerWifiScan()
              }
            }
          }
        }

        // Title
        Text {
          text: "Wi-Fi"
          font.family: "SF Pro Text"
          font.pixelSize: 15
          font.bold: true
          color: controlCenterWindow.isLight ? "#1d1d1f" : "#ffffff"
        }

        // Search Bar
        Rectangle {
          visible: controlCenterWindow.wifiOn
          Layout.fillWidth: true
          implicitHeight: 32
          radius: 8
          color: controlCenterWindow.isLight ? Qt.rgba(0, 0, 0, 0.05) : Qt.rgba(1, 1, 1, 0.08)
          border.color: controlCenterWindow.isLight ? Qt.rgba(0, 0, 0, 0.08) : Qt.rgba(1, 1, 1, 0.12)

          RowLayout {
            anchors.fill: parent
            anchors.leftMargin: 8
            anchors.rightMargin: 8
            spacing: 6

            Text { text: "🔍"; font.pixelSize: 11; opacity: 0.6 }

            TextInput {
              id: macWifiSearchBox
              Layout.fillWidth: true
              color: controlCenterWindow.isLight ? "#1a1a1a" : "#ffffff"
              font.family: "SF Pro Text"
              font.pixelSize: 11
              clip: true
              onTextChanged: controlCenterWindow.wifiSearchText = text

              Text {
                text: "Search Wi-Fi networks..."
                color: controlCenterWindow.isLight ? Qt.rgba(0, 0, 0, 0.4) : Qt.rgba(1, 1, 1, 0.4)
                font: macWifiSearchBox.font
                visible: !macWifiSearchBox.text && !macWifiSearchBox.activeFocus
              }
            }

            Rectangle {
              visible: macWifiSearchBox.text.length > 0
              implicitWidth: 16
              implicitHeight: 16
              radius: 8
              color: Qt.rgba(1, 1, 1, 0.2)
              Text { anchors.centerIn: parent; text: "✕"; font.pixelSize: 9; color: "#ffffff" }
              MouseArea {
                anchors.fill: parent
                cursorShape: Qt.PointingHandCursor
                onClicked: {
                  macWifiSearchBox.text = ""
                  controlCenterWindow.wifiSearchText = ""
                }
              }
            }
          }
        }

        // Active Connection Capsule
        Rectangle {
          visible: controlCenterWindow.wifiSsid.length > 0 && controlCenterWindow.wifiSsid !== "Wi-Fi" && controlCenterWindow.wifiOn
          Layout.fillWidth: true
          implicitHeight: 40
          radius: 8
          color: controlCenterWindow.isLight ? Qt.rgba(0, 122, 255, 0.12) : Qt.rgba(0, 122, 255, 0.22)

          RowLayout {
            anchors.fill: parent
            anchors.leftMargin: 10
            anchors.rightMargin: 10
            spacing: 8

            Text { text: "✓"; color: "#007aff"; font.bold: true }
            Text {
              text: controlCenterWindow.wifiSsid
              font.family: "SF Pro Text"
              font.pixelSize: 12
              font.bold: true
              color: controlCenterWindow.isLight ? "#1a1a1a" : "#ffffff"
              Layout.fillWidth: true
              elide: Text.ElideRight
            }
            Text { text: "󰤨"; font.pixelSize: 14; color: "#007aff" }
          }
        }

        // Section Title
        RowLayout {
          visible: controlCenterWindow.wifiOn
          Layout.fillWidth: true
          Text {
            text: controlCenterWindow.wifiSearchText.length > 0
              ? "Search Results (" + controlCenterWindow.filteredNetworks.length + ")"
              : "Available Networks"
            font.family: "SF Pro Text"
            font.pixelSize: 11
            font.bold: true
            color: controlCenterWindow.isLight ? Qt.rgba(0, 0, 0, 0.5) : Qt.rgba(1, 1, 1, 0.5)
            Layout.fillWidth: true
          }
          Text {
            visible: controlCenterWindow.isScanningWifi
            text: "Scanning..."
            font.family: "SF Pro Text"
            font.pixelSize: 10
            color: "#007aff"
          }
        }

        // Networks List
        ScrollView {
          visible: controlCenterWindow.wifiOn
          Layout.fillWidth: true
          Layout.fillHeight: true
          clip: true

          ListView {
            id: macCcNetList
            width: parent.width
            model: controlCenterWindow.filteredNetworks
            spacing: 3

            delegate: ColumnLayout {
              width: macCcNetList.width
              spacing: 3

              Rectangle {
                Layout.fillWidth: true
                implicitHeight: 34
                radius: 6
                color: macRowM.containsMouse ? (controlCenterWindow.isLight ? Qt.rgba(0, 0, 0, 0.06) : Qt.rgba(1, 1, 1, 0.10)) : "transparent"

                RowLayout {
                  anchors.fill: parent
                  anchors.leftMargin: 8
                  anchors.rightMargin: 8
                  spacing: 8

                  Text {
                    text: modelData.inUse ? "󰤨" : (modelData.signal > 60 ? "󰤨" : (modelData.signal > 30 ? "󰤥" : "󰤟"))
                    font.pixelSize: 13
                    color: modelData.inUse ? "#007aff" : (controlCenterWindow.isLight ? "#1a1a1a" : "#ffffff")
                  }
                  Text {
                    text: modelData.ssid
                    font.family: "SF Pro Text"
                    font.pixelSize: 11
                    font.bold: modelData.inUse
                    color: modelData.inUse ? "#007aff" : (controlCenterWindow.isLight ? "#1a1a1a" : "#ffffff")
                    Layout.fillWidth: true
                    elide: Text.ElideRight
                  }
                  Text { visible: modelData.isSecured; text: "🔒"; font.pixelSize: 10 }
                }

                MouseArea {
                  id: macRowM
                  anchors.fill: parent
                  hoverEnabled: true
                  cursorShape: Qt.PointingHandCursor
                  onClicked: {
                    if (modelData.inUse) return
                    if (modelData.isSecured) {
                      controlCenterWindow.connectingSsid = (controlCenterWindow.connectingSsid === modelData.ssid ? "" : modelData.ssid)
                      controlCenterWindow.wifiPasswordInput = ""
                    } else {
                      controlCenterWindow.connectWifi(modelData.ssid, "")
                      controlCenterWindow.triggerWifiScan()
                    }
                  }
                }
              }

              // Password Entry if needed
              Rectangle {
                visible: controlCenterWindow.connectingSsid === modelData.ssid
                Layout.fillWidth: true
                implicitHeight: 38
                radius: 6
                color: controlCenterWindow.isLight ? Qt.rgba(0, 0, 0, 0.05) : Qt.rgba(1, 1, 1, 0.08)

                RowLayout {
                  anchors.fill: parent
                  anchors.margins: 4
                  spacing: 6

                  TextInput {
                    id: macPwInput
                    Layout.fillWidth: true
                    font.pixelSize: 11
                    color: controlCenterWindow.isLight ? "#1a1a1a" : "#ffffff"
                    echoMode: TextInput.Password
                    clip: true
                    onTextChanged: controlCenterWindow.wifiPasswordInput = text
                    onAccepted: {
                      controlCenterWindow.connectWifi(modelData.ssid, macPwInput.text)
                      macPwInput.text = ""
                      controlCenterWindow.connectingSsid = ""
                      controlCenterWindow.triggerWifiScan()
                    }
                  }

                  Rectangle {
                    implicitWidth: 60
                    implicitHeight: 26
                    radius: 5
                    color: "#007aff"
                    Text { anchors.centerIn: parent; text: "Join"; color: "#ffffff"; font.family: "SF Pro Text"; font.pixelSize: 10; font.bold: true }
                    MouseArea {
                      anchors.fill: parent
                      cursorShape: Qt.PointingHandCursor
                      onClicked: {
                        controlCenterWindow.connectWifi(modelData.ssid, macPwInput.text)
                        macPwInput.text = ""
                        controlCenterWindow.connectingSsid = ""
                        controlCenterWindow.triggerWifiScan()
                      }
                    }
                  }
                }
              }
            }
          }
        }

        // Footer Link
        Rectangle {
          Layout.fillWidth: true
          implicitHeight: 28
          radius: 6
          color: macWifiPrefM.containsMouse ? (controlCenterWindow.isLight ? Qt.rgba(0, 0, 0, 0.05) : Qt.rgba(1, 1, 1, 0.08)) : "transparent"
          Text {
            anchors.centerIn: parent
            text: "Wi-Fi Settings..."
            font.family: "SF Pro Text"
            font.pixelSize: 11
            color: "#007aff"
          }
          MouseArea {
            id: macWifiPrefM
            anchors.fill: parent
            hoverEnabled: true
            cursorShape: Qt.PointingHandCursor
            onClicked: {
              Qt.quit()
              controlCenterWindow.runCmd("nm-connection-editor || omarchy-undercover-settings")
            }
          }
        }
      }

      // ==========================================
      // VIEW 3: IN-PLACE BLUETOOTH SUB-PAGE (macOS)
      // ==========================================
      ColumnLayout {
        id: macBtSubView
        visible: controlCenterWindow.currentView === "bluetooth"
        anchors.fill: parent
        anchors.margins: 14
        spacing: 10

        // Header Row
        RowLayout {
          Layout.fillWidth: true
          implicitHeight: 32
          spacing: 8

          Rectangle {
            implicitWidth: 100
            implicitHeight: 26
            radius: 6
            color: macBtBackM.containsMouse ? (controlCenterWindow.isLight ? Qt.rgba(0, 0, 0, 0.08) : Qt.rgba(1, 1, 1, 0.12)) : "transparent"

            RowLayout {
              anchors.centerIn: parent
              spacing: 4
              Text {
                text: "‹"
                font.family: "SF Pro Text"
                font.pixelSize: 16
                font.bold: true
                color: "#007aff"
              }
              Text {
                text: "Control Center"
                font.family: "SF Pro Text"
                font.pixelSize: 11
                font.bold: true
                color: "#007aff"
              }
            }

            MouseArea {
              id: macBtBackM
              anchors.fill: parent
              hoverEnabled: true
              cursorShape: Qt.PointingHandCursor
              onClicked: controlCenterWindow.currentView = "main"
            }
          }

          Item { Layout.fillWidth: true }

          // Scan / Refresh
          Rectangle {
            implicitWidth: 26
            implicitHeight: 26
            radius: 13
            color: macBtRefreshM.containsMouse ? (controlCenterWindow.isLight ? Qt.rgba(0, 0, 0, 0.08) : Qt.rgba(1, 1, 1, 0.12)) : "transparent"
            Text {
              anchors.centerIn: parent
              text: "🔄"
              font.pixelSize: 11
              opacity: controlCenterWindow.isScanningBt ? 0.4 : 1.0
            }
            MouseArea {
              id: macBtRefreshM
              anchors.fill: parent
              hoverEnabled: true
              cursorShape: Qt.PointingHandCursor
              onClicked: controlCenterWindow.triggerBtScan()
            }
          }

          // Bluetooth Power Switch
          Rectangle {
            implicitWidth: 38
            implicitHeight: 22
            radius: 11
            color: controlCenterWindow.btOn ? "#007aff" : Qt.rgba(0.5, 0.5, 0.5, 0.4)

            Rectangle {
              anchors.verticalCenter: parent.verticalCenter
              x: controlCenterWindow.btOn ? parent.width - width - 2 : 2
              implicitWidth: 18
              implicitHeight: 18
              radius: 9
              color: "#ffffff"
              Behavior on x { NumberAnimation { duration: 150; easing.type: Easing.OutCubic } }
            }

            MouseArea {
              anchors.fill: parent
              cursorShape: Qt.PointingHandCursor
              onClicked: {
                var target = !controlCenterWindow.btOn
                controlCenterWindow.btOn = target
                Quickshell.execDetached(["omarchy-bluetooth-dbus", target ? "on" : "off"])
                controlCenterWindow.triggerBtScan()
              }
            }
          }
        }

        // Title
        Text {
          text: "Bluetooth"
          font.family: "SF Pro Text"
          font.pixelSize: 15
          font.bold: true
          color: controlCenterWindow.isLight ? "#1d1d1f" : "#ffffff"
        }

        // Search Bar
        Rectangle {
          visible: controlCenterWindow.btOn
          Layout.fillWidth: true
          implicitHeight: 32
          radius: 8
          color: controlCenterWindow.isLight ? Qt.rgba(0, 0, 0, 0.05) : Qt.rgba(1, 1, 1, 0.08)
          border.color: controlCenterWindow.isLight ? Qt.rgba(0, 0, 0, 0.08) : Qt.rgba(1, 1, 1, 0.12)

          RowLayout {
            anchors.fill: parent
            anchors.leftMargin: 8
            anchors.rightMargin: 8
            spacing: 6

            Text { text: "🔍"; font.pixelSize: 11; opacity: 0.6 }

            TextInput {
              id: macBtSearchBox
              Layout.fillWidth: true
              color: controlCenterWindow.isLight ? "#1a1a1a" : "#ffffff"
              font.family: "SF Pro Text"
              font.pixelSize: 11
              clip: true
              onTextChanged: controlCenterWindow.btSearchText = text

              Text {
                text: "Search Bluetooth devices..."
                color: controlCenterWindow.isLight ? Qt.rgba(0, 0, 0, 0.4) : Qt.rgba(1, 1, 1, 0.4)
                font: macBtSearchBox.font
                visible: !macBtSearchBox.text && !macBtSearchBox.activeFocus
              }
            }

            Rectangle {
              visible: macBtSearchBox.text.length > 0
              implicitWidth: 16
              implicitHeight: 16
              radius: 8
              color: Qt.rgba(1, 1, 1, 0.2)
              Text { anchors.centerIn: parent; text: "✕"; font.pixelSize: 9; color: "#ffffff" }
              MouseArea {
                anchors.fill: parent
                cursorShape: Qt.PointingHandCursor
                onClicked: {
                  macBtSearchBox.text = ""
                  controlCenterWindow.btSearchText = ""
                }
              }
            }
          }
        }

        // Section Title
        RowLayout {
          visible: controlCenterWindow.btOn
          Layout.fillWidth: true
          Text {
            text: controlCenterWindow.btSearchText.length > 0
              ? "Search Results (" + controlCenterWindow.filteredBtDevices.length + ")"
              : "Devices"
            font.family: "SF Pro Text"
            font.pixelSize: 11
            font.bold: true
            color: controlCenterWindow.isLight ? Qt.rgba(0, 0, 0, 0.5) : Qt.rgba(1, 1, 1, 0.5)
            Layout.fillWidth: true
          }
          Text {
            visible: controlCenterWindow.isScanningBt
            text: "Scanning..."
            font.family: "SF Pro Text"
            font.pixelSize: 10
            color: "#007aff"
          }
        }

        // Devices List
        ScrollView {
          visible: controlCenterWindow.btOn
          Layout.fillWidth: true
          Layout.fillHeight: true
          clip: true

          ListView {
            id: macCcBtList
            width: parent.width
            model: controlCenterWindow.filteredBtDevices
            spacing: 3

            delegate: Rectangle {
              width: macCcBtList.width
              implicitHeight: 38
              radius: 6
              color: macCcBtRowM.containsMouse ? (controlCenterWindow.isLight ? Qt.rgba(0, 0, 0, 0.06) : Qt.rgba(1, 1, 1, 0.10)) : "transparent"

              RowLayout {
                anchors.fill: parent
                anchors.leftMargin: 8
                anchors.rightMargin: 8
                spacing: 8

                Text { text: modelData.type; font.pixelSize: 16 }
                Text {
                  text: modelData.name
                  font.family: "SF Pro Text"
                  font.pixelSize: 11
                  font.bold: modelData.connected
                  color: controlCenterWindow.isLight ? "#1a1a1a" : "#ffffff"
                  Layout.fillWidth: true
                  elide: Text.ElideRight
                }
                Rectangle {
                  implicitWidth: 60
                  implicitHeight: 24
                  radius: 5
                  color: modelData.connected
                    ? (controlCenterWindow.isLight ? Qt.rgba(0, 0, 0, 0.08) : Qt.rgba(1, 1, 1, 0.12))
                    : (macCcBtBtnM.containsMouse ? "#007aff" : (controlCenterWindow.isLight ? Qt.rgba(0, 122, 255, 0.10) : Qt.rgba(0, 122, 255, 0.20)))

                  Text {
                    anchors.centerIn: parent
                    text: modelData.connected ? "Disconnect" : "Connect"
                    font.family: "SF Pro Text"
                    font.pixelSize: 10
                    font.bold: true
                    color: modelData.connected
                      ? (controlCenterWindow.isLight ? "#515154" : Qt.rgba(1, 1, 1, 0.75))
                      : (macCcBtBtnM.containsMouse ? "#ffffff" : "#007aff")
                  }

                  MouseArea {
                    id: macCcBtBtnM
                    anchors.fill: parent
                    hoverEnabled: true
                    cursorShape: Qt.PointingHandCursor
                    onClicked: {
                      if (modelData.connected) {
                        Quickshell.execDetached(["omarchy-bluetooth-dbus", "disconnect", modelData.mac])
                      } else {
                        Quickshell.execDetached(["omarchy-bluetooth-dbus", "connect", modelData.mac])
                      }
                      controlCenterWindow.triggerBtScan()
                    }
                  }
                }
              }

              MouseArea {
                id: macCcBtRowM
                anchors.fill: parent
                hoverEnabled: true
                cursorShape: Qt.PointingHandCursor
                acceptedButtons: Qt.RightButton
                onClicked: {
                  if (modelData.connected) {
                    Quickshell.execDetached(["omarchy-bluetooth-dbus", "disconnect", modelData.mac])
                    controlCenterWindow.triggerBtScan()
                  }
                }
              }
            }
          }
        }

        // Footer Link
        Rectangle {
          Layout.fillWidth: true
          implicitHeight: 28
          radius: 6
          color: macBtPrefM.containsMouse ? (controlCenterWindow.isLight ? Qt.rgba(0, 0, 0, 0.05) : Qt.rgba(1, 1, 1, 0.08)) : "transparent"
          Text {
            anchors.centerIn: parent
            text: "Bluetooth Settings..."
            font.family: "SF Pro Text"
            font.pixelSize: 11
            color: "#007aff"
          }
          MouseArea {
            id: macBtPrefM
            anchors.fill: parent
            hoverEnabled: true
            cursorShape: Qt.PointingHandCursor
            onClicked: {
              Qt.quit()
              controlCenterWindow.runCmd("blueman-manager || omarchy-undercover-settings")
            }
          }
        }
      }
    }
  }
}

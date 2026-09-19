import Quickshell
import Quickshell.Wayland
import Quickshell.Hyprland
import Quickshell.Io
import QtQuick
import QtQuick.Layouts
import QtQuick.Controls

ShellRoot {
  PanelWindow {
    id: macWifiWindow
    screen: Quickshell.screens[0]

    anchors {
      top: true
      right: true
    }
    margins {
      top: 36
      right: 12
    }

    WlrLayershell.layer: WlrLayer.Overlay
    WlrLayershell.namespace: "omarchy-menu"
    color: "transparent"

    implicitWidth: 340
    implicitHeight: 460

    property bool isDark: true
    property bool wifiEnabled: true
    property string activeSsid: ""
    property var networks: []
    property string connectingSsid: ""
    property string searchText: ""
    property bool isScanning: false

    readonly property var filteredNetworks: {
      var q = macWifiWindow.searchText.toLowerCase().trim()
      var result = []
      for (var i = 0; i < macWifiWindow.networks.length; i++) {
        var n = macWifiWindow.networks[i]
        if (!n.ssid || n.ssid.length === 0) continue
        if (!q ||
            n.ssid.toLowerCase().indexOf(q) !== -1 ||
            (n.security && n.security.toLowerCase().indexOf(q) !== -1) ||
            (n.bssid && n.bssid.toLowerCase().replace(/[-:]/g, "").indexOf(q.replace(/[-:]/g, "")) !== -1)) {
          result.push(n)
        }
      }
      // Best signal first, active network pinned to the top of results.
      result.sort(function(a, b) {
        if (a.inUse && !b.inUse) return -1
        if (!a.inUse && b.inUse) return 1
        return (b.signal || 0) - (a.signal || 0)
      })
      return result
    }

    function triggerScan() {
      macWifiWindow.isScanning = true
      macWifiWindow.networks = []
      if (!scanPoller.running) scanPoller.running = true
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
        macWifiWindow.triggerScan()
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

    // Theme state poller
    Process {
      id: statePoller
      running: true
      command: ["bash", "-c", "cat $HOME/.config/omarchy-undercover/state 2>/dev/null || echo 'mac-dark'"]
      stdout: SplitParser {
        onRead: function(line) {
          var s = String(line).trim()
          macWifiWindow.isDark = (s.indexOf("light") === -1)
        }
      }
    }

    // Wi-Fi Radio status poller (NetworkManager over D-Bus)
    Process {
      id: radioPoller
      running: true
      command: ["bash", "-c", "omarchy-wifi-dbus radio"]
      stdout: SplitParser {
        onRead: function(line) {
          macWifiWindow.wifiEnabled = (String(line).trim().toLowerCase() === "enabled")
        }
      }
    }

    // Wi-Fi Scan Process (NetworkManager over D-Bus)
    Process {
      id: scanPoller
      running: true
      command: ["bash", "-c", "omarchy-wifi-dbus scan"]
      onExited: function() {
        macWifiWindow.isScanning = false
      }
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
              if (inUse) macWifiWindow.activeSsid = ssid
              var currentList = macWifiWindow.networks.slice(0)
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
              macWifiWindow.networks = currentList
            }
          }
        }
      }
    }

    Timer {
      interval: 8000
      running: true
      repeat: true
      triggeredOnStart: true
      onTriggered: {
        if (!scanPoller.running) scanPoller.running = true
        if (!radioPoller.running) radioPoller.running = true
      }
    }

    Rectangle {
      anchors.fill: parent
      radius: 16
      color: macWifiWindow.isDark ? Qt.rgba(0.12, 0.12, 0.17, 0.90) : Qt.rgba(0.96, 0.96, 0.98, 0.92)
      border.color: macWifiWindow.isDark ? Qt.rgba(1, 1, 1, 0.18) : Qt.rgba(0, 0, 0, 0.12)
      border.width: 1

      ColumnLayout {
        anchors.fill: parent
        anchors.margins: 14
        spacing: 10

        // Header
        RowLayout {
          Layout.fillWidth: true
          Text {
            text: "Wi-Fi"
            font.family: "SF Pro Text"
            font.pixelSize: 14
            font.weight: Font.Bold
            color: macWifiWindow.isDark ? "#ffffff" : "#1a1a1a"
            Layout.fillWidth: true
          }

          // Scan / Refresh Button
          Rectangle {
            implicitWidth: 24
            implicitHeight: 24
            radius: 12
            color: scanM.containsMouse ? (macWifiWindow.isDark ? Qt.rgba(1, 1, 1, 0.12) : Qt.rgba(0, 0, 0, 0.08)) : "transparent"
            Text {
              anchors.centerIn: parent
              text: "🔄"
              font.pixelSize: 11
              opacity: macWifiWindow.isScanning ? 0.4 : 1.0
            }
            MouseArea {
              id: scanM
              anchors.fill: parent
              hoverEnabled: true
              cursorShape: Qt.PointingHandCursor
              onClicked: macWifiWindow.triggerScan()
            }
          }

          Rectangle {
            implicitWidth: 38
            implicitHeight: 22
            radius: 11
            color: macWifiWindow.wifiEnabled ? "#007aff" : Qt.rgba(0.5, 0.5, 0.5, 0.4)

            Rectangle {
              anchors.verticalCenter: parent.verticalCenter
              x: macWifiWindow.wifiEnabled ? parent.width - width - 2 : 2
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
                var target = !macWifiWindow.wifiEnabled
                macWifiWindow.wifiEnabled = target
                Quickshell.execDetached(["omarchy-wifi-dbus", target ? "on" : "off"])
                if (!scanPoller.running) scanPoller.running = true
              }
            }
          }

          Rectangle {
            implicitWidth: 24
            implicitHeight: 24
            radius: 12
            color: closeM.containsMouse ? (macWifiWindow.isDark ? Qt.rgba(1, 1, 1, 0.12) : Qt.rgba(0, 0, 0, 0.08)) : "transparent"
            Text { anchors.centerIn: parent; text: "✕"; font.pixelSize: 11; color: macWifiWindow.isDark ? "#ffffff" : "#1a1a1a" }
            MouseArea {
              id: closeM
              anchors.fill: parent
              hoverEnabled: true
              cursorShape: Qt.PointingHandCursor
              onClicked: Qt.quit()
            }
          }
        }

        // Search Bar
        Rectangle {
          visible: macWifiWindow.wifiEnabled
          Layout.fillWidth: true
          implicitHeight: 32
          radius: 8
          color: macWifiWindow.isDark ? Qt.rgba(1, 1, 1, 0.08) : Qt.rgba(0, 0, 0, 0.05)
          border.color: macWifiWindow.isDark ? Qt.rgba(1, 1, 1, 0.12) : Qt.rgba(0, 0, 0, 0.08)

          RowLayout {
            anchors.fill: parent
            anchors.leftMargin: 8
            anchors.rightMargin: 8
            spacing: 6

            Text { text: "🔍"; font.pixelSize: 11; opacity: 0.6 }

            TextInput {
              id: wifiSearchBox
              Layout.fillWidth: true
              color: macWifiWindow.isDark ? "#ffffff" : "#1a1a1a"
              font.family: "SF Pro Text"
              font.pixelSize: 12
              clip: true
              onTextChanged: macWifiWindow.searchText = text

              Text {
                text: "Search Wi-Fi networks..."
                color: macWifiWindow.isDark ? Qt.rgba(1, 1, 1, 0.4) : Qt.rgba(0, 0, 0, 0.4)
                font: wifiSearchBox.font
                visible: !wifiSearchBox.text && !wifiSearchBox.activeFocus
              }
            }

            Rectangle {
              visible: wifiSearchBox.text.length > 0
              implicitWidth: 16
              implicitHeight: 16
              radius: 8
              color: Qt.rgba(1, 1, 1, 0.2)
              Text { anchors.centerIn: parent; text: "✕"; font.pixelSize: 9; color: "#ffffff" }
              MouseArea {
                anchors.fill: parent
                cursorShape: Qt.PointingHandCursor
                onClicked: {
                  wifiSearchBox.text = ""
                  macWifiWindow.searchText = ""
                }
              }
            }
          }
        }

        // Active Connection Capsule
        Rectangle {
          visible: macWifiWindow.activeSsid.length > 0 && macWifiWindow.wifiEnabled
          Layout.fillWidth: true
          implicitHeight: 40
          radius: 8
          color: macWifiWindow.isDark ? Qt.rgba(0, 122, 255, 0.22) : Qt.rgba(0, 122, 255, 0.12)

          RowLayout {
            anchors.fill: parent
            anchors.leftMargin: 10
            anchors.rightMargin: 10
            spacing: 8

            Text { text: "✓"; color: "#007aff"; font.weight: Font.Bold }
            Text {
              text: macWifiWindow.activeSsid
              font.family: "SF Pro Text"
              font.pixelSize: 12
              font.weight: Font.DemiBold
              color: macWifiWindow.isDark ? "#ffffff" : "#1a1a1a"
              Layout.fillWidth: true
              elide: Text.ElideRight
            }
            Text { text: "󰤨"; font.pixelSize: 14; color: "#007aff" }
          }
        }

        // Known / Available Networks Title
        RowLayout {
          visible: macWifiWindow.wifiEnabled
          Layout.fillWidth: true
          Text {
            text: macWifiWindow.searchText.length > 0 ? "Search Results (" + macWifiWindow.filteredNetworks.length + ")" : "Available Networks"
            font.family: "SF Pro Text"
            font.pixelSize: 11
            font.weight: Font.DemiBold
            color: macWifiWindow.isDark ? Qt.rgba(1, 1, 1, 0.5) : Qt.rgba(0, 0, 0, 0.45)
            Layout.fillWidth: true
          }
          Text {
            visible: macWifiWindow.isScanning
            text: "Scanning..."
            font.family: "SF Pro Text"
            font.pixelSize: 10
            color: "#007aff"
          }
        }

        ScrollView {
          visible: macWifiWindow.wifiEnabled
          Layout.fillWidth: true
          Layout.fillHeight: true
          clip: true

          ListView {
            id: macNetList
            width: parent.width
            model: macWifiWindow.filteredNetworks
            spacing: 3

            delegate: Rectangle {
              width: macNetList.width
              implicitHeight: 34
              radius: 6
              color: macRowM.containsMouse ? (macWifiWindow.isDark ? Qt.rgba(1, 1, 1, 0.10) : Qt.rgba(0, 0, 0, 0.06)) : "transparent"

              RowLayout {
                anchors.fill: parent
                anchors.leftMargin: 8
                anchors.rightMargin: 8
                spacing: 8

                Text { text: modelData.inUse ? "󰤨" : (modelData.signal > 60 ? "󰤨" : (modelData.signal > 30 ? "󰤥" : "󰤟")); font.pixelSize: 13; color: modelData.inUse ? "#007aff" : (macWifiWindow.isDark ? "#ffffff" : "#1a1a1a") }
                Text {
                  text: modelData.ssid
                  font.family: "SF Pro Text"
                  font.pixelSize: 12
                  font.weight: modelData.inUse ? Font.DemiBold : Font.Normal
                  color: modelData.inUse ? "#007aff" : (macWifiWindow.isDark ? "#ffffff" : "#1a1a1a")
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
                  macWifiWindow.connectWifi(modelData.ssid, "")
                  if (!scanPoller.running) scanPoller.running = true
                }
              }
            }
          }
        }

        // Footer Link
        Rectangle {
          Layout.fillWidth: true
          implicitHeight: 30
          radius: 6
          color: prefM.containsMouse ? (macWifiWindow.isDark ? Qt.rgba(1, 1, 1, 0.08) : Qt.rgba(0, 0, 0, 0.05)) : "transparent"
          Text {
            anchors.centerIn: parent
            text: "Wi-Fi Settings..."
            font.family: "SF Pro Text"
            font.pixelSize: 11
            color: "#007aff"
          }
          MouseArea {
            id: prefM
            anchors.fill: parent
            hoverEnabled: true
            cursorShape: Qt.PointingHandCursor
            onClicked: {
              Qt.quit()
              macWifiWindow.runCmd("nm-connection-editor || omarchy-undercover-settings")
            }
          }
        }
      }
    }
  }
}

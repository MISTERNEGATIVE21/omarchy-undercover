import Quickshell
import Quickshell.Wayland
import Quickshell.Hyprland
import Quickshell.Io
import QtQuick
import QtQuick.Layouts
import QtQuick.Controls

ShellRoot {
  PanelWindow {
    id: wifiWindow
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
    color: "transparent"

    implicitWidth: Math.min(380, (screen ? screen.width : 1280) - 24)
    implicitHeight: Math.min(460, (screen ? screen.height : 720) - 70)

    property bool isDark: true
    property bool wifiEnabled: true
    property string activeSsid: ""
    property var networks: []
    property string connectingSsid: ""
    property string passwordInput: ""
    property bool isScanning: false
    property string searchText: ""

    // Fluent Design Theme Tokens
    readonly property color cardBg: isDark ? Qt.rgba(0.13, 0.14, 0.17, 0.98) : Qt.rgba(0.97, 0.98, 0.99, 0.98)
    readonly property color cardBorder: isDark ? Qt.rgba(1, 1, 1, 0.14) : Qt.rgba(0, 0, 0, 0.12)
    readonly property color innerCardBg: isDark ? Qt.rgba(1, 1, 1, 0.08) : "#ffffff"
    readonly property color innerCardBorder: isDark ? Qt.rgba(1, 1, 1, 0.12) : Qt.rgba(0, 0, 0, 0.10)
    readonly property color textPrimary: isDark ? "#ffffff" : "#111111"
    readonly property color textSecondary: isDark ? Qt.rgba(1, 1, 1, 0.74) : "#555555"
    readonly property color textMuted: isDark ? Qt.rgba(1, 1, 1, 0.52) : "#777777"
    readonly property color accentColor: isDark ? "#60cdff" : "#0067c0"
    readonly property color hoverBg: isDark ? Qt.rgba(1, 1, 1, 0.08) : Qt.rgba(0, 0, 0, 0.05)

    readonly property var filteredNetworks: {
      var q = wifiWindow.searchText.toLowerCase().trim()
      var result = []
      for (var i = 0; i < wifiWindow.networks.length; i++) {
        var n = wifiWindow.networks[i]
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
      wifiWindow.isScanning = true
      wifiWindow.networks = []
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
        wifiWindow.triggerScan()
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
      command: ["bash", "-c", "cat $HOME/.config/omarchy-undercover/state 2>/dev/null || echo 'win11-dark'"]
      stdout: SplitParser {
        onRead: function(line) {
          var s = String(line).trim()
          wifiWindow.isDark = (s.indexOf("light") === -1)
        }
      }
    }

    // Wi-Fi Radio status poller
    Process {
      id: radioPoller
      running: true
      command: ["bash", "-c", "omarchy-wifi-dbus radio"]
      stdout: SplitParser {
        onRead: function(line) {
          wifiWindow.wifiEnabled = (String(line).trim().toLowerCase() === "enabled")
        }
      }
    }

    // Wi-Fi Scan Process (NetworkManager over D-Bus)
    Process {
      id: scanPoller
      running: true
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
              if (inUse) wifiWindow.activeSsid = ssid
              var currentList = wifiWindow.networks.slice(0)
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
              wifiWindow.networks = currentList
            }
          }
        }
      }
      onExited: function() {
        wifiWindow.isScanning = false
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

    function getSignalIcon(sig) {
      if (sig >= 75) return "󰤨"
      if (sig >= 50) return "󰤥"
      if (sig >= 25) return "󰤢"
      return "󰤟"
    }

    Rectangle {
      id: card
      anchors.fill: parent
      radius: 12
      color: wifiWindow.cardBg
      border.color: wifiWindow.cardBorder
      border.width: 1
      clip: true

      ColumnLayout {
        anchors.fill: parent
        anchors.margins: 16
        spacing: 12

        // Header Row
        RowLayout {
          Layout.fillWidth: true
          implicitHeight: 30
          spacing: 10

          Text {
            text: "󰤨"
            font.pixelSize: 18
            color: wifiWindow.accentColor
          }

          Text {
            text: "Wi-Fi Networks"
            font.family: "Segoe UI, sans-serif"
            font.pixelSize: 14
            font.weight: Font.DemiBold
            color: wifiWindow.textPrimary
            Layout.fillWidth: true
          }

          // Scan button
          Rectangle {
            implicitWidth: 28
            implicitHeight: 28
            radius: 6
            color: scanMouse.containsMouse ? (wifiWindow.isDark ? Qt.rgba(1, 1, 1, 0.12) : Qt.rgba(0, 0, 0, 0.08)) : "transparent"
            Text {
              anchors.centerIn: parent
              text: "🔄"
              font.pixelSize: 12
              color: wifiWindow.textPrimary
            }
            MouseArea {
              id: scanMouse
              anchors.fill: parent
              hoverEnabled: true
              cursorShape: Qt.PointingHandCursor
              onClicked: wifiWindow.triggerScan()
            }
          }

          // Close button
          Rectangle {
            implicitWidth: 28
            implicitHeight: 28
            radius: 6
            color: closeMouse.containsMouse ? Qt.rgba(196, 43, 28, 0.16) : "transparent"
            Text {
              anchors.centerIn: parent
              text: "✕"
              font.pixelSize: 12
              color: closeMouse.containsMouse ? "#c42b1c" : wifiWindow.textPrimary
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

        // Wi-Fi Power Switch Card
        Rectangle {
          Layout.fillWidth: true
          implicitHeight: 46
          radius: 8
          color: wifiWindow.innerCardBg
          border.color: wifiWindow.innerCardBorder
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
                font.pixelSize: 13
                font.weight: Font.DemiBold
                color: wifiWindow.textPrimary
              }
              Text {
                text: wifiWindow.wifiEnabled ? "Enabled" : "Disabled"
                font.family: "Segoe UI, sans-serif"
                font.pixelSize: 11
                color: wifiWindow.textSecondary
              }
            }

            Rectangle {
              implicitWidth: 44
              implicitHeight: 22
              radius: 11
              color: wifiWindow.wifiEnabled ? wifiWindow.accentColor : Qt.rgba(0.5, 0.5, 0.5, 0.4)

              Rectangle {
                anchors.verticalCenter: parent.verticalCenter
                x: wifiWindow.wifiEnabled ? parent.width - width - 3 : 3
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
                  var target = !wifiWindow.wifiEnabled
                  wifiWindow.wifiEnabled = target
                  Quickshell.execDetached(["omarchy-wifi-dbus", target ? "on" : "off"])
                  wifiWindow.triggerScan()
                }
              }
            }
          }
        }

        // Search Bar
        Rectangle {
          visible: wifiWindow.wifiEnabled
          Layout.fillWidth: true
          implicitHeight: 34
          radius: 6
          color: wifiWindow.innerCardBg
          border.color: wifiWindow.innerCardBorder
          border.width: 1

          RowLayout {
            anchors.fill: parent
            anchors.leftMargin: 10
            anchors.rightMargin: 10
            spacing: 8

            Text {
              text: "🔍"
              font.pixelSize: 11
              color: wifiWindow.textMuted
            }

            TextInput {
              id: win11WifiSearch
              Layout.fillWidth: true
              color: wifiWindow.textPrimary
              font.family: "Segoe UI, sans-serif"
              font.pixelSize: 12
              clip: true
              onTextChanged: wifiWindow.searchText = text

              Text {
                text: "Search Wi-Fi networks..."
                color: wifiWindow.textMuted
                font: win11WifiSearch.font
                visible: !win11WifiSearch.text && !win11WifiSearch.activeFocus
              }
            }

            Rectangle {
              visible: win11WifiSearch.text.length > 0
              implicitWidth: 18
              implicitHeight: 18
              radius: 9
              color: wifiWindow.isDark ? Qt.rgba(1, 1, 1, 0.16) : Qt.rgba(0, 0, 0, 0.08)
              Text {
                anchors.centerIn: parent
                text: "✕"
                font.pixelSize: 9
                color: wifiWindow.textPrimary
              }
              MouseArea {
                anchors.fill: parent
                cursorShape: Qt.PointingHandCursor
                onClicked: {
                  win11WifiSearch.text = ""
                  wifiWindow.searchText = ""
                }
              }
            }
          }
        }

        // Active Connected Banner
        Rectangle {
          visible: wifiWindow.activeSsid.length > 0 && wifiWindow.wifiEnabled
          Layout.fillWidth: true
          implicitHeight: 52
          radius: 8
          color: wifiWindow.isDark ? Qt.rgba(0, 120, 212, 0.20) : Qt.rgba(0, 103, 192, 0.08)
          border.color: wifiWindow.isDark ? "#60cdff" : Qt.rgba(0, 103, 192, 0.35)
          border.width: 1

          RowLayout {
            anchors.fill: parent
            anchors.leftMargin: 12
            anchors.rightMargin: 12
            spacing: 10

            Text {
              text: "󰤨"
              font.pixelSize: 20
              color: wifiWindow.accentColor
            }

            ColumnLayout {
              spacing: 1
              Layout.fillWidth: true
              Text {
                text: wifiWindow.activeSsid
                font.family: "Segoe UI, sans-serif"
                font.pixelSize: 12
                font.weight: Font.DemiBold
                color: wifiWindow.textPrimary
                elide: Text.ElideRight
              }
              Text {
                text: "Connected, secured"
                font.family: "Segoe UI, sans-serif"
                font.pixelSize: 10
                color: wifiWindow.textSecondary
              }
            }

            Rectangle {
              implicitWidth: 84
              implicitHeight: 28
              radius: 6
              color: disMouse.containsMouse
                ? (wifiWindow.isDark ? "#d83b01" : "#c42b1c")
                : (wifiWindow.isDark ? Qt.rgba(255, 95, 86, 0.16) : Qt.rgba(196, 43, 28, 0.08))
              border.color: disMouse.containsMouse
                ? "transparent"
                : (wifiWindow.isDark ? Qt.rgba(255, 95, 86, 0.35) : Qt.rgba(196, 43, 28, 0.35))
              border.width: 1

              Text {
                anchors.centerIn: parent
                text: "Disconnect"
                font.family: "Segoe UI, sans-serif"
                font.pixelSize: 11
                font.weight: Font.DemiBold
                color: disMouse.containsMouse
                  ? "#ffffff"
                  : (wifiWindow.isDark ? "#ff7b72" : "#c42b1c")
              }
              MouseArea {
                id: disMouse
                anchors.fill: parent
                hoverEnabled: true
                cursorShape: Qt.PointingHandCursor
                onClicked: {
                  Quickshell.execDetached(["omarchy-wifi-dbus", "disconnect"])
                  wifiWindow.activeSsid = ""
                  wifiWindow.triggerScan()
                }
              }
            }
          }
        }

        // Available Networks Section Title
        RowLayout {
          visible: wifiWindow.wifiEnabled
          Layout.fillWidth: true
          Text {
            text: wifiWindow.searchText.length > 0
              ? "Search Results (" + wifiWindow.filteredNetworks.length + ")"
              : "Available Networks"
            font.family: "Segoe UI, sans-serif"
            font.pixelSize: 12
            font.weight: Font.DemiBold
            color: wifiWindow.textPrimary
            Layout.fillWidth: true
          }
          Text {
            visible: wifiWindow.isScanning
            text: "Scanning..."
            font.family: "Segoe UI, sans-serif"
            font.pixelSize: 11
            color: wifiWindow.accentColor
          }
        }

        // Empty State / Searching State
        Rectangle {
          visible: wifiWindow.wifiEnabled && wifiWindow.filteredNetworks.length === 0
          Layout.fillWidth: true
          Layout.fillHeight: true
          radius: 8
          color: wifiWindow.isDark ? Qt.rgba(1, 1, 1, 0.04) : Qt.rgba(0, 0, 0, 0.02)
          border.color: wifiWindow.isDark ? Qt.rgba(1, 1, 1, 0.08) : Qt.rgba(0, 0, 0, 0.06)
          border.width: 1

          ColumnLayout {
            anchors.centerIn: parent
            spacing: 8

            Text {
              Layout.alignment: Qt.AlignHCenter
              text: wifiWindow.isScanning ? "󰤩" : "󰤮"
              font.pixelSize: 28
              color: wifiWindow.accentColor
            }

            Text {
              Layout.alignment: Qt.AlignHCenter
              text: wifiWindow.isScanning
                ? "Searching for Wi-Fi networks..."
                : (wifiWindow.searchText.length > 0 ? "No networks matching \"" + wifiWindow.searchText + "\"" : "No networks found")
              font.family: "Segoe UI, sans-serif"
              font.pixelSize: 12
              color: wifiWindow.textSecondary
            }

            Rectangle {
              visible: !wifiWindow.isScanning
              Layout.alignment: Qt.AlignHCenter
              implicitWidth: 100
              implicitHeight: 28
              radius: 6
              color: emptyScanM.containsMouse ? wifiWindow.accentColor : wifiWindow.innerCardBg
              border.color: emptyScanM.containsMouse ? "transparent" : wifiWindow.innerCardBorder
              border.width: 1

              Text {
                anchors.centerIn: parent
                text: "Scan again"
                font.family: "Segoe UI, sans-serif"
                font.pixelSize: 11
                font.weight: Font.DemiBold
                color: emptyScanM.containsMouse ? "#ffffff" : wifiWindow.accentColor
              }

              MouseArea {
                id: emptyScanM
                anchors.fill: parent
                hoverEnabled: true
                cursorShape: Qt.PointingHandCursor
                onClicked: wifiWindow.triggerScan()
              }
            }
          }
        }

        // Networks ScrollView
        ScrollView {
          visible: wifiWindow.wifiEnabled && wifiWindow.filteredNetworks.length > 0
          Layout.fillWidth: true
          Layout.fillHeight: true
          clip: true

          ListView {
            id: netListView
            width: parent.width
            model: wifiWindow.filteredNetworks
            spacing: 4

            delegate: ColumnLayout {
              width: netListView.width
              spacing: 4

              Rectangle {
                Layout.fillWidth: true
                implicitHeight: 42
                radius: 6
                color: modelData.inUse
                  ? (wifiWindow.isDark ? Qt.rgba(0, 120, 212, 0.16) : Qt.rgba(0, 103, 192, 0.08))
                  : (netRowMouse.containsMouse ? wifiWindow.hoverBg : "transparent")
                border.color: modelData.inUse
                  ? (wifiWindow.isDark ? Qt.rgba(96, 205, 255, 0.30) : Qt.rgba(0, 103, 192, 0.20))
                  : "transparent"
                border.width: modelData.inUse ? 1 : 0

                RowLayout {
                  anchors.fill: parent
                  anchors.leftMargin: 10
                  anchors.rightMargin: 10
                  spacing: 10

                  Text {
                    text: wifiWindow.getSignalIcon(modelData.signal)
                    font.pixelSize: 16
                    color: modelData.inUse ? wifiWindow.accentColor : wifiWindow.textPrimary
                  }

                  Text {
                    text: modelData.ssid
                    font.family: "Segoe UI, sans-serif"
                    font.pixelSize: 12
                    font.weight: modelData.inUse ? Font.DemiBold : Font.Normal
                    color: wifiWindow.textPrimary
                    elide: Text.ElideRight
                    Layout.fillWidth: true
                  }

                  Rectangle {
                    visible: modelData.inUse
                    implicitWidth: 64
                    implicitHeight: 20
                    radius: 10
                    color: wifiWindow.isDark ? Qt.rgba(0, 120, 212, 0.25) : Qt.rgba(0, 103, 192, 0.12)
                    Text {
                      anchors.centerIn: parent
                      text: "Connected"
                      font.family: "Segoe UI, sans-serif"
                      font.pixelSize: 10
                      font.weight: Font.DemiBold
                      color: wifiWindow.accentColor
                    }
                  }

                  Text {
                    visible: modelData.isSecured && !modelData.inUse
                    text: "🔒"
                    font.pixelSize: 11
                    color: wifiWindow.textSecondary
                  }
                }

                MouseArea {
                  id: netRowMouse
                  anchors.fill: parent
                  hoverEnabled: true
                  cursorShape: Qt.PointingHandCursor
                  onClicked: {
                    if (modelData.inUse) return
                    if (modelData.isSecured) {
                      wifiWindow.connectingSsid = (wifiWindow.connectingSsid === modelData.ssid ? "" : modelData.ssid)
                      wifiWindow.passwordInput = ""
                    } else {
                      wifiWindow.connectWifi(modelData.ssid, "")
                      wifiWindow.triggerScan()
                    }
                  }
                }
              }

              // Inline Password Input Panel
              Rectangle {
                visible: wifiWindow.connectingSsid === modelData.ssid
                Layout.fillWidth: true
                implicitHeight: 68
                radius: 6
                color: wifiWindow.innerCardBg
                border.color: wifiWindow.innerCardBorder
                border.width: 1

                ColumnLayout {
                  anchors.fill: parent
                  anchors.margins: 8
                  spacing: 6

                  RowLayout {
                    Layout.fillWidth: true
                    spacing: 8

                    Rectangle {
                      Layout.fillWidth: true
                      implicitHeight: 30
                      radius: 4
                      color: wifiWindow.isDark ? Qt.rgba(0, 0, 0, 0.40) : "#ffffff"
                      border.color: wifiWindow.isDark ? Qt.rgba(1, 1, 1, 0.20) : Qt.rgba(0, 0, 0, 0.18)
                      border.width: 1

                      TextInput {
                        id: pwInput
                        anchors.fill: parent
                        anchors.leftMargin: 8
                        anchors.rightMargin: 8
                        echoMode: TextInput.Password
                        font.pixelSize: 12
                        color: wifiWindow.textPrimary
                        selectByMouse: true
                        onTextChanged: wifiWindow.passwordInput = text
                        onAccepted: {
                          wifiWindow.connectWifi(modelData.ssid, pwInput.text)
                          pwInput.text = ""
                          wifiWindow.connectingSsid = ""
                          wifiWindow.triggerScan()
                        }
                      }
                    }

                    Rectangle {
                      implicitWidth: 70
                      implicitHeight: 30
                      radius: 4
                      color: wifiWindow.accentColor
                      Text {
                        anchors.centerIn: parent
                        text: "Connect"
                        color: "#ffffff"
                        font.family: "Segoe UI, sans-serif"
                        font.pixelSize: 11
                        font.weight: Font.DemiBold
                      }
                      MouseArea {
                        anchors.fill: parent
                        cursorShape: Qt.PointingHandCursor
                        onClicked: {
                          wifiWindow.connectWifi(modelData.ssid, pwInput.text)
                          pwInput.text = ""
                          wifiWindow.connectingSsid = ""
                          wifiWindow.triggerScan()
                        }
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
          implicitHeight: 34
          radius: 6
          color: setLinkM.containsMouse ? wifiWindow.hoverBg : "transparent"
          RowLayout {
            anchors.centerIn: parent
            spacing: 8
            Text {
              text: "⚙️"
              font.pixelSize: 13
            }
            Text {
              text: "More Wi-Fi settings"
              font.family: "Segoe UI, sans-serif"
              font.pixelSize: 11
              font.weight: Font.DemiBold
              color: wifiWindow.accentColor
            }
          }
          MouseArea {
            id: setLinkM
            anchors.fill: parent
            hoverEnabled: true
            cursorShape: Qt.PointingHandCursor
            onClicked: {
              Qt.quit()
              wifiWindow.runCmd("nm-connection-editor || omarchy-undercover-settings")
            }
          }
        }
      }
    }
  }
}

import Quickshell
import Quickshell.Wayland
import Quickshell.Hyprland
import Quickshell.Io
import QtQuick
import QtQuick.Layouts
import QtQuick.Controls

ShellRoot {
  PanelWindow {
    id: btWindow
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
    property bool btEnabled: true
    property var pairedDevices: []
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

    readonly property var filteredDevices: {
      var q = btWindow.searchText.toLowerCase().trim()
      var result = []
      for (var i = 0; i < btWindow.pairedDevices.length; i++) {
        var d = btWindow.pairedDevices[i]
        if ((d.name && d.name.toLowerCase().indexOf(q) !== -1) || (d.mac && d.mac.toLowerCase().indexOf(q) !== -1)) {
          result.push(d)
        }
      }
      // Connected first, then alphabetically by name.
      result.sort(function(a, b) {
        if (a.connected && !b.connected) return -1
        if (!a.connected && b.connected) return 1
        return (a.name || "").localeCompare(b.name || "")
      })
      return result
    }

    function runCmd(cmd) {
      btWindow.visible = false
      Qt.quit()
      Quickshell.execDetached(["bash", "-c", cmd])
    }

    // Theme state poller
    Process {
      id: statePoller
      running: true
      command: ["bash", "-c", "cat $HOME/.config/omarchy-undercover/state 2>/dev/null || echo 'win11-dark'"]
      stdout: SplitParser {
        onRead: function(line) {
          var s = String(line).trim()
          btWindow.isDark = (s.indexOf("light") === -1)
        }
      }
    }

    // Bluetooth power poller
    Process {
      id: powerPoller
      running: true
      command: ["bash", "-c", "omarchy-bluetooth-dbus power"]
      stdout: SplitParser {
        onRead: function(line) {
          btWindow.btEnabled = (String(line).trim().toLowerCase() === "yes")
        }
      }
    }

    // Devices query & scan (BlueZ over D-Bus)
    Process {
      id: devicesPoller
      running: true
      command: ["bash", "-c", "omarchy-bluetooth-dbus listwin"]
      stdout: SplitParser {
        onRead: function(line) {
          var l = String(line).trim()
          if (!l) return
          var parts = l.split("|")
          if (parts.length >= 3) {
            var mac = parts[0]
            var connected = (parts[1] === "1")
            var name = parts.slice(2).join("|")
            var currentList = btWindow.pairedDevices.slice(0)
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
            btWindow.pairedDevices = currentList
          }
        }
      }
      onExited: function() {
        btWindow.isScanning = false
      }
    }

    Process {
      id: discoverPoller
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
            var currentList = btWindow.pairedDevices.slice(0)
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
            btWindow.pairedDevices = currentList
          }
        }
      }
      onExited: function() {
        btWindow.isScanning = false
      }
    }

    function triggerQuery() {
      btWindow.isScanning = true
      btWindow.pairedDevices = []
      if (!discoverPoller.running) discoverPoller.running = true
    }

    Timer {
      interval: 8000
      running: true
      repeat: true
      triggeredOnStart: true
      onTriggered: {
        if (!powerPoller.running) powerPoller.running = true
        if (!devicesPoller.running) devicesPoller.running = true
      }
    }

    Rectangle {
      id: card
      anchors.fill: parent
      radius: 12
      color: btWindow.cardBg
      border.color: btWindow.cardBorder
      border.width: 1
      clip: true
      opacity: 0
      y: 12

      Behavior on opacity { NumberAnimation { duration: 160; easing.type: Easing.OutCubic } }
      Behavior on y { NumberAnimation { duration: 160; easing.type: Easing.OutCubic } }

      Component.onCompleted: {
        opacity = 1.0
        y = 0
      }

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
            text: "󰂯"
            font.pixelSize: 18
            color: btWindow.accentColor
          }

          Text {
            text: "Bluetooth Devices"
            font.family: "Segoe UI, sans-serif"
            font.pixelSize: 14
            font.weight: Font.DemiBold
            color: btWindow.textPrimary
            Layout.fillWidth: true
          }

          // Scan button
          Rectangle {
            implicitWidth: 28
            implicitHeight: 28
            radius: 6
            color: scanMouse.containsMouse ? (btWindow.isDark ? Qt.rgba(1, 1, 1, 0.12) : Qt.rgba(0, 0, 0, 0.08)) : "transparent"
            Text {
              anchors.centerIn: parent
              text: "󰑐"
              font.pixelSize: 13
              color: btWindow.textPrimary
            }
            MouseArea {
              id: scanMouse
              anchors.fill: parent
              hoverEnabled: true
              cursorShape: Qt.PointingHandCursor
              onClicked: btWindow.triggerQuery()
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
              color: closeMouse.containsMouse ? "#c42b1c" : btWindow.textPrimary
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

        // Bluetooth Power Switch Card
        Rectangle {
          Layout.fillWidth: true
          implicitHeight: 46
          radius: 8
          color: btWindow.innerCardBg
          border.color: btWindow.innerCardBorder
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
                font.pixelSize: 13
                font.weight: Font.DemiBold
                color: btWindow.textPrimary
              }
              Text {
                text: btWindow.btEnabled ? "Discoverable and active" : "Turned off"
                font.family: "Segoe UI, sans-serif"
                font.pixelSize: 11
                color: btWindow.textSecondary
              }
            }

            Rectangle {
              implicitWidth: 44
              implicitHeight: 22
              radius: 11
              color: btWindow.btEnabled ? btWindow.accentColor : Qt.rgba(0.5, 0.5, 0.5, 0.4)

              Rectangle {
                anchors.verticalCenter: parent.verticalCenter
                x: btWindow.btEnabled ? parent.width - width - 3 : 3
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
                  var target = !btWindow.btEnabled
                  btWindow.btEnabled = target
                  Quickshell.execDetached(["omarchy-bluetooth-dbus", target ? "on" : "off"])
                  btWindow.triggerQuery()
                }
              }
            }
          }
        }

        // Search Bar
        Rectangle {
          visible: btWindow.btEnabled
          Layout.fillWidth: true
          implicitHeight: 34
          radius: 6
          color: btWindow.innerCardBg
          border.color: btWindow.innerCardBorder
          border.width: 1

          RowLayout {
            anchors.fill: parent
            anchors.leftMargin: 10
            anchors.rightMargin: 10
            spacing: 8

            Text {
              text: "󰍉"
              font.pixelSize: 13
              color: btWindow.textMuted
            }

            TextInput {
              id: win11BtSearch
              Layout.fillWidth: true
              color: btWindow.textPrimary
              font.family: "Segoe UI, sans-serif"
              font.pixelSize: 12
              clip: true
              onTextChanged: btWindow.searchText = text

              Text {
                text: "Search Bluetooth devices..."
                color: btWindow.textMuted
                font: win11BtSearch.font
                visible: !win11BtSearch.text && !win11BtSearch.activeFocus
              }
            }

            Rectangle {
              visible: win11BtSearch.text.length > 0
              implicitWidth: 18
              implicitHeight: 18
              radius: 9
              color: btWindow.isDark ? Qt.rgba(1, 1, 1, 0.16) : Qt.rgba(0, 0, 0, 0.08)
              Text {
                anchors.centerIn: parent
                text: "✕"
                font.pixelSize: 9
                color: btWindow.textPrimary
              }
              MouseArea {
                anchors.fill: parent
                cursorShape: Qt.PointingHandCursor
                onClicked: {
                  win11BtSearch.text = ""
                  btWindow.searchText = ""
                }
              }
            }
          }
        }

        // Devices Title & Scanning Indicator
        RowLayout {
          visible: btWindow.btEnabled
          Layout.fillWidth: true
          Text {
            text: btWindow.searchText.length > 0
              ? "Search Results (" + btWindow.filteredDevices.length + ")"
              : "Paired & Available Devices"
            font.family: "Segoe UI, sans-serif"
            font.pixelSize: 12
            font.weight: Font.DemiBold
            color: btWindow.textPrimary
            Layout.fillWidth: true
          }
          Text {
            visible: btWindow.isScanning
            text: "󰂰 Scanning..."
            font.family: "Segoe UI, sans-serif"
            font.pixelSize: 11
            color: btWindow.accentColor
          }
        }

        // Empty State / Searching State
        Rectangle {
          visible: btWindow.btEnabled && btWindow.filteredDevices.length === 0
          Layout.fillWidth: true
          Layout.fillHeight: true
          radius: 8
          color: btWindow.isDark ? Qt.rgba(1, 1, 1, 0.04) : Qt.rgba(0, 0, 0, 0.02)
          border.color: btWindow.isDark ? Qt.rgba(1, 1, 1, 0.08) : Qt.rgba(0, 0, 0, 0.06)
          border.width: 1

          ColumnLayout {
            anchors.centerIn: parent
            spacing: 8

            Text {
              Layout.alignment: Qt.AlignHCenter
              text: btWindow.isScanning ? "󰂰" : "󰂲"
              font.pixelSize: 28
              color: btWindow.accentColor
            }

            Text {
              Layout.alignment: Qt.AlignHCenter
              text: btWindow.isScanning
                ? "Scanning for nearby devices..."
                : (btWindow.searchText.length > 0 ? "No devices matching \"" + btWindow.searchText + "\"" : "No Bluetooth devices found")
              font.family: "Segoe UI, sans-serif"
              font.pixelSize: 12
              color: btWindow.textSecondary
            }

            Rectangle {
              visible: !btWindow.isScanning
              Layout.alignment: Qt.AlignHCenter
              implicitWidth: 100
              implicitHeight: 28
              radius: 6
              color: emptyBtScanM.containsMouse ? btWindow.accentColor : btWindow.innerCardBg
              border.color: emptyBtScanM.containsMouse ? "transparent" : btWindow.innerCardBorder
              border.width: 1

              Text {
                anchors.centerIn: parent
                text: "Scan again"
                font.family: "Segoe UI, sans-serif"
                font.pixelSize: 11
                font.weight: Font.DemiBold
                color: emptyBtScanM.containsMouse ? "#ffffff" : btWindow.accentColor
              }

              MouseArea {
                id: emptyBtScanM
                anchors.fill: parent
                hoverEnabled: true
                cursorShape: Qt.PointingHandCursor
                onClicked: btWindow.triggerQuery()
              }
            }
          }
        }

        // Devices ScrollView
        ScrollView {
          visible: btWindow.btEnabled && btWindow.filteredDevices.length > 0
          Layout.fillWidth: true
          Layout.fillHeight: true
          clip: true

          ListView {
            id: btListView
            width: parent.width
            model: btWindow.filteredDevices
            spacing: 4

            delegate: Rectangle {
              width: btListView.width
              implicitHeight: 48
              radius: 6
              color: modelData.connected
                ? (btWindow.isDark ? Qt.rgba(0, 120, 212, 0.16) : Qt.rgba(0, 103, 192, 0.08))
                : (devRowMouse.containsMouse ? btWindow.hoverBg : "transparent")
              border.color: modelData.connected
                ? (btWindow.isDark ? Qt.rgba(96, 205, 255, 0.30) : Qt.rgba(0, 103, 192, 0.20))
                : "transparent"
              border.width: modelData.connected ? 1 : 0

              RowLayout {
                anchors.fill: parent
                anchors.leftMargin: 10
                anchors.rightMargin: 10
                spacing: 10

                Text {
                  text: modelData.type
                  font.pixelSize: 18
                }

                ColumnLayout {
                  spacing: 1
                  Layout.fillWidth: true
                  RowLayout {
                    spacing: 6
                    Text {
                      text: modelData.name
                      font.family: "Segoe UI, sans-serif"
                      font.pixelSize: 12
                      font.weight: modelData.connected ? Font.DemiBold : Font.Normal
                      color: btWindow.textPrimary
                      elide: Text.ElideRight
                      Layout.maximumWidth: 160
                    }
                    Rectangle {
                      visible: modelData.connected
                      implicitWidth: 64
                      implicitHeight: 18
                      radius: 9
                      color: btWindow.isDark ? Qt.rgba(0, 120, 212, 0.25) : Qt.rgba(0, 103, 192, 0.12)
                      Text {
                        anchors.centerIn: parent
                        text: "Connected"
                        font.family: "Segoe UI, sans-serif"
                        font.pixelSize: 9
                        font.weight: Font.DemiBold
                        color: btWindow.accentColor
                      }
                    }
                  }
                  Text {
                    text: modelData.mac
                    font.family: "Segoe UI, sans-serif"
                    font.pixelSize: 10
                    color: btWindow.textMuted
                  }
                }

                // Connect / Disconnect Action Button
                Rectangle {
                  implicitWidth: 76
                  implicitHeight: 28
                  radius: 5

                  color: modelData.connected
                    ? (btnConnM.containsMouse
                        ? (btWindow.isDark ? "#d83b01" : "#c42b1c")
                        : (btWindow.isDark ? Qt.rgba(255, 95, 86, 0.16) : Qt.rgba(196, 43, 28, 0.08)))
                    : (btnConnM.containsMouse
                        ? (btWindow.isDark ? "#0078d4" : "#0067c0")
                        : (btWindow.isDark ? Qt.rgba(0, 120, 212, 0.18) : Qt.rgba(0, 103, 192, 0.08)))

                  border.color: btnConnM.containsMouse
                    ? "transparent"
                    : (modelData.connected
                        ? (btWindow.isDark ? Qt.rgba(255, 95, 86, 0.35) : Qt.rgba(196, 43, 28, 0.35))
                        : (btWindow.isDark ? Qt.rgba(96, 205, 255, 0.35) : Qt.rgba(0, 103, 192, 0.35)))
                  border.width: 1

                  Text {
                    anchors.centerIn: parent
                    text: modelData.connected ? "Disconnect" : "Connect"
                    font.family: "Segoe UI, sans-serif"
                    font.pixelSize: 11
                    font.weight: Font.DemiBold
                    color: btnConnM.containsMouse
                      ? "#ffffff"
                      : (modelData.connected
                          ? (btWindow.isDark ? "#ff7b72" : "#c42b1c")
                          : (btWindow.isDark ? "#60cdff" : "#0067c0"))
                  }

                  MouseArea {
                    id: btnConnM
                    anchors.fill: parent
                    hoverEnabled: true
                    cursorShape: Qt.PointingHandCursor
                    onClicked: {
                      if (modelData.connected) {
                        Quickshell.execDetached(["omarchy-bluetooth-dbus", "disconnect", modelData.mac])
                      } else {
                        Quickshell.execDetached(["omarchy-bluetooth-dbus", "connect", modelData.mac])
                      }
                      btWindow.triggerQuery()
                    }
                  }
                }
              }

              MouseArea {
                id: devRowMouse
                anchors.fill: parent
                hoverEnabled: true
                cursorShape: Qt.PointingHandCursor
                acceptedButtons: Qt.RightButton
                onClicked: {
                  if (modelData.connected) {
                    Quickshell.execDetached(["omarchy-bluetooth-dbus", "disconnect", modelData.mac])
                    btWindow.triggerQuery()
                  }
                }
              }
            }
          }
        }

        // Bluetooth Settings Link Footer
        Rectangle {
          Layout.fillWidth: true
          implicitHeight: 34
          radius: 6
          color: btSetLinkM.containsMouse ? btWindow.hoverBg : "transparent"
          RowLayout {
            anchors.centerIn: parent
            spacing: 8
            Text {
              text: "⚙️"
              font.pixelSize: 13
            }
            Text {
              text: "More Bluetooth settings"
              font.family: "Segoe UI, sans-serif"
              font.pixelSize: 11
              font.weight: Font.DemiBold
              color: btWindow.accentColor
            }
          }
          MouseArea {
            id: btSetLinkM
            anchors.fill: parent
            hoverEnabled: true
            cursorShape: Qt.PointingHandCursor
            onClicked: {
              Qt.quit()
              btWindow.runCmd("blueman-manager || omarchy-undercover-settings")
            }
          }
        }
      }
    }
  }
}

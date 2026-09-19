import Quickshell
import Quickshell.Wayland
import Quickshell.Hyprland
import Quickshell.Io
import QtQuick
import QtQuick.Layouts
import QtQuick.Controls

ShellRoot {
  PanelWindow {
    id: macBtWindow
    screen: Quickshell.screens[0]

    anchors {
      top: true
      right: true
    }
    margins {
      top: 8
      right: 12
    }

    WlrLayershell.layer: WlrLayer.Overlay
    WlrLayershell.namespace: "omarchy-menu"
    color: "transparent"

    implicitWidth: Math.min(340, (screen ? screen.width : 1280) - 24)
    implicitHeight: Math.min(460, (screen ? screen.height : 720) - 50)

    property bool isDark: true
    property bool btEnabled: true
    property var pairedDevices: []
    property bool isScanning: false
    property string searchText: ""

    readonly property var filteredDevices: {
      var q = macBtWindow.searchText.toLowerCase().trim()
      var result = []
      for (var i = 0; i < macBtWindow.pairedDevices.length; i++) {
        var d = macBtWindow.pairedDevices[i]
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

    function triggerScan() {
      macBtWindow.isScanning = true
      macBtWindow.pairedDevices = []
      if (!discoverPoller.running) discoverPoller.running = true
    }

    function runCmd(cmd) {
      Quickshell.execDetached(["bash", "-c", cmd])
    }

    // Theme state poller
    Process {
      id: statePoller
      running: true
      command: ["bash", "-c", "cat $HOME/.config/omarchy-undercover/state 2>/dev/null || echo 'mac-dark'"]
      stdout: SplitParser {
        onRead: function(line) {
          var s = String(line).trim()
          macBtWindow.isDark = (s.indexOf("light") === -1)
        }
      }
    }

    // Bluetooth power poller (BlueZ over D-Bus)
    Process {
      id: powerPoller
      running: true
      command: ["bash", "-c", "omarchy-bluetooth-dbus power"]
      stdout: SplitParser {
        onRead: function(line) {
          macBtWindow.btEnabled = (String(line).trim().toLowerCase() === "yes")
        }
      }
    }

    // Devices query & discovery scan (BlueZ over D-Bus)
    Process {
      id: devicesPoller
      running: true
      command: ["bash", "-c", "omarchy-bluetooth-dbus listwin"]
      onExited: function() {
        macBtWindow.isScanning = false
      }
      stdout: SplitParser {
        onRead: function(line) {
          var l = String(line).trim()
          if (!l) return
          var parts = l.split("|")
          if (parts.length >= 3) {
            var mac = parts[0]
            var connected = (parts[1] === "1")
            var name = parts.slice(2).join("|")
            var currentList = macBtWindow.pairedDevices.slice(0)
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
            macBtWindow.pairedDevices = currentList
          }
        }
      }
    }

    Process {
      id: discoverPoller
      command: ["bash", "-c", "omarchy-bluetooth-dbus scan"]
      onExited: function() {
        macBtWindow.isScanning = false
      }
      stdout: SplitParser {
        onRead: function(line) {
          var l = String(line).trim()
          if (!l) return
          var parts = l.split("|")
          if (parts.length >= 3) {
            var mac = parts[0]
            var connected = (parts[1] === "1")
            var name = parts.slice(2).join("|")
            var currentList = macBtWindow.pairedDevices.slice(0)
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
            macBtWindow.pairedDevices = currentList
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
        if (!powerPoller.running) powerPoller.running = true
        if (!devicesPoller.running) devicesPoller.running = true
      }
    }

    Rectangle {
      anchors.fill: parent
      radius: 16
      color: macBtWindow.isDark ? Qt.rgba(0.12, 0.12, 0.17, 0.90) : Qt.rgba(0.96, 0.96, 0.98, 0.92)
      border.color: macBtWindow.isDark ? Qt.rgba(1, 1, 1, 0.18) : Qt.rgba(0, 0, 0, 0.12)
      border.width: 1

      ColumnLayout {
        anchors.fill: parent
        anchors.margins: 14
        spacing: 10

        // Header
        RowLayout {
          Layout.fillWidth: true
          Text {
            text: "Bluetooth"
            font.family: "SF Pro Text"
            font.pixelSize: 14
            font.weight: Font.Bold
            color: macBtWindow.isDark ? "#ffffff" : "#1a1a1a"
            Layout.fillWidth: true
          }

          // Scan / Refresh Button
          Rectangle {
            implicitWidth: 24
            implicitHeight: 24
            radius: 12
            color: scanM.containsMouse ? (macBtWindow.isDark ? Qt.rgba(1, 1, 1, 0.12) : Qt.rgba(0, 0, 0, 0.08)) : "transparent"
            Text {
              anchors.centerIn: parent
              text: "🔄"
              font.pixelSize: 11
              opacity: macBtWindow.isScanning ? 0.4 : 1.0
            }
            MouseArea {
              id: scanM
              anchors.fill: parent
              hoverEnabled: true
              cursorShape: Qt.PointingHandCursor
              onClicked: macBtWindow.triggerScan()
            }
          }

          Rectangle {
            implicitWidth: 38
            implicitHeight: 22
            radius: 11
            color: macBtWindow.btEnabled ? "#007aff" : Qt.rgba(0.5, 0.5, 0.5, 0.4)

            Rectangle {
              anchors.verticalCenter: parent.verticalCenter
              x: macBtWindow.btEnabled ? parent.width - width - 2 : 2
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
                var target = !macBtWindow.btEnabled
                macBtWindow.btEnabled = target
                Quickshell.execDetached(["omarchy-bluetooth-dbus", target ? "on" : "off"])
                if (!devicesPoller.running) devicesPoller.running = true
              }
            }
          }

          Rectangle {
            implicitWidth: 24
            implicitHeight: 24
            radius: 12
            color: closeM.containsMouse ? (macBtWindow.isDark ? Qt.rgba(1, 1, 1, 0.12) : Qt.rgba(0, 0, 0, 0.08)) : "transparent"
            Text { anchors.centerIn: parent; text: "✕"; font.pixelSize: 11; color: macBtWindow.isDark ? "#ffffff" : "#1a1a1a" }
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
          visible: macBtWindow.btEnabled
          Layout.fillWidth: true
          implicitHeight: 32
          radius: 8
          color: macBtWindow.isDark ? Qt.rgba(1, 1, 1, 0.08) : Qt.rgba(0, 0, 0, 0.05)
          border.color: macBtWindow.isDark ? Qt.rgba(1, 1, 1, 0.12) : Qt.rgba(0, 0, 0, 0.08)

          RowLayout {
            anchors.fill: parent
            anchors.leftMargin: 8
            anchors.rightMargin: 8
            spacing: 6

            Text { text: "🔍"; font.pixelSize: 11; opacity: 0.6 }

            TextInput {
              id: macBtSearchBox
              Layout.fillWidth: true
              color: macBtWindow.isDark ? "#ffffff" : "#1a1a1a"
              font.family: "SF Pro Text"
              font.pixelSize: 12
              clip: true
              onTextChanged: macBtWindow.searchText = text

              Text {
                text: "Search Bluetooth devices..."
                color: macBtWindow.isDark ? Qt.rgba(1, 1, 1, 0.4) : Qt.rgba(0, 0, 0, 0.4)
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
                  macBtWindow.searchText = ""
                }
              }
            }
          }
        }

        // Devices Title
        RowLayout {
          visible: macBtWindow.btEnabled
          Layout.fillWidth: true
          Text {
            text: macBtWindow.searchText.length > 0 ? "Search Results (" + macBtWindow.filteredDevices.length + ")" : "Devices"
            font.family: "SF Pro Text"
            font.pixelSize: 11
            font.weight: Font.DemiBold
            color: macBtWindow.isDark ? Qt.rgba(1, 1, 1, 0.5) : Qt.rgba(0, 0, 0, 0.45)
            Layout.fillWidth: true
          }
          Text {
            visible: macBtWindow.isScanning
            text: "Scanning..."
            font.family: "SF Pro Text"
            font.pixelSize: 10
            color: "#007aff"
          }
        }

        ScrollView {
          visible: macBtWindow.btEnabled
          Layout.fillWidth: true
          Layout.fillHeight: true
          clip: true

          ListView {
            id: macBtList
            width: parent.width
            model: macBtWindow.filteredDevices
            spacing: 3

            delegate: Rectangle {
              width: macBtList.width
              implicitHeight: 38
              radius: 6
              color: macRowM.containsMouse ? (macBtWindow.isDark ? Qt.rgba(1, 1, 1, 0.10) : Qt.rgba(0, 0, 0, 0.06)) : "transparent"

              RowLayout {
                anchors.fill: parent
                anchors.leftMargin: 8
                anchors.rightMargin: 8
                spacing: 8

                Text { text: modelData.type; font.pixelSize: 16 }
                Text {
                  text: modelData.name
                  font.family: "SF Pro Text"
                  font.pixelSize: 12
                  color: macBtWindow.isDark ? "#ffffff" : "#1a1a1a"
                  Layout.fillWidth: true
                  elide: Text.ElideRight
                }
                Text {
                  text: modelData.connected ? "Disconnect" : "Connect"
                  font.family: "SF Pro Text"
                  font.pixelSize: 10
                  color: modelData.connected ? (macBtWindow.isDark ? Qt.rgba(1, 1, 1, 0.6) : Qt.rgba(0, 0, 0, 0.5)) : "#007aff"
                  font.weight: Font.DemiBold
                }
              }

              MouseArea {
                id: macRowM
                anchors.fill: parent
                hoverEnabled: true
                cursorShape: Qt.PointingHandCursor
                onClicked: {
                  if (modelData.connected) {
                    Quickshell.execDetached(["omarchy-bluetooth-dbus", "disconnect", modelData.mac])
                  } else {
                    Quickshell.execDetached(["omarchy-bluetooth-dbus", "connect", modelData.mac])
                  }
                  macBtWindow.triggerScan()
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
          color: prefM.containsMouse ? (macBtWindow.isDark ? Qt.rgba(1, 1, 1, 0.08) : Qt.rgba(0, 0, 0, 0.05)) : "transparent"
          Text {
            anchors.centerIn: parent
            text: "Bluetooth Settings..."
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
              macBtWindow.runCmd("blueman-manager || omarchy-undercover-settings")
            }
          }
        }
      }
    }
  }
}

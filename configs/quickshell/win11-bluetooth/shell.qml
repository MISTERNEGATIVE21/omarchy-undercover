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
      bottom: 54
      right: 12
    }

    WlrLayershell.layer: WlrLayer.Overlay
    WlrLayershell.namespace: "omarchy-menu"
    color: "transparent"

    implicitWidth: 360
    implicitHeight: 480

    property bool isDark: true
    property bool btEnabled: true
    property var pairedDevices: []
    property bool isScanning: false

    function runCmd(cmd) {
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
      command: ["bash", "-c", "bluetoothctl show | grep -i 'Powered:' | awk '{print $2}' || echo 'no'"]
      stdout: SplitParser {
        onRead: function(line) {
          btWindow.btEnabled = (String(line).trim().toLowerCase() === "yes")
        }
      }
    }

    // Paired Devices query
    Process {
      id: devicesPoller
      command: ["bash", "-c", "bluetoothctl devices Paired 2>/dev/null"]
      stdout: SplitParser {
        onRead: function(line) {
          var l = String(line).trim()
          if (!l) return
          // Device 00:11:22:33:44:55 Device_Name
          var parts = l.split(" ")
          if (parts.length >= 3 && parts[0] === "Device") {
            var mac = parts[1]
            var name = parts.slice(2).join(" ")
            var currentList = btWindow.pairedDevices
            var exists = false
            for (var i = 0; i < currentList.length; i++) {
              if (currentList[i].mac === mac) {
                currentList[i].name = name
                exists = true
                break
              }
            }
            if (!exists) {
              currentList.push({
                mac: mac,
                name: name,
                connected: false,
                type: (name.toLowerCase().indexOf("headset") !== -1 || name.toLowerCase().indexOf("audio") !== -1 || name.toLowerCase().indexOf("airpods") !== -1 || name.toLowerCase().indexOf("wh-") !== -1) ? "🎧" : ((name.toLowerCase().indexOf("mouse") !== -1) ? "🖱️" : ((name.toLowerCase().indexOf("key") !== -1) ? "⌨️" : "📱"))
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
      btWindow.pairedDevices = []
      devicesPoller.running = true
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
      radius: 14
      color: btWindow.isDark ? Qt.rgba(0.12, 0.12, 0.16, 0.96) : Qt.rgba(0.97, 0.97, 0.98, 0.98)
      border.color: btWindow.isDark ? Qt.rgba(1, 1, 1, 0.14) : Qt.rgba(0, 0, 0, 0.10)
      border.width: 1

      ColumnLayout {
        anchors.fill: parent
        anchors.margins: 16
        spacing: 12

        // Header Row
        RowLayout {
          Layout.fillWidth: true
          spacing: 10

          Text {
            text: "󰂯"
            font.pixelSize: 18
            color: btWindow.isDark ? "#60cdff" : "#0067c0"
          }

          Text {
            text: "Bluetooth Devices"
            font.family: "Segoe UI"
            font.pixelSize: 14
            font.weight: Font.DemiBold
            color: btWindow.isDark ? "#ffffff" : "#1a1a1a"
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
              text: "🔄"
              font.pixelSize: 12
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
            color: closeMouse.containsMouse ? (btWindow.isDark ? Qt.rgba(1, 1, 1, 0.12) : Qt.rgba(0, 0, 0, 0.08)) : "transparent"
            Text {
              anchors.centerIn: parent
              text: "✕"
              font.pixelSize: 12
              color: btWindow.isDark ? "#ffffff" : "#1a1a1a"
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
          color: btWindow.isDark ? Qt.rgba(1, 1, 1, 0.06) : Qt.rgba(0, 0, 0, 0.04)
          border.color: btWindow.isDark ? Qt.rgba(1, 1, 1, 0.08) : Qt.rgba(0, 0, 0, 0.06)

          RowLayout {
            anchors.fill: parent
            anchors.leftMargin: 12
            anchors.rightMargin: 12

            Text {
              text: "Bluetooth"
              font.family: "Segoe UI"
              font.pixelSize: 12.5
              font.weight: Font.DemiBold
              color: btWindow.isDark ? "#ffffff" : "#1a1a1a"
              Layout.fillWidth: true
            }

            Rectangle {
              implicitWidth: 44
              implicitHeight: 22
              radius: 11
              color: btWindow.btEnabled ? (btWindow.isDark ? "#60cdff" : "#0067c0") : Qt.rgba(0.5, 0.5, 0.5, 0.4)

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
                  btWindow.runCmd("bluetoothctl power " + (target ? "on" : "off"))
                  btWindow.triggerQuery()
                }
              }
            }
          }
        }

        // Paired Devices Title
        Text {
          visible: btWindow.btEnabled
          text: "Paired Devices"
          font.family: "Segoe UI"
          font.pixelSize: 11
          font.weight: Font.DemiBold
          color: btWindow.isDark ? Qt.rgba(1, 1, 1, 0.6) : Qt.rgba(0, 0, 0, 0.5)
        }

        // Paired Devices ScrollView
        ScrollView {
          visible: btWindow.btEnabled
          Layout.fillWidth: true
          Layout.fillHeight: true
          clip: true

          ListView {
            id: btListView
            width: parent.width
            model: btWindow.pairedDevices
            spacing: 4

            delegate: Rectangle {
              width: btListView.width
              implicitHeight: 46
              radius: 6
              color: devRowMouse.containsMouse ? (btWindow.isDark ? Qt.rgba(1, 1, 1, 0.10) : Qt.rgba(0, 0, 0, 0.06)) : "transparent"

              RowLayout {
                anchors.fill: parent
                anchors.leftMargin: 8
                anchors.rightMargin: 8
                spacing: 10

                Text {
                  text: modelData.type
                  font.pixelSize: 18
                }

                ColumnLayout {
                  spacing: 1
                  Layout.fillWidth: true
                  Text {
                    text: modelData.name
                    font.family: "Segoe UI"
                    font.pixelSize: 12
                    font.weight: Font.DemiBold
                    color: btWindow.isDark ? "#ffffff" : "#1a1a1a"
                    elide: Text.ElideRight
                    Layout.fillWidth: true
                  }
                  Text {
                    text: modelData.mac
                    font.family: "Segoe UI"
                    font.pixelSize: 9.5
                    color: btWindow.isDark ? Qt.rgba(1, 1, 1, 0.5) : Qt.rgba(0, 0, 0, 0.45)
                  }
                }

                Rectangle {
                  implicitWidth: 68
                  implicitHeight: 26
                  radius: 5
                  color: btnConnM.containsMouse ? (btWindow.isDark ? "#0078d4" : "#0067c0") : (btWindow.isDark ? Qt.rgba(1, 1, 1, 0.12) : Qt.rgba(0, 0, 0, 0.08))

                  Text {
                    anchors.centerIn: parent
                    text: "Connect"
                    font.family: "Segoe UI"
                    font.pixelSize: 10.5
                    color: "#ffffff"
                  }

                  MouseArea {
                    id: btnConnM
                    anchors.fill: parent
                    hoverEnabled: true
                    cursorShape: Qt.PointingHandCursor
                    onClicked: {
                      btWindow.runCmd("bluetoothctl connect " + modelData.mac)
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
                  btWindow.runCmd("bluetoothctl disconnect " + modelData.mac)
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
          color: btSetLinkM.containsMouse ? (btWindow.isDark ? Qt.rgba(1, 1, 1, 0.08) : Qt.rgba(0, 0, 0, 0.06)) : "transparent"
          RowLayout {
            anchors.centerIn: parent
            spacing: 6
            Text { text: "⚙️"; font.pixelSize: 12 }
            Text {
              text: "More Bluetooth settings"
              font.family: "Segoe UI"
              font.pixelSize: 11
              font.weight: Font.DemiBold
              color: btWindow.isDark ? "#60cdff" : "#0067c0"
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

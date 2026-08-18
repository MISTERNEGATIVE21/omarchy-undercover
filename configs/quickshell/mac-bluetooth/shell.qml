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
      top: 36
      right: 12
    }

    WlrLayershell.layer: WlrLayer.Overlay
    WlrLayershell.namespace: "omarchy-menu"
    color: "transparent"

    implicitWidth: 340
    implicitHeight: 460

    property bool isDark: true
    property bool btEnabled: true
    property var pairedDevices: []

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

    // Bluetooth power poller
    Process {
      id: powerPoller
      running: true
      command: ["bash", "-c", "bluetoothctl show | grep -i 'Powered:' | awk '{print $2}' || echo 'no'"]
      stdout: SplitParser {
        onRead: function(line) {
          macBtWindow.btEnabled = (String(line).trim().toLowerCase() === "yes")
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
          var parts = l.split(" ")
          if (parts.length >= 3 && parts[0] === "Device") {
            var mac = parts[1]
            var name = parts.slice(2).join(" ")
            var currentList = macBtWindow.pairedDevices
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
                type: (name.toLowerCase().indexOf("airpods") !== -1 || name.toLowerCase().indexOf("head") !== -1) ? "🎧" : ((name.toLowerCase().indexOf("mouse") !== -1 || name.toLowerCase().indexOf("trackpad") !== -1) ? "🖱️" : ((name.toLowerCase().indexOf("key") !== -1) ? "⌨️" : "📱"))
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
                macBtWindow.runCmd("bluetoothctl power " + (target ? "on" : "off"))
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

        // Devices Title
        Text {
          visible: macBtWindow.btEnabled
          text: "Devices"
          font.family: "SF Pro Text"
          font.pixelSize: 11
          font.weight: Font.DemiBold
          color: macBtWindow.isDark ? Qt.rgba(1, 1, 1, 0.5) : Qt.rgba(0, 0, 0, 0.45)
        }

        ScrollView {
          visible: macBtWindow.btEnabled
          Layout.fillWidth: true
          Layout.fillHeight: true
          clip: true

          ListView {
            id: macBtList
            width: parent.width
            model: macBtWindow.pairedDevices
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
                  text: "Connect"
                  font.family: "SF Pro Text"
                  font.pixelSize: 10
                  color: "#007aff"
                  font.weight: Font.DemiBold
                }
              }

              MouseArea {
                id: macRowM
                anchors.fill: parent
                hoverEnabled: true
                cursorShape: Qt.PointingHandCursor
                onClicked: {
                  macBtWindow.runCmd("bluetoothctl connect " + modelData.mac)
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

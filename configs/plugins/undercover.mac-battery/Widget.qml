import QtQuick
import QtQuick.Layouts
import QtQuick.Shapes
import Quickshell
import Quickshell.Io
import qs.Commons
import qs.Ui

BarWidget {
  id: root
  moduleName: "undercover.mac-battery"

  implicitWidth: button.implicitWidth
  implicitHeight: button.implicitHeight

  property int batteryPct: 90
  property bool isCharging: false

  Process {
    id: batPoller
    running: true
    command: [
      "bash", "-c",
      "cat /sys/class/power_supply/BAT*/capacity 2>/dev/null | head -1 || echo '90'; " +
      "cat /sys/class/power_supply/BAT*/status 2>/dev/null | head -1 || echo 'Discharging'"
    ]
    stdout: SplitParser {
      onRead: function(line) {
        var s = String(line).trim()
        if (!isNaN(parseInt(s))) {
          root.batteryPct = Math.max(1, Math.min(100, parseInt(s)))
        } else if (s.toLowerCase().indexOf("charg") !== -1) {
          root.isCharging = true
        } else {
          root.isCharging = false
        }
      }
    }
  }

  Timer {
    interval: 10000
    running: true
    repeat: true
    onTriggered: {
      if (!batPoller.running) batPoller.running = true
    }
  }

  WidgetButton {
    id: button
    anchors.fill: parent
    bar: root.bar
    text: " "
    labelVisible: false
    tooltipText: "Battery: " + root.batteryPct + "% (" + (root.isCharging ? "Power Source: Power Adapter" : "Power Source: Battery") + ")"
    horizontalMargin: 6

    onPressed: function() {
      if (root.bar) {
        root.bar.run("omarchy-mac-widgets")
      } else {
        Quickshell.execDetached(["omarchy-mac-widgets"])
      }
    }

    RowLayout {
      anchors.centerIn: parent
      spacing: 5

      // Battery Percentage
      Text {
        text: root.batteryPct + "%"
        font.family: "SF Pro Text, -apple-system, sans-serif"
        font.pixelSize: 12
        font.weight: Font.Medium
        color: root.bar ? root.bar.foreground : "#ffffff"
      }

      // Vector macOS Battery Capsule
      Item {
        implicitWidth: 24
        implicitHeight: 12

        readonly property color fgColor: root.bar ? root.bar.foreground : "#ffffff"
        readonly property color fillColor: root.batteryPct <= 20 ? "#ff453a" : (root.isCharging ? "#30d158" : parent.fgColor)

        // Outer Capsule
        Rectangle {
          id: outerBorder
          anchors.left: parent.left
          anchors.verticalCenter: parent.verticalCenter
          width: 20
          height: 11
          radius: 3
          color: "transparent"
          border.color: parent.fgColor
          border.width: 1.2

          // Interior Fill Level
          Rectangle {
            anchors.left: parent.left
            anchors.leftMargin: 1.5
            anchors.verticalCenter: parent.verticalCenter
            width: Math.max(2, Math.round((outerBorder.width - 3) * (root.batteryPct / 100.0)))
            height: outerBorder.height - 3
            radius: 1.5
            color: parent.parent.fillColor
          }

          // Charging Bolt
          Item {
            visible: root.isCharging
            anchors.centerIn: parent
            width: 8
            height: 8

            Shape {
              anchors.fill: parent
              ShapePath {
                fillColor: "#ffffff"
                strokeWidth: 0
                startX: 5; startY: 0
                PathLine { x: 1; y: 4.5 }
                PathLine { x: 4; y: 4.5 }
                PathLine { x: 3; y: 8 }
                PathLine { x: 7; y: 3.5 }
                PathLine { x: 4.5; y: 3.5 }
                PathLine { x: 5; y: 0 }
              }
            }
          }
        }

        // Terminal Nipple
        Rectangle {
          anchors.left: outerBorder.right
          anchors.leftMargin: 1
          anchors.verticalCenter: parent.verticalCenter
          width: 2
          height: 4.5
          radius: 1
          color: parent.fgColor
        }
      }
    }
  }
}

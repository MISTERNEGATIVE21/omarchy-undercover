import QtQuick
import Quickshell
import Quickshell.Io
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
    command: ["bash", "-c", "cat /sys/class/power_supply/BAT*/capacity 2>/dev/null | head -1 || echo '90'; cat /sys/class/power_supply/BAT*/status 2>/dev/null | head -1 || echo 'Discharging'"]
    stdout: SplitParser {
      onRead: function(line) {
        var s = String(line).trim()
        if (!isNaN(parseInt(s))) {
          root.batteryPct = parseInt(s)
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
    text: root.batteryPct + "% " + (root.isCharging ? "󰂄" : "󰁹")
    tooltipText: "Battery: " + root.batteryPct + "% (" + (root.isCharging ? "Power Source: Power Adapter" : "Power Source: Battery") + ")"
    horizontalMargin: 6
    onPressed: function() {
      if (root.bar) {
        root.bar.run("omarchy-mac-widgets")
      } else {
        Quickshell.execDetached(["omarchy-mac-widgets"])
      }
    }
  }
}

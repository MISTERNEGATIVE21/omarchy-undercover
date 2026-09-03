import QtQuick
import Quickshell
import Quickshell.Io
import qs.Ui

BarWidget {
  id: root
  moduleName: "undercover.mac-sound"

  implicitWidth: button.implicitWidth
  implicitHeight: button.implicitHeight

  property real volumeLevel: 0.65
  property bool isMuted: false

  Process {
    id: volPoller
    running: true
    command: ["bash", "-c", "wpctl get-volume @DEFAULT_AUDIO_SINK@ 2>/dev/null || echo 'Volume: 0.65'"]
    stdout: SplitParser {
      onRead: function(line) {
        var l = String(line).trim()
        root.isMuted = (l.indexOf("[MUTED]") !== -1)
        var parts = l.replace("[MUTED]", "").trim().split(" ")
        if (parts.length >= 2) {
          var val = parseFloat(parts[1])
          if (!isNaN(val)) root.volumeLevel = val
        }
      }
    }
  }

  Timer {
    interval: 4000
    running: true
    repeat: true
    onTriggered: {
      if (!volPoller.running) volPoller.running = true
    }
  }

  BarIconButton {
    id: button
    anchors.fill: parent
    bar: root.bar
    text: root.isMuted ? "󰝟" : (root.volumeLevel > 0.5 ? "󰕾" : (root.volumeLevel > 0 ? "󰖀" : "󰕿"))
    tooltipText: "Sound: " + (root.isMuted ? "Muted" : Math.round(root.volumeLevel * 100) + "%")
    onPressed: function() {
      if (root.bar) {
        root.bar.run("omarchy-mac-sound")
      } else {
        Quickshell.execDetached(["omarchy-mac-sound"])
      }
    }
  }
}

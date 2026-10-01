import QtQuick
import Quickshell
import Quickshell.Io
import qs.Commons
import qs.Ui

BarWidget {
  id: root
  moduleName: "mac-sound"

  readonly property int contentWidth: Style.bar.iconSlot > 0 ? Style.bar.iconSlot : 28

  implicitWidth: contentWidth
  implicitHeight: root.bar ? root.bar.barSize : 28

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

  property string homeDir: Quickshell.env("HOME")
  property string configDir: homeDir + "/.config/omarchy/plugins/omarchy-undercover"

  BarIconButton {
    id: button
    anchors.fill: parent
    bar: root.bar
    text: root.isMuted ? "󰝟" : (root.volumeLevel > 0.5 ? "󰕾" : (root.volumeLevel > 0 ? "󰖀" : "󰕿"))
    tooltipText: "Sound: " + (root.isMuted ? "Muted" : Math.round(root.volumeLevel * 100) + "%")
    onPressed: function() {
      var pluginScripts = root.configDir + "/scripts"
      var devScripts = root.homeDir + "/omarchy-undercover/scripts"
      var cmd = pluginScripts + "/omarchy-mac-sound"
      var wrapped = "export PATH=\"" + pluginScripts + ":" + devScripts + ":$PATH\"; " + cmd
      Quickshell.execDetached(["bash", "-c", wrapped])
    }
  }
}

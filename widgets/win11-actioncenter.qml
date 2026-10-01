import QtQuick
import QtQuick.Layouts
import Quickshell
import Quickshell.Io
import qs.Ui

BarWidget {
  id: root
  moduleName: "win11-actioncenter"

  implicitWidth: pillContainer.implicitWidth + 14
  implicitHeight: root.bar ? root.bar.barSize : 40

  readonly property bool interactive: true
  readonly property bool pressable: true
  readonly property bool concealed: false

  function triggerPress(button) {
    if (button === Qt.RightButton) {
      root.runCmd("omarchy-win11-wifi")
    } else {
      root.runCmd("omarchy-win11-actioncenter")
    }
  }

  property var registeredBar: null
  function syncClickRegistration() {
    if (registeredBar && registeredBar.unregisterClickTarget) registeredBar.unregisterClickTarget(root)
    registeredBar = root.bar
    if (registeredBar && registeredBar.registerClickTarget) registeredBar.registerClickTarget(root)
  }
  onBarChanged: syncClickRegistration()
  Component.onCompleted: syncClickRegistration()
  Component.onDestruction: if (registeredBar && registeredBar.unregisterClickTarget) registeredBar.unregisterClickTarget(root)

  property bool wifiOn: true
  property real volumeLevel: 0.7
  property bool isMuted: false
  property int batteryPct: 90
  property bool isCharging: false
  property string homeDir: Quickshell.env("HOME")
  property string configDir: homeDir + "/.config/omarchy/plugins/omarchy-undercover"

  function resolveCmd(cmd) {
    if (!cmd) return ""
    var pluginScripts = root.configDir + "/scripts"
    var devScripts = root.homeDir + "/omarchy-undercover/scripts"
    return cmd.replace(/\b(omarchy-[a-zA-Z0-9_-]+)\b/g, function(match) {
      return pluginScripts + "/" + match
    })
  }

  function runCmd(cmd) {
    var pluginScripts = root.configDir + "/scripts"
    var devScripts = root.homeDir + "/omarchy-undercover/scripts"
    var fullCmd = root.resolveCmd(cmd)
    var wrapped = "export PATH=\"" + pluginScripts + ":" + devScripts + ":$PATH\"; " + fullCmd
    Quickshell.execDetached(["bash", "-c", wrapped])
  }

  Process {
    id: statePoller
    running: true
    command: [
      "bash", "-c",
      "wifi=$(nmcli radio wifi 2>/dev/null || echo 'disabled'); " +
      "vol=$(wpctl get-volume @DEFAULT_AUDIO_SINK@ 2>/dev/null || echo 'Volume: 0.70'); " +
      "bat=$(cat /sys/class/power_supply/BAT*/capacity 2>/dev/null | head -1 || echo '90'); " +
      "chg=$(cat /sys/class/power_supply/BAT*/status 2>/dev/null | head -1 || echo 'Discharging'); " +
      "echo \"$wifi|$vol|$bat|$chg\""
    ]
    stdout: SplitParser {
      onRead: function(line) {
        if (!line) return
        var parts = line.trim().split("|")
        if (parts.length >= 4) {
          root.wifiOn = (parts[0].indexOf("enabled") !== -1)
          var vStr = parts[1]
          root.isMuted = (vStr.indexOf("[MUTED]") !== -1)
          var vParts = vStr.replace("[MUTED]", "").trim().split(" ")
          if (vParts.length >= 2) {
            var v = parseFloat(vParts[1])
            if (!isNaN(v)) root.volumeLevel = v
          }
          var b = parseInt(parts[2])
          if (!isNaN(b)) root.batteryPct = b
          root.isCharging = (parts[3].toLowerCase().indexOf("charg") !== -1)
        }
      }
    }
  }

  Timer {
    interval: 5000
    running: true
    repeat: true
    onTriggered: {
      if (!statePoller.running) statePoller.running = true
    }
  }

  Rectangle {
    id: pillContainer
    anchors.verticalCenter: parent.verticalCenter
    implicitWidth: row.implicitWidth + 16
    implicitHeight: root.bar ? root.bar.barSize - 8 : 32
    radius: 4
    color: pillMouse.containsMouse ? (root.bar && root.bar.foreground !== undefined && root.bar.foreground === "#1a1a1a" ? Qt.rgba(0, 0, 0, 0.08) : Qt.rgba(1, 1, 1, 0.08)) : "transparent"
    border.color: pillMouse.containsMouse ? (root.bar && root.bar.foreground !== undefined && root.bar.foreground === "#1a1a1a" ? Qt.rgba(0, 0, 0, 0.10) : Qt.rgba(1, 1, 1, 0.10)) : "transparent"
    border.width: 1

    RowLayout {
      id: row
      anchors.centerIn: parent
      spacing: 8

      Text {
        text: root.wifiOn ? "󰤨" : "󰤭"
        font.pixelSize: 13
        color: root.bar && root.bar.foreground !== undefined ? root.bar.foreground : "#ffffff"
      }

      Text {
        text: root.isMuted ? "󰝟" : (root.volumeLevel > 0.5 ? "󰕾" : (root.volumeLevel > 0 ? "󰖀" : "󰕿"))
        font.pixelSize: 13
        color: root.bar && root.bar.foreground !== undefined ? root.bar.foreground : "#ffffff"
      }

      Text {
        text: root.isCharging ? "󰂄" : "󰁹"
        font.pixelSize: 14
        color: root.bar && root.bar.foreground !== undefined ? root.bar.foreground : "#ffffff"
      }
    }

    MouseArea {
      id: pillMouse
      anchors.fill: parent
      acceptedButtons: Qt.LeftButton | Qt.RightButton
      hoverEnabled: true
      cursorShape: Qt.PointingHandCursor
      onClicked: function(mouse) {
        if (mouse.button === Qt.RightButton) {
          root.runCmd("omarchy-win11-wifi")
        } else {
          root.runCmd("omarchy-win11-actioncenter")
        }
      }
      onPressAndHold: {
        root.runCmd("omarchy-win11-sound")
      }
    }
  }
}

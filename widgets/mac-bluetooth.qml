import QtQuick
import Quickshell
import Quickshell.Io
import qs.Commons
import qs.Ui

BarWidget {
  id: root
  moduleName: "mac-bluetooth"

  readonly property int contentWidth: Style.bar.iconSlot > 0 ? Style.bar.iconSlot : 28

  implicitWidth: contentWidth
  implicitHeight: root.bar ? root.bar.barSize : 28

  property bool btEnabled: true
  property bool btConnected: false
  property string connectedDevice: ""

  property string homeDir: Quickshell.env("HOME")
  property string configDir: homeDir + "/.config/omarchy/plugins/omarchy-undercover"

  function launchFlyout() {
    var pluginScripts = root.configDir + "/scripts"
    var devScripts = root.homeDir + "/omarchy-undercover/scripts"
    var cmd = pluginScripts + "/omarchy-mac-bluetooth"
    var wrapped = "export PATH=\"$HOME/.local/bin:" + pluginScripts + ":" + devScripts + ":$PATH\"; " + cmd
    Quickshell.execDetached(["bash", "-c", wrapped])
  }

  Process {
    id: btStatusProc
    running: true
    command: ["bash", "-c", "p=$(omarchy-bluetooth-power is-on 2>/dev/null && echo 'on' || echo 'off'); c=$(bluetoothctl devices Connected 2>/dev/null | head -n 1 | cut -d ' ' -f 3-); echo \"$p|$c\""]
    stdout: SplitParser {
      onRead: function(line) {
        var l = String(line).trim()
        if (!l) return
        var parts = l.split("|")
        root.btEnabled = (parts[0] === "on")
        var dev = parts.length > 1 ? parts[1].trim() : ""
        root.btConnected = (dev.length > 0)
        root.connectedDevice = dev
      }
    }
  }

  Timer {
    interval: 3500
    running: true
    repeat: true
    onTriggered: {
      if (!btStatusProc.running) btStatusProc.running = true
    }
  }

  BarIconButton {
    id: button
    anchors.fill: parent
    bar: root.bar
    text: !root.btEnabled ? "󰂲" : (root.btConnected ? "󰂱" : "󰂯")
    tooltipText: !root.btEnabled ? "Bluetooth: Off (Click to Open Bluetooth Menu)" : (root.btConnected ? "Bluetooth: Connected (" + root.connectedDevice + ") (Click to Open Bluetooth Menu)" : "Bluetooth: On (Click to Open Bluetooth Menu)")
    onPressed: function(btn) {
      if (!btStatusProc.running) btStatusProc.running = true
      root.launchFlyout()
    }
  }

  MouseArea {
    anchors.fill: parent
    acceptedButtons: Qt.LeftButton | Qt.RightButton
    hoverEnabled: true
    cursorShape: Qt.PointingHandCursor
    onEntered: {
      if (root.bar) root.bar.showTooltip(root, button.tooltipText)
    }
    onExited: {
      if (root.bar) root.bar.hideTooltip(root)
    }
    onClicked: function(mouse) {
      if (root.bar) root.bar.hideTooltip(root)
      if (!btStatusProc.running) btStatusProc.running = true
      root.launchFlyout()
    }
    onPressAndHold: {
      if (root.bar) root.bar.hideTooltip(root)
      root.launchFlyout()
    }
  }
}

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

  Process {
    id: btPoller
    running: true
    command: ["bash", "-c", "p=$(bluetoothctl show 2>/dev/null | grep -q 'Powered: yes' && echo '1' || echo '0'); c=$(bluetoothctl devices Connected 2>/dev/null | head -1); echo \"$p|$c\""]
    stdout: SplitParser {
      onRead: function(line) {
        if (!line) return
        var parts = String(line).trim().split("|")
        root.btEnabled = (parts[0] === "1")
        var dev = parts.length > 1 ? parts[1].trim() : ""
        if (dev.length > 0) {
          root.btConnected = true
          var devParts = dev.split(" ")
          root.connectedDevice = devParts.length > 2 ? devParts.slice(2).join(" ") : dev
        } else {
          root.btConnected = false
          root.connectedDevice = ""
        }
      }
    }
  }

  Timer {
    interval: 8000
    running: true
    repeat: true
    onTriggered: {
      if (!btPoller.running) btPoller.running = true
    }
  }

  property string homeDir: Quickshell.env("HOME")
  property string configDir: homeDir + "/.config/omarchy/plugins/omarchy-undercover"

  function launchFlyout() {
    var pluginScripts = root.configDir + "/scripts"
    var devScripts = root.homeDir + "/omarchy-undercover/scripts"
    var cmd = pluginScripts + "/omarchy-mac-bluetooth"
    var wrapped = "export PATH=\"" + pluginScripts + ":" + devScripts + ":$PATH\"; " + cmd
    Quickshell.execDetached(["bash", "-c", wrapped])
  }

  BarIconButton {
    id: button
    anchors.fill: parent
    bar: root.bar
    text: !root.btEnabled ? "󰂲" : (root.btConnected ? "󰂱" : "󰂯")
    tooltipText: !root.btEnabled ? "Bluetooth: Off (Click to Open Bluetooth Menu)" : (root.btConnected ? "Bluetooth: Connected (" + root.connectedDevice + ") (Click to Open Bluetooth Menu)" : "Bluetooth: On (Click to Open Bluetooth Menu)")
    onPressed: function(btn) {
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
      root.launchFlyout()
    }
    onPressAndHold: {
      if (root.bar) root.bar.hideTooltip(root)
      root.launchFlyout()
    }
  }
}

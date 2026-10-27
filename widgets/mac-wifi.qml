import QtQuick
import Quickshell
import Quickshell.Io
import qs.Commons
import qs.Ui

BarWidget {
  id: root
  moduleName: "mac-wifi"

  readonly property int contentWidth: Style.bar.iconSlot > 0 ? Style.bar.iconSlot : 28

  implicitWidth: contentWidth
  implicitHeight: root.bar ? root.bar.barSize : 28

  property bool wifiRadioOn: true
  property bool wifiConnected: false
  property string activeSsid: ""

  property string homeDir: Quickshell.env("HOME")
  property string configDir: homeDir + "/.config/omarchy/plugins/omarchy-undercover"

  function launchFlyout() {
    var pluginScripts = root.configDir + "/scripts"
    var devScripts = root.homeDir + "/omarchy-undercover/scripts"
    var cmd = pluginScripts + "/omarchy-mac-wifi"
    var wrapped = "export PATH=\"$HOME/.local/bin:" + pluginScripts + ":" + devScripts + ":$PATH\"; " + cmd
    Quickshell.execDetached(["bash", "-c", wrapped])
  }

  Process {
    id: wifiStatusProc
    running: true
    command: ["bash", "-c", "radio=$(nmcli radio wifi 2>/dev/null || echo 'enabled'); status=$(omarchy-network-status 2>/dev/null || echo 'disconnected'); echo \"$radio|$status\""]
    stdout: SplitParser {
      onRead: function(line) {
        var l = String(line).trim()
        if (!l) return
        var parts = l.split("|")
        var radio = parts[0]
        var net = parts[1] || ""
        root.wifiRadioOn = (radio.indexOf("enabled") !== -1)
        if (net.indexOf("wifi") === 0) {
          root.wifiConnected = true
          var netParts = net.split("\t")
          root.activeSsid = netParts.length > 1 ? netParts[1] : ""
        } else if (net.indexOf("ethernet") === 0) {
          root.wifiConnected = true
          root.activeSsid = "Ethernet"
        } else {
          root.wifiConnected = false
          root.activeSsid = ""
        }
      }
    }
  }

  Timer {
    interval: 3500
    running: true
    repeat: true
    onTriggered: {
      if (!wifiStatusProc.running) wifiStatusProc.running = true
    }
  }

  BarIconButton {
    id: button
    anchors.fill: parent
    bar: root.bar
    text: !root.wifiRadioOn ? "󰤮" : (root.wifiConnected ? "󰤨" : "󰤭")
    tooltipText: !root.wifiRadioOn ? "Wi-Fi: Off (Click to Open Wi-Fi Menu)" : (root.wifiConnected ? "Wi-Fi: " + root.activeSsid + " (Click to Open Wi-Fi Menu)" : "Wi-Fi: Disconnected (Click to Open Wi-Fi Menu)")
    onPressed: function(btn) {
      if (!wifiStatusProc.running) wifiStatusProc.running = true
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
      if (!wifiStatusProc.running) wifiStatusProc.running = true
      root.launchFlyout()
    }
    onPressAndHold: {
      if (root.bar) root.bar.hideTooltip(root)
      root.launchFlyout()
    }
  }
}

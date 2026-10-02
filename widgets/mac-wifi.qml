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

  Process {
    id: wifiPoller
    running: true
    command: ["bash", "-c", "r=$(nmcli radio wifi 2>/dev/null || echo 'disabled'); s=$(nmcli -t -f active,ssid dev wifi 2>/dev/null | grep '^yes:' | cut -d: -f2 || echo ''); echo \"$r|$s\""]
    stdout: SplitParser {
      onRead: function(line) {
        if (!line) return
        var parts = String(line).trim().split("|")
        root.wifiRadioOn = (parts[0] === "enabled")
        var s = parts.length > 1 ? parts[1].trim() : ""
        root.activeSsid = s
        root.wifiConnected = (s.length > 0)
      }
    }
  }

  Timer {
    interval: 8000
    running: true
    repeat: true
    onTriggered: {
      if (!wifiPoller.running) wifiPoller.running = true
    }
  }

  property string homeDir: Quickshell.env("HOME")
  property string configDir: homeDir + "/.config/omarchy/plugins/omarchy-undercover"

  function launchFlyout() {
    var pluginScripts = root.configDir + "/scripts"
    var devScripts = root.homeDir + "/omarchy-undercover/scripts"
    var cmd = pluginScripts + "/omarchy-mac-wifi"
    var wrapped = "export PATH=\"" + pluginScripts + ":" + devScripts + ":$PATH\"; " + cmd
    Quickshell.execDetached(["bash", "-c", wrapped])
  }

  BarIconButton {
    id: button
    anchors.fill: parent
    bar: root.bar
    text: !root.wifiRadioOn ? "󰤮" : (root.wifiConnected ? "󰤨" : "󰤭")
    tooltipText: !root.wifiRadioOn ? "Wi-Fi: Off (Click to Open Wi-Fi Menu)" : (root.wifiConnected ? "Wi-Fi: " + root.activeSsid + " (Click to Open Wi-Fi Menu)" : "Wi-Fi: Disconnected (Click to Open Wi-Fi Menu)")
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

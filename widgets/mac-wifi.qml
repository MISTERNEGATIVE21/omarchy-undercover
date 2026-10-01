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

  property bool wifiEnabled: true
  property string activeSsid: ""

  Process {
    id: wifiPoller
    running: true
    command: ["bash", "-c", "nmcli -t -f active,ssid dev wifi 2>/dev/null | grep '^yes:' | cut -d: -f2 || echo ''"]
    stdout: SplitParser {
      onRead: function(line) {
        var s = String(line).trim()
        root.activeSsid = s
        root.wifiEnabled = (s.length > 0)
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
    text: root.wifiEnabled ? "󰤨" : "󰤭"
    tooltipText: root.activeSsid.length > 0 ? "Wi-Fi: " + root.activeSsid + " (Click to Open Wi-Fi Menu)" : (root.wifiEnabled ? "Wi-Fi: Connected (Click to Open Wi-Fi Menu)" : "Wi-Fi: Disconnected (Click to Open Wi-Fi Menu)")
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

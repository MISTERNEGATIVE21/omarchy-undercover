import QtQuick
import Quickshell
import Quickshell.Io
import qs.Commons
import qs.Ui

BarWidget {
  id: root
  moduleName: "undercover.mac-wifi"

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

  function launchFlyout() {
    if (root.bar) {
      root.bar.run("omarchy-mac-wifi")
    } else {
      Quickshell.execDetached(["omarchy-mac-wifi"])
    }
  }

  function launchManager() {
    if (root.bar) {
      root.bar.run("omarchy-wifi-manager")
    } else {
      Quickshell.execDetached(["omarchy-wifi-manager"])
    }
  }

  BarIconButton {
    id: button
    anchors.fill: parent
    bar: root.bar
    text: root.wifiEnabled ? "󰤨" : "󰤭"
    tooltipText: root.activeSsid.length > 0 ? "Wi-Fi: " + root.activeSsid + " (Long-press / Right-click to Scan & Search)" : (root.wifiEnabled ? "Wi-Fi: Connected (Long-press / Right-click to Scan & Search)" : "Wi-Fi: Disconnected (Long-press / Right-click to Scan & Search)")
    onPressed: function(btn) {
      if (btn === Qt.RightButton) {
        root.launchManager()
      } else {
        root.launchFlyout()
      }
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
      if (mouse.button === Qt.RightButton) {
        root.launchManager()
      } else {
        root.launchFlyout()
      }
    }
    onPressAndHold: {
      if (root.bar) root.bar.hideTooltip(root)
      root.launchManager()
    }
  }
}

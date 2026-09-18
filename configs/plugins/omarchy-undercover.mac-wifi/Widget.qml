import QtQuick
import Quickshell
import Quickshell.Io
import qs.Commons
import qs.Ui

BarWidget {
  id: root
  moduleName: "omarchy-undercover.mac-wifi"

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

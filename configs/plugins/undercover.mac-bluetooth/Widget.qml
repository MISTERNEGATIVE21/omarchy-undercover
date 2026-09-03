import QtQuick
import Quickshell
import Quickshell.Io
import qs.Ui

BarWidget {
  id: root
  moduleName: "undercover.mac-bluetooth"

  implicitWidth: button.implicitWidth
  implicitHeight: button.implicitHeight

  property bool btEnabled: true

  Process {
    id: btPoller
    running: true
    command: ["bash", "-c", "bluetoothctl show 2>/dev/null | grep -q 'Powered: yes' && echo '1' || echo '0'"]
    stdout: SplitParser {
      onRead: function(line) {
        root.btEnabled = (String(line).trim() === "1")
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

  function launchFlyout() {
    if (root.bar) {
      root.bar.run("omarchy-mac-bluetooth")
    } else {
      Quickshell.execDetached(["omarchy-mac-bluetooth"])
    }
  }

  function launchManager() {
    if (root.bar) {
      root.bar.run("omarchy-bluetooth-manager")
    } else {
      Quickshell.execDetached(["omarchy-bluetooth-manager"])
    }
  }

  BarIconButton {
    id: button
    anchors.fill: parent
    bar: root.bar
    text: root.btEnabled ? "󰂯" : "󰂲"
    tooltipText: root.btEnabled ? "Bluetooth: On (Long-press / Right-click to Scan & Search)" : "Bluetooth: Off (Long-press / Right-click to Scan & Search)"
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

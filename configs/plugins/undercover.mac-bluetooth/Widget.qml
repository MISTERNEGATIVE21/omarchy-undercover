import QtQuick
import Quickshell
import Quickshell.Io
import qs.Commons
import qs.Ui

BarWidget {
  id: root
  moduleName: "undercover.mac-bluetooth"

  readonly property int contentWidth: Style.bar.iconSlot > 0 ? Style.bar.iconSlot : 28

  implicitWidth: contentWidth
  implicitHeight: root.bar ? root.bar.barSize : 28

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

  BarIconButton {
    id: button
    anchors.fill: parent
    bar: root.bar
    text: root.btEnabled ? "󰂯" : "󰂲"
    tooltipText: root.btEnabled ? "Bluetooth: On (Click to Open Bluetooth Menu)" : "Bluetooth: Off (Click to Open Bluetooth Menu)"
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

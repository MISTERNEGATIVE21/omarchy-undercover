import QtQuick
import Quickshell
import Quickshell.Io
import Quickshell.Bluetooth
import qs.Commons
import qs.Ui

BarWidget {
  id: root
  moduleName: "mac-bluetooth"

  readonly property int contentWidth: Style.bar.iconSlot > 0 ? Style.bar.iconSlot : 28

  implicitWidth: contentWidth
  implicitHeight: root.bar ? root.bar.barSize : 28

  readonly property var adapter: Bluetooth.defaultAdapter
  readonly property bool btEnabled: adapter ? adapter.enabled : false
  readonly property var connectedDevices: {
    if (!adapter || !adapter.devices) return [];
    var list = [];
    for (var i = 0; i < adapter.devices.length; i++) {
      if (adapter.devices[i].connected) list.push(adapter.devices[i]);
    }
    return list;
  }
  readonly property bool btConnected: connectedDevices.length > 0
  readonly property string connectedDevice: btConnected ? (connectedDevices[0].deviceName || connectedDevices[0].name || "") : ""

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

import QtQuick
import Quickshell
import qs.Ui

BarWidget {
  id: root
  moduleName: "undercover.mac-bluetooth"

  implicitWidth: button.implicitWidth
  implicitHeight: button.implicitHeight

  BarIconButton {
    id: button
    anchors.fill: parent
    bar: root.bar
    text: "󰂯"
    tooltipText: "Bluetooth"
    onPressed: function() {
      if (root.bar) {
        root.bar.run("omarchy-mac-bluetooth")
      } else {
        Quickshell.execDetached(["omarchy-mac-bluetooth"])
      }
    }
  }
}

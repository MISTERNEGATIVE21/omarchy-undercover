import QtQuick
import Quickshell
import qs.Ui

BarWidget {
  id: root
  moduleName: "undercover.mac-controlcenter"

  implicitWidth: button.implicitWidth
  implicitHeight: button.implicitHeight

  BarIconButton {
    id: button
    anchors.fill: parent
    bar: root.bar
    text: "󰕓"
    tooltipText: "Control Center"
    onPressed: function() {
      if (root.bar) {
        root.bar.run("omarchy-mac-controlcenter")
      } else {
        Quickshell.execDetached(["omarchy-mac-controlcenter"])
      }
    }
  }
}

import QtQuick
import Quickshell
import qs.Ui

BarWidget {
  id: root
  moduleName: "undercover.mac-sound"

  implicitWidth: button.implicitWidth
  implicitHeight: button.implicitHeight

  BarIconButton {
    id: button
    anchors.fill: parent
    bar: root.bar
    text: "󰕾"
    tooltipText: "Sound & Volume"
    onPressed: function() {
      if (root.bar) {
        root.bar.run("omarchy-mac-sound")
      } else {
        Quickshell.execDetached(["omarchy-mac-sound"])
      }
    }
  }
}

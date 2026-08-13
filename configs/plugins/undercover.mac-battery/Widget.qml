import QtQuick
import qs.Ui

BarWidget {
  id: root
  moduleName: "undercover.mac-battery"

  implicitWidth: button.implicitWidth
  implicitHeight: button.implicitHeight

  WidgetButton {
    id: button
    anchors.fill: parent
    bar: root.bar
    text: "94% 󰁹"
    tooltipText: "Battery: 94% (Power Source: Battery)"
    horizontalMargin: 6
    onPressed: function() {
      if (root.bar) root.bar.run("omarchy-mac-widgets")
    }
  }
}

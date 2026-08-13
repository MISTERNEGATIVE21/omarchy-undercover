import QtQuick
import qs.Ui

BarWidget {
  id: root
  moduleName: "undercover.win11-taskview"

  implicitWidth: button.implicitWidth
  implicitHeight: button.implicitHeight

  WidgetButton {
    id: button
    anchors.fill: parent
    bar: root.bar
    text: "󰕓"
    tooltipText: "Task View (Win + Tab)"
    horizontalMargin: 8
    onPressed: function() {
      if (root.bar) root.bar.run("rofi -show window -theme ~/.config/rofi/windows11.rasi")
    }
  }
}

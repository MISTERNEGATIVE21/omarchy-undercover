import QtQuick
import qs.Ui

BarWidget {
  id: root
  moduleName: "undercover.mac-spotlight"

  implicitWidth: button.implicitWidth
  implicitHeight: button.implicitHeight

  BarIconButton {
    id: button
    anchors.fill: parent
    bar: root.bar
    text: "🔍"
    tooltipText: "Spotlight (Super + Space)"
    onPressed: function() {
      if (root.bar) root.bar.run("rofi -show drun -theme ~/.config/rofi/mac.rasi")
    }
  }
}

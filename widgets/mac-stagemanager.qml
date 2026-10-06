import QtQuick
import Quickshell
import qs.Commons
import qs.Ui

BarWidget {
  id: root
  moduleName: "mac-stagemanager"

  readonly property int contentWidth: Style.bar.iconSlot > 0 ? Style.bar.iconSlot : 28

  implicitWidth: contentWidth
  implicitHeight: root.bar ? root.bar.barSize : 28

  WidgetButton {
    id: button
    anchors.fill: parent
    bar: root.bar
    text: " "
    labelVisible: false
    fixedWidth: root.contentWidth
    tooltipText: "Stage Manager"

    property string homeDir: Quickshell.env("HOME")
    property string configDir: homeDir + "/.config/omarchy/plugins/omarchy-undercover"

    onPressed: function() {
      var pluginScripts = button.configDir + "/scripts"
      var devScripts = button.homeDir + "/omarchy-undercover/scripts"
      var cmd = pluginScripts + "/omarchy-mac-stagemanager --toggle"
      var wrapped = "export PATH=\"" + pluginScripts + ":" + devScripts + ":$PATH\"; " + cmd
      Quickshell.execDetached(["bash", "-c", wrapped])
    }

    // Vector macOS Stage Manager glyph: 1 main stage card + 3 miniature window cards on left
    Item {
      anchors.centerIn: parent
      width: 16
      height: 14

      readonly property color iconColor: button.active ? Color.accent : (root.bar ? root.bar.foreground : "#ffffff")

      // Main stage card
      Rectangle {
        x: 6
        y: 1
        width: 10
        height: 12
        radius: 2
        color: "transparent"
        border.color: parent.iconColor
        border.width: 1.2
      }

      // 3 recent miniature cards on the left
      Repeater {
        model: 3

        Rectangle {
          required property int index
          x: 0
          y: 2 + index * 4
          width: 4
          height: 2.2
          radius: 1
          color: parent.iconColor
          opacity: 0.9
        }
      }
    }
  }
}

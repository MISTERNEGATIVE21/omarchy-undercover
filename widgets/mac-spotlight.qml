import QtQuick
import QtQuick.Shapes
import Quickshell
import qs.Commons
import qs.Ui

BarWidget {
  id: root
  moduleName: "mac-spotlight"

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
    tooltipText: "Spotlight (Super + Alt + Space)"

    property string homeDir: Quickshell.env("HOME")
    property string configDir: homeDir + "/.config/omarchy/plugins/omarchy-undercover"

    onPressed: function() {
      var pluginScripts = button.configDir + "/scripts"
      var devScripts = button.homeDir + "/omarchy-undercover/scripts"
      var cmd = pluginScripts + "/omarchy-undercover-launcher"
      var wrapped = "export PATH=\"" + pluginScripts + ":" + devScripts + ":$PATH\"; " + cmd
      Quickshell.execDetached(["bash", "-c", wrapped])
    }

    // Vector macOS Spotlight Magnifying Glass
    Item {
      id: spotIcon
      anchors.centerIn: parent
      width: 16
      height: 16

      readonly property color iconColor: button.active ? Color.accent : (root.bar ? root.bar.foreground : "#ffffff")

      Shape {
        anchors.fill: parent
        layer.enabled: true
        layer.samples: 4

        ShapePath {
          strokeColor: spotIcon.iconColor
          strokeWidth: 1.5
          fillColor: "transparent"
          capStyle: ShapePath.RoundCap

          // Circle lens
          PathAngleArc {
            centerX: 6.5
            centerY: 6.5
            radiusX: 4.5
            radiusY: 4.5
            startAngle: 0
            sweepAngle: 360
          }
        }

        ShapePath {
          strokeColor: spotIcon.iconColor
          strokeWidth: 1.6
          fillColor: "transparent"
          capStyle: ShapePath.RoundCap

          // 45-degree handle
          startX: 9.8
          startY: 9.8
          PathLine { x: 14.5; y: 14.5 }
        }
      }
    }
  }
}

import QtQuick
import QtQuick.Layouts
import Quickshell
import Quickshell.Services.Pipewire
import qs.Ui

BarWidget {
  id: root
  moduleName: "undercover.win11-actioncenter"

  readonly property var sink: Pipewire.defaultAudioSink
  readonly property real volume: sink && sink.audio ? sink.audio.volume : 0.5
  readonly property bool muted: sink && sink.audio ? sink.audio.muted : false

  readonly property string volIcon: muted ? "󰝟" : (volume > 0.5 ? "󰕾" : (volume > 0 ? "󰖀" : "󰕿"))

  implicitWidth: container.implicitWidth + 18
  implicitHeight: root.bar ? root.bar.barSize : 26

  Rectangle {
    id: bg
    anchors.fill: parent
    anchors.margins: 2
    radius: 6
    color: mouseArea.containsMouse ? (root.bar ? root.bar.hoverBackground : "rgba(255,255,255,0.12)") : "transparent"
    border.color: mouseArea.containsMouse ? "rgba(255,255,255,0.15)" : "transparent"
    border.width: 1

    RowLayout {
      id: container
      anchors.centerIn: parent
      spacing: 6

      Text {
        text: "󰤨"
        font.family: root.bar ? root.bar.fontFamily : "sans-serif"
        font.pixelSize: 13
        color: root.bar ? root.bar.foreground : "#ffffff"
      }

      Text {
        text: root.volIcon
        font.family: root.bar ? root.bar.fontFamily : "sans-serif"
        font.pixelSize: 13
        color: root.bar ? root.bar.foreground : "#ffffff"
      }

      Text {
        text: "󱐋"
        font.family: root.bar ? root.bar.fontFamily : "sans-serif"
        font.pixelSize: 13
        color: root.bar ? root.bar.foreground : "#ffffff"
      }
    }

    MouseArea {
      id: mouseArea
      anchors.fill: parent
      hoverEnabled: true
      cursorShape: Qt.PointingHandCursor
      acceptedButtons: Qt.LeftButton | Qt.RightButton
      onClicked: function(mouse) {
        if (!root.bar) return
        if (mouse.button === Qt.RightButton) {
          root.bar.run("omarchy-undercover-settings --page hardware")
        } else {
          root.bar.run("omarchy-win11-notifications")
        }
      }
    }
  }
}

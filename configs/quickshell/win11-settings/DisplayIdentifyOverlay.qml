import QtQuick
import Quickshell
import Quickshell.Io
import Quickshell.Wayland

Item {
  id: root

  property bool active: false
  property real badgeOpacity: 0.0

  function trigger() {
    fadeTimer.stop()
    root.active = true
    root.badgeOpacity = 1.0
    expiryTimer.restart()
  }

  function hide() {
    root.badgeOpacity = 0.0
    fadeTimer.restart()
  }

  Timer {
    id: expiryTimer
    interval: 3500
    repeat: false
    onTriggered: root.hide()
  }

  Timer {
    id: fadeTimer
    interval: 220
    repeat: false
    onTriggered: root.active = false
  }

  FileView {
    id: triggerWatcher
    path: (Quickshell.env("XDG_RUNTIME_DIR") || "/tmp") + "/omarchy-identify-displays"
    watchChanges: true
    onLoaded: {
      var txt = text().trim()
      if (txt.length > 0) root.trigger()
    }
    onFileChanged: {
      reload()
      root.trigger()
    }
  }

  Variants {
    model: root.active ? Quickshell.screens : []

    PanelWindow {
      id: overlayWindow
      required property var modelData
      readonly property int screenIndex: Quickshell.screens ? Quickshell.screens.indexOf(modelData) : 0

      screen: modelData
      visible: true
      color: "transparent"
      exclusionMode: ExclusionMode.Ignore

      WlrLayershell.namespace: "omarchy-display-identify"
      WlrLayershell.layer: WlrLayer.Overlay
      WlrLayershell.keyboardFocus: WlrKeyboardFocus.None

      anchors {
        top: true
        bottom: true
        left: true
        right: true
      }

      // Input-transparent mask: clicks pass through to whatever is beneath
      mask: Region {}

      // Windows 11 Authentic Display Identification Badge
      Rectangle {
        id: badgeCard
        anchors.left: parent.left
        anchors.bottom: parent.bottom
        anchors.margins: 48
        width: 120
        height: 120
        radius: 8
        color: Qt.rgba(0.11, 0.13, 0.17, 0.94)
        border.color: Qt.rgba(1.0, 1.0, 1.0, 0.15)
        border.width: 1
        opacity: root.badgeOpacity

        Behavior on opacity {
          NumberAnimation { duration: 180; easing.type: Easing.OutCubic }
        }

        // Inner subtle accent ring
        Rectangle {
          anchors.fill: parent
          anchors.margins: 2
          radius: 6
          color: "transparent"
          border.color: Qt.rgba(0.0, 0.47, 0.84, 0.35)
          border.width: 1
        }

        Column {
          anchors.centerIn: parent
          spacing: 2

          Text {
            anchors.horizontalCenter: parent.horizontalCenter
            text: String(overlayWindow.screenIndex + 1)
            font.family: "Segoe UI, sans-serif"
            font.pixelSize: 52
            font.bold: true
            color: "#ffffff"
          }

          Text {
            anchors.horizontalCenter: parent.horizontalCenter
            text: overlayWindow.modelData ? (overlayWindow.modelData.name || ("Display " + (overlayWindow.screenIndex + 1))) : "Display"
            font.family: "Segoe UI, sans-serif"
            font.pixelSize: 11
            font.weight: Font.DemiBold
            color: Qt.rgba(1.0, 1.0, 1.0, 0.85)
            elide: Text.ElideRight
            maximumLineCount: 1
          }

          Text {
            anchors.horizontalCenter: parent.horizontalCenter
            text: overlayWindow.modelData ? (overlayWindow.modelData.width + " × " + overlayWindow.modelData.height) : ""
            font.family: "Segoe UI, sans-serif"
            font.pixelSize: 9
            color: Qt.rgba(1.0, 1.0, 1.0, 0.55)
          }
        }
      }
    }
  }
}

import QtQuick
import QtQuick.Layouts
import QtQuick.Shapes
import Quickshell
import qs.Commons
import qs.Ui

BarWidget {
  id: root
  moduleName: "undercover.mac-apple"

  implicitWidth: button.implicitWidth
  implicitHeight: button.implicitHeight

  property bool menuOpen: false

  function runCmd(cmd) {
    root.menuOpen = false
    if (root.bar) {
      root.bar.run(cmd)
    } else {
      Quickshell.execDetached(["bash", "-c", cmd])
    }
  }

  WidgetButton {
    id: button
    anchors.fill: parent
    bar: root.bar
    text: " "
    labelVisible: false
    fixedWidth: Style.bar.iconSlot > 0 ? Style.bar.iconSlot : 28
    tooltipText: "Apple Menu"
    active: root.menuOpen

    onPressed: function(btn) {
      if (btn === Qt.RightButton) {
        root.runCmd("omarchy-undercover-settings")
      } else {
        root.menuOpen = !root.menuOpen
      }
    }

    Item {
      anchors.centerIn: parent
      width: 16
      height: 16

      Shape {
        anchors.centerIn: parent
        width: 24
        height: 24
        scale: 15 / 24
        layer.enabled: true
        layer.samples: 4

        ShapePath {
          fillColor: button.active ? Color.accent : (root.bar ? root.bar.foreground : "#ffffff")
          strokeWidth: 0
          PathSvg {
            path: "M18.71 19.5c-.83 1.24-1.71 2.45-3.05 2.47-1.34.03-1.77-.79-3.29-.79-1.53 0-2 .77-3.27.82-1.31.05-2.3-1.32-3.14-2.53C4.25 17 2.94 12.45 4.7 9.39c.87-1.52 2.43-2.48 4.12-2.51 1.28-.02 2.5.87 3.29.87.78 0 2.26-1.07 3.81-.91.65.03 2.47.26 3.64 1.98-.09.06-2.17 1.28-2.15 3.81.03 3.02 2.65 4.03 2.68 4.04-.03.07-.42 1.44-1.38 2.83M15.97 4.15c.66-.8 1.11-1.92.99-3.04-1 .04-2.2.67-2.92 1.5-.64.74-1.2 1.92-1.05 3.03 1.12.09 2.26-.59 2.98-1.49z"
          }
        }
      }
    }
  }

  // Authentic macOS Apple Menu Dropdown
  KeyboardPanel {
    id: menuPanel
    anchorItem: button
    owner: root
    bar: root.bar
    open: root.menuOpen
    contentWidth: 230
    contentHeight: menuCol.implicitHeight + 16

    Rectangle {
      anchors.fill: parent
      color: Color.popups.background
      radius: Style.radius(10)
      border.color: Qt.rgba(1, 1, 1, 0.16)
      border.width: 1
      clip: true

      ColumnLayout {
        id: menuCol
        anchors.fill: parent
        anchors.margins: 6
        spacing: 2

        // Menu Items
        Rectangle {
          Layout.fillWidth: true
          height: 26
          radius: 5
          color: m1.containsMouse ? Color.accent : "transparent"
          Text {
            anchors.left: parent.left; anchors.leftMargin: 10; anchors.verticalCenter: parent.verticalCenter
            text: "About This Mac"
            font.family: "SF Pro Text, -apple-system, sans-serif"; font.pixelSize: 12
            color: m1.containsMouse ? "#ffffff" : Color.foreground
          }
          MouseArea { id: m1; anchors.fill: parent; hoverEnabled: true; cursorShape: Qt.PointingHandCursor; onClicked: root.runCmd("omarchy-mac-applemenu") }
        }

        Rectangle { Layout.fillWidth: true; height: 1; color: Color.separator }

        Rectangle {
          Layout.fillWidth: true
          height: 26
          radius: 5
          color: m2.containsMouse ? Color.accent : "transparent"
          Text {
            anchors.left: parent.left; anchors.leftMargin: 10; anchors.verticalCenter: parent.verticalCenter
            text: "System Settings..."
            font.family: "SF Pro Text, -apple-system, sans-serif"; font.pixelSize: 12
            color: m2.containsMouse ? "#ffffff" : Color.foreground
          }
          MouseArea { id: m2; anchors.fill: parent; hoverEnabled: true; cursorShape: Qt.PointingHandCursor; onClicked: root.runCmd("omarchy-mac-settings") }
        }

        Rectangle {
          Layout.fillWidth: true
          height: 26
          radius: 5
          color: m3.containsMouse ? Color.accent : "transparent"
          Text {
            anchors.left: parent.left; anchors.leftMargin: 10; anchors.verticalCenter: parent.verticalCenter
            text: "App Store..."
            font.family: "SF Pro Text, -apple-system, sans-serif"; font.pixelSize: 12
            color: m3.containsMouse ? "#ffffff" : Color.foreground
          }
          MouseArea { id: m3; anchors.fill: parent; hoverEnabled: true; cursorShape: Qt.PointingHandCursor; onClicked: root.runCmd("pamac-manager || gnome-software || discover") }
        }

        Rectangle { Layout.fillWidth: true; height: 1; color: Color.separator }

        Rectangle {
          Layout.fillWidth: true
          height: 26
          radius: 5
          color: mRestore.containsMouse ? Color.accent : "transparent"
          Text {
            anchors.left: parent.left; anchors.leftMargin: 10; anchors.verticalCenter: parent.verticalCenter
            text: "Restore Original Omarchy..."
            font.family: "SF Pro Text, -apple-system, sans-serif"; font.pixelSize: 12
            color: mRestore.containsMouse ? "#ffffff" : Color.foreground
          }
          MouseArea { id: mRestore; anchors.fill: parent; hoverEnabled: true; cursorShape: Qt.PointingHandCursor; onClicked: root.runCmd("omarchy-undercover --disable") }
        }

        Rectangle { Layout.fillWidth: true; height: 1; color: Color.separator }

        Rectangle {
          Layout.fillWidth: true
          height: 26
          radius: 5
          color: m4.containsMouse ? Color.accent : "transparent"
          Text {
            anchors.left: parent.left; anchors.leftMargin: 10; anchors.verticalCenter: parent.verticalCenter
            text: "Force Quit Applications..."
            font.family: "SF Pro Text, -apple-system, sans-serif"; font.pixelSize: 12
            color: m4.containsMouse ? "#ffffff" : Color.foreground
          }
          MouseArea { id: m4; anchors.fill: parent; hoverEnabled: true; cursorShape: Qt.PointingHandCursor; onClicked: root.runCmd("hyprctl kill") }
        }

        Rectangle { Layout.fillWidth: true; height: 1; color: Color.separator }

        Rectangle {
          Layout.fillWidth: true
          height: 26
          radius: 5
          color: m5.containsMouse ? Color.accent : "transparent"
          Text {
            anchors.left: parent.left; anchors.leftMargin: 10; anchors.verticalCenter: parent.verticalCenter
            text: "Sleep"
            font.family: "SF Pro Text, -apple-system, sans-serif"; font.pixelSize: 12
            color: m5.containsMouse ? "#ffffff" : Color.foreground
          }
          MouseArea { id: m5; anchors.fill: parent; hoverEnabled: true; cursorShape: Qt.PointingHandCursor; onClicked: root.runCmd("loginctl suspend") }
        }

        Rectangle {
          Layout.fillWidth: true
          height: 26
          radius: 5
          color: m6.containsMouse ? Color.accent : "transparent"
          Text {
            anchors.left: parent.left; anchors.leftMargin: 10; anchors.verticalCenter: parent.verticalCenter
            text: "Restart..."
            font.family: "SF Pro Text, -apple-system, sans-serif"; font.pixelSize: 12
            color: m6.containsMouse ? "#ffffff" : Color.foreground
          }
          MouseArea { id: m6; anchors.fill: parent; hoverEnabled: true; cursorShape: Qt.PointingHandCursor; onClicked: root.runCmd("loginctl reboot") }
        }

        Rectangle {
          Layout.fillWidth: true
          height: 26
          radius: 5
          color: m7.containsMouse ? Color.accent : "transparent"
          Text {
            anchors.left: parent.left; anchors.leftMargin: 10; anchors.verticalCenter: parent.verticalCenter
            text: "Shut Down..."
            font.family: "SF Pro Text, -apple-system, sans-serif"; font.pixelSize: 12
            color: m7.containsMouse ? "#ffffff" : Color.foreground
          }
          MouseArea { id: m7; anchors.fill: parent; hoverEnabled: true; cursorShape: Qt.PointingHandCursor; onClicked: root.runCmd("loginctl poweroff") }
        }

        Rectangle { Layout.fillWidth: true; height: 1; color: Color.separator }

        Rectangle {
          Layout.fillWidth: true
          height: 26
          radius: 5
          color: m8.containsMouse ? Color.accent : "transparent"
          Text {
            anchors.left: parent.left; anchors.leftMargin: 10; anchors.verticalCenter: parent.verticalCenter
            text: "Lock Screen"
            font.family: "SF Pro Text, -apple-system, sans-serif"; font.pixelSize: 12
            color: m8.containsMouse ? "#ffffff" : Color.foreground
          }
          MouseArea { id: m8; anchors.fill: parent; hoverEnabled: true; cursorShape: Qt.PointingHandCursor; onClicked: root.runCmd("hyprlock || loginctl lock-session") }
        }
      }
    }
  }
}

import QtQuick
import QtQuick.Layouts
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
    text: ""
    fontFamily: "SF Pro Text, -apple-system, Segoe UI, sans-serif"
    tooltipText: "Apple Menu"
    active: root.menuOpen
    horizontalMargin: 10

    onPressed: function(btn) {
      if (btn === Qt.RightButton) {
        root.runCmd("omarchy-undercover-settings")
      } else {
        root.menuOpen = !root.menuOpen
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
          MouseArea { id: m2; anchors.fill: parent; hoverEnabled: true; cursorShape: Qt.PointingHandCursor; onClicked: root.runCmd("omarchy-undercover-settings") }
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
          MouseArea { id: m5; anchors.fill: parent; hoverEnabled: true; cursorShape: Qt.PointingHandCursor; onClicked: root.runCmd("systemctl suspend") }
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
          MouseArea { id: m6; anchors.fill: parent; hoverEnabled: true; cursorShape: Qt.PointingHandCursor; onClicked: root.runCmd("systemctl reboot") }
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
          MouseArea { id: m7; anchors.fill: parent; hoverEnabled: true; cursorShape: Qt.PointingHandCursor; onClicked: root.runCmd("systemctl poweroff") }
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

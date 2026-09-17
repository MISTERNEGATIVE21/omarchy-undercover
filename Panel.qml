import QtQuick
import QtQuick.Layouts
import QtQuick.Controls
import Quickshell
import Quickshell.Io
import qs.Commons
import qs.Ui

Panel {
  id: root
  moduleName: "undercover"
  ipcTarget: "undercover"
  manageIpc: false

  property var anchorItem: null
  property var hostWidget: null
  property var widget: null
  readonly property var barIdentity: hostWidget || root

  readonly property string homeDir: Quickshell.env("HOME")
  readonly property string pluginDir: {
    var resolved = Qt.resolvedUrl(".").toString().replace(/^file:\/\//, "").replace(/\/$/, "");
    if (resolved && resolved.length > 1 && resolved.indexOf("/") !== -1) return resolved;
    return homeDir + "/.config/omarchy/plugins/omarchy-undercover";
  }
  readonly property string currentMode: widget ? widget.currentMode : "mac"
  readonly property string activeState: widget ? widget.activeState : "mac-dark"
  readonly property bool isAutohide: widget ? widget.isAutohide : false
  readonly property bool isTransparent: widget ? widget.isTransparent : true
  readonly property real activeOpacity: widget ? widget.activeOpacity : 0.95

  function runCmd(cmd) {
    var fullCmd = cmd.replace(/^omarchy-([a-zA-Z0-9_-]+)/, function(match) {
      return root.pluginDir + "/scripts/" + match
    })
    if (root.bar) {
      root.bar.run(fullCmd)
    } else {
      Quickshell.execDetached(["bash", "-c", fullCmd])
    }
  }

  KeyboardPanel {
    id: panel
    anchorItem: root.anchorItem
    owner: root.barIdentity
    bar: root.bar
    open: root.opened
    centerOnBar: false
    contentWidth: Style.space(420)
    contentHeight: Style.space(580)

    Rectangle {
      anchors.fill: parent
      color: Color.popups.background
      radius: Style.radius(16)
      clip: true

      // Specular Top Border Highlight
      Rectangle {
        anchors.left: parent.left
        anchors.right: parent.right
        anchors.top: parent.top
        height: 1
        color: Qt.rgba(1, 1, 1, 0.25)
      }

      // Outer Accent Border
      Rectangle {
        anchors.fill: parent
        color: "transparent"
        radius: Style.radius(16)
        border.color: Qt.rgba(Color.accent.r, Color.accent.g, Color.accent.b, 0.35)
        border.width: 1
      }

      Flickable {
        anchors.fill: parent
        anchors.margins: Style.space(16)
        contentHeight: contentCol.implicitHeight
        clip: true
        boundsBehavior: Flickable.StopAtBounds

        ColumnLayout {
          id: contentCol
          width: parent.width
          spacing: Style.space(14)

          // 1. Header Section
          RowLayout {
            Layout.fillWidth: true
            spacing: Style.space(12)

            Rectangle {
              width: Style.space(44)
              height: Style.space(44)
              radius: Style.radius(12)
              color: Qt.rgba(Color.accent.r, Color.accent.g, Color.accent.b, 0.18)
              border.color: Color.accent
              border.width: 1

              Text {
                anchors.centerIn: parent
                text: root.currentMode === "mac" ? "" : (root.currentMode === "win11" ? "󰍲" : "󰈈")
                font.family: root.currentMode === "mac" ? "SF Pro Text, -apple-system" : Style.font.family
                font.pixelSize: Style.font.title
                color: Color.accent
              }
            }

            ColumnLayout {
              Layout.fillWidth: true
              spacing: 2

              Text {
                text: "Omarchy Undercover"
                font.family: Style.font.family
                font.pixelSize: Style.font.body
                font.bold: true
                color: Color.foreground
              }

              Text {
                text: "Active: " + (root.currentMode === "mac" ? "macOS Sequoia (" + (root.activeState.indexOf("light") !== -1 ? "Light" : "Dark") + ")" : (root.currentMode === "win11" ? "Windows 11 Fluent (" + (root.activeState.indexOf("light") !== -1 ? "Light" : "Dark") + ")" : "Default Omarchy"))
                font.family: Style.font.family
                font.pixelSize: Style.font.caption
                color: Color.mutedForeground
              }
            }

            // Quick Toggle / Close
            Button {
              text: root.currentMode === "omarchy" ? "Camouflage" : "Restore"
              onClicked: {
                root.runCmd("omarchy-undercover --toggle")
                root.close()
              }
            }
          }

          Rectangle {
            Layout.fillWidth: true
            height: 1
            color: Color.separator
          }

          // 2. Disguise Presets
          Text {
            text: "TRANSFORMATION PRESETS"
            font.family: Style.font.family
            font.pixelSize: Style.font.caption - 1
            font.bold: true
            color: Color.mutedForeground
          }

          // macOS Card
          Rectangle {
            Layout.fillWidth: true
            implicitHeight: Style.space(72)
            radius: Style.radius(10)
            color: root.currentMode === "mac" ? Qt.rgba(Color.accent.r, Color.accent.g, Color.accent.b, 0.12) : Qt.rgba(1, 1, 1, 0.04)
            border.color: root.currentMode === "mac" ? Color.accent : Qt.rgba(1, 1, 1, 0.08)
            border.width: 1

            RowLayout {
              anchors.fill: parent
              anchors.margins: Style.space(10)
              spacing: Style.space(10)

              Text {
                text: "🍏"
                font.pixelSize: 22
              }

              ColumnLayout {
                Layout.fillWidth: true
                spacing: 1

                Text {
                  text: "Apple macOS Sequoia"
                  font.family: "SF Pro Text, -apple-system, sans-serif"
                  font.pixelSize: Style.font.caption + 1
                  font.bold: true
                  color: Color.foreground
                }
                Text {
                  text: "Frosted Menu Bar • Dynamic Dock • SF Fonts"
                  font.family: "SF Pro Text, -apple-system, sans-serif"
                  font.pixelSize: Style.font.caption - 1
                  color: Color.mutedForeground
                }
              }

              RowLayout {
                spacing: 6
                Button {
                  text: "🌙 Dark"
                  onClicked: { root.runCmd("omarchy-undercover -mac"); root.close() }
                }
                Button {
                  text: "☀️ Light"
                  onClicked: { root.runCmd("omarchy-undercover -mac-light"); root.close() }
                }
              }
            }
          }

          // Windows 11 Card
          Rectangle {
            Layout.fillWidth: true
            implicitHeight: Style.space(72)
            radius: Style.radius(10)
            color: root.currentMode === "win11" ? Qt.rgba(Color.accent.r, Color.accent.g, Color.accent.b, 0.12) : Qt.rgba(1, 1, 1, 0.04)
            border.color: root.currentMode === "win11" ? Color.accent : Qt.rgba(1, 1, 1, 0.08)
            border.width: 1

            RowLayout {
              anchors.fill: parent
              anchors.margins: Style.space(10)
              spacing: Style.space(10)

              Text {
                text: "🪟"
                font.pixelSize: 22
              }

              ColumnLayout {
                Layout.fillWidth: true
                spacing: 1

                Text {
                  text: "Windows 11 Fluent"
                  font.family: "Segoe UI, sans-serif"
                  font.pixelSize: Style.font.caption + 1
                  font.bold: true
                  color: Color.foreground
                }
                Text {
                  text: "Centered Mica Taskbar • Start Menu • Segoe UI"
                  font.family: "Segoe UI, sans-serif"
                  font.pixelSize: Style.font.caption - 1
                  color: Color.mutedForeground
                }
              }

              RowLayout {
                spacing: 6
                Button {
                  text: "🌙 Dark"
                  onClicked: { root.runCmd("omarchy-undercover -w11"); root.close() }
                }
                Button {
                  text: "☀️ Light"
                  onClicked: { root.runCmd("omarchy-undercover -w11-light"); root.close() }
                }
              }
            }
          }

          // Omarchy Default Card
          Rectangle {
            Layout.fillWidth: true
            implicitHeight: Style.space(52)
            radius: Style.radius(10)
            color: root.currentMode === "omarchy" ? Qt.rgba(Color.accent.r, Color.accent.g, Color.accent.b, 0.12) : Qt.rgba(1, 1, 1, 0.04)
            border.color: root.currentMode === "omarchy" ? Color.accent : Qt.rgba(1, 1, 1, 0.08)
            border.width: 1

            RowLayout {
              anchors.fill: parent
              anchors.margins: Style.space(10)
              spacing: Style.space(10)

              Text {
                text: "🐧"
                font.pixelSize: 18
              }

              Text {
                Layout.fillWidth: true
                text: "Default Clean Omarchy Desktop"
                font.family: Style.font.family
                font.pixelSize: Style.font.caption + 1
                color: Color.foreground
              }

              Button {
                text: "Restore"
                onClicked: { root.runCmd("omarchy-undercover --disable"); root.close() }
              }
            }
          }

          Rectangle {
            Layout.fillWidth: true
            height: 1
            color: Color.separator
          }

          // 3. Desktop Feature Toggles
          Text {
            text: "DESKTOP ENGINE CONTROLS"
            font.family: Style.font.family
            font.pixelSize: Style.font.caption - 1
            font.bold: true
            color: Color.mutedForeground
          }

          GridLayout {
            Layout.fillWidth: true
            columns: 2
            rowSpacing: 8
            columnSpacing: 8

            Button {
              Layout.fillWidth: true
              text: "Alignment: " + (root.currentMode === "win11" ? "Center / Left" : "Top Bar")
              onClicked: {
                root.runCmd("omarchy-undercover-settings -a")
              }
            }

            Button {
              Layout.fillWidth: true
              text: "Auto-hide: " + (root.isAutohide ? "ON (Edge-sensing)" : "OFF (Pinned)")
              onClicked: {
                root.runCmd("omarchy-undercover --autohide")
              }
            }

            Button {
              Layout.fillWidth: true
              text: "Frosted Glass: " + (root.isTransparent ? "Blur / Mica" : "Solid")
              onClicked: {
                root.runCmd("omarchy-undercover --transparency " + (root.isTransparent ? "off" : "on"))
              }
            }

            Button {
              Layout.fillWidth: true
              text: "Full Settings GUI"
              onClicked: {
                root.runCmd("omarchy-undercover-settings")
                root.close()
              }
            }
          }

          Rectangle {
            Layout.fillWidth: true
            height: 1
            color: Color.separator
          }

          // 4. Quick Productivity Utilities
          Text {
            text: "QUICK PRODUCTIVITY UTILITIES"
            font.family: Style.font.family
            font.pixelSize: Style.font.caption - 1
            font.bold: true
            color: Color.mutedForeground
          }

          RowLayout {
            Layout.fillWidth: true
            spacing: Style.space(8)

            Button {
              Layout.fillWidth: true
              text: "📐 Snap Assist"
              onClicked: { root.runCmd("omarchy-undercover-snap --assist"); root.close() }
            }
            Button {
              Layout.fillWidth: true
              text: "🖥️ Show Desktop"
              onClicked: { root.runCmd("omarchy-undercover-show-desktop"); root.close() }
            }
            Button {
              Layout.fillWidth: true
              text: "⚙️ Win11 Settings"
              onClicked: { root.runCmd("omarchy-win11-settings"); root.close() }
            }
          }

          Rectangle {
            Layout.fillWidth: true
            height: 1
            color: Color.separator
          }

          // 5. Quick Wallpapers Carousel
          Text {
            text: "AUTHENTIC 6K WALLPAPERS"
            font.family: Style.font.family
            font.pixelSize: Style.font.caption - 1
            font.bold: true
            color: Color.mutedForeground
          }

          RowLayout {
            Layout.fillWidth: true
            spacing: Style.space(8)

            Button {
              Layout.fillWidth: true
              text: "Sequoia"
              onClicked: root.runCmd("omarchy-undercover-wallpaper -s 'macOS-Sequoia-Dark.jpg'")
            }
            Button {
              Layout.fillWidth: true
              text: "Sonoma"
              onClicked: root.runCmd("omarchy-undercover-wallpaper -s 'Sonoma-dark.jpg'")
            }
            Button {
              Layout.fillWidth: true
              text: "Ventura"
              onClicked: root.runCmd("omarchy-undercover-wallpaper -s 'Ventura-dark.jpg'")
            }
            Button {
              Layout.fillWidth: true
              text: "Win 11 Bloom"
              onClicked: root.runCmd("omarchy-undercover-wallpaper -s 'win11_bloom_dark.jpg'")
            }
          }
        }
      }
    }
  }
}

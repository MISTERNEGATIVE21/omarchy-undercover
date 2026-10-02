import QtQuick
import QtQuick.Layouts
import Quickshell
import Quickshell.Io
import qs.Commons
import qs.Ui

Panel {
  id: root
  moduleName: "omarchy-undercover"
  ipcTarget: "omarchy-undercover"
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
    var pluginScripts = root.pluginDir + "/scripts"
    var devScripts = root.homeDir + "/omarchy-undercover/scripts"
    var fullCmd = cmd.replace(/^omarchy-([a-zA-Z0-9_-]+)/, function(match) {
      return pluginScripts + "/" + match
    })
    var wrapped = "export PATH=\"" + pluginScripts + ":" + devScripts + ":$PATH\"; " + fullCmd
    if (root.bar && typeof root.bar.run === "function") {
      root.bar.run(wrapped)
    } else {
      Quickshell.execDetached(["bash", "-c", wrapped])
    }
  }

  KeyboardPanel {
    id: panel
    anchorItem: root.anchorItem || root
    owner: root.barIdentity
    bar: root.bar
    open: root.opened
    centerOnBar: false
    contentWidth: typeof panel.fittedContentWidth === "function" ? panel.fittedContentWidth(Style.space(420)) : Style.space(420)
    contentHeight: typeof panel.fittedContentHeight === "function" ? panel.fittedContentHeight(Style.space(560)) : Style.space(560)

    Rectangle {
      anchors.fill: parent
      color: "transparent"
      clip: true

      Flickable {
        anchors.fill: parent
        contentWidth: width
        contentHeight: contentCol.implicitHeight
        clip: true
        boundsBehavior: Flickable.StopAtBounds

        ColumnLayout {
          id: contentCol
          width: parent.width
          spacing: Style.space(12)

          // 1. Header Section
          RowLayout {
            Layout.fillWidth: true
            spacing: Style.space(12)

            Rectangle {
              width: Style.space(44)
              height: Style.space(44)
              radius: 12
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
                color: Color.muted
              }
            }

            // Quick Toggle / Close
            Button {
              bordered: true
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
            color: Qt.rgba(1, 1, 1, 0.12)
          }

          // 2. Disguise Presets
          Text {
            text: "TRANSFORMATION PRESETS"
            font.family: Style.font.family
            font.pixelSize: Style.font.caption
            font.bold: true
            color: Color.muted
          }

          // macOS Card
          Rectangle {
            Layout.fillWidth: true
            implicitHeight: Style.space(72)
            radius: 10
            color: root.currentMode === "mac" ? Qt.rgba(Color.accent.r, Color.accent.g, Color.accent.b, 0.14) : Qt.rgba(1, 1, 1, 0.04)
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

                RowLayout {
                  spacing: 6
                  Text {
                    text: "Apple macOS Sequoia"
                    font.family: "SF Pro Text, -apple-system, sans-serif"
                    font.pixelSize: Style.font.caption + 1
                    font.bold: true
                    color: Color.foreground
                  }
                  Rectangle {
                    visible: root.currentMode === "mac"
                    implicitWidth: 48
                    implicitHeight: 16
                    radius: 8
                    color: Color.accent
                    Text {
                      anchors.centerIn: parent
                      text: "ACTIVE"
                      font.pixelSize: 9
                      font.bold: true
                      color: "#ffffff"
                    }
                  }
                }

                Text {
                  text: "Frosted Menu Bar • Dynamic Dock • SF Fonts"
                  font.family: "SF Pro Text, -apple-system, sans-serif"
                  font.pixelSize: Style.font.caption
                  color: Color.muted
                }
              }

              RowLayout {
                spacing: 6
                Button {
                  bordered: true
                  text: "🌙 Dark"
                  onClicked: { root.runCmd("omarchy-undercover -mac"); root.close() }
                }
                Button {
                  bordered: true
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
            radius: 10
            color: root.currentMode === "win11" ? Qt.rgba(Color.accent.r, Color.accent.g, Color.accent.b, 0.14) : Qt.rgba(1, 1, 1, 0.04)
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

                RowLayout {
                  spacing: 6
                  Text {
                    text: "Windows 11 Fluent"
                    font.family: "Segoe UI, sans-serif"
                    font.pixelSize: Style.font.caption + 1
                    font.bold: true
                    color: Color.foreground
                  }
                  Rectangle {
                    visible: root.currentMode === "win11"
                    implicitWidth: 48
                    implicitHeight: 16
                    radius: 8
                    color: Color.accent
                    Text {
                      anchors.centerIn: parent
                      text: "ACTIVE"
                      font.pixelSize: 9
                      font.bold: true
                      color: "#ffffff"
                    }
                  }
                }

                Text {
                  text: "Centered Mica Taskbar • Start Menu • Segoe UI"
                  font.family: "Segoe UI, sans-serif"
                  font.pixelSize: Style.font.caption
                  color: Color.muted
                }
              }

              RowLayout {
                spacing: 6
                Button {
                  bordered: true
                  text: "🌙 Dark"
                  onClicked: { root.runCmd("omarchy-undercover -w11"); root.close() }
                }
                Button {
                  bordered: true
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
            radius: 10
            color: root.currentMode === "omarchy" ? Qt.rgba(Color.accent.r, Color.accent.g, Color.accent.b, 0.14) : Qt.rgba(1, 1, 1, 0.04)
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
                bordered: true
                text: "Restore"
                onClicked: { root.runCmd("omarchy-undercover --disable"); root.close() }
              }
            }
          }

          Rectangle {
            Layout.fillWidth: true
            height: 1
            color: Qt.rgba(1, 1, 1, 0.12)
          }

          // 3. Desktop Engine Controls
          Text {
            text: "DESKTOP ENGINE CONTROLS"
            font.family: Style.font.family
            font.pixelSize: Style.font.caption
            font.bold: true
            color: Color.muted
          }

          GridLayout {
            Layout.fillWidth: true
            columns: 2
            rowSpacing: 8
            columnSpacing: 8

            Button {
              Layout.fillWidth: true
              bordered: true
              text: "Alignment: " + (root.currentMode === "win11" ? "Center / Left" : "Top Bar")
              onClicked: {
                root.runCmd("omarchy-undercover-settings -a")
              }
            }

            Button {
              Layout.fillWidth: true
              bordered: true
              text: "Auto-hide: " + (root.isAutohide ? "ON (Edge)" : "OFF (Pinned)")
              onClicked: {
                root.runCmd("omarchy-undercover --autohide")
              }
            }

            Button {
              Layout.fillWidth: true
              bordered: true
              text: "Frosted Glass: " + (root.isTransparent ? "Blur / Mica" : "Solid")
              onClicked: {
                root.runCmd("omarchy-undercover --transparency " + (root.isTransparent ? "off" : "on"))
              }
            }

            Button {
              Layout.fillWidth: true
              bordered: true
              text: "⚙️ System Settings"
              onClicked: {
                root.runCmd("omarchy-undercover-settings")
                root.close()
              }
            }
          }

          Rectangle {
            Layout.fillWidth: true
            height: 1
            color: Qt.rgba(1, 1, 1, 0.12)
          }

          // 4. Quick Productivity Utilities
          Text {
            text: "QUICK PRODUCTIVITY UTILITIES"
            font.family: Style.font.family
            font.pixelSize: Style.font.caption
            font.bold: true
            color: Color.muted
          }

          GridLayout {
            Layout.fillWidth: true
            columns: 2
            rowSpacing: 8
            columnSpacing: 8

            Button {
              Layout.fillWidth: true
              bordered: true
              text: "📐 Snap Assist"
              onClicked: { root.runCmd("omarchy-undercover-snap --assist"); root.close() }
            }
            Button {
              Layout.fillWidth: true
              bordered: true
              text: "🖥️ Identify Displays"
              onClicked: { root.runCmd("omarchy-display-identify"); root.close() }
            }
            Button {
              Layout.fillWidth: true
              bordered: true
              text: "🖥️ Show Desktop"
              onClicked: { root.runCmd("omarchy-undercover-show-desktop"); root.close() }
            }
            Button {
              Layout.fillWidth: true
              bordered: true
              text: "⚙️ Win11 Settings"
              onClicked: { root.runCmd("omarchy-win11-settings"); root.close() }
            }
          }

          Rectangle {
            Layout.fillWidth: true
            height: 1
            color: Qt.rgba(1, 1, 1, 0.12)
          }

          // 5. Quick Wallpapers Carousel
          Text {
            text: "AUTHENTIC 6K WALLPAPERS"
            font.family: Style.font.family
            font.pixelSize: Style.font.caption
            font.bold: true
            color: Color.muted
          }

          RowLayout {
            Layout.fillWidth: true
            spacing: Style.space(8)

            Button {
              Layout.fillWidth: true
              bordered: true
              text: "Sequoia"
              onClicked: root.runCmd("omarchy-undercover-wallpaper -s 'macOS-Sequoia-Dark.jpg'")
            }
            Button {
              Layout.fillWidth: true
              bordered: true
              text: "Sonoma"
              onClicked: root.runCmd("omarchy-undercover-wallpaper -s 'Sonoma-dark.jpg'")
            }
            Button {
              Layout.fillWidth: true
              bordered: true
              text: "Ventura"
              onClicked: root.runCmd("omarchy-undercover-wallpaper -s 'Ventura-dark.jpg'")
            }
            Button {
              Layout.fillWidth: true
              bordered: true
              text: "Win 11 Bloom"
              onClicked: root.runCmd("omarchy-undercover-wallpaper -s 'win11_bloom_dark.jpg'")
            }
          }
        }
      }
    }
  }
}

import Quickshell
import Quickshell.Wayland
import Quickshell.Hyprland
import Quickshell.Io
import QtQuick
import QtQuick.Layouts

ShellRoot {
  PanelWindow {
    id: dockWindow
    screen: Quickshell.screens[0]

    anchors {
      bottom: true
    }
    margins {
      bottom: 8
    }

    WlrLayershell.layer: WlrLayer.Top
    WlrLayershell.namespace: "omarchy-bar"
    exclusionMode: ExclusionMode.Auto
    color: "transparent"

    implicitWidth: dockCard.implicitWidth + 24
    implicitHeight: 74

    property real baseIconSize: 48
    property real maxMagnification: 1.35
    property string homeDir: Quickshell.env("HOME")
    property string iconBasePath: homeDir + "/.local/share/icons/mac-dock/"

    // Strict Theme Isolation Watcher: If state is not macOS mode, exit immediately
    Process {
      id: stateWatcher
      running: true
      command: ["bash", "-c", "cat $HOME/.config/omarchy-undercover/state 2>/dev/null || echo 'mac-dark'"]
      stdout: SplitParser {
        onRead: function(line) {
          var s = String(line).trim()
          if (s && s.indexOf("mac") !== 0) {
            Qt.quit()
          }
        }
      }
    }

    Timer {
      interval: 1500
      running: true
      repeat: true
      onTriggered: {
        if (!stateWatcher.running) stateWatcher.running = true
      }
    }

    // Helper function to find matching running toplevel window
    function getAppToplevel(matchers) {
      if (!matchers || matchers.length === 0) return null
      try {
        var list = ToplevelManager.toplevels ? ToplevelManager.toplevels.values : []
        for (var i = 0; i < list.length; i++) {
          var tl = list[i]
          var id = (tl.appId || "").toLowerCase()
          var title = (tl.title || "").toLowerCase()
          for (var m = 0; m < matchers.length; m++) {
            var pat = matchers[m].toLowerCase()
            if (id.indexOf(pat) !== -1 || title.indexOf(pat) !== -1) {
              return tl
            }
          }
        }
      } catch (e) {}
      return null
    }

    function isRunning(matchers) {
      if (!matchers || matchers.length === 0) return false
      return getAppToplevel(matchers) !== null
    }

    function isFocused(matchers) {
      try {
        var active = ToplevelManager.activeToplevel
        if (!active || !matchers || matchers.length === 0) return false
        var id = (active.appId || "").toLowerCase()
        var title = (active.title || "").toLowerCase()
        for (var m = 0; m < matchers.length; m++) {
          var pat = matchers[m].toLowerCase()
          if (id.indexOf(pat) !== -1 || title.indexOf(pat) !== -1) {
            return true
          }
        }
      } catch (e) {}
      return false
    }

    property var dockApps: [
      { name: "Finder", icon: "finder.svg", exec: "nautilus computer:/// || thunar || dolphin", matchers: ["nautilus", "thunar", "dolphin", "files", "org.gnome.nautilus"] },
      { name: "Launchpad", icon: "launchpad.svg", exec: "rofi -show drun -theme ~/.config/rofi/mac.rasi", matchers: [] },
      { name: "Safari", icon: "safari.svg", exec: "xdg-open https://apple.com || firefox || google-chrome-stable", matchers: ["chrome", "chromium", "firefox", "vivaldi", "edge", "brave", "zen", "safari"] },
      { name: "Antigravity IDE", icon: "antigravity.svg", exec: "antigravity-ide || code || vscodium", matchers: ["antigravity", "code", "vscodium", "vscode", "codium"] },
      { name: "Messages", icon: "messages.svg", exec: "omarchy-mac-widgets", matchers: ["messages"] },
      { name: "Music", icon: "music.svg", exec: "spotify || omarchy-mac-widgets", matchers: ["spotify", "music"] },
      { name: "Photos", icon: "photos.svg", exec: "eog || gwenview || loupe", matchers: ["eog", "gwenview", "loupe", "photos"] },
      { name: "Terminal", icon: "terminal.svg", exec: "xdg-terminal-exec", matchers: ["kitty", "alacritty", "foot", "terminal", "wezterm", "ghostty", "ptyxis", "xterm"] },
      { name: "System Settings", icon: "settings.svg", exec: "omarchy-undercover-settings", matchers: ["omarchy-undercover-settings", "org.omarchy.undercover.settings", "settings", "gnome-control-center"] },
      { name: "App Store", icon: "appstore.svg", exec: "pamac-manager || gnome-software || discover", matchers: ["pamac", "software", "discover"] }
    ]

    Rectangle {
      id: dockCard
      anchors.horizontalCenter: parent.horizontalCenter
      anchors.bottom: parent.bottom
      anchors.bottomMargin: 2

      implicitWidth: mainRow.implicitWidth + 22
      implicitHeight: 64

      radius: 20
      color: Qt.rgba(0.12, 0.12, 0.16, 0.85)
      border.color: Qt.rgba(1, 1, 1, 0.22)
      border.width: 1

      RowLayout {
        id: mainRow
        anchors.centerIn: parent
        spacing: 10

        Repeater {
          model: dockWindow.dockApps

          Item {
            id: appItem
            implicitWidth: dockWindow.baseIconSize
            implicitHeight: dockWindow.baseIconSize + 8

            property bool isHovered: mouseArea.containsMouse
            property bool appRunning: dockWindow.isRunning(modelData.matchers)
            property bool appFocused: dockWindow.isFocused(modelData.matchers)
            property real currentScale: isHovered ? dockWindow.maxMagnification : 1.0

            Behavior on currentScale {
              NumberAnimation { duration: 150; easing.type: Easing.OutBack }
            }

            // Tooltip
            Rectangle {
              visible: appItem.isHovered
              anchors.bottom: iconImage.top
              anchors.bottomMargin: 8
              anchors.horizontalCenter: parent.horizontalCenter
              radius: 6
              color: Qt.rgba(0.08, 0.08, 0.10, 0.94)
              border.color: Qt.rgba(1, 1, 1, 0.22)
              border.width: 1
              implicitWidth: tooltipText.implicitWidth + 12
              implicitHeight: tooltipText.implicitHeight + 6
              z: 100

              Text {
                id: tooltipText
                anchors.centerIn: parent
                text: modelData.name
                color: "#ffffff"
                font.pixelSize: 11
                font.weight: Font.DemiBold
              }
            }

            // App Icon
            Image {
              id: iconImage
              anchors.centerIn: parent
              width: Math.round(dockWindow.baseIconSize * appItem.currentScale)
              height: Math.round(dockWindow.baseIconSize * appItem.currentScale)
              source: dockWindow.iconBasePath + modelData.icon
              sourceSize.width: 64
              sourceSize.height: 64
              fillMode: Image.PreserveAspectFit
              smooth: true
              mipmap: true
              z: appItem.isHovered ? 20 : 1
            }

            // Active Dot Indicator (macOS style running indicator)
            Rectangle {
              visible: appItem.appRunning
              anchors.bottom: parent.bottom
              anchors.bottomMargin: -3
              anchors.horizontalCenter: parent.horizontalCenter
              width: appItem.appFocused ? 6 : 4
              height: appItem.appFocused ? 6 : 4
              radius: appItem.appFocused ? 3 : 2
              color: appItem.appFocused ? "#60cdff" : "#ffffff"
            }

            MouseArea {
              id: mouseArea
              anchors.fill: parent
              hoverEnabled: true
              cursorShape: Qt.PointingHandCursor
              onClicked: {
                if (modelData.matchers && modelData.matchers.length > 0) {
                  var tl = dockWindow.getAppToplevel(modelData.matchers)
                  if (tl) {
                    tl.activate()
                    return
                  }
                }
                Quickshell.execDetached(["bash", "-c", modelData.exec])
              }
            }
          }
        }

        // Separator
        Rectangle {
          implicitWidth: 1
          implicitHeight: 36
          color: Qt.rgba(1, 1, 1, 0.22)
          Layout.alignment: Qt.AlignVCenter
          Layout.leftMargin: 2
          Layout.rightMargin: 2
        }

        // Trash Bin Item
        Item {
          id: trashItem
          implicitWidth: dockWindow.baseIconSize
          implicitHeight: dockWindow.baseIconSize + 8

          property bool isTrashHovered: trashMouse.containsMouse
          property real trashScale: isTrashHovered ? dockWindow.maxMagnification : 1.0

          Behavior on trashScale {
            NumberAnimation { duration: 150; easing.type: Easing.OutBack }
          }

          Rectangle {
            visible: trashItem.isTrashHovered
            anchors.bottom: trashText.top
            anchors.bottomMargin: 8
            anchors.horizontalCenter: parent.horizontalCenter
            radius: 6
            color: Qt.rgba(0.08, 0.08, 0.10, 0.94)
            border.color: Qt.rgba(1, 1, 1, 0.22)
            border.width: 1
            implicitWidth: trashTip.implicitWidth + 12
            implicitHeight: trashTip.implicitHeight + 6
            z: 100

            Text {
              id: trashTip
              anchors.centerIn: parent
              text: "Trash"
              color: "#ffffff"
              font.pixelSize: 11
              font.weight: Font.DemiBold
            }
          }

          Text {
            id: trashText
            anchors.centerIn: parent
            text: "🗑️"
            font.pixelSize: Math.round(26 * trashItem.trashScale)
            z: trashItem.isTrashHovered ? 20 : 1
          }

          MouseArea {
            id: trashMouse
            anchors.fill: parent
            hoverEnabled: true
            cursorShape: Qt.PointingHandCursor
            onClicked: {
              Quickshell.execDetached(["bash", "-c", "nautilus trash:/// || thunar trash:/// || dolphin trash:/"])
            }
          }
        }
      }
    }
  }
}

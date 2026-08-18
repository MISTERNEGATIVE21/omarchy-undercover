import QtQuick
import QtQuick.Layouts
import Quickshell
import Quickshell.Wayland
import Quickshell.Hyprland
import Quickshell.Io
import qs.Commons
import qs.Ui

PanelWindow {
  id: dockWindow
  screen: Quickshell.screens[0]

  anchors {
    bottom: true
  }
  margins {
    bottom: 8
  }

  WlLayer.layer: WlLayer.Top
  WlLayer.namespace: "mac-dock"
  exclusiveZone: 0
  color: "transparent"

  implicitWidth: dockCard.implicitWidth + 24
  implicitHeight: 80

  property real baseIconSize: 48
  property real maxMagnification: 1.32
  property string homeDir: Quickshell.env("HOME")
  property string iconBasePath: homeDir + "/.local/share/icons/mac-dock/"

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

  // Defaults & pinned apps poller
  property var macPinsConfig: ({})

  Process {
    id: defaultsPoller
    running: true
    command: ["bash", "-c", "cat $HOME/.config/omarchy-undercover/defaults.json 2>/dev/null || echo '{}'"]
    stdout: SplitParser {
      onRead: function(line) {
        try {
          var d = JSON.parse(String(line))
          if (d && d.mac_pins) {
            dockWindow.macPinsConfig = d.mac_pins
          }
        } catch(e) {}
      }
    }
  }

  Timer {
    interval: 3000
    running: true
    repeat: true
    triggeredOnStart: true
    onTriggered: {
      if (!defaultsPoller.running) defaultsPoller.running = true
    }
  }

  // Active dock apps model
  property var dockApps: [
    { id: "finder", name: "Finder", icon: "finder.svg", exec: "nautilus computer:/// || thunar || dolphin", matchers: ["nautilus", "thunar", "dolphin", "files", "org.gnome.nautilus"] },
    { id: "launchpad", name: "Launchpad", icon: "launchpad.svg", exec: "rofi -show drun -theme ~/.config/rofi/mac.rasi", matchers: [] },
    { id: "safari", name: "Safari", icon: "safari.svg", exec: "omarchy-browser || xdg-open https://apple.com", matchers: ["chrome", "chromium", "firefox", "vivaldi", "edge", "brave", "zen", "safari"] },
    { id: "antigravity", name: "Antigravity IDE", icon: "antigravity.svg", exec: "antigravity-ide || code || vscodium", matchers: ["antigravity", "code", "vscodium", "vscode", "codium"] },
    { id: "messages", name: "Messages", icon: "messages.svg", exec: "omarchy-mac-widgets", matchers: ["messages"] },
    { id: "music", name: "Music", icon: "music.svg", exec: "spotify || omarchy-mac-widgets", matchers: ["spotify", "music"] },
    { id: "photos", name: "Photos", icon: "photos.svg", exec: "loupe || eog || gwenview", matchers: ["eog", "gwenview", "loupe", "photos"] },
    { id: "terminal", name: "Terminal", icon: "terminal.svg", exec: "xdg-terminal-exec || alacritty || kitty", matchers: ["kitty", "alacritty", "foot", "terminal", "wezterm", "ghostty", "ptyxis", "xterm"] },
    { id: "settings", name: "System Settings", icon: "settings.svg", exec: "omarchy-undercover-settings", matchers: ["omarchy-undercover-settings", "org.omarchy.undercover.settings", "settings", "gnome-control-center"] },
    { id: "appstore", name: "App Store", icon: "appstore.svg", exec: "pamac-manager || gnome-software || discover", matchers: ["pamac", "software", "discover"] }
  ]

  function getVisibleDockApps() {
    return dockWindow.dockApps.filter(function(app) {
      if (dockWindow.macPinsConfig && dockWindow.macPinsConfig[app.id] !== undefined) {
        return dockWindow.macPinsConfig[app.id] === true
      }
      return true
    })
  }

  Rectangle {
    id: dockCard
    anchors.horizontalCenter: parent.horizontalCenter
    anchors.bottom: parent.bottom
    anchors.bottomMargin: 4

    implicitWidth: mainRow.implicitWidth + 20
    implicitHeight: 64

    radius: 20
    color: "rgba(35, 35, 45, 0.78)"
    border.color: "rgba(255, 255, 255, 0.22)"
    border.width: 1

    RowLayout {
      id: mainRow
      anchors.centerIn: parent
      spacing: 10

      Repeater {
        model: dockWindow.getVisibleDockApps()

        Item {
          id: appItem
          implicitWidth: dockWindow.baseIconSize
          implicitHeight: dockWindow.baseIconSize + 8

          property bool isHovered: mouseArea.containsMouse
          property bool appRunning: dockWindow.isRunning(modelData.matchers)
          property bool appFocused: dockWindow.isFocused(modelData.matchers)
          property real currentScale: isHovered ? dockWindow.maxMagnification : 1.0

          Behavior on currentScale {
            NumberAnimation { duration: 160; easing.type: Easing.OutBack }
          }

          // Tooltip above icon
          Rectangle {
            visible: appItem.isHovered
            anchors.bottom: iconImage.top
            anchors.bottomMargin: 8
            anchors.horizontalCenter: parent.horizontalCenter
            radius: 6
            color: "rgba(20, 20, 26, 0.90)"
            border.color: "rgba(255, 255, 255, 0.20)"
            border.width: 1
            implicitWidth: tipText.implicitWidth + 12
            implicitHeight: tipText.implicitHeight + 6

            Text {
              id: tipText
              anchors.centerIn: parent
              text: modelData.name
              color: "#ffffff"
              font.pixelSize: 11
              font.weight: Font.DemiBold
            }
          }

          // App Icon Image
          Image {
            id: iconImage
            anchors.centerIn: parent
            width: dockWindow.baseIconSize * appItem.currentScale
            height: dockWindow.baseIconSize * appItem.currentScale
            source: "file://" + dockWindow.iconBasePath + modelData.icon
            sourceSize.width: 64
            sourceSize.height: 64
            fillMode: Image.PreserveAspectFit
            smooth: true
            mipmap: true
            z: appItem.isHovered ? 10 : 1
          }

          // Running dot indicator
          Rectangle {
            visible: appItem.appRunning
            anchors.bottom: parent.bottom
            anchors.bottomMargin: 1
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
                var matchStr = modelData.matchers.join(",")
                Quickshell.execDetached(["omarchy-undercover-activate", matchStr, modelData.exec])
              } else {
                Quickshell.execDetached(["bash", "-c", modelData.exec])
              }
            }
          }
        }
      }

      // Dock Separator
      Rectangle {
        implicitWidth: 1
        implicitHeight: 38
        color: "rgba(255, 255, 255, 0.20)"
        Layout.alignment: Qt.AlignVCenter
        Layout.leftMargin: 2
        Layout.rightMargin: 2
      }

      // Trash Bin Item
      Item {
        implicitWidth: dockWindow.baseIconSize
        implicitHeight: dockWindow.baseIconSize + 8

        property bool isTrashHovered: trashMouse.containsMouse
        property real trashScale: isTrashHovered ? dockWindow.maxMagnification : 1.0

        Behavior on trashScale {
          NumberAnimation { duration: 160; easing.type: Easing.OutBack }
        }

        // Trash Tooltip
        Rectangle {
          visible: isTrashHovered
          anchors.bottom: trashIcon.top
          anchors.bottomMargin: 8
          anchors.horizontalCenter: parent.horizontalCenter
          radius: 6
          color: "rgba(20, 20, 26, 0.90)"
          border.color: "rgba(255, 255, 255, 0.20)"
          border.width: 1
          implicitWidth: trashTipText.implicitWidth + 12
          implicitHeight: trashTipText.implicitHeight + 6

          Text {
            id: trashTipText
            anchors.centerIn: parent
            text: "Trash"
            color: "#ffffff"
            font.pixelSize: 11
            font.weight: Font.DemiBold
          }
        }

        Text {
          id: trashIcon
          anchors.centerIn: parent
          text: "🗑️"
          font.pixelSize: Math.round(26 * trashScale)
          z: isTrashHovered ? 10 : 1
        }

        MouseArea {
          id: trashMouse
          anchors.fill: parent
          hoverEnabled: true
          cursorShape: Qt.PointingHandCursor
          onClicked: {
            Quickshell.execDetached("nautilus trash:/// || thunar trash:/// || dolphin trash:/")
          }
        }
      }
    }
  }
}

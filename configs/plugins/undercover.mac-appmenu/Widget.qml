import QtQuick
import QtQuick.Layouts
import Quickshell
import Quickshell.Wayland
import qs.Commons
import qs.Ui

BarWidget {
  id: root
  moduleName: "undercover.mac-appmenu"

  property string openMenu: "" // "", "app", "file", "edit", "view", "go", "window", "help"
  readonly property bool hasOpenMenu: openMenu !== ""

  function runCmd(cmd) {
    root.openMenu = ""
    if (root.bar) {
      root.bar.run(cmd)
    } else {
      Quickshell.execDetached(["bash", "-c", cmd])
    }
  }

  // Active Application Name Resolver
  readonly property string activeAppName: {
    var tl = ToplevelManager.activeToplevel
    if (!tl) return "Finder"
    var title = tl.title || ""
    var appId = tl.appId || ""

    if (appId) {
      var aid = appId.toLowerCase()
      if (aid.indexOf("flea") !== -1 || aid.indexOf("nautilus") !== -1 || aid.indexOf("thunar") !== -1 || aid.indexOf("dolphin") !== -1 || aid.indexOf("nemo") !== -1 || aid.indexOf("pcmanfm") !== -1) return "Finder"
      if (aid.indexOf("alacritty") !== -1 || aid.indexOf("kitty") !== -1 || aid.indexOf("terminal") !== -1 || aid.indexOf("foot") !== -1) return "Terminal"
      if (aid.indexOf("code") !== -1 || aid.indexOf("vscodium") !== -1) return "Visual Studio Code"
      if (aid.indexOf("antigravity") !== -1) return "Antigravity IDE"
      if (aid.indexOf("firefox") !== -1) return "Firefox"
      if (aid.indexOf("chrome") !== -1 || aid.indexOf("chromium") !== -1) return "Google Chrome"
      if (aid.indexOf("edge") !== -1) return "Microsoft Edge"
      if (aid.indexOf("discord") !== -1 || aid.indexOf("vesktop") !== -1) return "Discord"
      if (aid.indexOf("spotify") !== -1) return "Spotify"
      if (aid.indexOf("settings") !== -1) return "System Settings"
      // Clean generic appId (e.g. org.gnome.TextEditor -> Text Editor)
      var segs = appId.split(".")
      var last = segs[segs.length - 1]
      return last.charAt(0).toUpperCase() + last.slice(1)
    }

    if (title) {
      var p = title.split(" — ")
      if (p.length > 1) return p[p.length - 1].trim()
      var dash = title.split(" - ")
      if (dash.length > 1) return dash[dash.length - 1].trim()
      return title.length > 20 ? title.substring(0, 18) + "…" : title
    }

    return "Finder"
  }

  implicitWidth: menuRow.implicitWidth + 8
  implicitHeight: root.bar ? root.bar.barSize : 24

  RowLayout {
    id: menuRow
    anchors.verticalCenter: parent.verticalCenter
    anchors.left: parent.left
    anchors.leftMargin: 2
    spacing: 0

    // 1. Active App Title (Bold)
    Rectangle {
      id: appTitleBtn
      implicitWidth: appTitleText.implicitWidth + 14
      implicitHeight: root.bar ? root.bar.barSize - 4 : 22
      radius: 4
      color: root.openMenu === "app" ? (root.bar ? root.bar.hoverBackground : Qt.rgba(1, 1, 1, 0.16)) : (appMouse.containsMouse ? (root.bar ? root.bar.widgetBackground : Qt.rgba(1, 1, 1, 0.08)) : "transparent")

      Text {
        id: appTitleText
        anchors.centerIn: parent
        text: root.activeAppName
        font.family: "SF Pro Text, -apple-system, sans-serif"
        font.pixelSize: 13
        font.weight: Font.Bold
        color: root.bar ? root.bar.foreground : "#ffffff"
      }

      MouseArea {
        id: appMouse
        anchors.fill: parent
        hoverEnabled: true
        cursorShape: Qt.PointingHandCursor
        onClicked: root.openMenu = (root.openMenu === "app" ? "" : "app")
      }
    }

    // Standard macOS Menus: File, Edit, View, Go, Window, Help
    Repeater {
      model: [
        { id: "file", title: "File" },
        { id: "edit", title: "Edit" },
        { id: "view", title: "View" },
        { id: "go", title: "Go" },
        { id: "window", title: "Window" },
        { id: "help", title: "Help" }
      ]

      Rectangle {
        id: menuItemBtn
        implicitWidth: menuLabel.implicitWidth + 14
        implicitHeight: root.bar ? root.bar.barSize - 4 : 22
        radius: 4
        color: root.openMenu === modelData.id ? (root.bar ? root.bar.hoverBackground : Qt.rgba(1, 1, 1, 0.16)) : (itemMouse.containsMouse ? (root.bar ? root.bar.widgetBackground : Qt.rgba(1, 1, 1, 0.08)) : "transparent")

        Text {
          id: menuLabel
          anchors.centerIn: parent
          text: modelData.title
          font.family: "SF Pro Text, -apple-system, sans-serif"
          font.pixelSize: 13
          font.weight: Font.Normal
          color: root.bar ? root.bar.foreground : "#ffffff"
        }

        MouseArea {
          id: itemMouse
          anchors.fill: parent
          hoverEnabled: true
          cursorShape: Qt.PointingHandCursor
          onEntered: {
            if (root.hasOpenMenu) root.openMenu = modelData.id
          }
          onClicked: {
            root.openMenu = (root.openMenu === modelData.id ? "" : modelData.id)
          }
        }
      }
    }
  }

  // Authentic macOS Popover Dropdown Panel
  KeyboardPanel {
    id: dropdownPanel
    anchorItem: menuRow
    owner: root
    bar: root.bar
    open: root.hasOpenMenu
    contentWidth: 230
    contentHeight: menuItemsCol.implicitHeight + 16

    Rectangle {
      anchors.fill: parent
      color: Color.popups.background
      radius: Style.radius(10)
      border.color: Qt.rgba(1, 1, 1, 0.16)
      border.width: 1
      clip: true

      ColumnLayout {
        id: menuItemsCol
        anchors.fill: parent
        anchors.margins: 6
        spacing: 2

        Repeater {
          model: {
            if (root.openMenu === "app") {
              return [
                { text: "About " + root.activeAppName, shortcut: "", cmd: "omarchy-mac-applemenu" },
                { isSeparator: true },
                { text: "Settings...", shortcut: "⌘,", cmd: "omarchy-mac-settings" },
                { isSeparator: true },
                { text: "Hide " + root.activeAppName, shortcut: "⌘H", cmd: "omarchy-undercover-minimize" },
                { text: "Hide Others", shortcut: "⌥⌘H", cmd: "" },
                { text: "Show All", shortcut: "", cmd: "" },
                { isSeparator: true },
                { text: "Quit " + root.activeAppName, shortcut: "⌘Q", cmd: "hyprctl dispatch killactive" }
              ]
            } else if (root.openMenu === "file") {
              return [
                { text: "New Window", shortcut: "⌘N", cmd: "xdg-terminal-exec || alacritty" },
                { text: "New Finder Window", shortcut: "⇧⌘N", cmd: "omarchy-undercover-filemanager ~" },
                { text: "Open...", shortcut: "⌘O", cmd: "omarchy-undercover-filemanager ~" },
                { isSeparator: true },
                { text: "Close Window", shortcut: "⌘W", cmd: "hyprctl dispatch killactive" }
              ]
            } else if (root.openMenu === "edit") {
              return [
                { text: "Undo", shortcut: "⌘Z", cmd: "wtype -M ctrl -k z -m ctrl" },
                { text: "Redo", shortcut: "⇧⌘Z", cmd: "wtype -M ctrl -M shift -k z -m shift -m ctrl" },
                { isSeparator: true },
                { text: "Cut", shortcut: "⌘X", cmd: "wtype -M ctrl -k x -m ctrl" },
                { text: "Copy", shortcut: "⌘C", cmd: "wtype -M ctrl -k c -m ctrl" },
                { text: "Paste", shortcut: "⌘V", cmd: "wtype -M ctrl -k v -m ctrl" },
                { text: "Select All", shortcut: "⌘A", cmd: "wtype -M ctrl -k a -m ctrl" }
              ]
            } else if (root.openMenu === "view") {
              return [
                { text: "Enter Full Screen", shortcut: "Fn F", cmd: "hyprctl dispatch fullscreen" },
                { isSeparator: true },
                { text: "Notification Center & Widgets", shortcut: "", cmd: "omarchy-mac-widgets" },
                { text: "Control Center", shortcut: "", cmd: "omarchy-mac-controlcenter" },
                { isSeparator: true },
                { text: "Cycle Camouflage Mode", shortcut: "", cmd: "omarchy-undercover --toggle" }
              ]
            } else if (root.openMenu === "go") {
              return [
                { text: "Home", shortcut: "⇧⌘H", cmd: "omarchy-undercover-filemanager ~" },
                { text: "Documents", shortcut: "⇧⌘O", cmd: "omarchy-undercover-filemanager ~/Documents" },
                { text: "Downloads", shortcut: "⌥⌘L", cmd: "omarchy-undercover-filemanager ~/Downloads" },
                { text: "Pictures", shortcut: "", cmd: "omarchy-undercover-filemanager ~/Pictures" },
                { text: "Applications", shortcut: "⇧⌘A", cmd: "rofi -show drun -theme ~/.config/rofi/mac.rasi" },
                { text: "Computer", shortcut: "⇧⌘C", cmd: "omarchy-undercover-filemanager /" }
              ]
            } else if (root.openMenu === "window") {
              return [
                { text: "Minimize", shortcut: "⌘M", cmd: "omarchy-undercover-minimize" },
                { text: "Zoom / Maximize", shortcut: "", cmd: "hyprctl dispatch fullscreen" },
                { isSeparator: true },
                { text: "Next Window", shortcut: "⌘`", cmd: "hyprctl dispatch cyclenext" },
                { text: "Mission Control", shortcut: "", cmd: "rofi -show window -theme ~/.config/rofi/mac.rasi" }
              ]
            } else if (root.openMenu === "help") {
              return [
                { text: "Omarchy Undercover Help", shortcut: "", cmd: "omarchy-undercover-settings -s" },
                { text: "System Settings...", shortcut: "", cmd: "omarchy-mac-settings" },
                { isSeparator: true },
                { text: "About This Mac", shortcut: "", cmd: "omarchy-mac-applemenu" }
              ]
            }
            return []
          }

          delegate: Item {
            Layout.fillWidth: true
            implicitHeight: modelData.isSeparator ? 9 : 26

            Rectangle {
              visible: modelData.isSeparator === true
              anchors.centerIn: parent
              width: parent.width - 8
              height: 1
              color: Color.separator
            }

            Rectangle {
              visible: !modelData.isSeparator
              anchors.fill: parent
              radius: 5
              color: itemRowMouse.containsMouse ? Color.accent : "transparent"

              RowLayout {
                anchors.fill: parent
                anchors.leftMargin: 10
                anchors.rightMargin: 10

                Text {
                  text: modelData.text || ""
                  font.family: "SF Pro Text, -apple-system, sans-serif"
                  font.pixelSize: 12
                  color: itemRowMouse.containsMouse ? "#ffffff" : Color.foreground
                  Layout.fillWidth: true
                  elide: Text.ElideRight
                }

                Text {
                  text: modelData.shortcut || ""
                  font.family: "SF Pro Text, -apple-system, sans-serif"
                  font.pixelSize: 11
                  color: itemRowMouse.containsMouse ? Qt.rgba(1, 1, 1, 0.85) : Qt.rgba(Color.foreground.r, Color.foreground.g, Color.foreground.b, 0.5)
                }
              }

              MouseArea {
                id: itemRowMouse
                anchors.fill: parent
                hoverEnabled: true
                cursorShape: Qt.PointingHandCursor
                onClicked: {
                  if (modelData.cmd) root.runCmd(modelData.cmd)
                  else root.openMenu = ""
                }
              }
            }
          }
        }
      }
    }
  }
}

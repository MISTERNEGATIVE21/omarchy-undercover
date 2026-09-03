import QtQuick
import QtQuick.Layouts
import Quickshell
import Quickshell.Wayland
import Quickshell.Hyprland
import Quickshell.Io
import qs.Ui

Panel {
  id: dockWindow

  anchors {
    bottom: true
  }
  margins {
    bottom: 6
  }

  WlrLayershell.layer: WlrLayer.Top
  WlrLayershell.namespace: "mac-dock"
  exclusionMode: dockWindow.isAutohide ? ExclusionMode.Ignore : ExclusionMode.Auto
  color: "transparent"

  implicitWidth: dockCard.implicitWidth + 48
  implicitHeight: 90

  property real baseIconSize: 48
  property real maxMagnification: 1.45
  property real effectRadius: 130.0
  property bool isMouseOverDock: false
  property real currentMouseX: 0

  property string homeDir: Quickshell.env("HOME")
  property string iconBasePath: homeDir + "/.local/share/icons/mac-dock/"
  property bool isLight: false
  property bool isAutohide: false
  property bool isDockRevealed: true

  // 30-Second Inactivity / Exit timer before sliding down
  Timer {
    id: hideTimer
    interval: 30000 // 30 seconds
    running: false
    repeat: false
    onTriggered: {
      if (dockWindow.isAutohide && !dockWindow.isMouseOverDock && !edgeTrigger.containsMouse) {
        dockWindow.isDockRevealed = false
      }
    }
  }

  // Inactivity timer while dock is visible
  Timer {
    id: inactivityTimer
    interval: 30000 // 30 seconds
    running: dockWindow.isAutohide && dockWindow.isDockRevealed
    repeat: false
    onTriggered: {
      if (dockWindow.isAutohide && !edgeTrigger.containsMouse) {
        dockWindow.isDockRevealed = false
      }
    }
  }

  FileView {
    id: stateWatcher
    path: dockWindow.homeDir + "/.config/omarchy-undercover/state"
    watchChanges: true
    onLoaded: {
      var s = text().trim()
      dockWindow.isLight = (s.indexOf("light") !== -1)
      if (s && s.indexOf("mac") !== 0) dockWindow.visible = false
      else dockWindow.visible = true
    }
    onFileChanged: {
      reload()
      var s = text().trim()
      dockWindow.isLight = (s.indexOf("light") !== -1)
      if (s && s.indexOf("mac") !== 0) dockWindow.visible = false
      else dockWindow.visible = true
    }
  }

  FileView {
    id: settingsWatcher
    path: dockWindow.homeDir + "/.config/omarchy-undercover/settings.conf"
    watchChanges: true
    onLoaded: {
      var s = text()
      dockWindow.isAutohide = (s.indexOf("AUTOHIDE=true") !== -1)
      if (!dockWindow.isAutohide) dockWindow.isDockRevealed = true
    }
    onFileChanged: {
      reload()
      var s = text()
      dockWindow.isAutohide = (s.indexOf("AUTOHIDE=true") !== -1)
      if (!dockWindow.isAutohide) dockWindow.isDockRevealed = true
    }
  }

  function matches(tl, matchers) {
    if (!tl || !matchers || matchers.length === 0) return false
    var target = ((tl.appId || "") + " " + (tl.title || "")).toLowerCase()
    return matchers.some(function(p) { return target.indexOf(p.toLowerCase()) !== -1 })
  }

  function isRunning(matchers) {
    var list = (ToplevelManager.toplevels && ToplevelManager.toplevels.values) ? ToplevelManager.toplevels.values : []
    return list.some(function(tl) { return dockWindow.matches(tl, matchers) })
  }

  function isFocused(matchers) {
    return dockWindow.matches(ToplevelManager.activeToplevel, matchers)
  }

  property var macPinsConfig: ({})
  FileView {
    id: defaultsFile
    path: dockWindow.homeDir + "/.config/omarchy-undercover/defaults.json"
    watchChanges: true
    onLoaded: {
      try {
        var d = JSON.parse(text())
        if (d && d.mac_pins) dockWindow.macPinsConfig = d.mac_pins
      } catch(e) {}
    }
    onFileChanged: {
      reload()
      try {
        var d = JSON.parse(text())
        if (d && d.mac_pins) dockWindow.macPinsConfig = d.mac_pins
      } catch(e) {}
    }
  }

  property var primaryDockApps: [
    { id: "finder", name: "Finder", icon: "finder.svg", exec: "nautilus computer:/// || thunar", matchers: ["nautilus", "thunar", "dolphin", "files", "org.gnome.nautilus"] },
    { id: "launchpad", name: "Launchpad", icon: "launchpad.svg", exec: "rofi -show drun -theme ~/.config/rofi/mac.rasi", matchers: [] },
    { id: "safari", name: "Safari", icon: "safari.svg", exec: "omarchy-browser", matchers: ["safari", "chrome", "chromium", "firefox", "vivaldi", "brave", "zen", "browser", "epiphany"] },
    { id: "messages", name: "Messages", icon: "messages.svg", exec: "telegram-desktop || discord || signal-desktop", matchers: ["telegram", "discord", "signal", "vesktop"] },
    { id: "mail", name: "Mail", icon: "mail.svg", exec: "thunderbird || geary || evolution", matchers: ["thunderbird", "geary", "evolution"] },
    { id: "maps", name: "Maps", icon: "maps.svg", exec: "gnome-maps || omarchy-browser https://maps.google.com", matchers: ["maps"] },
    { id: "photos", name: "Photos", icon: "photos.svg", exec: "eog || gwenview || loupe", matchers: ["eog", "gwenview", "loupe", "shotwell"] },
    { id: "facetime", name: "FaceTime", icon: "facetime.svg", exec: "cheese || kamoso", matchers: ["cheese", "kamoso"] },
    { id: "calendar", name: "Calendar", icon: "calendar.svg", exec: "gnome-calendar || korganizer", matchers: ["calendar", "korganizer"] },
    { id: "contacts", name: "Contacts", icon: "contacts.svg", exec: "gnome-contacts || kaddressbook", matchers: ["contacts"] },
    { id: "reminders", name: "Reminders", icon: "reminders.svg", exec: "gnome-todo || korganizer", matchers: ["todo", "reminders"] },
    { id: "notes", name: "Notes", icon: "notes.svg", exec: "gnome-notes || bijiben || obsidian", matchers: ["notes", "bijiben", "obsidian"] },
    { id: "music", name: "Music", icon: "music.svg", exec: "spotify || rhythmbox || amberol", matchers: ["spotify", "rhythmbox", "amberol", "music"] },
    { id: "antigravity", name: "Antigravity IDE", icon: "antigravity-ide.svg", exec: "antigravity-ide || code || vscodium", matchers: ["antigravity", "code", "vscodium", "vscode", "codium"] },
    { id: "terminal", name: "Terminal", icon: "terminal.svg", exec: "xdg-terminal-exec || alacritty || kitty", matchers: ["kitty", "alacritty", "foot", "terminal", "wezterm", "ghostty", "ptyxis", "xterm"] },
    { id: "settings", name: "System Settings", icon: "settings.svg", exec: "omarchy-undercover-settings", matchers: ["omarchy-undercover-settings", "org.omarchy.undercover.settings", "settings", "gnome-control-center"] },
    { id: "appstore", name: "App Store", icon: "appstore.svg", exec: "pamac-manager || gnome-software || discover", matchers: ["pamac", "software", "discover"] }
  ]

  function getVisibleDockApps() {
    return dockWindow.primaryDockApps.filter(function(app) {
      if (dockWindow.macPinsConfig && dockWindow.macPinsConfig[app.id] !== undefined) {
        return dockWindow.macPinsConfig[app.id] === true
      }
      return true
    })
  }

  // Native Wayland Bottom Edge Trigger Strip
  MouseArea {
    id: edgeTrigger
    anchors.left: parent.left
    anchors.right: parent.right
    anchors.bottom: parent.bottom
    height: 6
    hoverEnabled: true
    z: 20
    onEntered: {
      dockWindow.isDockRevealed = true
      inactivityTimer.restart()
      hideTimer.stop()
    }
  }

  Rectangle {
    anchors.horizontalCenter: dockCard.horizontalCenter
    anchors.bottom: dockCard.bottom
    anchors.bottomMargin: -3
    width: dockCard.width + 8
    height: dockCard.height + 4
    radius: 24
    color: Qt.rgba(0, 0, 0, 0.35)
    z: 0
    y: dockCard.y
  }

  Rectangle {
    id: dockCard
    anchors.horizontalCenter: parent.horizontalCenter
    anchors.bottom: parent.bottom
    anchors.bottomMargin: 2
    z: 1

    y: (dockWindow.isAutohide && !dockWindow.isDockRevealed) ? 82 : 0
    Behavior on y {
      NumberAnimation { duration: 240; easing.type: Easing.OutQuad }
    }

    implicitWidth: dockLayoutRow.implicitWidth + 24
    implicitHeight: 66
    radius: 20

    color: dockWindow.isLight ? Qt.rgba(0.98, 0.98, 1.0, 0.72) : Qt.rgba(0.12, 0.12, 0.16, 0.72)
    border.color: dockWindow.isLight ? Qt.rgba(0, 0, 0, 0.12) : Qt.rgba(1, 1, 1, 0.22)
    border.width: 1

    Rectangle {
      anchors.left: parent.left
      anchors.right: parent.right
      anchors.top: parent.top
      anchors.leftMargin: 12
      anchors.rightMargin: 12
      height: 1
      color: Qt.rgba(1, 1, 1, 0.38)
    }

    RowLayout {
      id: dockLayoutRow
      anchors.centerIn: parent
      spacing: 6

      Repeater {
        id: appsRepeater
        model: dockWindow.getVisibleDockApps()

        Item {
          id: appItem
          implicitWidth: dockWindow.baseIconSize
          implicitHeight: 62

          property var appData: modelData
          property bool appRunning: dockWindow.isRunning(modelData.matchers)
          property bool appFocused: dockWindow.isFocused(modelData.matchers)
          property real bounceOffset: 0

          readonly property real itemCenterX: appItem.mapToItem(dockCard, appItem.width / 2, 0).x
          readonly property real distToMouse: Math.abs(dockWindow.currentMouseX - itemCenterX)
          
          readonly property real targetScale: {
            if (!dockWindow.isMouseOverDock) return 1.0
            if (distToMouse >= dockWindow.effectRadius) return 1.0
            var ratio = distToMouse / dockWindow.effectRadius
            var factor = Math.cos(ratio * (Math.PI / 2))
            return 1.0 + (dockWindow.maxMagnification - 1.0) * factor * factor
          }

          property real currentScale: 1.0
          Behavior on currentScale {
            NumberAnimation { duration: 120; easing.type: Easing.OutQuad }
          }
          Binding {
            target: appItem
            property: "currentScale"
            value: appItem.targetScale
          }

          SequentialAnimation {
            id: bounceAnim
            running: false
            NumberAnimation { target: appItem; property: "bounceOffset"; to: -28; duration: 200; easing.type: Easing.OutQuad }
            NumberAnimation { target: appItem; property: "bounceOffset"; to: 0; duration: 180; easing.type: Easing.InQuad }
            NumberAnimation { target: appItem; property: "bounceOffset"; to: -16; duration: 150; easing.type: Easing.OutQuad }
            NumberAnimation { target: appItem; property: "bounceOffset"; to: 0; duration: 130; easing.type: Easing.InQuad }
            NumberAnimation { target: appItem; property: "bounceOffset"; to: -6; duration: 90; easing.type: Easing.OutQuad }
            NumberAnimation { target: appItem; property: "bounceOffset"; to: 0; duration: 70; easing.type: Easing.InQuad }
          }

          Rectangle {
            id: tooltip
            visible: dockWindow.isMouseOverDock && distToMouse < 28
            anchors.bottom: iconContainer.top
            anchors.bottomMargin: 10
            anchors.horizontalCenter: parent.horizontalCenter
            implicitWidth: tooltipText.implicitWidth + 16
            implicitHeight: 24
            radius: 6
            color: Qt.rgba(0.12, 0.12, 0.16, 0.94)
            border.color: Qt.rgba(1, 1, 1, 0.18)
            border.width: 1
            z: 99

            Text {
              id: tooltipText
              anchors.centerIn: parent
              text: modelData.name
              font.family: "SF Pro Text, -apple-system, sans-serif"
              font.pixelSize: 11
              font.bold: true
              color: "#ffffff"
            }
          }

          Item {
            id: iconContainer
            anchors.horizontalCenter: parent.horizontalCenter
            anchors.bottom: parent.bottom
            anchors.bottomMargin: 10
            width: dockWindow.baseIconSize
            height: dockWindow.baseIconSize
            scale: appItem.currentScale
            transformOrigin: Item.Bottom
            y: appItem.bounceOffset

            Image {
              id: appIcon
              anchors.fill: parent
              source: {
                var p = dockWindow.iconBasePath + modelData.icon
                if (modelData.icon.indexOf("/") !== -1 || modelData.icon.indexOf("file://") === 0) return modelData.icon
                return "file://" + p
              }
              fillMode: Image.PreserveAspectFit
              smooth: true
              mipmap: true
            }
          }

          Rectangle {
            visible: appItem.appRunning
            anchors.horizontalCenter: parent.horizontalCenter
            anchors.bottom: parent.bottom
            anchors.bottomMargin: 2
            width: appItem.appFocused ? 8 : 4.5
            height: 4.5
            radius: 2.25
            color: appItem.appFocused ? "#007aff" : (dockWindow.isLight ? Qt.rgba(0, 0, 0, 0.5) : Qt.rgba(1, 1, 1, 0.65))

            Behavior on width {
              NumberAnimation { duration: 150; easing.type: Easing.OutQuad }
            }
          }
        }
      }

      Rectangle {
        Layout.preferredWidth: 1
        Layout.preferredHeight: 40
        Layout.alignment: Qt.AlignVCenter
        color: dockWindow.isLight ? Qt.rgba(0, 0, 0, 0.16) : Qt.rgba(1, 1, 1, 0.20)
      }

      Item {
        id: trashItem
        implicitWidth: dockWindow.baseIconSize
        implicitHeight: 62

        readonly property real itemCenterX: trashItem.mapToItem(dockCard, trashItem.width / 2, 0).x
        readonly property real distToMouse: Math.abs(dockWindow.currentMouseX - itemCenterX)
        readonly property real targetScale: {
          if (!dockWindow.isMouseOverDock) return 1.0
          if (distToMouse >= dockWindow.effectRadius) return 1.0
          var ratio = distToMouse / dockWindow.effectRadius
          var factor = Math.cos(ratio * (Math.PI / 2))
          return 1.0 + (dockWindow.maxMagnification - 1.0) * factor * factor
        }

        property real currentScale: 1.0
        Behavior on currentScale {
          NumberAnimation { duration: 120; easing.type: Easing.OutQuad }
        }
        Binding {
          target: trashItem
          property: "currentScale"
          value: trashItem.targetScale
        }

        Rectangle {
          visible: dockWindow.isMouseOverDock && distToMouse < 28
          anchors.bottom: trashContainer.top
          anchors.bottomMargin: 10
          anchors.horizontalCenter: parent.horizontalCenter
          implicitWidth: trashText.implicitWidth + 16
          implicitHeight: 24
          radius: 6
          color: Qt.rgba(0.12, 0.12, 0.16, 0.94)
          border.color: Qt.rgba(1, 1, 1, 0.18)
          border.width: 1
          z: 99

          Text {
            id: trashText
            anchors.centerIn: parent
            text: "Trash"
            font.family: "SF Pro Text, -apple-system, sans-serif"
            font.pixelSize: 11
            font.bold: true
            color: "#ffffff"
          }
        }

        Item {
          id: trashContainer
          anchors.horizontalCenter: parent.horizontalCenter
          anchors.bottom: parent.bottom
          anchors.bottomMargin: 10
          width: dockWindow.baseIconSize
          height: dockWindow.baseIconSize
          scale: trashItem.currentScale
          transformOrigin: Item.Bottom

          Image {
            anchors.fill: parent
            source: "file://" + dockWindow.iconBasePath + "trash.svg"
            fillMode: Image.PreserveAspectFit
            smooth: true
          }
        }
      }
    }

    MouseArea {
      id: dockMouseArea
      anchors.fill: parent
      hoverEnabled: true
      acceptedButtons: Qt.LeftButton | Qt.RightButton
      cursorShape: Qt.PointingHandCursor

      onEntered: {
        dockWindow.isMouseOverDock = true
        dockWindow.isDockRevealed = true
        inactivityTimer.restart()
        hideTimer.stop()
      }

      onExited: {
        dockWindow.isMouseOverDock = false
        if (dockWindow.isAutohide) hideTimer.restart()
      }

      onPositionChanged: function(mouse) {
        dockWindow.currentMouseX = mouse.x
        inactivityTimer.restart()
      }

      onClicked: function(mouse) {
        var visibleApps = dockWindow.getVisibleDockApps()
        for (var i = 0; i < appsRepeater.count; i++) {
          var item = appsRepeater.itemAt(i)
          if (item) {
            var pos = item.mapToItem(dockCard, 0, 0)
            if (mouse.x >= pos.x && mouse.x <= pos.x + item.width) {
              item.children[2].running = true
              Quickshell.execDetached(["bash", "-c", item.appData.exec])
              return
            }
          }
        }

        var trashPos = trashItem.mapToItem(dockCard, 0, 0)
        if (mouse.x >= trashPos.x && mouse.x <= trashPos.x + trashItem.width) {
          Quickshell.execDetached(["nautilus", "trash:///"])
        }
      }
    }
  }
}

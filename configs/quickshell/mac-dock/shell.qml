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
      bottom: 0
    }

    WlrLayershell.layer: WlrLayer.Top
    WlrLayershell.namespace: "mac-dock"
    
    // Always overlays on top of windows without resizing them (the dock's
    // magnified icons + tooltips paint over whatever is behind it).
    exclusionMode: ExclusionMode.Ignore
    color: "transparent"

    readonly property real screenWidth: dockWindow.screen ? dockWindow.screen.width : 1920
    readonly property real screenHeight: dockWindow.screen ? dockWindow.screen.height : 1080
    readonly property real dpiScale: (dockWindow.screen && dockWindow.screen.devicePixelRatio) ? dockWindow.screen.devicePixelRatio : 1.0

    // Responsive scale factor based on screen height and DPI
    readonly property real responsiveScale: Math.max(0.85, Math.min(1.4, (screenHeight >= 1440 ? 1.15 : (screenHeight >= 1080 ? 1.0 : 0.9))))

    // Configured icon size (px) from settings.conf DOCK_SIZE
    property int dockSize: 44
    // Max number of app icons to show (DOCK_MAX_ITEMS), caps runaway running apps
    property int maxDockItems: 24
    // User-defined apps from defaults.json mac_custom_apps
    property var customDockApps: []

    readonly property real baseIconSize: Math.round(Math.max(24, dockWindow.dockSize) * dockWindow.responsiveScale)

    // Icon size dynamically re-computed so the whole dock always fits the screen
    readonly property real effectiveIconSize: {
      var count = dockWindow.dockItemCount
      if (count <= 1) return dockWindow.baseIconSize
      var spacing = Math.round(4 * dockWindow.responsiveScale)
      var avail = dockWindow.screenWidth * 0.94 - spacing * (count - 1)
      var fit = Math.floor(avail / count)
      return Math.max(Math.round(24 * dockWindow.responsiveScale), Math.min(dockWindow.baseIconSize, fit))
    }

    // Vertical headroom for magnified icons + tooltips (no top clipping / overlap)
    readonly property real magnifyRoom: Math.round((dockWindow.maxMagnification - 1.0) * dockWindow.effectiveIconSize + 28 * dockWindow.responsiveScale)

    implicitWidth: dockCard.implicitWidth + Math.round(32 * responsiveScale)
    implicitHeight: dockCard.height + Math.round(36 * responsiveScale) + (dockWindow.isMouseOverDock ? dockWindow.magnifyRoom : Math.round(6 * responsiveScale))

    property real maxMagnification: 1.24
    property real effectRadius: Math.round(70.0 * responsiveScale)
    property bool isMouseOverDock: false
    property real currentMouseX: 0
    // Dock background transparency (0-100, 100 = fully opaque)
    property int dockTransparency: 76

    property string homeDir: Quickshell.env("HOME")
    property string iconBasePath: homeDir + "/.local/share/icons/mac-dock/"
    property bool isLight: false
    property bool isAutohide: false
    property bool isDockRevealed: true

    // Quick macOS-style autohide delay (400ms) after mouse exits dock
    Timer {
      id: hideTimer
      interval: 400
      running: false
      repeat: false
      onTriggered: {
        if (dockWindow.isAutohide && !dockWindow.isMouseOverDock) {
          dockWindow.isDockRevealed = false
        }
      }
    }

    // Timer if cursor revealed dock from edge but didn't enter dock items
    Timer {
      id: edgeInactivityTimer
      interval: 1500
      running: false
      repeat: false
      onTriggered: {
        if (dockWindow.isAutohide && !dockWindow.isMouseOverDock) {
          dockWindow.isDockRevealed = false
        }
      }
    }

    // Strict Theme Isolation Watcher via reactive FileView
    FileView {
      id: stateWatcher
      path: dockWindow.homeDir + "/.config/omarchy-undercover/state"
      watchChanges: true
      onLoaded: {
        var s = text().trim()
        dockWindow.isLight = (s.indexOf("light") !== -1)
        if (s && s.indexOf("mac") !== 0) Qt.quit()
      }
      onFileChanged: {
        reload()
        var s = text().trim()
        dockWindow.isLight = (s.indexOf("light") !== -1)
        if (s && s.indexOf("mac") !== 0) Qt.quit()
      }
    }

    // Settings Watcher for dynamic autohide
    FileView {
      id: settingsWatcher
      path: dockWindow.homeDir + "/.config/omarchy-undercover/settings.conf"
      watchChanges: true
      onLoaded: {
        var s = text()
        dockWindow.isAutohide = (s.indexOf("AUTOHIDE=true") !== -1 || s.indexOf("AUTOHIDE=1") !== -1)
        var dm = s.match(/DOCK_SIZE=(\d+)/)
        if (dm && dm[1]) dockWindow.dockSize = Math.max(24, parseInt(dm[1]))
        var mm = s.match(/DOCK_MAX_ITEMS=(\d+)/)
        if (mm && mm[1]) dockWindow.maxDockItems = Math.max(4, parseInt(mm[1]))
        var dt = s.match(/DOCK_TRANSPARENCY=(\d+)/)
        if (dt && dt[1]) dockWindow.dockTransparency = Math.max(10, Math.min(100, parseInt(dt[1])))
        if (!dockWindow.isAutohide) dockWindow.isDockRevealed = true
      }
      onFileChanged: {
        reload()
        var s = text()
        dockWindow.isAutohide = (s.indexOf("AUTOHIDE=true") !== -1 || s.indexOf("AUTOHIDE=1") !== -1)
        var dm = s.match(/DOCK_SIZE=(\d+)/)
        if (dm && dm[1]) dockWindow.dockSize = Math.max(24, parseInt(dm[1]))
        var mm = s.match(/DOCK_MAX_ITEMS=(\d+)/)
        if (mm && mm[1]) dockWindow.maxDockItems = Math.max(4, parseInt(mm[1]))
        var dt = s.match(/DOCK_TRANSPARENCY=(\d+)/)
        if (dt && dt[1]) dockWindow.dockTransparency = Math.max(10, Math.min(100, parseInt(dt[1])))
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

    // Pinned apps configuration
    property var macPinsConfig: ({})
    FileView {
      id: defaultsFile
      path: dockWindow.homeDir + "/.config/omarchy-undercover/defaults.json"
      watchChanges: true
      onLoaded: {
        try {
          var d = JSON.parse(text())
          if (d && d.mac_pins) dockWindow.macPinsConfig = d.mac_pins
          if (d && d.mac_custom_apps) dockWindow.customDockApps = d.mac_custom_apps
        } catch(e) {}
      }
      onFileChanged: {
        reload()
        try {
          var d = JSON.parse(text())
          if (d && d.mac_pins) dockWindow.macPinsConfig = d.mac_pins
          if (d && d.mac_custom_apps) dockWindow.customDockApps = d.mac_custom_apps
        } catch(e) {}
      }
    }

    // Primary Curated macOS Sequoia Applications
    property var primaryDockApps: [
      { id: "finder", name: "Finder", icon: "finder.svg", exec: "nautilus computer:/// || thunar || dolphin", matchers: ["nautilus", "thunar", "dolphin", "files", "org.gnome.nautilus"] },
      { id: "launchpad", name: "Launchpad", icon: "launchpad.svg", exec: "rofi -show drun -theme ~/.config/rofi/mac.rasi", matchers: [] },
      { id: "safari", name: "Safari", icon: "safari.svg", exec: "omarchy-browser", matchers: ["safari", "chrome", "chromium", "firefox", "vivaldi", "brave", "zen", "browser", "epiphany"] },
      { id: "messages", name: "Messages", icon: "messages.svg", exec: "telegram-desktop || discord || signal-desktop || vesktop", matchers: ["telegram", "discord", "signal", "vesktop"] },
      { id: "mail", name: "Mail", icon: "mail.svg", exec: "thunderbird || geary || evolution || omarchy-browser https://mail.google.com", matchers: ["thunderbird", "geary", "evolution"] },
      { id: "maps", name: "Maps", icon: "maps.svg", exec: "gnome-maps || omarchy-browser https://maps.google.com", matchers: ["maps"] },
      { id: "photos", name: "Photos", icon: "photos.svg", exec: "eog || gwenview || loupe || shotwell", matchers: ["eog", "gwenview", "loupe", "shotwell"] },
      { id: "calendar", name: "Calendar", icon: "calendar.svg", exec: "gnome-calendar || korganizer || omarchy-browser https://calendar.google.com", matchers: ["calendar", "korganizer"] },
      { id: "notes", name: "Notes", icon: "notes.svg", exec: "gnome-notes || bijiben || obsidian", matchers: ["notes", "bijiben", "obsidian"] },
      { id: "reminders", name: "Reminders", icon: "reminders.svg", exec: "gnome-todo || korganizer", matchers: ["todo", "reminders"] },
      { id: "music", name: "Music", icon: "music.svg", exec: "spotify || rhythmbox || amberol", matchers: ["spotify", "rhythmbox", "amberol", "music"] },
      { id: "antigravity", name: "Antigravity IDE", icon: "antigravity-ide.svg", exec: "antigravity-ide || code || vscodium", matchers: ["antigravity", "code", "vscodium", "vscode", "codium"] },
      { id: "terminal", name: "Terminal", icon: "terminal.svg", exec: "xdg-terminal-exec || alacritty || kitty", matchers: ["kitty", "alacritty", "foot", "terminal", "wezterm", "ghostty", "ptyxis", "xterm"] },
      { id: "settings", name: "System Settings", icon: "settings.svg", exec: "omarchy-mac-settings", matchers: ["omarchy-mac-settings", "omarchy-undercover-settings", "org.omarchy.undercover.settings", "settings", "gnome-control-center"] },
      { id: "appstore", name: "App Store", icon: "appstore.svg", exec: "pamac-manager || gnome-software || discover", matchers: ["pamac", "software", "discover"] }
    ]

    function getVisibleDockApps() {
      var pinned = dockWindow.primaryDockApps.filter(function(app) {
        if (dockWindow.macPinsConfig && dockWindow.macPinsConfig[app.id] !== undefined) {
          return dockWindow.macPinsConfig[app.id] === true
        }
        return true
      })

      // Merge user-defined custom apps (respecting per-app mac_pins toggles)
      var custom = (dockWindow.customDockApps || []).filter(function(app) {
        if (dockWindow.macPinsConfig && dockWindow.macPinsConfig[app.id] !== undefined) {
          return dockWindow.macPinsConfig[app.id] === true
        }
        return true
      })

      // Discover unpinned running applications
      var list = (ToplevelManager.toplevels && ToplevelManager.toplevels.values) ? ToplevelManager.toplevels.values : []
      var unpinned = []
      var seenAppIds = {}

      for (var i = 0; i < list.length; i++) {
        var tl = list[i]
        if (!tl) continue
        var isPinned = pinned.concat(custom).some(function(p) { return dockWindow.matches(tl, p.matchers) })
        if (!isPinned) {
          var aid = (tl.appId || "app").toLowerCase()
          if (!seenAppIds[aid]) {
            seenAppIds[aid] = true
            unpinned.push({
              id: "running_" + aid,
              name: tl.title || tl.appId || "Application",
              toplevel: tl,
              isDynamic: true,
              appId: tl.appId || "",
              icon: "",
              exec: "",
              matchers: [tl.appId || ""]
            })
          }
        }
      }

      // Control the dock element count: keep pinned + custom, then cap running apps
      var fixed = pinned.length + custom.length
      var dynamicBudget = Math.max(0, dockWindow.maxDockItems - fixed)
      var runningApps = unpinned.slice(0, dynamicBudget)

      return pinned.concat(custom).concat(runningApps)
    }

    // Total slots used by the full dock row (apps + divider + trash), drives fit-scaling
    readonly property int dockItemCount: dockWindow.getVisibleDockApps ? (dockWindow.getVisibleDockApps().length + 2) : 2

    // Native Wayland Bottom Edge Trigger Strip
    MouseArea {
      id: edgeTrigger
      anchors.left: parent.left
      anchors.right: parent.right
      anchors.bottom: parent.bottom
      height: 12
      hoverEnabled: true
      z: 20
      enabled: dockWindow.isAutohide && !dockWindow.isDockRevealed
      onEntered: {
        dockWindow.isDockRevealed = true
        hideTimer.stop()
        edgeInactivityTimer.restart()
      }
    }

    // Drop Shadow under dock
    Rectangle {
      anchors.horizontalCenter: dockCard.horizontalCenter
      anchors.bottom: dockCard.bottom
      anchors.bottomMargin: -2
      width: dockCard.width + 6
      height: dockCard.height + 4
      radius: dockCard.radius + 2
      color: Qt.rgba(0, 0, 0, 0.35)
      z: 0

      transform: Translate {
        y: (dockWindow.isAutohide && !dockWindow.isDockRevealed) ? (dockCard.height + Math.round(30 * dockWindow.responsiveScale)) : 0
        Behavior on y {
          NumberAnimation { duration: 260; easing.type: Easing.OutCubic }
        }
      }
    }

    // Sequoia Frosted Glass Dock Pill
    Rectangle {
      id: dockCard
      anchors.horizontalCenter: parent.horizontalCenter
      anchors.bottom: parent.bottom
      anchors.bottomMargin: 6
      z: 1

      // Auto-Hide animated sliding translation
      transform: Translate {
        id: dockCardTranslate
        y: (dockWindow.isAutohide && !dockWindow.isDockRevealed) ? (dockCard.height + Math.round(30 * dockWindow.responsiveScale)) : 0
        Behavior on y {
          NumberAnimation { duration: 260; easing.type: Easing.OutCubic }
        }
      }

      implicitWidth: dockLayoutRow.implicitWidth + Math.round(20 * dockWindow.responsiveScale)
      implicitHeight: dockWindow.effectiveIconSize + Math.round(16 * dockWindow.responsiveScale)
      radius: Math.round(18 * dockWindow.responsiveScale)

      // Authentic Sequoia Glassmorphism
      color: dockWindow.isLight ? Qt.rgba(0.98, 0.98, 1.0, dockWindow.dockTransparency / 100.0) : Qt.rgba(0.12, 0.12, 0.16, dockWindow.dockTransparency / 100.0)
      border.color: dockWindow.isLight ? Qt.rgba(0, 0, 0, 0.12) : Qt.rgba(1, 1, 1, 0.22)
      border.width: 1

      // Top Specular Highlight
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
        spacing: Math.round(4 * dockWindow.responsiveScale)

        // 1. Primary & Dynamic App Icons
        Repeater {
          id: appsRepeater
          model: dockWindow.getVisibleDockApps()

          Item {
            id: appItem
            // Fixed slot: layout never reflows during magnification, so the
            // icon wave stays perfectly stable under the cursor (no shaking).
            implicitWidth: dockWindow.effectiveIconSize
            implicitHeight: dockCard.height

            property var appData: modelData
            property bool appRunning: modelData.isDynamic ? true : dockWindow.isRunning(modelData.matchers)
            property bool appFocused: modelData.isDynamic ? (ToplevelManager.activeToplevel === modelData.toplevel) : dockWindow.isFocused(modelData.matchers)
            property real bounceOffset: 0

            // Distance to mouse in dock coordinates (reactive)
            readonly property real itemCenterX: dockLayoutRow.x + appItem.x + appItem.width / 2
            readonly property real distToMouse: Math.abs(dockWindow.currentMouseX - itemCenterX)
            
            // Cosine Wave Magnification
            readonly property real targetScale: {
              if (!dockWindow.isMouseOverDock) return 1.0
              if (distToMouse >= dockWindow.effectRadius) return 1.0
              var ratio = distToMouse / dockWindow.effectRadius
              var factor = Math.cos(ratio * (Math.PI / 2))
              return 1.0 + (dockWindow.maxMagnification - 1.0) * factor * factor
            }

            property real currentScale: 1.0
            Behavior on currentScale {
              NumberAnimation { duration: 70; easing.type: Easing.OutCubic }
            }
            Binding {
              target: appItem
              property: "currentScale"
              value: appItem.targetScale
            }

            function bounce() {
              bounceAnim.restart()
            }

            function launch() {
              bounce()
              if (modelData.isDynamic && modelData.toplevel && typeof modelData.toplevel.activate === "function") {
                modelData.toplevel.activate()
                return
              }
              var match = (ToplevelManager.toplevels && ToplevelManager.toplevels.values) ? ToplevelManager.toplevels.values.find(function(tl) {
                return dockWindow.matches(tl, appData.matchers)
              }) : null

              if (match && typeof match.activate === "function") {
                match.activate()
              } else if (appData && appData.exec) {
                Quickshell.execDetached(["bash", "-c", appData.exec])
              }
            }

            // Authentic 3-Stage macOS Launch Bounce
            SequentialAnimation {
              id: bounceAnim
              running: false
              NumberAnimation { target: appItem; property: "bounceOffset"; to: -24; duration: 140; easing.type: Easing.OutQuad }
              NumberAnimation { target: appItem; property: "bounceOffset"; to: 0; duration: 130; easing.type: Easing.InQuad }
              NumberAnimation { target: appItem; property: "bounceOffset"; to: -14; duration: 110; easing.type: Easing.OutQuad }
              NumberAnimation { target: appItem; property: "bounceOffset"; to: 0; duration: 90; easing.type: Easing.InQuad }
              NumberAnimation { target: appItem; property: "bounceOffset"; to: -5; duration: 70; easing.type: Easing.OutQuad }
              NumberAnimation { target: appItem; property: "bounceOffset"; to: 0; duration: 60; easing.type: Easing.InQuad }
            }

            // Tooltip
            Rectangle {
              id: tooltip
              visible: dockWindow.isMouseOverDock && appItem.distToMouse < Math.round(dockWindow.effectiveIconSize * 0.42)
              anchors.bottom: iconContainer.top
              anchors.bottomMargin: 8
              anchors.horizontalCenter: parent.horizontalCenter
              implicitWidth: tooltipText.implicitWidth + 16
              implicitHeight: 22
              radius: 5
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

            // Icon Container
            Item {
              id: iconContainer
              anchors.horizontalCenter: parent.horizontalCenter
              anchors.bottom: parent.bottom
              anchors.bottomMargin: Math.round(9 * dockWindow.responsiveScale)
              width: dockWindow.effectiveIconSize
              height: dockWindow.effectiveIconSize
              scale: appItem.currentScale
              transformOrigin: Item.Bottom
              z: Math.round(appItem.currentScale * 10)

              transform: Translate {
                y: appItem.bounceOffset
              }

              Image {
                id: appIcon
                anchors.fill: parent
                source: {
                  if (modelData.isDynamic && modelData.appId) {
                    var ip = Quickshell.iconPath(modelData.appId)
                    if (ip) return "file://" + ip
                    return "image://icon/" + modelData.appId
                  }
                  if (modelData.icon) {
                    var p = dockWindow.iconBasePath + modelData.icon
                    if (modelData.icon.indexOf("/") !== -1 || modelData.icon.indexOf("file://") === 0) return modelData.icon
                    return "file://" + p
                  }
                  return ""
                }
                fillMode: Image.PreserveAspectFit
                smooth: true
                mipmap: true
              }
            }

            // Glowing Active Running Indicator Dot
            Rectangle {
              visible: appItem.appRunning
              anchors.horizontalCenter: parent.horizontalCenter
              anchors.bottom: parent.bottom
              anchors.bottomMargin: 2
              width: appItem.appFocused ? 7.5 : 4
              height: 4
              radius: 2
              color: appItem.appFocused ? "#007aff" : (dockWindow.isLight ? Qt.rgba(0, 0, 0, 0.5) : Qt.rgba(1, 1, 1, 0.70))

              Behavior on width {
                NumberAnimation { duration: 150; easing.type: Easing.OutQuad }
              }
            }
          }
        }

        // 2. Vertical Glass Divider Separator
        Rectangle {
          Layout.preferredWidth: 1
          Layout.preferredHeight: Math.round(dockWindow.effectiveIconSize * 0.75)
          Layout.alignment: Qt.AlignVCenter
          color: dockWindow.isLight ? Qt.rgba(0, 0, 0, 0.16) : Qt.rgba(1, 1, 1, 0.20)
        }

        // 3. Special App: Trash Can
Item {
            id: trashItem
            // Fixed slot (same stability principle as app items above)
            implicitWidth: dockWindow.effectiveIconSize
            implicitHeight: dockCard.height

          property real bounceOffset: 0
          readonly property real itemCenterX: dockLayoutRow.x + trashItem.x + trashItem.width / 2
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
            NumberAnimation { duration: 70; easing.type: Easing.OutCubic }
          }
          Binding {
            target: trashItem
            property: "currentScale"
            value: trashItem.targetScale
          }

          function bounce() {
            trashBounceAnim.restart()
          }

          function launch() {
            bounce()
            Quickshell.execDetached(["bash", "-c", "nautilus trash:/// || thunar trash:/// || pcmanfm trash:/// || dolphin trash:///"])
          }

          SequentialAnimation {
            id: trashBounceAnim
            running: false
            NumberAnimation { target: trashItem; property: "bounceOffset"; to: -22; duration: 140; easing.type: Easing.OutQuad }
            NumberAnimation { target: trashItem; property: "bounceOffset"; to: 0; duration: 130; easing.type: Easing.InQuad }
            NumberAnimation { target: trashItem; property: "bounceOffset"; to: -10; duration: 100; easing.type: Easing.OutQuad }
            NumberAnimation { target: trashItem; property: "bounceOffset"; to: 0; duration: 80; easing.type: Easing.InQuad }
          }

          // Tooltip
          Rectangle {
            visible: dockWindow.isMouseOverDock && trashItem.distToMouse < Math.round(dockWindow.effectiveIconSize * 0.42)
            anchors.bottom: trashContainer.top
            anchors.bottomMargin: 8
            anchors.horizontalCenter: parent.horizontalCenter
            implicitWidth: trashText.implicitWidth + 16
            implicitHeight: 22
            radius: 5
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
            anchors.bottomMargin: Math.round(9 * dockWindow.responsiveScale)
            width: dockWindow.effectiveIconSize
            height: dockWindow.effectiveIconSize
            scale: trashItem.currentScale
            transformOrigin: Item.Bottom
            z: Math.round(trashItem.currentScale * 10)

            transform: Translate {
              y: trashItem.bounceOffset
            }

            Image {
              anchors.fill: parent
              source: "file://" + dockWindow.iconBasePath + "trash.svg"
              fillMode: Image.PreserveAspectFit
              smooth: true
              mipmap: true
            }
          }
        }
      }

      // Unified MouseArea across dock for continuous wave tracking & click handling
      MouseArea {
        id: dockMouseArea
        anchors.left: parent.left
        anchors.right: parent.right
        anchors.bottom: parent.bottom
        anchors.top: parent.top
        anchors.topMargin: -Math.round(dockWindow.effectiveIconSize * 0.75)
        hoverEnabled: true
        acceptedButtons: Qt.LeftButton | Qt.RightButton
        cursorShape: Qt.PointingHandCursor

        onEntered: {
          dockWindow.isMouseOverDock = true
          dockWindow.isDockRevealed = true
          edgeInactivityTimer.stop()
          hideTimer.stop()
        }

        onExited: {
          dockWindow.isMouseOverDock = false
          if (dockWindow.isAutohide) {
            hideTimer.restart()
          }
        }

        onPositionChanged: function(mouse) {
          dockWindow.currentMouseX = mouse.x
        }

        onClicked: function(mouse) {
          var mx = mouse.x
          for (var i = 0; i < appsRepeater.count; i++) {
            var item = appsRepeater.itemAt(i)
            if (item) {
              var leftX = dockLayoutRow.x + item.x
              if (mx >= leftX && mx <= (leftX + item.width)) {
                item.launch()
                return
              }
            }
          }

          var trashLeft = dockLayoutRow.x + trashItem.x
          if (mx >= trashLeft && mx <= (trashLeft + trashItem.width)) {
            trashItem.launch()
          }
        }
      }
    }
  }
}

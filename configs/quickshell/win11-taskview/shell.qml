import Quickshell
import Quickshell.Wayland
import Quickshell.Hyprland
import Quickshell.Io
import Quickshell.Widgets
import QtQuick
import QtQuick.Layouts
import QtQuick.Controls

ShellRoot {
  id: shellRoot

  PanelWindow {
    id: taskViewWindow
    screen: Quickshell.screens[0]

    anchors {
      top: true
      bottom: true
      left: true
      right: true
    }

    WlrLayershell.layer: WlrLayer.Overlay
    WlrLayershell.namespace: "win11-taskview"
    WlrLayershell.keyboardFocus: WlrKeyboardFocus.Exclusive
    exclusiveZone: 0
    color: "transparent"

    property string homeDir: Quickshell.env("HOME")
    property string pluginDir: Quickshell.env("OMARCHY_PLUGIN_DIR") || (taskViewWindow.homeDir + "/.config/omarchy/plugins/omarchy-undercover")
    property bool isDark: true
    property string searchQuery: ""
    property bool filterAllDesktops: false
    property int selectedDesktopId: 1
    property int focusedWindowIndex: 0
    property var contextMenuTarget: null
    property bool showContextMenu: false
    property point contextMenuPos: Qt.point(0, 0)

    // Live Wayland Toplevel handles mapping for ScreencopyView
    property var handleByAddress: ({})

    function buildHandles() {
      var map = {}
      var tls = (ToplevelManager && ToplevelManager.toplevels) ? ToplevelManager.toplevels.values : []
      for (var i = 0; i < tls.length; i++) {
        var t = tls[i]
        var h = t.HyprlandToplevel
        if (h) {
          if (!t._boundAddress) {
            t._boundAddress = true
            h.addressChanged.connect(taskViewWindow.buildHandles)
          }
          var addr = String(h.address || "").toLowerCase().trim()
          if (addr && addr !== "0") {
            map["0x" + addr] = t
            map[addr] = t
          }
        }
      }
      taskViewWindow.handleByAddress = map
    }

    Connections {
      target: (ToplevelManager && ToplevelManager.toplevels) ? ToplevelManager.toplevels : null
      function onValuesChanged() { taskViewWindow.buildHandles() }
    }

    Component.onCompleted: {
      taskViewWindow.buildHandles()
      hyprStateProc.running = true
    }

    function closeTaskView() {
      taskViewWindow.visible = false
      var pidFile = (Quickshell.env("XDG_RUNTIME_DIR") || "/tmp") + "/omarchy-win11-taskview.pid"
      Quickshell.execDetached(["rm", "-f", pidFile])
      Quickshell.execDetached(["kill", String(Quickshell.processId)])
    }

    function shellQuote(val) {
      return "'" + String(val || "").replace(/'/g, "'\\''") + "'"
    }

    function focusClient(client) {
      if (!client || !client.address) return
      var rawAddr = String(client.address).trim()
      var wsId = (client.workspace && client.workspace.id) ? parseInt(client.workspace.id) : 1
      var cmd = "hyprctl dispatch workspace " + wsId + " 2>/dev/null; hyprctl dispatch focuswindow " + taskViewWindow.shellQuote("address:" + rawAddr) + " 2>/dev/null"
      Quickshell.execDetached(["bash", "-c", cmd])
      taskViewWindow.closeTaskView()
    }

    function closeClient(client) {
      if (!client || !client.address) return
      var rawAddr = String(client.address).trim()
      var cmd = "hyprctl dispatch closewindow " + taskViewWindow.shellQuote("address:" + rawAddr) + " 2>/dev/null"
      Quickshell.execDetached(["bash", "-c", cmd])
      // Optimistically remove client from view
      var nextClients = []
      for (var i = 0; i < taskViewWindow.hyprClients.length; i++) {
        if (taskViewWindow.hyprClients[i].address !== rawAddr) {
          nextClients.push(taskViewWindow.hyprClients[i])
        }
      }
      taskViewWindow.hyprClients = nextClients
      refreshTimer.restart()
    }

    function moveClientToWorkspace(client, wsId) {
      if (!client || !client.address) return
      var rawAddr = String(client.address).trim()
      var cmd = "hyprctl dispatch movetoworkspace " + wsId + ",address:" + rawAddr
      Quickshell.execDetached(["bash", "-c", cmd])
      taskViewWindow.showContextMenu = false
      refreshTimer.restart()
    }

    function toggleFloating(client) {
      if (!client || !client.address) return
      var rawAddr = String(client.address).trim()
      var cmd = "hyprctl dispatch togglefloating address:" + rawAddr
      Quickshell.execDetached(["bash", "-c", cmd])
      taskViewWindow.showContextMenu = false
      refreshTimer.restart()
    }

    function toggleFullscreen(client) {
      if (!client || !client.address) return
      var rawAddr = String(client.address).trim()
      var cmd = "hyprctl dispatch focuswindow address:" + rawAddr + "; hyprctl dispatch fullscreen 1"
      Quickshell.execDetached(["bash", "-c", cmd])
      taskViewWindow.showContextMenu = false
      taskViewWindow.closeTaskView()
    }

    function switchToWorkspace(wsId) {
      taskViewWindow.selectedDesktopId = wsId
      var cmd = "hyprctl dispatch workspace " + wsId
      Quickshell.execDetached(["bash", "-c", cmd])
      refreshTimer.restart()
    }

    function createNewDesktop() {
      var maxWs = 1
      for (var i = 0; i < taskViewWindow.workspaceList.length; i++) {
        if (taskViewWindow.workspaceList[i] > maxWs) maxWs = taskViewWindow.workspaceList[i]
      }
      var nextWs = maxWs + 1
      taskViewWindow.switchToWorkspace(nextWs)
    }

    function closeDesktop(wsId) {
      var cls = taskViewWindow.hyprClients.filter(function(c) {
        return c && c.workspace && c.workspace.id === wsId
      })
      var targetWs = (wsId > 1) ? (wsId - 1) : 1
      for (var i = 0; i < cls.length; i++) {
        if (cls[i] && cls[i].address) {
          Quickshell.execDetached(["hyprctl", "dispatch", "movetoworkspacesilent", targetWs + ",address:" + cls[i].address])
        }
      }
      taskViewWindow.switchToWorkspace(targetWs)
      refreshTimer.restart()
    }

    function resolveAppIcon(client) {
      if (!client) return ""
      var cls = (client.class || client.initialClass || "").toLowerCase().trim()
      var candidates = [
        cls,
        cls.replace(/[\s_-]+/g, ""),
        cls.split(/[\s_-]+/)[0]
      ]
      for (var i = 0; i < candidates.length; i++) {
        var p = Quickshell.iconPath(candidates[i], true)
        if (p && p.length > 0) return p
      }
      return Quickshell.iconPath("application-x-executable", true) || ""
    }

    // Hyprland State Tracking
    property var workspaceList: [1, 2, 3, 4]
    property int activeWorkspaceId: 1
    property var hyprClients: []
    property var hyprActiveWindow: ({})

    Process {
      id: hyprStateProc
      command: [
        "bash", "-c",
        "hyprctl --batch 'j/activeworkspace ; j/workspaces ; j/clients ; j/activewindow' 2>/dev/null | jq -s -c '{actWs: (.[0] // {}), allWs: (.[1] // []), cls: (.[2] // []), actWin: (.[3] // {})}'"
      ]
      running: true
      stdout: SplitParser {
        onRead: function(line) {
          if (!line) return
          try {
            var data = JSON.parse(line.trim())
            if (data.actWs && data.actWs.id) {
              taskViewWindow.activeWorkspaceId = data.actWs.id
              if (taskViewWindow.selectedDesktopId === 1 && data.actWs.id > 1 && !taskViewWindow.filterAllDesktops) {
                taskViewWindow.selectedDesktopId = data.actWs.id
              }
            }
            if (Array.isArray(data.allWs)) {
              var ids = data.allWs.map(function(w) { return w.id }).filter(function(id) { return id > 0 && id <= 10 })
              ids.sort(function(a, b) { return a - b })
              if (ids.indexOf(taskViewWindow.activeWorkspaceId) === -1 && taskViewWindow.activeWorkspaceId > 0) {
                ids.push(taskViewWindow.activeWorkspaceId)
                ids.sort(function(a, b) { return a - b })
              }
              if (ids.length === 0) ids = [1]
              taskViewWindow.workspaceList = ids
            }
            if (Array.isArray(data.cls)) {
              taskViewWindow.hyprClients = data.cls.filter(function(c) { return c && c.mapped && !c.hidden })
            }
            if (data.actWin && data.actWin.address) {
              taskViewWindow.hyprActiveWindow = data.actWin
            }
          } catch(e) {}
        }
      }
    }

    Timer {
      id: refreshTimer
      interval: 100
      running: false
      repeat: false
      onTriggered: {
        if (!hyprStateProc.running) hyprStateProc.running = true
      }
    }

    Process {
      id: socketListener
      command: [
        "bash", "-c",
        "sock=\"$XDG_RUNTIME_DIR/hypr/$HYPRLAND_INSTANCE_SIGNATURE/.socket2.sock\"; if [ -S \"$sock\" ]; then exec socat -u UNIX-CONNECT:\"$sock\" -; fi"
      ]
      running: true
      stdout: SplitParser {
        onRead: function(line) {
          var l = String(line)
          if (l.indexOf("activewindow>>") === 0 ||
              l.indexOf("openwindow>>") === 0 ||
              l.indexOf("closewindow>>") === 0 ||
              l.indexOf("workspace>>") === 0) {
            refreshTimer.restart()
          }
        }
      }
    }

    // Filtered Windows for Grid
    readonly property var visibleClients: {
      var list = taskViewWindow.hyprClients || []
      var q = taskViewWindow.searchQuery.toLowerCase().trim()
      var targetWs = taskViewWindow.selectedDesktopId

      return list.filter(function(c) {
        if (!c) return false
        if (!taskViewWindow.filterAllDesktops) {
          var cWs = (c.workspace && c.workspace.id) ? c.workspace.id : 1
          if (cWs !== targetWs) return false
        }
        if (q.length > 0) {
          var title = String(c.title || "").toLowerCase()
          var cls = String(c.class || c.initialClass || "").toLowerCase()
          if (title.indexOf(q) === -1 && cls.indexOf(q) === -1) return false
        }
        return true
      })
    }

    // Keyboard Shortcuts
    Shortcut {
      sequence: "Escape"
      onActivated: {
        if (taskViewWindow.showContextMenu) {
          taskViewWindow.showContextMenu = false
        } else {
          taskViewWindow.closeTaskView()
        }
      }
    }

    Shortcut {
      sequence: "Return"
      onActivated: {
        if (taskViewWindow.visibleClients.length > 0) {
          var idx = Math.max(0, Math.min(taskViewWindow.focusedWindowIndex, taskViewWindow.visibleClients.length - 1))
          taskViewWindow.focusClient(taskViewWindow.visibleClients[idx])
        }
      }
    }

    Shortcut {
      sequence: "Left"
      onActivated: {
        if (taskViewWindow.focusedWindowIndex > 0) taskViewWindow.focusedWindowIndex--
      }
    }

    Shortcut {
      sequence: "Right"
      onActivated: {
        if (taskViewWindow.focusedWindowIndex < taskViewWindow.visibleClients.length - 1) taskViewWindow.focusedWindowIndex++
      }
    }

    Shortcut {
      sequence: "Delete"
      onActivated: {
        if (taskViewWindow.visibleClients.length > 0) {
          var idx = Math.max(0, Math.min(taskViewWindow.focusedWindowIndex, taskViewWindow.visibleClients.length - 1))
          taskViewWindow.closeClient(taskViewWindow.visibleClients[idx])
        }
      }
    }

    // Fullscreen Backdrop (Windows 11 Acrylic Blur / Mica Glass)
    Rectangle {
      id: backdrop
      anchors.fill: parent
      color: Qt.rgba(0.06, 0.07, 0.09, 0.88)

      MouseArea {
        anchors.fill: parent
        onClicked: {
          if (taskViewWindow.showContextMenu) {
            taskViewWindow.showContextMenu = false
          } else {
            taskViewWindow.closeTaskView()
          }
        }
      }

      // Subtle decorative gradient
      Rectangle {
        anchors.fill: parent
        gradient: Gradient {
          GradientStop { position: 0.0; color: Qt.rgba(0.0, 0.35, 0.65, 0.08) }
          GradientStop { position: 0.4; color: Qt.rgba(0.0, 0.0, 0.0, 0.0) }
          GradientStop { position: 1.0; color: Qt.rgba(0.0, 0.0, 0.0, 0.4) }
        }
      }

      // Main Content Container
      ColumnLayout {
        anchors.fill: parent
        anchors.margins: 28
        spacing: 16

        // 1. Top Navigation & Search Bar
        RowLayout {
          Layout.fillWidth: true
          Layout.preferredHeight: 46
          spacing: 16

          // Windows 11 Task View Brand Icon & Title
          RowLayout {
            spacing: 10
            Rectangle {
              width: 34
              height: 34
              radius: 6
              color: Qt.rgba(1, 1, 1, 0.08)
              border.color: Qt.rgba(1, 1, 1, 0.15)
              border.width: 1

              Item {
                anchors.centerIn: parent
                width: 20
                height: 20

                Rectangle {
                  x: 0; y: 0
                  width: 14; height: 14
                  radius: 2
                  color: "transparent"
                  border.width: 1.6
                  border.color: Qt.rgba(1, 1, 1, 0.85)
                }
                Rectangle {
                  x: 6; y: 6
                  width: 14; height: 14
                  radius: 2
                  color: Qt.rgba(0, 0.47, 0.83, 0.4)
                  border.width: 1.6
                  border.color: "#60cdff"
                }
              }
            }

            ColumnLayout {
              spacing: 0
              Text {
                text: "Task View"
                font.family: "Segoe UI"
                font.pixelSize: 17
                font.bold: true
                color: "#ffffff"
              }
              Text {
                text: "Desktop " + taskViewWindow.selectedDesktopId + " · " + taskViewWindow.visibleClients.length + " open windows"
                font.family: "Segoe UI"
                font.pixelSize: 11
                color: Qt.rgba(1, 1, 1, 0.6)
              }
            }
          }

          Item { Layout.fillWidth: true }

          // Search / Filter Input
          Rectangle {
            Layout.preferredWidth: 360
            Layout.preferredHeight: 38
            radius: 6
            color: searchInput.activeFocus ? Qt.rgba(0.12, 0.13, 0.17, 0.98) : Qt.rgba(1, 1, 1, 0.08)
            border.color: searchInput.activeFocus ? "#60cdff" : Qt.rgba(1, 1, 1, 0.15)
            border.width: searchInput.activeFocus ? 2 : 1

            RowLayout {
              anchors.fill: parent
              anchors.leftMargin: 12
              anchors.rightMargin: 10
              spacing: 8

              Text {
                text: "🔍"
                font.pixelSize: 13
                color: Qt.rgba(1, 1, 1, 0.6)
              }

              TextInput {
                id: searchInput
                Layout.fillWidth: true
                color: "#ffffff"
                font.family: "Segoe UI"
                font.pixelSize: 13
                selectByMouse: true
                clip: true
                onTextChanged: {
                  taskViewWindow.searchQuery = text
                  taskViewWindow.focusedWindowIndex = 0
                }

                Text {
                  anchors.fill: parent
                  visible: !searchInput.text && !searchInput.activeFocus
                  text: "Search open windows... (Type to filter)"
                  color: Qt.rgba(1, 1, 1, 0.45)
                  font.family: "Segoe UI"
                  font.pixelSize: 13
                }
              }

              Rectangle {
                visible: searchInput.text.length > 0
                width: 18; height: 18
                radius: 9
                color: clearMouse.containsMouse ? Qt.rgba(1, 1, 1, 0.25) : Qt.rgba(1, 1, 1, 0.12)
                Text {
                  anchors.centerIn: parent
                  text: "✕"
                  font.pixelSize: 9
                  color: "#ffffff"
                }
                MouseArea {
                  id: clearMouse
                  anchors.fill: parent
                  hoverEnabled: true
                  onClicked: {
                    searchInput.text = ""
                    searchInput.forceActiveFocus()
                  }
                }
              }
            }
          }

          // Filter Toggle: Current Desktop vs All Desktops
          Rectangle {
            Layout.preferredHeight: 36
            Layout.preferredWidth: filterRow.implicitWidth + 8
            radius: 6
            color: Qt.rgba(1, 1, 1, 0.08)
            border.color: Qt.rgba(1, 1, 1, 0.12)
            border.width: 1

            RowLayout {
              id: filterRow
              anchors.centerIn: parent
              spacing: 4

              Rectangle {
                implicitWidth: 110
                implicitHeight: 28
                radius: 4
                color: !taskViewWindow.filterAllDesktops ? "#0078d4" : "transparent"
                Text {
                  anchors.centerIn: parent
                  text: "Current Desktop"
                  font.family: "Segoe UI"
                  font.pixelSize: 11
                  font.bold: !taskViewWindow.filterAllDesktops
                  color: "#ffffff"
                }
                MouseArea {
                  anchors.fill: parent
                  onClicked: taskViewWindow.filterAllDesktops = false
                }
              }

              Rectangle {
                implicitWidth: 90
                implicitHeight: 28
                radius: 4
                color: taskViewWindow.filterAllDesktops ? "#0078d4" : "transparent"
                Text {
                  anchors.centerIn: parent
                  text: "All Desktops"
                  font.family: "Segoe UI"
                  font.pixelSize: 11
                  font.bold: taskViewWindow.filterAllDesktops
                  color: "#ffffff"
                }
                MouseArea {
                  anchors.fill: parent
                  onClicked: taskViewWindow.filterAllDesktops = true
                }
              }
            }
          }

          // Close Overlay Button
          Rectangle {
            Layout.preferredWidth: 36
            Layout.preferredHeight: 36
            radius: 18
            color: closeTopMouse.containsMouse ? "#c42b1c" : Qt.rgba(1, 1, 1, 0.10)
            border.color: Qt.rgba(1, 1, 1, 0.15)
            border.width: 1

            Text {
              anchors.centerIn: parent
              text: "✕"
              font.pixelSize: 14
              color: "#ffffff"
            }

            MouseArea {
              id: closeTopMouse
              anchors.fill: parent
              hoverEnabled: true
              cursorShape: Qt.PointingHandCursor
              onClicked: taskViewWindow.closeTaskView()
            }
          }
        }

        // 2. Open Windows Grid Area
        Item {
          Layout.fillWidth: true
          Layout.fillHeight: true

          // Empty state when no windows match
          ColumnLayout {
            anchors.centerIn: parent
            visible: taskViewWindow.visibleClients.length === 0
            spacing: 12

            Text {
              Layout.alignment: Qt.AlignHCenter
              text: taskViewWindow.searchQuery.length > 0 ? "🔍" : "🪟"
              font.pixelSize: 48
            }
            Text {
              Layout.alignment: Qt.AlignHCenter
              text: taskViewWindow.searchQuery.length > 0 ? "No open windows match \"" + taskViewWindow.searchQuery + "\"" : "No open windows on Desktop " + taskViewWindow.selectedDesktopId
              font.family: "Segoe UI"
              font.pixelSize: 16
              font.bold: true
              color: "#ffffff"
            }
            Text {
              Layout.alignment: Qt.AlignHCenter
              text: taskViewWindow.searchQuery.length > 0 ? "Try searching for a different application name or window title." : "Open an application or switch to another desktop below."
              font.family: "Segoe UI"
              font.pixelSize: 12
              color: Qt.rgba(1, 1, 1, 0.5)
            }
          }

          // Responsive Windows Grid View
          ScrollView {
            id: gridScroll
            anchors.fill: parent
            clip: true
            ScrollBar.horizontal.policy: ScrollBar.AlwaysOff
            ScrollBar.vertical.policy: taskViewWindow.visibleClients.length > 8 ? ScrollBar.AlwaysOn : ScrollBar.AsNeeded

            Flow {
              width: gridScroll.width
              spacing: 20
              padding: 10

              Repeater {
                model: taskViewWindow.visibleClients

                // Interactive Window Card
                Rectangle {
                  id: winCard
                  property var winClient: modelData
                  property bool isCurrentFocused: taskViewWindow.hyprActiveWindow && taskViewWindow.hyprActiveWindow.address === winClient.address
                  property bool isSelected: index === taskViewWindow.focusedWindowIndex
                  property var winHandle: {
                    var a = String(winClient.address || "").toLowerCase().trim()
                    return taskViewWindow.handleByAddress[a] || taskViewWindow.handleByAddress["0x" + a] || null
                  }

                  width: {
                    var totalW = gridScroll.width - 40
                    var count = taskViewWindow.visibleClients.length
                    if (count <= 2) return Math.min(520, Math.floor(totalW / 2) - 20)
                    if (count <= 4) return Math.min(460, Math.floor(totalW / 2) - 20)
                    if (count <= 6) return Math.min(380, Math.floor(totalW / 3) - 20)
                    return Math.min(350, Math.floor(totalW / 4) - 20)
                  }
                  height: Math.round(width * 0.65)
                  radius: 8

                  color: cardMouse.containsMouse
                         ? Qt.rgba(0.18, 0.20, 0.26, 0.95)
                         : (isCurrentFocused ? Qt.rgba(0.14, 0.16, 0.22, 0.95) : Qt.rgba(0.10, 0.11, 0.15, 0.92))
                  border.color: isCurrentFocused || isSelected
                                ? "#60cdff"
                                : (cardMouse.containsMouse ? Qt.rgba(1, 1, 1, 0.35) : Qt.rgba(1, 1, 1, 0.14))
                  border.width: (isCurrentFocused || isSelected) ? 2 : 1

                  scale: cardMouse.containsMouse ? 1.02 : 1.0
                  Behavior on scale {
                    NumberAnimation { duration: 120; easing.type: Easing.OutQuad }
                  }

                  ColumnLayout {
                    anchors.fill: parent
                    anchors.margins: 8
                    spacing: 6

                    // Card Title Bar
                    RowLayout {
                      Layout.fillWidth: true
                      Layout.preferredHeight: 24
                      spacing: 8

                      Image {
                        Layout.preferredWidth: 16
                        Layout.preferredHeight: 16
                        sourceSize: Qt.size(16, 16)
                        source: taskViewWindow.resolveAppIcon(winClient)
                        fillMode: Image.PreserveAspectFit
                      }

                      Text {
                        text: winClient ? (winClient.title || winClient.class || "Application") : ""
                        font.family: "Segoe UI"
                        font.pixelSize: 11
                        font.bold: isCurrentFocused
                        color: "#ffffff"
                        Layout.fillWidth: true
                        elide: Text.ElideRight
                      }

                      // Workspace Badge (if showing All Desktops)
                      Rectangle {
                        visible: taskViewWindow.filterAllDesktops
                        implicitWidth: wsLabel.implicitWidth + 8
                        implicitHeight: 16
                        radius: 8
                        color: Qt.rgba(1, 1, 1, 0.12)
                        Text {
                          id: wsLabel
                          anchors.centerIn: parent
                          text: "D" + (winClient.workspace ? winClient.workspace.id : 1)
                          font.family: "Segoe UI"
                          font.pixelSize: 9
                          color: "#60cdff"
                        }
                      }

                      // Floating indicator
                      Rectangle {
                        visible: winClient && winClient.floating
                        implicitWidth: 42
                        implicitHeight: 16
                        radius: 4
                        color: Qt.rgba(1, 1, 1, 0.10)
                        Text {
                          anchors.centerIn: parent
                          text: "Float"
                          font.family: "Segoe UI"
                          font.pixelSize: 9
                          color: Qt.rgba(1, 1, 1, 0.7)
                        }
                      }

                      // Close Window Button (Windows 11 style)
                      Rectangle {
                        id: closeWinBtn
                        implicitWidth: 20
                        implicitHeight: 20
                        radius: 3
                        color: closeWinMouse.containsMouse ? "#c42b1c" : Qt.rgba(1, 1, 1, 0.08)

                        Text {
                          anchors.centerIn: parent
                          text: "✕"
                          font.pixelSize: 10
                          font.bold: true
                          color: "#ffffff"
                        }

                        MouseArea {
                          id: closeWinMouse
                          anchors.fill: parent
                          hoverEnabled: true
                          cursorShape: Qt.PointingHandCursor
                          onClicked: {
                            taskViewWindow.closeClient(winClient)
                          }
                        }
                      }
                    }

                    // Window Preview Thumbnail Area
                    Rectangle {
                      id: thumbBox
                      Layout.fillWidth: true
                      Layout.fillHeight: true
                      radius: 6
                      color: Qt.rgba(0.04, 0.05, 0.07, 0.85)
                      clip: true
                      border.color: Qt.rgba(1, 1, 1, 0.08)
                      border.width: 1

                      // Live Wayland ScreencopyView
                      ScreencopyView {
                        id: screencopy
                        anchors.fill: parent
                        captureSource: winHandle
                        live: true
                        visible: winHandle !== null && screencopy.hasContent
                      }

                      // Fallback Graphic when screencopy is not active
                      ColumnLayout {
                        anchors.centerIn: parent
                        visible: !screencopy.visible
                        spacing: 8

                        Image {
                          Layout.alignment: Qt.AlignHCenter
                          Layout.preferredWidth: Math.min(54, Math.max(32, thumbBox.height * 0.45))
                          Layout.preferredHeight: Layout.preferredWidth
                          sourceSize: Qt.size(64, 64)
                          source: taskViewWindow.resolveAppIcon(winClient)
                          fillMode: Image.PreserveAspectFit
                        }

                        Text {
                          Layout.alignment: Qt.AlignHCenter
                          text: winClient ? (winClient.class || winClient.initialClass || "") : ""
                          font.family: "Segoe UI"
                          font.pixelSize: 12
                          font.bold: true
                          color: Qt.rgba(1, 1, 1, 0.75)
                        }
                      }
                    }
                  }

                  // Mouse Handling for Window Card
                  MouseArea {
                    id: cardMouse
                    anchors.fill: parent
                    hoverEnabled: true
                    acceptedButtons: Qt.LeftButton | Qt.RightButton
                    cursorShape: Qt.PointingHandCursor

                    onClicked: function(mouse) {
                      if (mouse.button === Qt.RightButton) {
                        taskViewWindow.contextMenuTarget = winClient
                        var pos = cardMouse.mapToItem(backdrop, mouse.x, mouse.y)
                        taskViewWindow.contextMenuPos = pos
                        taskViewWindow.showContextMenu = true
                      } else {
                        taskViewWindow.focusClient(winClient)
                      }
                    }
                  }
                }
              }
            }
          }
        }

        // 3. Virtual Desktops Bar (Windows 11 Fluent Strip)
        Rectangle {
          Layout.fillWidth: true
          Layout.preferredHeight: 120
          radius: 10
          color: Qt.rgba(0.12, 0.13, 0.17, 0.95)
          border.color: Qt.rgba(1, 1, 1, 0.12)
          border.width: 1

          ColumnLayout {
            anchors.fill: parent
            anchors.margins: 10
            spacing: 8

            RowLayout {
              Layout.fillWidth: true
              Text {
                text: "Desktops"
                font.family: "Segoe UI"
                font.pixelSize: 12
                font.bold: true
                color: Qt.rgba(1, 1, 1, 0.85)
              }
              Item { Layout.fillWidth: true }
              Text {
                text: "Click a desktop to switch · Hover to close"
                font.family: "Segoe UI"
                font.pixelSize: 10
                color: Qt.rgba(1, 1, 1, 0.45)
              }
            }

            // Desktops Scrollable Strip
            Flickable {
              Layout.fillWidth: true
              Layout.fillHeight: true
              contentWidth: deskRow.implicitWidth + 20
              clip: true

              RowLayout {
                id: deskRow
                spacing: 12

                Repeater {
                  model: taskViewWindow.workspaceList

                  // Desktop Card Pill
                  Rectangle {
                    id: deskCard
                    property int wsId: modelData
                    property bool isSelectedWs: wsId === taskViewWindow.selectedDesktopId
                    property bool isActiveWs: wsId === taskViewWindow.activeWorkspaceId
                    property var wsClients: taskViewWindow.hyprClients.filter(function(c) {
                      return c && c.workspace && c.workspace.id === wsId
                    })

                    implicitWidth: 150
                    implicitHeight: 72
                    radius: 6

                    color: deskMouse.containsMouse
                           ? Qt.rgba(1, 1, 1, 0.14)
                           : (isSelectedWs ? Qt.rgba(1, 1, 1, 0.10) : Qt.rgba(0, 0, 0, 0.35))
                    border.color: isSelectedWs ? "#60cdff" : (deskMouse.containsMouse ? Qt.rgba(1, 1, 1, 0.22) : Qt.rgba(1, 1, 1, 0.10))
                    border.width: isSelectedWs ? 2 : 1

                    ColumnLayout {
                      anchors.fill: parent
                      anchors.margins: 6
                      spacing: 4

                      RowLayout {
                        Layout.fillWidth: true
                        spacing: 4

                        Text {
                          text: "Desktop " + wsId
                          font.family: "Segoe UI"
                          font.pixelSize: 11
                          font.bold: isSelectedWs
                          color: "#ffffff"
                          Layout.fillWidth: true
                        }

                        // Close desktop button on hover (if > 1 desktop)
                        Rectangle {
                          visible: deskMouse.containsMouse && taskViewWindow.workspaceList.length > 1
                          implicitWidth: 16
                          implicitHeight: 16
                          radius: 3
                          color: deskCloseM.containsMouse ? "#c42b1c" : Qt.rgba(1, 1, 1, 0.15)

                          Text {
                            anchors.centerIn: parent
                            text: "✕"
                            font.pixelSize: 8
                            color: "#ffffff"
                          }

                          MouseArea {
                            id: deskCloseM
                            anchors.fill: parent
                            hoverEnabled: true
                            onClicked: taskViewWindow.closeDesktop(wsId)
                          }
                        }
                      }

                      // Miniature window count and icons
                      RowLayout {
                        Layout.fillWidth: true
                        Layout.fillHeight: true
                        spacing: 4

                        Repeater {
                          model: deskCard.wsClients.slice(0, 4)
                          Image {
                            Layout.preferredWidth: 16
                            Layout.preferredHeight: 16
                            sourceSize: Qt.size(16, 16)
                            source: taskViewWindow.resolveAppIcon(modelData)
                            fillMode: Image.PreserveAspectFit
                          }
                        }

                        Item { Layout.fillWidth: true }

                        Text {
                          text: deskCard.wsClients.length + " apps"
                          font.family: "Segoe UI"
                          font.pixelSize: 9
                          color: Qt.rgba(1, 1, 1, 0.5)
                        }
                      }

                      // Active desktop bottom blue indicator line
                      Rectangle {
                        Layout.fillWidth: true
                        Layout.preferredHeight: 2
                        radius: 1
                        color: isSelectedWs ? "#60cdff" : "transparent"
                      }
                    }

                    MouseArea {
                      id: deskMouse
                      anchors.fill: parent
                      hoverEnabled: true
                      cursorShape: Qt.PointingHandCursor
                      onClicked: {
                        taskViewWindow.switchToWorkspace(wsId)
                      }
                    }
                  }
                }

                // "+ New desktop" Button (Windows 11 Fluent style)
                Rectangle {
                  implicitWidth: 130
                  implicitHeight: 72
                  radius: 6
                  color: newDeskM.containsMouse ? Qt.rgba(1, 1, 1, 0.14) : Qt.rgba(1, 1, 1, 0.06)
                  border.color: newDeskM.containsMouse ? Qt.rgba(1, 1, 1, 0.3) : Qt.rgba(1, 1, 1, 0.12)
                  border.width: 1

                  ColumnLayout {
                    anchors.centerIn: parent
                    spacing: 4

                    Text {
                      Layout.alignment: Qt.AlignHCenter
                      text: "＋"
                      font.pixelSize: 18
                      font.bold: true
                      color: "#60cdff"
                    }

                    Text {
                      Layout.alignment: Qt.AlignHCenter
                      text: "New desktop"
                      font.family: "Segoe UI"
                      font.pixelSize: 11
                      color: "#ffffff"
                    }
                  }

                  MouseArea {
                    id: newDeskM
                    anchors.fill: parent
                    hoverEnabled: true
                    cursorShape: Qt.PointingHandCursor
                    onClicked: taskViewWindow.createNewDesktop()
                  }
                }
              }
            }
          }
        }
      }

      // Context Menu Popup for Windows
      Rectangle {
        id: winContextMenu
        visible: taskViewWindow.showContextMenu && taskViewWindow.contextMenuTarget !== null
        x: Math.min(backdrop.width - width - 20, Math.max(20, taskViewWindow.contextMenuPos.x))
        y: Math.min(backdrop.height - height - 20, Math.max(20, taskViewWindow.contextMenuPos.y))
        width: 220
        height: menuCol.implicitHeight + 16
        radius: 8
        color: Qt.rgba(0.14, 0.15, 0.19, 0.98)
        border.color: Qt.rgba(1, 1, 1, 0.18)
        border.width: 1
        z: 999

        ColumnLayout {
          id: menuCol
          anchors.fill: parent
          anchors.margins: 8
          spacing: 4

          Text {
            text: taskViewWindow.contextMenuTarget ? (taskViewWindow.contextMenuTarget.title || taskViewWindow.contextMenuTarget.class || "Window") : ""
            font.family: "Segoe UI"
            font.pixelSize: 11
            font.bold: true
            color: "#60cdff"
            Layout.fillWidth: true
            elide: Text.ElideRight
          }

          Rectangle {
            Layout.fillWidth: true
            Layout.preferredHeight: 1
            color: Qt.rgba(1, 1, 1, 0.12)
          }

          // Switch to window
          Rectangle {
            Layout.fillWidth: true
            Layout.preferredHeight: 26
            radius: 4
            color: miFocusM.containsMouse ? Qt.rgba(1, 1, 1, 0.12) : "transparent"
            Text {
              anchors.left: parent.left
              anchors.leftMargin: 8
              anchors.verticalCenter: parent.verticalCenter
              text: "Switch to window"
              font.family: "Segoe UI"
              font.pixelSize: 11
              color: "#ffffff"
            }
            MouseArea {
              id: miFocusM
              anchors.fill: parent
              hoverEnabled: true
              onClicked: {
                taskViewWindow.focusClient(taskViewWindow.contextMenuTarget)
              }
            }
          }

          // Move to Desktop 1
          Rectangle {
            Layout.fillWidth: true
            Layout.preferredHeight: 26
            radius: 4
            color: miMv1.containsMouse ? Qt.rgba(1, 1, 1, 0.12) : "transparent"
            Text {
              anchors.left: parent.left
              anchors.leftMargin: 8
              anchors.verticalCenter: parent.verticalCenter
              text: "Move to Desktop 1"
              font.family: "Segoe UI"
              font.pixelSize: 11
              color: "#ffffff"
            }
            MouseArea {
              id: miMv1
              anchors.fill: parent
              hoverEnabled: true
              onClicked: taskViewWindow.moveClientToWorkspace(taskViewWindow.contextMenuTarget, 1)
            }
          }

          // Move to Desktop 2
          Rectangle {
            Layout.fillWidth: true
            Layout.preferredHeight: 26
            radius: 4
            color: miMv2.containsMouse ? Qt.rgba(1, 1, 1, 0.12) : "transparent"
            Text {
              anchors.left: parent.left
              anchors.leftMargin: 8
              anchors.verticalCenter: parent.verticalCenter
              text: "Move to Desktop 2"
              font.family: "Segoe UI"
              font.pixelSize: 11
              color: "#ffffff"
            }
            MouseArea {
              id: miMv2
              anchors.fill: parent
              hoverEnabled: true
              onClicked: taskViewWindow.moveClientToWorkspace(taskViewWindow.contextMenuTarget, 2)
            }
          }

          // Toggle Floating
          Rectangle {
            Layout.fillWidth: true
            Layout.preferredHeight: 26
            radius: 4
            color: miFloat.containsMouse ? Qt.rgba(1, 1, 1, 0.12) : "transparent"
            Text {
              anchors.left: parent.left
              anchors.leftMargin: 8
              anchors.verticalCenter: parent.verticalCenter
              text: taskViewWindow.contextMenuTarget && taskViewWindow.contextMenuTarget.floating ? "Tile window" : "Float window"
              font.family: "Segoe UI"
              font.pixelSize: 11
              color: "#ffffff"
            }
            MouseArea {
              id: miFloat
              anchors.fill: parent
              hoverEnabled: true
              onClicked: taskViewWindow.toggleFloating(taskViewWindow.contextMenuTarget)
            }
          }

          // Toggle Fullscreen
          Rectangle {
            Layout.fillWidth: true
            Layout.preferredHeight: 26
            radius: 4
            color: miFs.containsMouse ? Qt.rgba(1, 1, 1, 0.12) : "transparent"
            Text {
              anchors.left: parent.left
              anchors.leftMargin: 8
              anchors.verticalCenter: parent.verticalCenter
              text: "Maximize window"
              font.family: "Segoe UI"
              font.pixelSize: 11
              color: "#ffffff"
            }
            MouseArea {
              id: miFs
              anchors.fill: parent
              hoverEnabled: true
              onClicked: taskViewWindow.toggleFullscreen(taskViewWindow.contextMenuTarget)
            }
          }

          Rectangle {
            Layout.fillWidth: true
            Layout.preferredHeight: 1
            color: Qt.rgba(1, 1, 1, 0.12)
          }

          // Close window
          Rectangle {
            Layout.fillWidth: true
            Layout.preferredHeight: 26
            radius: 4
            color: miClose.containsMouse ? "#c42b1c" : "transparent"
            Text {
              anchors.left: parent.left
              anchors.leftMargin: 8
              anchors.verticalCenter: parent.verticalCenter
              text: "Close window"
              font.family: "Segoe UI"
              font.pixelSize: 11
              color: "#ffffff"
            }
            MouseArea {
              id: miClose
              anchors.fill: parent
              hoverEnabled: true
              onClicked: {
                taskViewWindow.closeClient(taskViewWindow.contextMenuTarget)
                taskViewWindow.showContextMenu = false
              }
            }
          }
        }
      }
    }
  }
}

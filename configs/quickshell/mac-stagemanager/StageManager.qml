import QtQuick
import Quickshell
import Quickshell.Hyprland
import Quickshell.Wayland
import Quickshell.Io

Item {
  id: root

  property var shell: null
  property var manifest: null
  property bool opened: false
  property bool revealed: false
  property bool focusPrimed: false
  property var targetScreen: Quickshell.screens.length > 0 ? Quickshell.screens[0] : null
  property int targetMonitorId: -1
  property string targetMonitorName: ""
  property var groups: []
  property var flatWindows: []
  property string selectedAddress: ""

  readonly property color background: Color.menu.background
  readonly property color foreground: Color.menu.text
  readonly property color borderColor: Color.menu.border
  readonly property color selectedBackground: Color.menu.selectedBackground
  readonly property color selectedText: Color.menu.selectedText
  readonly property var activeWindowBorderSpec: Border.hyprlandActiveSpec(borderColor, Style.space(2))
  readonly property string fontFamily: Style.font.menuFamily
  readonly property real screenWidth: targetScreen ? targetScreen.width : 1280
  readonly property int railWidth: Math.round(Math.max(Style.space(196), Math.min(Style.space(218), screenWidth * 0.175)))
  readonly property int panelGap: Style.gapsOut
  readonly property int previewHeight: Math.round((railWidth - Style.space(20)) * 0.58)
  readonly property real cardRadius: Style.cornerRadius * 1.65

  function screenByName(name) {
    var screens = Quickshell.screens || []
    for (var i = 0; i < screens.length; i++) {
      if (String(screens[i].name) === String(name)) return screens[i]
    }
    return screens.length > 0 ? screens[0] : null
  }

  function normalize(value) {
    return String(value || "").trim().toLowerCase()
  }

  function friendlyName(value) {
    var text = String(value || "Application")
      .replace(/^org\./i, "")
      .replace(/^com\./i, "")
      .replace(/[._-]+/g, " ")
      .trim()
    if (text === "") return "Application"
    return text.split(/\s+/).map(function(word) {
      return word.charAt(0).toUpperCase() + word.slice(1)
    }).join(" ")
  }

  function desktopEntryFor(values) {
    var applications = DesktopEntries.applications.values || []
    var candidates = []
    for (var i = 0; i < values.length; i++) {
      var candidate = normalize(values[i])
      if (candidate !== "" && candidates.indexOf(candidate) === -1) candidates.push(candidate)
    }

    for (var c = 0; c < candidates.length; c++) {
      var exact = DesktopEntries.byId(candidates[c])
      if (exact) return exact
    }

    for (var a = 0; a < applications.length; a++) {
      var entry = applications[a]
      var entryId = normalize(entry.id)
      var startupClass = normalize(entry.startupClass)
      for (var k = 0; k < candidates.length; k++) {
        var needle = candidates[k]
        if (entryId === needle || startupClass === needle || entryId === needle + ".desktop") return entry
      }
    }

    for (var h = 0; h < candidates.length; h++) {
      var heuristic = DesktopEntries.heuristicLookup(candidates[h])
      if (heuristic) return heuristic
    }
    return null
  }

  function iconSource(icon) {
    var name = String(icon || "")
    if (name.indexOf("file://") === 0 || name.indexOf("image://") === 0) return name
    if (name.charAt(0) === "/") return "file://" + name
    var resolved = name !== "" ? Quickshell.iconPath(name, true) : ""
    if (resolved !== "") {
      if (resolved.charAt(0) === "/") return "file://" + resolved
      return resolved
    }
    var fallback = Quickshell.iconPath("application-x-executable", true)
    if (fallback && fallback.charAt(0) === "/") return "file://" + fallback
    return fallback || ("image://icon/" + (name || "application-x-executable"))
  }

  function rebuild() {
    var values = Hyprland.toplevels.values || []
    var buckets = ({})
    var activeAddress = Hyprland.activeToplevel ? String(Hyprland.activeToplevel.address || "") : ""

    for (var i = 0; i < values.length; i++) {
      var toplevel = values[i]
      var ipc = toplevel.lastIpcObject || ({})
      var monitorId = toplevel.monitor ? Number(toplevel.monitor.id) : Number(ipc.monitor)
      var workspaceId = toplevel.workspace ? Number(toplevel.workspace.id)
        : Number(ipc.workspace && ipc.workspace.id)
      var mapped = ipc.mapped === undefined ? true : ipc.mapped === true

      // Positive ids are normal workspaces. Layer surfaces, special workspaces
      // and shell-owned windows never become Stage Manager entries.
      if (!mapped || workspaceId <= 0 || monitorId !== root.targetMonitorId) continue

      var initialClass = String(ipc.initialClass || "")
      var currentClass = String(ipc.class || "")
      var appId = toplevel.wayland ? String(toplevel.wayland.appId || "") : ""
      var key = normalize(initialClass || currentClass || appId || toplevel.address)
      if (!buckets[key]) {
        var entry = root.desktopEntryFor([initialClass, currentClass, appId])
        buckets[key] = {
          key: key,
          name: entry ? String(entry.name || root.friendlyName(initialClass || currentClass || appId))
            : root.friendlyName(initialClass || currentClass || appId),
          icon: root.iconSource(entry ? entry.icon : (appId || currentClass || initialClass)),
          windows: [],
          recency: 1000000
        }
      }

      var history = Number(ipc.focusHistoryID)
      if (!isFinite(history) || history < 0) history = 1000000
      var record = {
        address: String(toplevel.address || ipc.address || ""),
        title: String(toplevel.title || ipc.title || buckets[key].name),
        workspaceId: workspaceId,
        workspaceName: String(toplevel.workspace ? toplevel.workspace.name
          : (ipc.workspace && ipc.workspace.name) || workspaceId),
        recency: history,
        active: String(toplevel.address || "") === activeAddress,
        toplevel: toplevel,
        wayland: toplevel.wayland || null,
        icon: buckets[key].icon,
        appName: buckets[key].name
      }
      buckets[key].windows.push(record)
      buckets[key].recency = Math.min(buckets[key].recency, history)
    }

    var nextGroups = []
    for (var key in buckets) {
      buckets[key].windows.sort(function(left, right) { return left.recency - right.recency })
      nextGroups.push(buckets[key])
    }
    nextGroups.sort(function(left, right) { return left.recency - right.recency })

    var nextFlat = []
    for (var g = 0; g < nextGroups.length; g++) {
      for (var w = 0; w < nextGroups[g].windows.length; w++) nextFlat.push(nextGroups[g].windows[w])
    }
    root.groups = nextGroups
    root.flatWindows = nextFlat

    var selectedStillExists = false
    for (var f = 0; f < nextFlat.length; f++) {
      if (nextFlat[f].address === root.selectedAddress) selectedStillExists = true
    }
    if (!selectedStillExists) root.selectedAddress = activeAddress || (nextFlat.length > 0 ? nextFlat[0].address : "")
  }

  function open(payloadJson) {
    var monitor = Hyprland.focusedMonitor
    root.targetMonitorId = monitor ? Number(monitor.id) : 0
    root.targetMonitorName = monitor ? String(monitor.name || "") : ""
    root.targetScreen = root.screenByName(root.targetMonitorName)
    root.selectedAddress = Hyprland.activeToplevel ? String(Hyprland.activeToplevel.address || "") : ""
    root.rebuild()
    root.focusPrimed = false
    root.revealed = false
    root.opened = true
    focusPrimeTimer.restart()
    Qt.callLater(function() {
      root.revealed = true
      keyCatcher.forceActiveFocus()
    })
  }

  function close() {
    focusPrimeTimer.stop()
    root.focusPrimed = false
    root.revealed = false
    root.opened = false
  }

  function toggle() {
    if (root.opened) root.close()
    else root.open("{}")
  }

  function status(arg) {
    return JSON.stringify({
      opened: root.opened,
      monitor: root.targetMonitorName,
      groups: root.groups.length,
      windows: root.flatWindows.length,
      reservedWidth: root.opened ? panel.implicitWidth : 0
    })
  }

  function selectedIndex() {
    for (var i = 0; i < root.flatWindows.length; i++) {
      if (root.flatWindows[i].address === root.selectedAddress) return i
    }
    return -1
  }

  function currentGroupIndex() {
    for (var g = 0; g < root.groups.length; g++) {
      for (var w = 0; w < root.groups[g].windows.length; w++) {
        if (root.groups[g].windows[w].address === root.selectedAddress) return g
      }
    }
    return -1
  }

  function selectGroup(delta) {
    if (root.groups.length === 0) return
    var cur = root.currentGroupIndex()
    if (cur < 0) cur = delta < 0 ? 0 : -1
    var next = (cur + delta + root.groups.length) % root.groups.length
    var grp = root.groups[next]
    if (grp && grp.windows.length > 0) {
      root.selectedAddress = grp.windows[0].address
    }
  }

  function cycleGroupWindow(delta) {
    var curG = root.currentGroupIndex()
    if (curG < 0 || root.groups.length === 0) return
    var grp = root.groups[curG]
    if (!grp || grp.windows.length <= 1) return
    var winIdx = -1
    for (var i = 0; i < grp.windows.length; i++) {
      if (grp.windows[i].address === root.selectedAddress) { winIdx = i; break; }
    }
    if (winIdx < 0) winIdx = 0
    var nextWin = (winIdx + delta + grp.windows.length) % grp.windows.length
    root.selectedAddress = grp.windows[nextWin].address
  }

  function select(delta) {
    if (root.flatWindows.length === 0) return
    var current = root.selectedIndex()
    if (current < 0) current = delta < 0 ? 0 : -1
    var next = (current + delta + root.flatWindows.length) % root.flatWindows.length
    root.selectedAddress = root.flatWindows[next].address
  }

  function revealGroup(item) {
    if (!item || !appFlick) return
    var top = groupsColumn.y + item.y
    var bottom = top + item.height
    if (top < appFlick.contentY) appFlick.contentY = top
    else if (bottom > appFlick.contentY + appFlick.height)
      appFlick.contentY = Math.min(Math.max(0, appFlick.contentHeight - appFlick.height), bottom - appFlick.height)
  }

  function activate(record) {
    if (!record) return
    var wayland = record.wayland
    var address = record.address
    var wsId = record.workspaceId
    root.close()
    if (root.shell && typeof root.shell.hide === "function") {
      root.shell.hide("omarchy-mac-stagemanager")
      root.shell.hide("debba.stage-manager")
    }
    Qt.callLater(function() {
      if (wsId && wsId > 0) {
        Quickshell.execDetached(["hyprctl", "dispatch", "workspace", String(wsId)])
      }
      if (wayland && typeof wayland.activate === "function") {
        wayland.activate()
      } else {
        Quickshell.execDetached(["hyprctl", "dispatch", "focuswindow", "address:" + address])
      }
    })
  }

  function activateSelected() {
    var index = root.selectedIndex()
    if (index >= 0) root.activate(root.flatWindows[index])
  }

  
  IpcHandler {
    target: "omarchy-mac-stagemanager"
    function toggle() { root.toggle() }
    function open() { root.open("{}") }
    function close() { root.close() }
    function status() { return root.status("") }
  }

Timer {
    id: focusPrimeTimer
    interval: 80
    repeat: false
    onTriggered: {
      root.focusPrimed = true
      keyCatcher.forceActiveFocus()
    }
  }

  Timer {
    id: rebuildTimer
    interval: 60
    repeat: false
    onTriggered: if (root.opened) root.rebuild()
  }

  Connections {
    target: Hyprland.toplevels
    function onValuesChanged() { rebuildTimer.restart() }
  }

  Connections {
    target: Hyprland
    function onRawEvent(event) {
      var watched = [
        "openwindow", "closewindow", "movewindow", "movewindowv2",
        "windowtitle", "windowtitlev2", "activewindow", "activewindowv2",
        "workspace", "workspacev2", "focusedmon", "changefloatingmode"
      ]
      if (root.opened && watched.indexOf(event.name) !== -1) rebuildTimer.restart()
    }
  }

  // Clicking a normal application outside the rail dismisses Stage Manager.
  // Unlike a fullscreen MouseArea, this does not cover or block the workspace.
  HyprlandFocusGrab {
    active: root.opened
    windows: panel.visible ? [panel] : []
    onCleared: if (root.opened) root.close()
  }

  PanelWindow {
    id: panel

    visible: root.opened
    screen: root.targetScreen
    color: "transparent"
    implicitWidth: root.railWidth + root.panelGap * 2
    exclusionMode: ExclusionMode.Auto
    surfaceFormat.opaque: false

    anchors {
      top: true
      bottom: true
      left: true
    }

    WlrLayershell.namespace: "omarchy-mac-stagemanager"
    WlrLayershell.layer: WlrLayer.Top
    WlrLayershell.keyboardFocus: root.opened
      ? (root.focusPrimed ? WlrKeyboardFocus.OnDemand : WlrKeyboardFocus.Exclusive)
      : WlrKeyboardFocus.None

    Item {
      id: keyCatcher
      anchors.fill: parent
      focus: true
      z: 20

      Keys.priority: Keys.BeforeItem
      Keys.onPressed: function(event) {
        if (event.key === Qt.Key_Escape) {
          root.close()
          event.accepted = true
        } else if (event.key === Qt.Key_Up) {
          root.selectGroup(-1)
          event.accepted = true
        } else if (event.key === Qt.Key_Down) {
          root.selectGroup(1)
          event.accepted = true
        } else if (event.key === Qt.Key_Left) {
          root.cycleGroupWindow(-1)
          event.accepted = true
        } else if (event.key === Qt.Key_Right) {
          root.cycleGroupWindow(1)
          event.accepted = true
        } else if (event.key === Qt.Key_Tab && (event.modifiers & Qt.ShiftModifier)) {
          root.select(-1)
          event.accepted = true
        } else if (event.key === Qt.Key_Tab) {
          root.select(1)
          event.accepted = true
        } else if (event.key === Qt.Key_Return || event.key === Qt.Key_Enter || event.key === Qt.Key_Space) {
          root.activateSelected()
          event.accepted = true
        }
      }
    }

    // macOS leaves the stage visually attached to the desktop rather than
    // drawing a settings panel around it. This soft horizontal wash keeps the
    // live thumbnails readable while the wallpaper remains visible.
    Rectangle {
      anchors.fill: parent
      opacity: root.revealed ? 1 : 0

      gradient: Gradient {
        orientation: Gradient.Horizontal
        GradientStop {
          position: 0
          color: Qt.rgba(root.background.r, root.background.g, root.background.b, 0.48)
        }
        GradientStop {
          position: 0.72
          color: Qt.rgba(root.background.r, root.background.g, root.background.b, 0.20)
        }
        GradientStop {
          position: 1
          color: Qt.rgba(root.background.r, root.background.g, root.background.b, 0.03)
        }
      }

      Behavior on opacity {
        NumberAnimation { duration: 180; easing.type: Easing.OutCubic }
      }
    }

    HoverHandler { id: panelHover }

    Item {
      id: stageRail
      x: root.revealed ? root.panelGap : -Style.space(24)
      y: 0
      width: root.railWidth
      height: panel.height
      opacity: root.revealed ? 1 : 0

      Behavior on x {
        NumberAnimation { duration: 260; easing.type: Easing.OutCubic }
      }

      Behavior on opacity {
        NumberAnimation { duration: 170; easing.type: Easing.OutCubic }
      }

      // Deliberately unobtrusive: Stage Manager is normally dismissed from
      // its shortcut or bar icon, but a close affordance appears on approach.
      Rectangle {
        id: closeButton
        z: 1000
        anchors.top: parent.top
        anchors.right: parent.right
        anchors.topMargin: Style.space(8)
        anchors.rightMargin: Style.space(4)
        width: Style.space(24)
        height: width
        radius: width / 2
        opacity: panelHover.hovered || closeMouse.containsMouse ? 1 : 0
        color: closeMouse.containsMouse
          ? "#ff5f57"
          : Qt.rgba(root.background.r, root.background.g, root.background.b, 0.72)
        border.width: 1
        border.color: Qt.rgba(root.foreground.r, root.foreground.g, root.foreground.b, 0.16)

        Behavior on opacity { NumberAnimation { duration: 120 } }
        Behavior on color { ColorAnimation { duration: 100 } }

        Text {
          anchors.centerIn: parent
          text: "×"
          color: root.foreground
          opacity: 0.78
          font.family: root.fontFamily
          font.pixelSize: Style.font.caption
        }

        MouseArea {
          id: closeMouse
          anchors.fill: parent
          hoverEnabled: true
          cursorShape: Qt.PointingHandCursor
          onClicked: root.close()
        }
      }

      Flickable {
        id: appFlick
        anchors.fill: parent
        anchors.leftMargin: Style.space(10)
        anchors.rightMargin: Style.space(10)
        anchors.topMargin: Style.space(12)
        anchors.bottomMargin: Style.space(12)
        property int contentPadding: Style.space(18)
        contentWidth: width
        contentHeight: Math.max(height, groupsColumn.y + groupsColumn.implicitHeight + contentPadding)
        clip: true
        boundsBehavior: Flickable.StopAtBounds
        flickableDirection: Flickable.VerticalFlick

        Column {
          id: groupsColumn
          y: Math.max(appFlick.contentPadding, (appFlick.height - implicitHeight) / 2)
          width: appFlick.width
          spacing: Style.space(14)

          Repeater {
            model: root.groups

            delegate: AppGroup {
              required property var modelData
              width: groupsColumn.width
              groupData: modelData
            }
          }
        }
      }

      Column {
        anchors.centerIn: parent
        width: parent.width - Style.space(28)
        spacing: Style.spacing.sm
        visible: root.flatWindows.length === 0

        Text {
          width: parent.width
          text: "󰕰"
          color: root.foreground
          opacity: 0.40
          font.family: Style.font.family
          font.pixelSize: Style.font.display
          horizontalAlignment: Text.AlignHCenter
        }

        Text {
          width: parent.width
          text: "No windows"
          color: root.foreground
          opacity: 0.52
          font.family: root.fontFamily
          font.pixelSize: Style.font.caption
          horizontalAlignment: Text.AlignHCenter
        }
      }
    }
  }

  component AppGroup: Item {
    id: appGroup

    property var groupData: null
    property int currentIndex: initialIndex()
    readonly property int windowCount: groupData ? groupData.windows.length : 0
    readonly property int stackDepth: Math.min(2, Math.max(0, windowCount - 1))
    readonly property bool hovered: groupHover.hovered
    readonly property bool selected: currentRecord && root.selectedAddress === currentRecord.address
    readonly property var currentRecord: groupData && windowCount > 0
      ? groupData.windows[Math.max(0, Math.min(currentIndex, windowCount - 1))] : null

    function initialIndex() {
      if (!groupData || !groupData.windows) return 0
      for (var i = 0; i < groupData.windows.length; i++) {
        if (groupData.windows[i].address === root.selectedAddress) return i
      }
      return 0
    }

    function selectWindow(index) {
      if (!groupData || index < 0 || index >= groupData.windows.length) return
      currentIndex = index
      root.selectedAddress = groupData.windows[index].address
    }

    function cycle(delta) {
      if (windowCount <= 1) return
      var next = (currentIndex + delta + windowCount) % windowCount
      selectWindow(next)
    }

    function syncSelection() {
      // A delegate whose context is already torn down still receives the
      // selection signal, and `root` reads back as undefined there.
      if (!groupData || !groupData.windows || !root) return
      for (var i = 0; i < groupData.windows.length; i++) {
        if (groupData.windows[i].address === root.selectedAddress) {
          currentIndex = i
          root.revealGroup(appGroup)
          return
        }
      }
    }

    function stackedRecord(layerIndex) {
      if (!groupData || windowCount < 2) return null
      return groupData.windows[(currentIndex + layerIndex + 1) % windowCount]
    }

    function selectorLabel(index) {
      if (!groupData || index < 0 || index >= groupData.windows.length) return ""
      var record = groupData.windows[index]
      var duplicates = 0
      for (var i = 0; i < groupData.windows.length; i++) {
        if (groupData.windows[i].workspaceName === record.workspaceName) duplicates++
      }
      return record.workspaceName + (duplicates > 1 ? "·" + (index + 1) : "")
    }

    implicitHeight: previewStack.height + Style.space(23)
    z: hovered ? 100 : 0
    scale: hovered ? 1.018 : 1

    Behavior on scale {
      NumberAnimation { duration: 150; easing.type: Easing.OutCubic }
    }

    onGroupDataChanged: syncSelection()

    Connections {
      target: root
      function onSelectedAddressChanged() { appGroup.syncSelection() }
    }

    HoverHandler { id: groupHover }

    WheelHandler {
      id: groupWheel
      onWheel: function(event) {
        if (appGroup.windowCount > 1) {
          if (event.angleDelta.y < 0 || event.angleDelta.x < 0) {
            appGroup.cycle(1)
          } else if (event.angleDelta.y > 0 || event.angleDelta.x > 0) {
            appGroup.cycle(-1)
          }
        }
      }
    }

    Item {
      id: previewStack
      width: parent.width
      height: root.previewHeight + appGroup.stackDepth * Style.space(6)

      // Two inexpensive rounded layers approximate the soft macOS shadow
      // without depending on an effects module outside Omarchy's base stack.
      Rectangle {
        x: -Style.space(2)
        y: Style.space(4)
        width: mainPreview.width + Style.space(4)
        height: mainPreview.height + Style.space(3)
        radius: root.cardRadius + Style.space(2)
        color: Qt.rgba(0, 0, 0, appGroup.hovered ? 0.30 : 0.22)

        Behavior on color { ColorAnimation { duration: 150 } }
      }

      Rectangle {
        x: -1
        y: Style.space(2)
        width: mainPreview.width + 2
        height: mainPreview.height + 1
        radius: root.cardRadius + 1
        color: Qt.rgba(0, 0, 0, 0.24)
      }

      Repeater {
        model: appGroup.stackDepth

        StackLayer {
          required property int index
          x: (index + 1) * Style.space(6)
          y: (index + 1) * Style.space(6)
          width: previewStack.width - appGroup.stackDepth * Style.space(6)
          height: root.previewHeight
          z: index + 1
          record: appGroup.stackedRecord(index)
          onClicked: {
            var targetIdx = (appGroup.currentIndex + index + 1) % appGroup.windowCount
            appGroup.selectWindow(targetIdx)
            if (record) root.activate(record)
          }
        }
      }

      WindowPreview {
        id: mainPreview
        width: previewStack.width - appGroup.stackDepth * Style.space(6)
        height: root.previewHeight
        z: 10
        record: appGroup.currentRecord
        hoveredState: appGroup.hovered
        showWorkspaceBadge: appGroup.windowCount === 1
        onHovered: if (appGroup.currentRecord) root.selectedAddress = appGroup.currentRecord.address
        onActivated: if (appGroup.currentRecord) root.activate(appGroup.currentRecord)
      }
    }

    // macOS places the application icon across the lower edge of the preview.
    Item {
      id: appIcon
      x: Style.space(7)
      y: previewStack.height - Style.space(10)
      width: Style.space(30)
      height: width
      z: 30

      Rectangle {
        x: -1
        y: Style.space(2)
        width: parent.width + 2
        height: parent.height + 2
        radius: Style.cornerRadius + 2
        color: Qt.rgba(0, 0, 0, 0.34)
      }

      Rectangle {
        anchors.fill: parent
        radius: Style.cornerRadius
        color: Qt.rgba(root.background.r, root.background.g, root.background.b, 0.94)
        border.width: 1
        border.color: Qt.rgba(1, 1, 1, 0.16)

        Image {
          anchors.fill: parent
          anchors.margins: Style.space(3)
          source: appGroup.groupData ? appGroup.groupData.icon : ""
          fillMode: Image.PreserveAspectFit
          asynchronous: true
          smooth: true
          onStatusChanged: {
            if (status === Image.Error) {
              var fb = Quickshell.iconPath("application-x-executable", true)
              if (fb && source !== (fb.charAt(0) === "/" ? "file://" + fb : fb)) {
                source = fb.charAt(0) === "/" ? "file://" + fb : fb
              }
            }
          }
        }
      }

      Rectangle {
        visible: appGroup.windowCount > 1
        anchors.top: parent.top
        anchors.right: parent.right
        anchors.topMargin: -Style.space(4)
        anchors.rightMargin: -Style.space(4)
        width: Style.space(15)
        height: width
        radius: width / 2
        color: root.selectedText
        border.width: 1
        border.color: Qt.rgba(root.background.r, root.background.g, root.background.b, 0.88)

        Text {
          anchors.centerIn: parent
          text: appGroup.windowCount
          color: root.background
          font.family: root.fontFamily
          font.pixelSize: Style.space(9)
          font.bold: true
        }
      }
    }

    Text {
      id: appLabel
      anchors.left: appIcon.right
      anchors.leftMargin: Style.space(6)
      anchors.right: windowSelectors.visible ? windowSelectors.left : parent.right
      anchors.rightMargin: Style.space(5)
      y: previewStack.height + Style.space(1)
      height: Style.space(20)
      text: appGroup.hovered && appGroup.windowCount > 1 && appGroup.currentRecord
        ? appGroup.currentRecord.title
        : (appGroup.groupData ? appGroup.groupData.name : "")
      color: root.foreground
      opacity: appGroup.hovered || appGroup.selected ? 0.86 : 0.56
      font.family: root.fontFamily
      font.pixelSize: Style.font.caption
      font.bold: appGroup.selected
      elide: Text.ElideRight
      verticalAlignment: Text.AlignVCenter

      Behavior on opacity { NumberAnimation { duration: 130 } }
    }

    Row {
      id: windowSelectors
      visible: appGroup.windowCount > 1
      anchors.right: parent.right
      y: previewStack.height + Style.space(1)
      height: Style.space(20)
      spacing: Style.space(3)
      z: 40

      Repeater {
        model: appGroup.groupData ? appGroup.groupData.windows : []

        Rectangle {
          id: selector
          required property var modelData
          required property int index
          readonly property bool current: index === appGroup.currentIndex

          width: Math.max(height, selectorText.implicitWidth + Style.space(8))
          height: windowSelectors.height
          radius: height / 2
          color: current ? Qt.rgba(root.foreground.r, root.foreground.g, root.foreground.b, 0.92)
            : (selectorMouse.containsMouse
              ? Qt.rgba(root.foreground.r, root.foreground.g, root.foreground.b, 0.18)
              : Qt.rgba(root.background.r, root.background.g, root.background.b, 0.68))
          border.width: 1
          border.color: current
            ? Qt.rgba(1, 1, 1, 0.44)
            : Qt.rgba(root.foreground.r, root.foreground.g, root.foreground.b, 0.18)

          Behavior on color { ColorAnimation { duration: 100 } }

          Text {
            id: selectorText
            anchors.centerIn: parent
            text: appGroup.selectorLabel(selector.index)
            color: selector.current ? root.background : root.foreground
            opacity: selector.current ? 1 : 0.72
            font.family: root.fontFamily
            font.pixelSize: Style.font.caption
            font.bold: selector.current
          }

          MouseArea {
            id: selectorMouse
            anchors.fill: parent
            hoverEnabled: true
            cursorShape: Qt.PointingHandCursor
            onEntered: appGroup.selectWindow(selector.index)
            onClicked: root.activate(selector.modelData)
          }
        }
      }
    }
  }

  component StackLayer: Rectangle {
    id: stackLayer

    property var record: null
    signal clicked()

    radius: root.cardRadius
    color: Qt.rgba(root.background.r, root.background.g, root.background.b, 0.96)
    border.width: 0
    clip: true

    MouseArea {
      anchors.fill: parent
      hoverEnabled: true
      cursorShape: Qt.PointingHandCursor
      onClicked: stackLayer.clicked()
    }

    Image {
      anchors.centerIn: parent
      width: Math.min(parent.width * 0.34, parent.height * 0.48)
      height: width
      source: stackLayer.record ? stackLayer.record.icon : ""
      fillMode: Image.PreserveAspectFit
      opacity: stackCapture.hasContent ? 0 : 0.54
      asynchronous: true
      smooth: true
    }

    ScreencopyView {
      id: stackCapture
      captureSource: stackLayer.record ? stackLayer.record.wayland : null
      live: root.opened && stackLayer.visible
      paintCursor: false
      anchors.centerIn: parent
      width: {
        if (!hasContent || sourceSize.width <= 0 || sourceSize.height <= 0) return parent.width
        return Math.min(parent.width, parent.height * sourceSize.width / sourceSize.height)
      }
      height: {
        if (!hasContent || sourceSize.width <= 0 || sourceSize.height <= 0) return parent.height
        return Math.min(parent.height, parent.width * sourceSize.height / sourceSize.width)
      }
      opacity: hasContent ? 0.78 : 0
    }

    Rectangle {
      anchors.fill: parent
      color: Qt.rgba(0, 0, 0, 0.12)
    }

    BorderOverlay {
      anchors.fill: parent
      radius: parent.radius
      borderSpec: Border.withWidth(root.activeWindowBorderSpec, 1)
      opacity: 0.42
    }
  }

  component WindowPreview: Rectangle {
    id: preview

    property var record: null
    property bool hoveredState: false
    property bool showWorkspaceBadge: false
    readonly property bool selected: record && root.selectedAddress === record.address
    signal hovered()
    signal activated()

    radius: root.cardRadius
    color: Qt.rgba(0, 0, 0, 0.30)
    clip: true

    Image {
      anchors.centerIn: parent
      width: Math.min(parent.width * 0.34, parent.height * 0.48)
      height: width
      source: preview.record ? preview.record.icon : ""
      fillMode: Image.PreserveAspectFit
      opacity: capture.hasContent ? 0 : 0.68
      asynchronous: true
      smooth: true
    }

    ScreencopyView {
      id: capture
      captureSource: preview.record ? preview.record.wayland : null
      live: root.opened && preview.visible
      paintCursor: false
      anchors.centerIn: parent
      // Contain, not cover: tiled windows are portrait-shaped, and cropping them
      // to the card's landscape ratio hid the title bar, the toolbars and most
      // of the content, leaving an empty band. macOS shows the whole window.
      width: {
        if (!hasContent || sourceSize.width <= 0 || sourceSize.height <= 0) return parent.width
        return Math.min(parent.width, parent.height * sourceSize.width / sourceSize.height)
      }
      height: {
        if (!hasContent || sourceSize.width <= 0 || sourceSize.height <= 0) return parent.height
        return Math.min(parent.height, parent.width * sourceSize.height / sourceSize.width)
      }
      opacity: hasContent ? 1 : 0

      Behavior on opacity { NumberAnimation { duration: 150 } }
    }

    Rectangle {
      anchors.fill: parent
      color: preview.hoveredState ? Qt.rgba(1, 1, 1, 0.045) : "transparent"

      Behavior on color { ColorAnimation { duration: 120 } }
    }

    BorderOverlay {
      anchors.fill: parent
      z: 20
      radius: parent.radius
      borderSpec: Border.withWidth(root.activeWindowBorderSpec, preview.selected ? Style.space(2) : 1)
      opacity: preview.selected ? 1 : (preview.hoveredState ? 0.62 : 0.38)

      Behavior on opacity { NumberAnimation { duration: 120 } }
    }

    Rectangle {
      visible: preview.showWorkspaceBadge
      anchors.top: parent.top
      anchors.right: parent.right
      anchors.topMargin: Style.space(7)
      anchors.rightMargin: Style.space(7)
      width: workspaceText.implicitWidth + Style.space(10)
      height: Style.space(19)
      radius: height / 2
      color: Qt.rgba(0, 0, 0, 0.58)
      border.width: 1
      border.color: Qt.rgba(1, 1, 1, 0.18)
      opacity: preview.hoveredState || preview.selected ? 0.92 : 0.56
      z: 25

      Behavior on opacity { NumberAnimation { duration: 120 } }

      Text {
        id: workspaceText
        anchors.centerIn: parent
        text: preview.record ? preview.record.workspaceName : ""
        color: "white"
        font.family: root.fontFamily
        font.pixelSize: Style.font.caption
        font.bold: true
      }
    }

    MouseArea {
      anchors.fill: parent
      z: 30
      hoverEnabled: true
      cursorShape: Qt.PointingHandCursor
      onEntered: preview.hovered()
      onClicked: preview.activated()
    }
  }
}

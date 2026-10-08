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
    id: taskManagerWindow
    screen: Quickshell.screens[0]

    anchors {
      top: true
      bottom: true
      left: true
      right: true
    }

    WlrLayershell.layer: WlrLayer.Overlay
    WlrLayershell.namespace: "win11-taskmanager"
    WlrLayershell.keyboardFocus: WlrKeyboardFocus.OnDemand
    exclusiveZone: 0
    color: "transparent"

    implicitWidth: Math.min(1020, (screen ? screen.width : 1280) - 40)
    implicitHeight: Math.min(680, (screen ? screen.height : 720) - 50)

    property string homeDir: Quickshell.env("HOME")
    property string pluginDir: Quickshell.env("OMARCHY_PLUGIN_DIR") || (taskManagerWindow.homeDir + "/.config/omarchy/plugins/omarchy-undercover")
    property bool isDark: true
    property bool isMaximized: false

    // Navigation & State
    property string activeTab: "processes" // "processes" | "performance" | "startup" | "services"
    property string performanceTab: "cpu"  // "cpu" | "memory" | "disk" | "network"
    property bool sidebarExpanded: false
    property string searchQuery: ""
    property var selectedProcess: null
    property bool showRunDialog: false
    property string runCommandText: ""
    property bool runAsAdmin: false
    property bool showContextMenu: false
    property point contextMenuPos: Qt.point(0, 0)
    property var contextProcess: null

    // System Statistics State
    property real overallCpu: 0.0
    property real cpuFreq: 2.40
    property string cpuModel: "Processor"
    property int physicalCores: 4
    property int logicalThreads: 8
    property int uptimeSeconds: 0
    property int totalProcesses: 0
    property real memUsedGb: 0.0
    property real memTotalGb: 16.0
    property real memAvailGb: 8.0
    property real memPct: 0.0
    property real swapUsedGb: 0.0
    property real swapTotalGb: 0.0
    property var appList: []
    property var bgProcList: []

    // Historical data for live charts (last 60 seconds)
    property var cpuHistory: [0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0]
    property var memHistory: [0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0]

    function closeManager() {
      taskManagerWindow.visible = false
      var pidFile = (Quickshell.env("XDG_RUNTIME_DIR") || "/tmp") + "/omarchy-win11-taskmanager.pid"
      Quickshell.execDetached(["rm", "-f", pidFile])
      Quickshell.execDetached(["kill", String(Quickshell.processId)])
    }

    function shellQuote(val) {
      return "'" + String(val || "").replace(/'/g, "'\\''") + "'"
    }

    function formatUptime(seconds) {
      var d = Math.floor(seconds / 86400)
      var h = Math.floor((seconds % 86400) / 3600)
      var m = Math.floor((seconds % 3600) / 60)
      var s = seconds % 60
      if (d > 0) return d + ":" + (h < 10 ? "0" : "") + h + ":" + (m < 10 ? "0" : "") + m + ":" + (s < 10 ? "0" : "") + s
      return (h < 10 ? "0" : "") + h + ":" + (m < 10 ? "0" : "") + m + ":" + (s < 10 ? "0" : "") + s
    }

    function endTask(proc, force) {
      if (!proc) return
      var sig = force ? "-9" : "-15"
      if (proc.pid) {
        Quickshell.execDetached(["kill", sig, String(proc.pid)])
      }
      if (proc.address) {
        Quickshell.execDetached(["hyprctl", "dispatch", "closewindow", "address:" + proc.address])
      }
      taskManagerWindow.showContextMenu = false
      taskManagerWindow.selectedProcess = null
    }

    function switchToWindow(proc) {
      if (!proc || !proc.address) return
      var cmd = "hyprctl dispatch focuswindow " + taskManagerWindow.shellQuote("address:" + proc.address)
      Quickshell.execDetached(["bash", "-c", cmd])
      taskManagerWindow.closeManager()
    }

    function executeNewTask(cmdStr, admin) {
      if (!cmdStr || cmdStr.trim().length === 0) return
      var fullCmd = admin ? ("pkexec " + cmdStr) : cmdStr
      Quickshell.execDetached(["bash", "-c", fullCmd])
      taskManagerWindow.showRunDialog = false
      taskManagerWindow.runCommandText = ""
    }

    function resolveAppIcon(item) {
      if (!item) return ""
      var cls = (item.class || item.name || "").toLowerCase().trim()
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

    // Process statistics backend
    Process {
      id: statsProc
      command: [
        "bash", "-c",
        "for p in \"" + taskManagerWindow.pluginDir + "/scripts/omarchy-win11-taskmanager-backend\" \"" + taskManagerWindow.homeDir + "/omarchy-undercover/scripts/omarchy-win11-taskmanager-backend\" \"$(which omarchy-win11-taskmanager-backend 2>/dev/null)\"; do if [ -x \"$p\" ]; then exec \"$p\" 1.5; fi; done"
      ]
      running: true
      stdout: SplitParser {
        onRead: function(line) {
          if (!line) return
          try {
            var data = JSON.parse(line.trim())
            if (data.error) return

            taskManagerWindow.overallCpu = data.cpu_pct || 0.0
            taskManagerWindow.cpuFreq = data.cpu_freq || 2.5
            taskManagerWindow.cpuModel = data.cpu_model || "Processor"
            taskManagerWindow.physicalCores = data.cores || 4
            taskManagerWindow.logicalThreads = data.threads || 8
            taskManagerWindow.uptimeSeconds = data.uptime_sec || 0
            taskManagerWindow.totalProcesses = data.proc_count || 0

            taskManagerWindow.memUsedGb = data.mem_used_gb || 0.0
            taskManagerWindow.memTotalGb = data.mem_total_gb || 16.0
            taskManagerWindow.memAvailGb = data.mem_avail_gb || 8.0
            taskManagerWindow.memPct = data.mem_pct || 0.0
            taskManagerWindow.swapUsedGb = data.swap_used_gb || 0.0
            taskManagerWindow.swapTotalGb = data.swap_total_gb || 0.0

            taskManagerWindow.appList = data.apps || []
            taskManagerWindow.bgProcList = data.bg_procs || []

            // Push to history charts
            var newCpuHist = taskManagerWindow.cpuHistory.slice()
            newCpuHist.push(taskManagerWindow.overallCpu)
            if (newCpuHist.length > 30) newCpuHist.shift()
            taskManagerWindow.cpuHistory = newCpuHist

            var newMemHist = taskManagerWindow.memHistory.slice()
            newMemHist.push(taskManagerWindow.memPct)
            if (newMemHist.length > 30) newMemHist.shift()
            taskManagerWindow.memHistory = newMemHist

            if (cpuCanvas.visible) cpuCanvas.requestPaint()
            if (memCanvas.visible) memCanvas.requestPaint()
          } catch(e) {}
        }
      }
    }

    // Keyboard Shortcuts
    Shortcut {
      sequence: "Escape"
      onActivated: {
        if (taskManagerWindow.showContextMenu) {
          taskManagerWindow.showContextMenu = false
        } else if (taskManagerWindow.showRunDialog) {
          taskManagerWindow.showRunDialog = false
        } else {
          taskManagerWindow.closeManager()
        }
      }
    }

    MouseArea {
      anchors.fill: parent
      onClicked: {
        if (taskManagerWindow.showContextMenu) {
          taskManagerWindow.showContextMenu = false
        } else if (taskManagerWindow.showRunDialog) {
          taskManagerWindow.showRunDialog = false
        }
      }
    }

    // Main Mica Acrylic Window Container
    Rectangle {
      id: mainFrame
      anchors.centerIn: parent
      width: taskManagerWindow.isMaximized ? ((taskManagerWindow.screen ? taskManagerWindow.screen.width : 1280) - 20) : Math.min(1020, (taskManagerWindow.screen ? taskManagerWindow.screen.width : 1280) - 40)
      height: taskManagerWindow.isMaximized ? ((taskManagerWindow.screen ? taskManagerWindow.screen.height : 720) - 40) : Math.min(680, (taskManagerWindow.screen ? taskManagerWindow.screen.height : 720) - 50)
      radius: taskManagerWindow.isMaximized ? 0 : 8
      color: Qt.rgba(0.12, 0.13, 0.17, 0.96)
      border.color: Qt.rgba(1, 1, 1, 0.14)
      border.width: 1
      clip: true

      Behavior on width { NumberAnimation { duration: 150; easing.type: Easing.OutQuad } }
      Behavior on height { NumberAnimation { duration: 150; easing.type: Easing.OutQuad } }

      ColumnLayout {
        anchors.fill: parent
        spacing: 0

        // 1. Windows 11 Titlebar
        Rectangle {
          Layout.fillWidth: true
          Layout.preferredHeight: 44
          color: Qt.rgba(0.09, 0.10, 0.13, 0.98)
          border.color: Qt.rgba(1, 1, 1, 0.06)
          border.width: 1

          RowLayout {
            anchors.fill: parent
            anchors.leftMargin: 12
            anchors.rightMargin: 0
            spacing: 12

            // Task Manager Logo
            Rectangle {
              width: 22
              height: 22
              radius: 4
              color: "#107c41"
              Text {
                anchors.centerIn: parent
                text: "📊"
                font.pixelSize: 12
              }
            }

            Text {
              text: "Task Manager"
              font.family: "Segoe UI"
              font.pixelSize: 12
              font.bold: true
              color: "#ffffff"
            }

            Item { Layout.preferredWidth: 20 }

            // Global Filter Search Bar
            Rectangle {
              Layout.preferredWidth: 320
              Layout.preferredHeight: 30
              radius: 4
              color: procSearchInput.activeFocus ? Qt.rgba(0.16, 0.17, 0.22, 0.95) : Qt.rgba(1, 1, 1, 0.06)
              border.color: procSearchInput.activeFocus ? "#60cdff" : Qt.rgba(1, 1, 1, 0.10)
              border.width: 1

              RowLayout {
                anchors.fill: parent
                anchors.leftMargin: 8
                anchors.rightMargin: 8
                spacing: 6

                Text {
                  text: "🔍"
                  font.pixelSize: 11
                  color: Qt.rgba(1, 1, 1, 0.5)
                }

                TextInput {
                  id: procSearchInput
                  Layout.fillWidth: true
                  color: "#ffffff"
                  font.family: "Segoe UI"
                  font.pixelSize: 11
                  selectByMouse: true
                  clip: true
                  onTextChanged: taskManagerWindow.searchQuery = text

                  Text {
                    anchors.fill: parent
                    visible: !procSearchInput.text && !procSearchInput.activeFocus
                    text: "Type a name, publisher, or PID to search"
                    color: Qt.rgba(1, 1, 1, 0.4)
                    font.family: "Segoe UI"
                    font.pixelSize: 11
                  }
                }
              }
            }

            Item { Layout.fillWidth: true }

            // Window Controls (Minimize, Maximize, Close)
            RowLayout {
              spacing: 0

              Rectangle {
                width: 44; height: 44
                color: btnMinM.containsMouse ? Qt.rgba(1, 1, 1, 0.08) : "transparent"
                Text { anchors.centerIn: parent; text: "─"; font.pixelSize: 10; color: "#ffffff" }
                MouseArea {
                  id: btnMinM
                  anchors.fill: parent
                  hoverEnabled: true
                  onClicked: {
                    Quickshell.execDetached(["omarchy-undercover-minimize"])
                    taskManagerWindow.closeManager()
                  }
                }
              }

              Rectangle {
                width: 44; height: 44
                color: btnMaxM.containsMouse ? Qt.rgba(1, 1, 1, 0.08) : "transparent"
                Text {
                  anchors.centerIn: parent
                  text: taskManagerWindow.isMaximized ? "🗗" : "□"
                  font.pixelSize: 11
                  color: "#ffffff"
                }
                MouseArea {
                  id: btnMaxM
                  anchors.fill: parent
                  hoverEnabled: true
                  onClicked: taskManagerWindow.isMaximized = !taskManagerWindow.isMaximized
                }
              }

              Rectangle {
                width: 44; height: 44
                color: btnCloseM.containsMouse ? "#c42b1c" : "transparent"
                Text { anchors.centerIn: parent; text: "✕"; font.pixelSize: 11; color: "#ffffff" }
                MouseArea { id: btnCloseM; anchors.fill: parent; hoverEnabled: true; onClicked: taskManagerWindow.closeManager() }
              }
            }
          }
        }

        // 2. Body Area (Sidebar Rail + Main Content)
        RowLayout {
          Layout.fillWidth: true
          Layout.fillHeight: true
          spacing: 0

          // Sidebar Navigation Rail
          Rectangle {
            Layout.preferredWidth: taskManagerWindow.sidebarExpanded ? 180 : 54
            Layout.fillHeight: true
            color: Qt.rgba(0.10, 0.11, 0.14, 0.98)
            border.color: Qt.rgba(1, 1, 1, 0.06)
            border.width: 1

            Behavior on Layout.preferredWidth {
              NumberAnimation { duration: 140; easing.type: Easing.OutQuad }
            }

            ColumnLayout {
              anchors.fill: parent
              anchors.margins: 6
              spacing: 4

              // Hamburger Menu Toggle
              Rectangle {
                Layout.fillWidth: true
                Layout.preferredHeight: 38
                radius: 4
                color: burgM.containsMouse ? Qt.rgba(1, 1, 1, 0.08) : "transparent"

                RowLayout {
                  anchors.fill: parent
                  anchors.leftMargin: 12
                  spacing: 12

                  Text {
                    text: "☰"
                    font.pixelSize: 15
                    color: "#ffffff"
                  }

                  Text {
                    visible: taskManagerWindow.sidebarExpanded
                    text: "Menu"
                    font.family: "Segoe UI"
                    font.pixelSize: 12
                    color: "#ffffff"
                  }
                }

                MouseArea {
                  id: burgM
                  anchors.fill: parent
                  hoverEnabled: true
                  onClicked: taskManagerWindow.sidebarExpanded = !taskManagerWindow.sidebarExpanded
                }
              }

              Rectangle {
                Layout.fillWidth: true
                Layout.preferredHeight: 1
                color: Qt.rgba(1, 1, 1, 0.08)
              }

              // Nav Item 1: Processes
              Rectangle {
                Layout.fillWidth: true
                Layout.preferredHeight: 38
                radius: 4
                color: taskManagerWindow.activeTab === "processes" ? Qt.rgba(1, 1, 1, 0.12) : (navProcM.containsMouse ? Qt.rgba(1, 1, 1, 0.06) : "transparent")

                RowLayout {
                  anchors.fill: parent
                  anchors.leftMargin: 12
                  spacing: 12

                  Text { text: "📊"; font.pixelSize: 14 }
                  Text {
                    visible: taskManagerWindow.sidebarExpanded
                    text: "Processes"
                    font.family: "Segoe UI"
                    font.pixelSize: 12
                    font.bold: taskManagerWindow.activeTab === "processes"
                    color: "#ffffff"
                  }
                }

                MouseArea {
                  id: navProcM
                  anchors.fill: parent
                  hoverEnabled: true
                  onClicked: taskManagerWindow.activeTab = "processes"
                }
              }

              // Nav Item 2: Performance
              Rectangle {
                Layout.fillWidth: true
                Layout.preferredHeight: 38
                radius: 4
                color: taskManagerWindow.activeTab === "performance" ? Qt.rgba(1, 1, 1, 0.12) : (navPerfM.containsMouse ? Qt.rgba(1, 1, 1, 0.06) : "transparent")

                RowLayout {
                  anchors.fill: parent
                  anchors.leftMargin: 12
                  spacing: 12

                  Text { text: "📈"; font.pixelSize: 14 }
                  Text {
                    visible: taskManagerWindow.sidebarExpanded
                    text: "Performance"
                    font.family: "Segoe UI"
                    font.pixelSize: 12
                    font.bold: taskManagerWindow.activeTab === "performance"
                    color: "#ffffff"
                  }
                }

                MouseArea {
                  id: navPerfM
                  anchors.fill: parent
                  hoverEnabled: true
                  onClicked: taskManagerWindow.activeTab = "performance"
                }
              }

              // Nav Item 3: Services
              Rectangle {
                Layout.fillWidth: true
                Layout.preferredHeight: 38
                radius: 4
                color: taskManagerWindow.activeTab === "services" ? Qt.rgba(1, 1, 1, 0.12) : (navSvcM.containsMouse ? Qt.rgba(1, 1, 1, 0.06) : "transparent")

                RowLayout {
                  anchors.fill: parent
                  anchors.leftMargin: 12
                  spacing: 12

                  Text { text: "🛠️"; font.pixelSize: 14 }
                  Text {
                    visible: taskManagerWindow.sidebarExpanded
                    text: "Services"
                    font.family: "Segoe UI"
                    font.pixelSize: 12
                    font.bold: taskManagerWindow.activeTab === "services"
                    color: "#ffffff"
                  }
                }

                MouseArea {
                  id: navSvcM
                  anchors.fill: parent
                  hoverEnabled: true
                  onClicked: taskManagerWindow.activeTab = "services"
                }
              }

              Item { Layout.fillHeight: true }

              // Settings icon at bottom
              Rectangle {
                Layout.fillWidth: true
                Layout.preferredHeight: 38
                radius: 4
                color: navSetM.containsMouse ? Qt.rgba(1, 1, 1, 0.08) : "transparent"

                RowLayout {
                  anchors.fill: parent
                  anchors.leftMargin: 12
                  spacing: 12

                  Text { text: "⚙️"; font.pixelSize: 14 }
                  Text {
                    visible: taskManagerWindow.sidebarExpanded
                    text: "Settings"
                    font.family: "Segoe UI"
                    font.pixelSize: 12
                    color: "#ffffff"
                  }
                }

                MouseArea {
                  id: navSetM
                  anchors.fill: parent
                  hoverEnabled: true
                  onClicked: {
                    Quickshell.execDetached(["omarchy-undercover-settings"])
                  }
                }
              }
            }
          }

          // Main View Content Container
          ColumnLayout {
            Layout.fillWidth: true
            Layout.fillHeight: true
            spacing: 0

            // Command Bar (Run task, End task, Efficiency mode)
            Rectangle {
              Layout.fillWidth: true
              Layout.preferredHeight: 42
              color: Qt.rgba(0.12, 0.13, 0.17, 0.98)
              border.color: Qt.rgba(1, 1, 1, 0.06)
              border.width: 1

              RowLayout {
                anchors.fill: parent
                anchors.leftMargin: 14
                anchors.rightMargin: 14
                spacing: 10

                // Run new task button
                Rectangle {
                  implicitWidth: runBtnRow.implicitWidth + 16
                  implicitHeight: 28
                  radius: 4
                  color: runTaskM.containsMouse ? Qt.rgba(1, 1, 1, 0.12) : Qt.rgba(1, 1, 1, 0.06)
                  border.color: Qt.rgba(1, 1, 1, 0.12)
                  border.width: 1

                  RowLayout {
                    id: runBtnRow
                    anchors.centerIn: parent
                    spacing: 6
                    Text { text: "＋"; font.pixelSize: 11; font.bold: true; color: "#60cdff" }
                    Text { text: "Run new task"; font.family: "Segoe UI"; font.pixelSize: 11; color: "#ffffff" }
                  }

                  MouseArea {
                    id: runTaskM
                    anchors.fill: parent
                    hoverEnabled: true
                    onClicked: taskManagerWindow.showRunDialog = true
                  }
                }

                // End task button
                Rectangle {
                  implicitWidth: endBtnRow.implicitWidth + 16
                  implicitHeight: 28
                  radius: 4
                  property bool hasTarget: taskManagerWindow.selectedProcess !== null
                  color: hasTarget ? (endTaskM.containsMouse ? "#c42b1c" : Qt.rgba(0.77, 0.17, 0.11, 0.75)) : Qt.rgba(1, 1, 1, 0.04)
                  border.color: hasTarget ? "#c42b1c" : Qt.rgba(1, 1, 1, 0.08)
                  border.width: 1

                  RowLayout {
                    id: endBtnRow
                    anchors.centerIn: parent
                    spacing: 6
                    Text { text: "✕"; font.pixelSize: 10; font.bold: true; color: parent.parent.hasTarget ? "#ffffff" : Qt.rgba(1, 1, 1, 0.3) }
                    Text { text: "End task"; font.family: "Segoe UI"; font.pixelSize: 11; color: parent.parent.hasTarget ? "#ffffff" : Qt.rgba(1, 1, 1, 0.3) }
                  }

                  MouseArea {
                    id: endTaskM
                    anchors.fill: parent
                    enabled: parent.hasTarget
                    hoverEnabled: true
                    onClicked: taskManagerWindow.endTask(taskManagerWindow.selectedProcess, false)
                  }
                }

                Item { Layout.fillWidth: true }

                // Quick overall stats pills
                Rectangle {
                  implicitWidth: cpuPill.implicitWidth + 16
                  implicitHeight: 26
                  radius: 4
                  color: Qt.rgba(1, 1, 1, 0.06)
                  Text {
                    id: cpuPill
                    anchors.centerIn: parent
                    text: "CPU: " + Math.round(taskManagerWindow.overallCpu) + "%"
                    font.family: "Segoe UI"
                    font.pixelSize: 11
                    font.bold: true
                    color: taskManagerWindow.overallCpu > 80 ? "#ff99a4" : (taskManagerWindow.overallCpu > 40 ? "#fce100" : "#60cdff")
                  }
                }

                Rectangle {
                  implicitWidth: memPill.implicitWidth + 16
                  implicitHeight: 26
                  radius: 4
                  color: Qt.rgba(1, 1, 1, 0.06)
                  Text {
                    id: memPill
                    anchors.centerIn: parent
                    text: "Memory: " + Math.round(taskManagerWindow.memPct) + "%"
                    font.family: "Segoe UI"
                    font.pixelSize: 11
                    font.bold: true
                    color: taskManagerWindow.memPct > 80 ? "#ff99a4" : "#60cdff"
                  }
                }
              }
            }

            // PAGE 1: PROCESSES TAB
            Item {
              visible: taskManagerWindow.activeTab === "processes"
              Layout.fillWidth: true
              Layout.fillHeight: true

              ColumnLayout {
                anchors.fill: parent
                spacing: 0

                // Table Header Row
                Rectangle {
                  Layout.fillWidth: true
                  Layout.preferredHeight: 32
                  color: Qt.rgba(0.09, 0.10, 0.13, 0.98)
                  border.color: Qt.rgba(1, 1, 1, 0.08)
                  border.width: 1

                  RowLayout {
                    anchors.fill: parent
                    anchors.leftMargin: 14
                    anchors.rightMargin: 14
                    spacing: 8

                    Text { Layout.preferredWidth: 320; text: "Name"; font.family: "Segoe UI"; font.pixelSize: 11; font.bold: true; color: Qt.rgba(1, 1, 1, 0.8) }
                    Text { Layout.preferredWidth: 100; text: "Status"; font.family: "Segoe UI"; font.pixelSize: 11; font.bold: true; color: Qt.rgba(1, 1, 1, 0.8) }
                    Text { Layout.preferredWidth: 100; text: "CPU %"; font.family: "Segoe UI"; font.pixelSize: 11; font.bold: true; color: Qt.rgba(1, 1, 1, 0.8) }
                    Text { Layout.preferredWidth: 110; text: "Memory (MB)"; font.family: "Segoe UI"; font.pixelSize: 11; font.bold: true; color: Qt.rgba(1, 1, 1, 0.8) }
                    Text { Layout.preferredWidth: 80; text: "PID"; font.family: "Segoe UI"; font.pixelSize: 11; font.bold: true; color: Qt.rgba(1, 1, 1, 0.8) }
                    Item { Layout.fillWidth: true }
                  }
                }

                // Table Rows List
                ScrollView {
                  id: procScroll
                  Layout.fillWidth: true
                  Layout.fillHeight: true
                  clip: true

                  ColumnLayout {
                    width: procScroll.width
                    spacing: 1

                    // SECTION 1: APPS HEADER
                    Rectangle {
                      Layout.fillWidth: true
                      Layout.preferredHeight: 28
                      color: Qt.rgba(1, 1, 1, 0.04)

                      RowLayout {
                        anchors.fill: parent
                        anchors.leftMargin: 14
                        spacing: 8
                        Text { text: "▼"; font.pixelSize: 8; color: Qt.rgba(1, 1, 1, 0.6) }
                        Text {
                          text: "Apps (" + taskManagerWindow.appList.length + ")"
                          font.family: "Segoe UI"
                          font.pixelSize: 11
                          font.bold: true
                          color: "#60cdff"
                        }
                      }
                    }

                    // APPS ROWS
                    Repeater {
                      model: {
                        var q = taskManagerWindow.searchQuery.toLowerCase().trim()
                        if (!q) return taskManagerWindow.appList
                        return taskManagerWindow.appList.filter(function(a) {
                          return (a.name || "").toLowerCase().indexOf(q) !== -1 ||
                                 (a.class || "").toLowerCase().indexOf(q) !== -1 ||
                                 String(a.pid).indexOf(q) !== -1
                        })
                      }

                      Rectangle {
                        id: appRow
                        property var procItem: modelData
                        property bool isSelectedRow: taskManagerWindow.selectedProcess && taskManagerWindow.selectedProcess.pid === procItem.pid
                        Layout.fillWidth: true
                        Layout.preferredHeight: 32
                        color: isSelectedRow
                               ? Qt.rgba(0, 0.47, 0.83, 0.35)
                               : (rowMouse.containsMouse ? Qt.rgba(1, 1, 1, 0.06) : "transparent")
                        border.color: isSelectedRow ? "#60cdff" : "transparent"
                        border.width: 1

                        RowLayout {
                          anchors.fill: parent
                          anchors.leftMargin: 18
                          anchors.rightMargin: 14
                          spacing: 8

                          // Icon + Title
                          RowLayout {
                            Layout.preferredWidth: 316
                            spacing: 8

                            Image {
                              Layout.preferredWidth: 16
                              Layout.preferredHeight: 16
                              sourceSize: Qt.size(16, 16)
                              source: taskManagerWindow.resolveAppIcon(procItem)
                              fillMode: Image.PreserveAspectFit
                            }

                            Text {
                              Layout.fillWidth: true
                              text: procItem.name || procItem.class || "App"
                              font.family: "Segoe UI"
                              font.pixelSize: 11
                              color: "#ffffff"
                              elide: Text.ElideRight
                            }
                          }

                          // Status
                          Text {
                            Layout.preferredWidth: 100
                            text: procItem.status || "Running"
                            font.family: "Segoe UI"
                            font.pixelSize: 11
                            color: Qt.rgba(1, 1, 1, 0.7)
                          }

                          // CPU % with heat-map color
                          Rectangle {
                            Layout.preferredWidth: 100
                            Layout.preferredHeight: 24
                            color: procItem.cpu > 25 ? Qt.rgba(0.9, 0.4, 0.1, 0.25) : (procItem.cpu > 5 ? Qt.rgba(0.9, 0.7, 0.1, 0.15) : "transparent")
                            radius: 3
                            Text {
                              anchors.left: parent.left
                              anchors.verticalCenter: parent.verticalCenter
                              text: procItem.cpu + "%"
                              font.family: "Segoe UI"
                              font.pixelSize: 11
                              font.bold: procItem.cpu > 10
                              color: procItem.cpu > 25 ? "#fce100" : "#ffffff"
                            }
                          }

                          // Memory MB with heat-map color
                          Rectangle {
                            Layout.preferredWidth: 110
                            Layout.preferredHeight: 24
                            color: procItem.mem_mb > 1000 ? Qt.rgba(0.9, 0.3, 0.2, 0.25) : (procItem.mem_mb > 400 ? Qt.rgba(0.9, 0.6, 0.1, 0.15) : "transparent")
                            radius: 3
                            Text {
                              anchors.left: parent.left
                              anchors.verticalCenter: parent.verticalCenter
                              text: procItem.mem_mb + " MB"
                              font.family: "Segoe UI"
                              font.pixelSize: 11
                              color: "#ffffff"
                            }
                          }

                          // PID
                          Text {
                            Layout.preferredWidth: 80
                            text: String(procItem.pid)
                            font.family: "Segoe UI"
                            font.pixelSize: 11
                            color: Qt.rgba(1, 1, 1, 0.6)
                          }

                          Item { Layout.fillWidth: true }
                        }

                        MouseArea {
                          id: rowMouse
                          anchors.fill: parent
                          hoverEnabled: true
                          acceptedButtons: Qt.LeftButton | Qt.RightButton

                          onClicked: function(mouse) {
                            taskManagerWindow.selectedProcess = procItem
                            if (mouse.button === Qt.RightButton) {
                              taskManagerWindow.contextProcess = procItem
                              var pos = rowMouse.mapToItem(mainFrame, mouse.x, mouse.y)
                              taskManagerWindow.contextMenuPos = pos
                              taskManagerWindow.showContextMenu = true
                            }
                          }

                          onDoubleClicked: {
                            if (procItem.address) {
                              taskManagerWindow.switchToWindow(procItem)
                            }
                          }
                        }
                      }
                    }

                    // SECTION 2: BACKGROUND PROCESSES HEADER
                    Rectangle {
                      Layout.fillWidth: true
                      Layout.preferredHeight: 28
                      color: Qt.rgba(1, 1, 1, 0.04)

                      RowLayout {
                        anchors.fill: parent
                        anchors.leftMargin: 14
                        spacing: 8
                        Text { text: "▼"; font.pixelSize: 8; color: Qt.rgba(1, 1, 1, 0.6) }
                        Text {
                          text: "Background processes (" + taskManagerWindow.bgProcList.length + ")"
                          font.family: "Segoe UI"
                          font.pixelSize: 11
                          font.bold: true
                          color: Qt.rgba(1, 1, 1, 0.75)
                        }
                      }
                    }

                    // BACKGROUND PROCESSES ROWS
                    Repeater {
                      model: {
                        var q = taskManagerWindow.searchQuery.toLowerCase().trim()
                        if (!q) return taskManagerWindow.bgProcList
                        return taskManagerWindow.bgProcList.filter(function(p) {
                          return (p.name || "").toLowerCase().indexOf(q) !== -1 ||
                                 String(p.pid).indexOf(q) !== -1
                        })
                      }

                      Rectangle {
                        id: bgRow
                        property var bgItem: modelData
                        property bool isSelectedBg: taskManagerWindow.selectedProcess && taskManagerWindow.selectedProcess.pid === bgItem.pid
                        Layout.fillWidth: true
                        Layout.preferredHeight: 30
                        color: isSelectedBg
                               ? Qt.rgba(0, 0.47, 0.83, 0.35)
                               : (bgMouse.containsMouse ? Qt.rgba(1, 1, 1, 0.06) : "transparent")
                        border.color: isSelectedBg ? "#60cdff" : "transparent"
                        border.width: 1

                        RowLayout {
                          anchors.fill: parent
                          anchors.leftMargin: 18
                          anchors.rightMargin: 14
                          spacing: 8

                          // Process Name
                          RowLayout {
                            Layout.preferredWidth: 316
                            spacing: 8
                            Text { text: "⚙️"; font.pixelSize: 11 }
                            Text {
                              Layout.fillWidth: true
                              text: bgItem.name || "Process"
                              font.family: "Segoe UI"
                              font.pixelSize: 11
                              color: Qt.rgba(1, 1, 1, 0.85)
                              elide: Text.ElideRight
                            }
                          }

                          // Status
                          Text {
                            Layout.preferredWidth: 100
                            text: bgItem.status || "Sleeping"
                            font.family: "Segoe UI"
                            font.pixelSize: 11
                            color: Qt.rgba(1, 1, 1, 0.5)
                          }

                          // CPU %
                          Text {
                            Layout.preferredWidth: 100
                            text: bgItem.cpu + "%"
                            font.family: "Segoe UI"
                            font.pixelSize: 11
                            color: bgItem.cpu > 10 ? "#fce100" : Qt.rgba(1, 1, 1, 0.7)
                          }

                          // Memory MB
                          Text {
                            Layout.preferredWidth: 110
                            text: bgItem.mem_mb + " MB"
                            font.family: "Segoe UI"
                            font.pixelSize: 11
                            color: Qt.rgba(1, 1, 1, 0.8)
                          }

                          // PID
                          Text {
                            Layout.preferredWidth: 80
                            text: String(bgItem.pid)
                            font.family: "Segoe UI"
                            font.pixelSize: 11
                            color: Qt.rgba(1, 1, 1, 0.5)
                          }

                          Item { Layout.fillWidth: true }
                        }

                        MouseArea {
                          id: bgMouse
                          anchors.fill: parent
                          hoverEnabled: true
                          acceptedButtons: Qt.LeftButton | Qt.RightButton

                          onClicked: function(mouse) {
                            taskManagerWindow.selectedProcess = bgItem
                            if (mouse.button === Qt.RightButton) {
                              taskManagerWindow.contextProcess = bgItem
                              var pos = bgMouse.mapToItem(mainFrame, mouse.x, mouse.y)
                              taskManagerWindow.contextMenuPos = pos
                              taskManagerWindow.showContextMenu = true
                            }
                          }
                        }
                      }
                    }
                  }
                }
              }
            }

            // PAGE 2: PERFORMANCE TAB
            Item {
              visible: taskManagerWindow.activeTab === "performance"
              Layout.fillWidth: true
              Layout.fillHeight: true

              RowLayout {
                anchors.fill: parent
                spacing: 0

                // Left Hardware List (CPU, Memory, Disk, Network)
                Rectangle {
                  Layout.preferredWidth: 220
                  Layout.fillHeight: true
                  color: Qt.rgba(0.09, 0.10, 0.13, 0.98)
                  border.color: Qt.rgba(1, 1, 1, 0.08)
                  border.width: 1

                  ColumnLayout {
                    anchors.fill: parent
                    anchors.margins: 8
                    spacing: 6

                    // CPU Item
                    Rectangle {
                      Layout.fillWidth: true
                      Layout.preferredHeight: 74
                      radius: 6
                      color: taskManagerWindow.performanceTab === "cpu" ? Qt.rgba(0, 0.47, 0.83, 0.25) : (perfCpuM.containsMouse ? Qt.rgba(1, 1, 1, 0.06) : "transparent")
                      border.color: taskManagerWindow.performanceTab === "cpu" ? "#60cdff" : "transparent"
                      border.width: 1

                      ColumnLayout {
                        anchors.fill: parent
                        anchors.margins: 10
                        spacing: 2

                        Text { text: "CPU"; font.family: "Segoe UI"; font.pixelSize: 13; font.bold: true; color: "#ffffff" }
                        Text { text: Math.round(taskManagerWindow.overallCpu) + "% " + taskManagerWindow.cpuFreq + " GHz"; font.family: "Segoe UI"; font.pixelSize: 11; color: "#60cdff" }
                        Text { text: taskManagerWindow.cpuModel; font.family: "Segoe UI"; font.pixelSize: 9; color: Qt.rgba(1, 1, 1, 0.5); elide: Text.ElideRight; Layout.fillWidth: true }
                      }

                      MouseArea {
                        id: perfCpuM
                        anchors.fill: parent
                        hoverEnabled: true
                        onClicked: taskManagerWindow.performanceTab = "cpu"
                      }
                    }

                    // Memory Item
                    Rectangle {
                      Layout.fillWidth: true
                      Layout.preferredHeight: 74
                      radius: 6
                      color: taskManagerWindow.performanceTab === "memory" ? Qt.rgba(0, 0.47, 0.83, 0.25) : (perfMemM.containsMouse ? Qt.rgba(1, 1, 1, 0.06) : "transparent")
                      border.color: taskManagerWindow.performanceTab === "memory" ? "#60cdff" : "transparent"
                      border.width: 1

                      ColumnLayout {
                        anchors.fill: parent
                        anchors.margins: 10
                        spacing: 2

                        Text { text: "Memory"; font.family: "Segoe UI"; font.pixelSize: 13; font.bold: true; color: "#ffffff" }
                        Text { text: taskManagerWindow.memUsedGb + "/" + taskManagerWindow.memTotalGb + " GB (" + Math.round(taskManagerWindow.memPct) + "%)"; font.family: "Segoe UI"; font.pixelSize: 11; color: "#60cdff" }
                        Text { text: taskManagerWindow.memAvailGb + " GB available"; font.family: "Segoe UI"; font.pixelSize: 9; color: Qt.rgba(1, 1, 1, 0.5) }
                      }

                      MouseArea {
                        id: perfMemM
                        anchors.fill: parent
                        hoverEnabled: true
                        onClicked: taskManagerWindow.performanceTab = "memory"
                      }
                    }

                    // Swap / Disk Item
                    Rectangle {
                      Layout.fillWidth: true
                      Layout.preferredHeight: 74
                      radius: 6
                      color: taskManagerWindow.performanceTab === "disk" ? Qt.rgba(0, 0.47, 0.83, 0.25) : (perfDiskM.containsMouse ? Qt.rgba(1, 1, 1, 0.06) : "transparent")
                      border.color: taskManagerWindow.performanceTab === "disk" ? "#60cdff" : "transparent"
                      border.width: 1

                      ColumnLayout {
                        anchors.fill: parent
                        anchors.margins: 10
                        spacing: 2

                        Text { text: "Swap / Storage"; font.family: "Segoe UI"; font.pixelSize: 13; font.bold: true; color: "#ffffff" }
                        Text { text: taskManagerWindow.swapUsedGb + "/" + taskManagerWindow.swapTotalGb + " GB swap"; font.family: "Segoe UI"; font.pixelSize: 11; color: "#60cdff" }
                        Text { text: "Active swap space"; font.family: "Segoe UI"; font.pixelSize: 9; color: Qt.rgba(1, 1, 1, 0.5) }
                      }

                      MouseArea {
                        id: perfDiskM
                        anchors.fill: parent
                        hoverEnabled: true
                        onClicked: taskManagerWindow.performanceTab = "disk"
                      }
                    }

                    Item { Layout.fillHeight: true }
                  }
                }

                // Main Performance Display Panel
                Rectangle {
                  Layout.fillWidth: true
                  Layout.fillHeight: true
                  color: Qt.rgba(0.12, 0.13, 0.17, 0.98)

                  ColumnLayout {
                    anchors.fill: parent
                    anchors.margins: 20
                    spacing: 16

                    // View 1: CPU Details & Live Chart
                    ColumnLayout {
                      visible: taskManagerWindow.performanceTab === "cpu"
                      Layout.fillWidth: true
                      Layout.fillHeight: true
                      spacing: 14

                      RowLayout {
                        Layout.fillWidth: true
                        ColumnLayout {
                          spacing: 2
                          Text { text: "CPU"; font.family: "Segoe UI"; font.pixelSize: 22; font.bold: true; color: "#ffffff" }
                          Text { text: "% Utilization over 60 seconds"; font.family: "Segoe UI"; font.pixelSize: 11; color: Qt.rgba(1, 1, 1, 0.5) }
                        }
                        Item { Layout.fillWidth: true }
                        Text { text: taskManagerWindow.cpuModel; font.family: "Segoe UI"; font.pixelSize: 14; font.bold: true; color: Qt.rgba(1, 1, 1, 0.85) }
                      }

                      // Real-time Canvas Graph for CPU
                      Rectangle {
                        Layout.fillWidth: true
                        Layout.preferredHeight: 180
                        radius: 6
                        color: Qt.rgba(0.06, 0.07, 0.09, 0.95)
                        border.color: Qt.rgba(1, 1, 1, 0.12)
                        border.width: 1
                        clip: true

                        Canvas {
                          id: cpuCanvas
                          anchors.fill: parent
                          anchors.margins: 4

                          onPaint: {
                            var ctx = getContext("2d")
                            ctx.clearRect(0, 0, width, height)

                            // Grid Lines
                            ctx.strokeStyle = Qt.rgba(1, 1, 1, 0.08)
                            ctx.lineWidth = 1
                            for (var y = 1; y < 4; y++) {
                              var gy = (height / 4) * y
                              ctx.beginPath()
                              ctx.moveTo(0, gy)
                              ctx.lineTo(width, gy)
                              ctx.stroke()
                            }
                            for (var x = 1; x < 6; x++) {
                              var gx = (width / 6) * x
                              ctx.beginPath()
                              ctx.moveTo(gx, 0)
                              ctx.lineTo(gx, height)
                              ctx.stroke()
                            }

                            var data = taskManagerWindow.cpuHistory
                            if (!data || data.length < 2) return

                            // Wave / Fill
                            var step = width / (data.length - 1)
                            ctx.beginPath()
                            ctx.moveTo(0, height)

                            for (var i = 0; i < data.length; i++) {
                              var val = Math.max(0, Math.min(100, data[i]))
                              var py = height - (val / 100 * height)
                              ctx.lineTo(i * step, py)
                            }
                            ctx.lineTo(width, height)
                            ctx.closePath()

                            ctx.fillStyle = Qt.rgba(0.0, 0.65, 0.95, 0.20)
                            ctx.fill()

                            // Line stroke
                            ctx.beginPath()
                            for (var j = 0; j < data.length; j++) {
                              var v = Math.max(0, Math.min(100, data[j]))
                              var ly = height - (v / 100 * height)
                              if (j === 0) ctx.moveTo(0, ly)
                              else ctx.lineTo(j * step, ly)
                            }
                            ctx.strokeStyle = "#60cdff"
                            ctx.lineWidth = 2
                            ctx.stroke()
                          }
                        }
                      }

                      // Hardware Specifications Details Grid
                      GridLayout {
                        Layout.fillWidth: true
                        columns: 4
                        rowSpacing: 12
                        columnSpacing: 20

                        ColumnLayout {
                          spacing: 2
                          Text { text: "Utilization"; font.family: "Segoe UI"; font.pixelSize: 10; color: Qt.rgba(1, 1, 1, 0.5) }
                          Text { text: Math.round(taskManagerWindow.overallCpu) + "%"; font.family: "Segoe UI"; font.pixelSize: 18; font.bold: true; color: "#ffffff" }
                        }
                        ColumnLayout {
                          spacing: 2
                          Text { text: "Speed"; font.family: "Segoe UI"; font.pixelSize: 10; color: Qt.rgba(1, 1, 1, 0.5) }
                          Text { text: taskManagerWindow.cpuFreq + " GHz"; font.family: "Segoe UI"; font.pixelSize: 18; font.bold: true; color: "#ffffff" }
                        }
                        ColumnLayout {
                          spacing: 2
                          Text { text: "Processes"; font.family: "Segoe UI"; font.pixelSize: 10; color: Qt.rgba(1, 1, 1, 0.5) }
                          Text { text: String(taskManagerWindow.totalProcesses); font.family: "Segoe UI"; font.pixelSize: 18; font.bold: true; color: "#ffffff" }
                        }
                        ColumnLayout {
                          spacing: 2
                          Text { text: "Up time"; font.family: "Segoe UI"; font.pixelSize: 10; color: Qt.rgba(1, 1, 1, 0.5) }
                          Text { text: taskManagerWindow.formatUptime(taskManagerWindow.uptimeSeconds); font.family: "Segoe UI"; font.pixelSize: 18; font.bold: true; color: "#ffffff" }
                        }

                        ColumnLayout {
                          spacing: 2
                          Text { text: "Sockets"; font.family: "Segoe UI"; font.pixelSize: 10; color: Qt.rgba(1, 1, 1, 0.5) }
                          Text { text: "1"; font.family: "Segoe UI"; font.pixelSize: 13; color: "#ffffff" }
                        }
                        ColumnLayout {
                          spacing: 2
                          Text { text: "Cores"; font.family: "Segoe UI"; font.pixelSize: 10; color: Qt.rgba(1, 1, 1, 0.5) }
                          Text { text: String(taskManagerWindow.physicalCores); font.family: "Segoe UI"; font.pixelSize: 13; color: "#ffffff" }
                        }
                        ColumnLayout {
                          spacing: 2
                          Text { text: "Logical processors"; font.family: "Segoe UI"; font.pixelSize: 10; color: Qt.rgba(1, 1, 1, 0.5) }
                          Text { text: String(taskManagerWindow.logicalThreads); font.family: "Segoe UI"; font.pixelSize: 13; color: "#ffffff" }
                        }
                        ColumnLayout {
                          spacing: 2
                          Text { text: "Virtualization"; font.family: "Segoe UI"; font.pixelSize: 10; color: Qt.rgba(1, 1, 1, 0.5) }
                          Text { text: "Enabled"; font.family: "Segoe UI"; font.pixelSize: 13; color: "#60cdff" }
                        }
                      }

                      Item { Layout.fillHeight: true }
                    }

                    // View 2: Memory Details & Live Chart
                    ColumnLayout {
                      visible: taskManagerWindow.performanceTab === "memory" || taskManagerWindow.performanceTab === "disk"
                      Layout.fillWidth: true
                      Layout.fillHeight: true
                      spacing: 14

                      RowLayout {
                        Layout.fillWidth: true
                        ColumnLayout {
                          spacing: 2
                          Text { text: "Memory"; font.family: "Segoe UI"; font.pixelSize: 22; font.bold: true; color: "#ffffff" }
                          Text { text: taskManagerWindow.memTotalGb + " GB RAM"; font.family: "Segoe UI"; font.pixelSize: 11; color: Qt.rgba(1, 1, 1, 0.5) }
                        }
                        Item { Layout.fillWidth: true }
                        Text { text: taskManagerWindow.memUsedGb + " GB In use"; font.family: "Segoe UI"; font.pixelSize: 14; font.bold: true; color: "#60cdff" }
                      }

                      // Memory Canvas Graph
                      Rectangle {
                        Layout.fillWidth: true
                        Layout.preferredHeight: 180
                        radius: 6
                        color: Qt.rgba(0.06, 0.07, 0.09, 0.95)
                        border.color: Qt.rgba(1, 1, 1, 0.12)
                        border.width: 1
                        clip: true

                        Canvas {
                          id: memCanvas
                          anchors.fill: parent
                          anchors.margins: 4

                          onPaint: {
                            var ctx = getContext("2d")
                            ctx.clearRect(0, 0, width, height)

                            ctx.strokeStyle = Qt.rgba(1, 1, 1, 0.08)
                            ctx.lineWidth = 1
                            for (var y = 1; y < 4; y++) {
                              var gy = (height / 4) * y
                              ctx.beginPath()
                              ctx.moveTo(0, gy)
                              ctx.lineTo(width, gy)
                              ctx.stroke()
                            }

                            var data = taskManagerWindow.memHistory
                            if (!data || data.length < 2) return

                            var step = width / (data.length - 1)
                            ctx.beginPath()
                            ctx.moveTo(0, height)

                            for (var i = 0; i < data.length; i++) {
                              var val = Math.max(0, Math.min(100, data[i]))
                              var py = height - (val / 100 * height)
                              ctx.lineTo(i * step, py)
                            }
                            ctx.lineTo(width, height)
                            ctx.closePath()

                            ctx.fillStyle = Qt.rgba(0.5, 0.2, 0.8, 0.20)
                            ctx.fill()

                            ctx.beginPath()
                            for (var j = 0; j < data.length; j++) {
                              var v = Math.max(0, Math.min(100, data[j]))
                              var ly = height - (v / 100 * height)
                              if (j === 0) ctx.moveTo(0, ly)
                              else ctx.lineTo(j * step, ly)
                            }
                            ctx.strokeStyle = "#b146c2"
                            ctx.lineWidth = 2
                            ctx.stroke()
                          }
                        }
                      }

                      GridLayout {
                        Layout.fillWidth: true
                        columns: 3
                        rowSpacing: 12
                        columnSpacing: 20

                        ColumnLayout {
                          spacing: 2
                          Text { text: "In use"; font.family: "Segoe UI"; font.pixelSize: 10; color: Qt.rgba(1, 1, 1, 0.5) }
                          Text { text: taskManagerWindow.memUsedGb + " GB"; font.family: "Segoe UI"; font.pixelSize: 18; font.bold: true; color: "#ffffff" }
                        }
                        ColumnLayout {
                          spacing: 2
                          Text { text: "Available"; font.family: "Segoe UI"; font.pixelSize: 10; color: Qt.rgba(1, 1, 1, 0.5) }
                          Text { text: taskManagerWindow.memAvailGb + " GB"; font.family: "Segoe UI"; font.pixelSize: 18; font.bold: true; color: "#ffffff" }
                        }
                        ColumnLayout {
                          spacing: 2
                          Text { text: "Swap used"; font.family: "Segoe UI"; font.pixelSize: 10; color: Qt.rgba(1, 1, 1, 0.5) }
                          Text { text: taskManagerWindow.swapUsedGb + " GB"; font.family: "Segoe UI"; font.pixelSize: 18; font.bold: true; color: "#ffffff" }
                        }
                      }

                      Item { Layout.fillHeight: true }
                    }
                  }
                }
              }
            }

            // PAGE 3: SERVICES TAB
            Item {
              visible: taskManagerWindow.activeTab === "services"
              Layout.fillWidth: true
              Layout.fillHeight: true

              ColumnLayout {
                anchors.fill: parent
                anchors.margins: 14
                spacing: 12

                Text {
                  text: "Systemd Services"
                  font.family: "Segoe UI"
                  font.pixelSize: 16
                  font.bold: true
                  color: "#ffffff"
                }

                Rectangle {
                  Layout.fillWidth: true
                  Layout.fillHeight: true
                  radius: 6
                  color: Qt.rgba(0.09, 0.10, 0.13, 0.98)
                  border.color: Qt.rgba(1, 1, 1, 0.08)
                  border.width: 1

                  ColumnLayout {
                    anchors.centerIn: parent
                    spacing: 8
                    Text { text: "🛠️"; font.pixelSize: 32; Layout.alignment: Qt.AlignHCenter }
                    Text { text: "Manage User & System Services"; font.family: "Segoe UI"; font.pixelSize: 14; font.bold: true; color: "#ffffff"; Layout.alignment: Qt.AlignHCenter }
                    Text { text: "Run systemctl commands or restart desktop units"; font.family: "Segoe UI"; font.pixelSize: 11; color: Qt.rgba(1, 1, 1, 0.5); Layout.alignment: Qt.AlignHCenter }

                    Rectangle {
                      Layout.alignment: Qt.AlignHCenter
                      implicitWidth: 150
                      implicitHeight: 32
                      radius: 4
                      color: "#0078d4"
                      Text { anchors.centerIn: parent; text: "Open systemctl"; font.family: "Segoe UI"; font.pixelSize: 11; font.bold: true; color: "#ffffff" }
                      MouseArea {
                        anchors.fill: parent
                        onClicked: Quickshell.execDetached(["xdg-terminal-exec", "-e", "systemctl", "--user", "status"])
                      }
                    }
                  }
                }
              }
            }
          }
        }
      }

      // Context Menu Popup for Processes
      Rectangle {
        id: procContextMenu
        visible: taskManagerWindow.showContextMenu && taskManagerWindow.contextProcess !== null
        x: Math.min(mainFrame.width - width - 10, Math.max(10, taskManagerWindow.contextMenuPos.x))
        y: Math.min(mainFrame.height - height - 10, Math.max(10, taskManagerWindow.contextMenuPos.y))
        width: 200
        height: ctxMenuCol.implicitHeight + 16
        radius: 6
        color: Qt.rgba(0.14, 0.15, 0.19, 0.98)
        border.color: Qt.rgba(1, 1, 1, 0.18)
        border.width: 1
        z: 999

        ColumnLayout {
          id: ctxMenuCol
          anchors.fill: parent
          anchors.margins: 8
          spacing: 4

          Text {
            text: taskManagerWindow.contextProcess ? (taskManagerWindow.contextProcess.name || "Process") : ""
            font.family: "Segoe UI"
            font.pixelSize: 11
            font.bold: true
            color: "#60cdff"
            Layout.fillWidth: true
            elide: Text.ElideRight
          }

          Rectangle { Layout.fillWidth: true; Layout.preferredHeight: 1; color: Qt.rgba(1, 1, 1, 0.10) }

          // Switch to window (if graphical app)
          Rectangle {
            visible: taskManagerWindow.contextProcess && taskManagerWindow.contextProcess.address
            Layout.fillWidth: true
            Layout.preferredHeight: 26
            radius: 4
            color: ctxSwM.containsMouse ? Qt.rgba(1, 1, 1, 0.12) : "transparent"
            Text { anchors.left: parent.left; anchors.leftMargin: 8; anchors.verticalCenter: parent.verticalCenter; text: "Switch to window"; font.family: "Segoe UI"; font.pixelSize: 11; color: "#ffffff" }
            MouseArea { id: ctxSwM; anchors.fill: parent; hoverEnabled: true; onClicked: taskManagerWindow.switchToWindow(taskManagerWindow.contextProcess) }
          }

          // End Task (SIGTERM)
          Rectangle {
            Layout.fillWidth: true
            Layout.preferredHeight: 26
            radius: 4
            color: ctxEndM.containsMouse ? "#c42b1c" : "transparent"
            Text { anchors.left: parent.left; anchors.leftMargin: 8; anchors.verticalCenter: parent.verticalCenter; text: "End task"; font.family: "Segoe UI"; font.pixelSize: 11; color: "#ffffff" }
            MouseArea { id: ctxEndM; anchors.fill: parent; hoverEnabled: true; onClicked: taskManagerWindow.endTask(taskManagerWindow.contextProcess, false) }
          }

          // Force Kill (SIGKILL)
          Rectangle {
            Layout.fillWidth: true
            Layout.preferredHeight: 26
            radius: 4
            color: ctxKillM.containsMouse ? "#c42b1c" : "transparent"
            Text { anchors.left: parent.left; anchors.leftMargin: 8; anchors.verticalCenter: parent.verticalCenter; text: "Force kill (SIGKILL)"; font.family: "Segoe UI"; font.pixelSize: 11; color: "#ffffff" }
            MouseArea { id: ctxKillM; anchors.fill: parent; hoverEnabled: true; onClicked: taskManagerWindow.endTask(taskManagerWindow.contextProcess, true) }
          }
        }
      }

      // Modal Dialog: "Run New Task" (Windows 11 Create Task Dialog)
      Rectangle {
        visible: taskManagerWindow.showRunDialog
        anchors.fill: parent
        color: Qt.rgba(0, 0, 0, 0.65)
        z: 1000

        MouseArea { anchors.fill: parent; onClicked: {} } // Block clicks underneath

        Rectangle {
          anchors.centerIn: parent
          width: 440
          height: 220
          radius: 8
          color: Qt.rgba(0.14, 0.15, 0.20, 0.98)
          border.color: Qt.rgba(1, 1, 1, 0.18)
          border.width: 1

          ColumnLayout {
            anchors.fill: parent
            anchors.margins: 16
            spacing: 12

            RowLayout {
              Layout.fillWidth: true
              Text { text: "Create new task"; font.family: "Segoe UI"; font.pixelSize: 14; font.bold: true; color: "#ffffff" }
              Item { Layout.fillWidth: true }
              Rectangle {
                width: 24; height: 24; radius: 12
                color: runCloseM.containsMouse ? Qt.rgba(1, 1, 1, 0.15) : "transparent"
                Text { anchors.centerIn: parent; text: "✕"; font.pixelSize: 10; color: "#ffffff" }
                MouseArea { id: runCloseM; anchors.fill: parent; hoverEnabled: true; onClicked: taskManagerWindow.showRunDialog = false }
              }
            }

            Text {
              text: "Type the name of a program, folder, document, or Internet resource, and Omarchy will open it for you."
              font.family: "Segoe UI"
              font.pixelSize: 11
              color: Qt.rgba(1, 1, 1, 0.7)
              wrapMode: Text.WordWrap
              Layout.fillWidth: true
            }

            RowLayout {
              Layout.fillWidth: true
              spacing: 8
              Text { text: "Open:"; font.family: "Segoe UI"; font.pixelSize: 11; color: "#ffffff" }
              Rectangle {
                Layout.fillWidth: true
                Layout.preferredHeight: 30
                radius: 4
                color: Qt.rgba(1, 1, 1, 0.08)
                border.color: runInput.activeFocus ? "#60cdff" : Qt.rgba(1, 1, 1, 0.14)
                border.width: 1

                TextInput {
                  id: runInput
                  anchors.fill: parent
                  anchors.margins: 6
                  color: "#ffffff"
                  font.family: "Segoe UI"
                  font.pixelSize: 12
                  selectByMouse: true
                  onAccepted: taskManagerWindow.executeNewTask(text, taskManagerWindow.runAsAdmin)
                }
              }
            }

            // Checkbox: Run with administrative privileges
            RowLayout {
              spacing: 8
              Rectangle {
                width: 16; height: 16; radius: 3
                color: taskManagerWindow.runAsAdmin ? "#0078d4" : Qt.rgba(1, 1, 1, 0.10)
                border.color: Qt.rgba(1, 1, 1, 0.25)
                border.width: 1
                Text { anchors.centerIn: parent; text: "✓"; font.pixelSize: 10; color: "#ffffff"; visible: taskManagerWindow.runAsAdmin }
                MouseArea { anchors.fill: parent; onClicked: taskManagerWindow.runAsAdmin = !taskManagerWindow.runAsAdmin }
              }
              Text {
                text: "Create this task with administrative privileges"
                font.family: "Segoe UI"
                font.pixelSize: 11
                color: Qt.rgba(1, 1, 1, 0.8)
              }
            }

            Item { Layout.fillHeight: true }

            RowLayout {
              Layout.fillWidth: true
              Item { Layout.fillWidth: true }
              Rectangle {
                implicitWidth: 80; implicitHeight: 28; radius: 4
                color: "#0078d4"
                Text { anchors.centerIn: parent; text: "OK"; font.family: "Segoe UI"; font.pixelSize: 11; font.bold: true; color: "#ffffff" }
                MouseArea { anchors.fill: parent; onClicked: taskManagerWindow.executeNewTask(runInput.text, taskManagerWindow.runAsAdmin) }
              }
              Rectangle {
                implicitWidth: 80; implicitHeight: 28; radius: 4
                color: Qt.rgba(1, 1, 1, 0.08)
                border.color: Qt.rgba(1, 1, 1, 0.15); border.width: 1
                Text { anchors.centerIn: parent; text: "Cancel"; font.family: "Segoe UI"; font.pixelSize: 11; color: "#ffffff" }
                MouseArea { anchors.fill: parent; onClicked: taskManagerWindow.showRunDialog = false }
              }
            }
          }
        }
      }
    }
  }
}

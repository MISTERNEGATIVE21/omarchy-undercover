import Quickshell
import QtQuick

ShellRoot {
  id: shellRoot

  Timer {
    id: exitTimer
    interval: 350
    repeat: false
    onTriggered: {
      var pidFile = (Quickshell.env("XDG_RUNTIME_DIR") || "/tmp") + "/omarchy-mac-stagemanager.pid"
      Quickshell.execDetached(["rm", "-f", pidFile])
      Quickshell.execDetached(["kill", String(Quickshell.processId)])
    }
  }

  StageManager {
    id: stageManager
    Component.onCompleted: {
      stageManager.open("{}")
    }
    onOpenedChanged: {
      if (!opened) {
        exitTimer.restart()
      } else {
        exitTimer.stop()
      }
    }
  }
}


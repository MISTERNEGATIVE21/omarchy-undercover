import Quickshell
import QtQuick

ShellRoot {
  id: shellRoot

  StageManager {
    id: stageManager
    Component.onCompleted: {
      stageManager.open("{}")
    }
    onOpenedChanged: {
      if (!opened) {
        var pidFile = (Quickshell.env("XDG_RUNTIME_DIR") || "/tmp") + "/omarchy-mac-stagemanager.pid"
        Quickshell.execDetached(["rm", "-f", pidFile])
        Quickshell.execDetached(["kill", String(Quickshell.processId)])
      }
    }
  }
}

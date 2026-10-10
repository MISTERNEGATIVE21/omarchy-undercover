#!/usr/bin/env bash
# =============================================================================
# Test: Windows 11 Task Manager Controls and Keybindings
# =============================================================================
set -euo pipefail

REPO_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"

# 1. Keybinding in windows-mode.lua
LUA_FILE="$REPO_DIR/configs/hypr/windows-mode.lua"
if ! grep -q "CTRL + SHIFT + ESCAPE" "$LUA_FILE" || ! grep -q "omarchy-win11-taskmanager" "$LUA_FILE"; then
  echo "FAIL: Ctrl+Shift+Escape keybinding missing from windows-mode.lua" >&2
  exit 1
fi

# 2. Keybinding in windows-mode.conf
CONF_FILE="$REPO_DIR/configs/hypr/windows-mode.conf"
if ! grep -q "CTRL SHIFT, Escape" "$CONF_FILE" || ! grep -q "omarchy-win11-taskmanager" "$CONF_FILE"; then
  echo "FAIL: Ctrl+Shift+Escape keybinding missing from windows-mode.conf" >&2
  exit 1
fi

# 3. Taskbar & Start menu right click in config-win.jsonc
WAYBAR_WIN="$REPO_DIR/configs/waybar/config-win.jsonc"
if ! grep -A 8 '"custom/startmenu"' "$WAYBAR_WIN" | grep -q "omarchy-win11-taskmanager"; then
  echo "FAIL: on-click-right to Task Manager missing from custom/startmenu in config-win.jsonc" >&2
  exit 1
fi

# 4. Window controls in win11-taskmanager/shell.qml
TM_QML="$REPO_DIR/configs/quickshell/win11-taskmanager/shell.qml"
if ! grep -q "property bool isMaximized" "$TM_QML"; then
  echo "FAIL: isMaximized property missing from win11-taskmanager/shell.qml" >&2
  exit 1
fi

if ! grep -q "🗗" "$TM_QML"; then
  echo "FAIL: restore symbol 🗗 missing from win11-taskmanager/shell.qml" >&2
  exit 1
fi

# 5. Taskbar right-click decoupling and Notepad omawrite integration
TASKBAR_QML="$REPO_DIR/widgets/win11-taskbar.qml"
START_QML="$REPO_DIR/configs/quickshell/win11-start/shell.qml"
START_MENU="$REPO_DIR/scripts/omarchy-win11-startmenu"

if grep -q "omarchy-win11-taskmanager" "$TASKBAR_QML"; then
  echo "FAIL: widgets/win11-taskbar.qml still contains fallback to omarchy-win11-taskmanager on pinned items" >&2
  exit 1
fi

if ! grep -q 'id: "notepad".*omawrite' "$TASKBAR_QML"; then
  echo "FAIL: widgets/win11-taskbar.qml Notepad entry does not use omawrite" >&2
  exit 1
fi

if ! grep -q 'name: "Notepad".*omawrite' "$START_QML"; then
  echo "FAIL: configs/quickshell/win11-start/shell.qml Notepad entry does not use omawrite" >&2
  exit 1
fi

if ! grep -q 'Notepad.*omawrite' "$START_MENU"; then
  echo "FAIL: scripts/omarchy-win11-startmenu Notepad entry does not use omawrite" >&2
  exit 1
fi

# 6. Windows 11 Task View virtual desktops and search
TASKVIEW_QML="$REPO_DIR/configs/quickshell/win11-taskview/shell.qml"
if ! grep -q "function createNewDesktop" "$TASKVIEW_QML" || ! grep -q "workspace empty" "$TASKVIEW_QML"; then
  echo "FAIL: createNewDesktop with 'workspace empty' dispatcher missing from win11-taskview/shell.qml" >&2
  exit 1
fi

if ! grep -q "function closeDesktop" "$TASKVIEW_QML" || ! grep -q "movetoworkspacesilent" "$TASKVIEW_QML"; then
  echo "FAIL: closeDesktop with 'movetoworkspacesilent' dispatcher missing from win11-taskview/shell.qml" >&2
  exit 1
fi

if ! grep -q "searchQuery" "$TASKVIEW_QML" || ! grep -q "visibleClients" "$TASKVIEW_QML"; then
  echo "FAIL: Task View search query filtering missing from win11-taskview/shell.qml" >&2
  exit 1
fi

# 7. Windows 11 Task Manager process filtering & window controls
if ! grep -q "function endTask" "$TM_QML" || ! grep -q "function switchToWindow" "$TM_QML"; then
  echo "FAIL: endTask or switchToWindow functions missing from win11-taskmanager/shell.qml" >&2
  exit 1
fi

if ! grep -q "searchQuery" "$TM_QML"; then
  echo "FAIL: Task Manager searchQuery missing from win11-taskmanager/shell.qml" >&2
  exit 1
fi

# 8. Windows 11 Taskbar Multi-instance Preview Controls
if ! grep -q "closeClient" "$TASKBAR_QML" || ! grep -q "isThumbFocused" "$TASKBAR_QML"; then
  echo "FAIL: Taskbar multi-instance closeClient or focus tracking missing from widgets/win11-taskbar.qml" >&2
  exit 1
fi

# 9. Syntax validation with Quickshell
QS_OUT=$(timeout 1.5s quickshell -p "$REPO_DIR/configs/quickshell/win11-taskmanager" 2>&1 || true)
if echo "$QS_OUT" | grep -iE "syntax error|fatal|cannot load"; then
  echo "FAIL: Quickshell failed to load Windows 11 Task Manager QML:" >&2
  echo "$QS_OUT" >&2
  exit 1
fi

QS_TV_OUT=$(timeout 1.5s quickshell -p "$REPO_DIR/configs/quickshell/win11-taskview" 2>&1 || true)
if echo "$QS_TV_OUT" | grep -iE "syntax error|fatal|cannot load"; then
  echo "FAIL: Quickshell failed to load Windows 11 Task View QML:" >&2
  echo "$QS_TV_OUT" >&2
  exit 1
fi

echo "PASS: Windows 11 Task Manager controls, bindings, and context menus verified."
exit 0

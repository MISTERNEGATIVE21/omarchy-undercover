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

# 5. Syntax validation with Quickshell
QS_OUT=$(timeout 1.5s quickshell -p "$REPO_DIR/configs/quickshell/win11-taskmanager" 2>&1 || true)
if echo "$QS_OUT" | grep -iE "syntax error|fatal|cannot load"; then
  echo "FAIL: Quickshell failed to load Windows 11 Task Manager QML:" >&2
  echo "$QS_OUT" >&2
  exit 1
fi

echo "PASS: Windows 11 Task Manager controls, bindings, and context menus verified."
exit 0

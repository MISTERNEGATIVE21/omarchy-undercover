#!/usr/bin/env bash
# ==============================================================================
# Test Undercover Toggle Shortcut Key, Reconfigurability, and Normal Bar Widget
# ==============================================================================
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
REPO_ROOT="$(cd "$SCRIPT_DIR/.." && pwd)"

echo "=== 1. Testing BIND_UNDERCOVER_TOGGLE presence and syntax in configs ==="
grep -q "BIND_UNDERCOVER_TOGGLE=" "$REPO_ROOT/settings.conf" || {
    echo "ERROR: BIND_UNDERCOVER_TOGGLE missing in settings.conf" >&2
    exit 1
}

grep -q "BIND_UNDERCOVER_TOGGLE" "$REPO_ROOT/configs/hypr/undercover.lua" || {
    echo "ERROR: BIND_UNDERCOVER_TOGGLE missing in undercover.lua" >&2
    exit 1
}

grep -q "BIND_UNDERCOVER_TOGGLE" "$REPO_ROOT/configs/hypr/mac-mode.lua" || {
    echo "ERROR: BIND_UNDERCOVER_TOGGLE missing in mac-mode.lua" >&2
    exit 1
}

grep -q "BIND_UNDERCOVER_TOGGLE" "$REPO_ROOT/configs/hypr/windows-mode.lua" || {
    echo "ERROR: BIND_UNDERCOVER_TOGGLE missing in windows-mode.lua" >&2
    exit 1
}
echo "✔ All Hyprland configurations dynamically reference BIND_UNDERCOVER_TOGGLE."

echo "=== 2. Validating Lua syntax of all Hyprland toggle scripts ==="
luac -p "$REPO_ROOT/configs/hypr/undercover.lua"
luac -p "$REPO_ROOT/configs/hypr/mac-mode.lua"
luac -p "$REPO_ROOT/configs/hypr/windows-mode.lua"
echo "✔ Lua syntax valid."

echo "=== 3. Testing binary in PATH (~/.local/bin/omarchy-undercover) ==="
if [[ ! -x "$HOME/.local/bin/omarchy-undercover" ]]; then
    echo "ERROR: ~/.local/bin/omarchy-undercover is missing or not executable" >&2
    exit 1
fi
echo "✔ omarchy-undercover is available in PATH."

echo "=== 4. Verifying disable_undercover_hyprland preserves undercover.lua ==="
grep -q "enable_undercover_hyprland \"omarchy\"" "$REPO_ROOT/scripts/common.sh" || {
    echo "ERROR: disable_undercover_hyprland does not keep undercover.lua enabled in toggles" >&2
    exit 1
}
echo "✔ disable_undercover_hyprland preserves toggle shortcut in Omarchy mode."

echo "=== 5. Verifying Widget.qml and Panel.qml normal mode configurations ==="
grep -q "toggleShortcut" "$REPO_ROOT/Widget.qml" || {
    echo "ERROR: toggleShortcut property missing in Widget.qml" >&2
    exit 1
}
grep -q "toggleShortcut" "$REPO_ROOT/Panel.qml" || {
    echo "ERROR: toggleShortcut property missing in Panel.qml" >&2
    exit 1
}
grep -q "icon.svg" "$REPO_ROOT/Widget.qml" || {
    echo "ERROR: icon.svg emblem missing in Widget.qml" >&2
    exit 1
}
echo "✔ Widget.qml and Panel.qml have Undercover normal mode branding and shortcuts."

echo "=== 6. Verifying omarchy-undercover-settings GUI shortcut customization ==="
grep -q "BIND_UNDERCOVER_TOGGLE" "$REPO_ROOT/scripts/omarchy-undercover-settings" || {
    echo "ERROR: BIND_UNDERCOVER_TOGGLE missing in omarchy-undercover-settings" >&2
    exit 1
}
echo "✔ omarchy-undercover-settings supports reconfiguring toggle shortcut."

echo "=== 7. Verifying Bar Widget Placement and Stealth in Camouflage Mode ==="
"$REPO_ROOT/scripts/omarchy-undercover" --bar-position right
grep -q "^BAR_POSITION=right" "$REPO_ROOT/settings.conf" || {
    echo "ERROR: BAR_POSITION not updated in settings.conf" >&2
    exit 1
}
jq -e '.bar.layout.right[] | select(.id == "omarchy-undercover")' "$HOME/.config/omarchy/shell.json" >/dev/null || {
    echo "ERROR: omarchy-undercover missing from bar.layout.right in shell.json" >&2
    exit 1
}
echo "✔ omarchy-undercover correctly positioned on right of bar in normal mode."

"$REPO_ROOT/scripts/omarchy-undercover" --bar-position left
grep -q "^BAR_POSITION=left" "$REPO_ROOT/settings.conf" || {
    echo "ERROR: BAR_POSITION left not updated in settings.conf" >&2
    exit 1
}
jq -e '.bar.layout.left[] | select(.id == "omarchy-undercover")' "$HOME/.config/omarchy/shell.json" >/dev/null || {
    echo "ERROR: omarchy-undercover missing from bar.layout.left in shell.json" >&2
    exit 1
}
echo "✔ omarchy-undercover correctly moved to left of bar."

# Restore user preferred right placement
"$REPO_ROOT/scripts/omarchy-undercover" --bar-position right

# Verify stealth in undercover configs and Widget.qml
grep -q 'visible: root.currentMode === "omarchy"' "$REPO_ROOT/Widget.qml" || {
    echo "ERROR: Widget.qml does not enforce visible only in omarchy mode" >&2
    exit 1
}
if jq -e '.bar.layout[]? | .. | objects | select(.id == "omarchy-undercover")' "$REPO_ROOT/configs/shell/shell-mac.json" >/dev/null 2>&1; then
    echo "ERROR: omarchy-undercover leaked into shell-mac.json" >&2
    exit 1
fi
if jq -e '.bar.layout[]? | .. | objects | select(.id == "omarchy-undercover")' "$REPO_ROOT/configs/shell/shell-win.json" >/dev/null 2>&1; then
    echo "ERROR: omarchy-undercover leaked into shell-win.json" >&2
    exit 1
fi
echo "✔ Undercover mode status bar configs are 100% stealthy (omarchy-undercover omitted)."

echo "=== ALL TOGGLE, SHORTCUT & BAR PLACEMENT TESTS PASSED CLEANLY! ==="


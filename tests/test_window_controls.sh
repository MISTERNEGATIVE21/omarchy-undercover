#!/usr/bin/env bash
# =============================================================================
# Test: Window Navigation Controls Across macOS, Windows 11 & GTK
# =============================================================================
set -euo pipefail

REPO_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
MAC_SETTINGS="$REPO_DIR/configs/quickshell/mac-settings/shell.qml"
WIN_SETTINGS="$REPO_DIR/configs/quickshell/win11-settings/shell.qml"
UNDERCOVER_SH="$REPO_DIR/scripts/omarchy-undercover"

# 1. macOS Settings Traffic Lights
if ! grep -q "isMaximized" "$MAC_SETTINGS"; then
  echo "FAIL: mac-settings missing isMaximized property" >&2
  exit 1
fi

if ! grep -A 10 "id: zoomM" "$MAC_SETTINGS" | grep -q "isMaximized"; then
  echo "FAIL: mac-settings zoomM does not toggle isMaximized" >&2
  exit 1
fi

if ! grep -A 10 "id: minM" "$MAC_SETTINGS" | grep -q "special:minimized"; then
  echo "FAIL: mac-settings minM missing special:minimized dispatch" >&2
  exit 1
fi

# 2. Windows 11 Settings Controls
if ! grep -q "isMaximized" "$WIN_SETTINGS"; then
  echo "FAIL: win11-settings missing isMaximized property" >&2
  exit 1
fi

if ! grep -A 10 "id: maxMouse" "$WIN_SETTINGS" | grep -q "isMaximized"; then
  echo "FAIL: win11-settings maxMouse does not toggle isMaximized" >&2
  exit 1
fi

if ! grep -B 5 -A 15 "id: maxMouse" "$WIN_SETTINGS" | grep -qE "🗗|□"; then
  echo "FAIL: win11-settings maxMouse missing restore glyph (🗗 or □)" >&2
  exit 1
fi

if ! grep -A 10 "id: minMouse" "$WIN_SETTINGS" | grep -q "special:minimized"; then
  echo "FAIL: win11-settings minMouse missing special:minimized dispatch" >&2
  exit 1
fi

# 3. GTK / gsettings Button Layout Enforcement in omarchy-undercover
if ! grep -q 'button-layout "close,minimize,maximize:"' "$UNDERCOVER_SH"; then
  echo "FAIL: omarchy-undercover missing macOS button-layout setting" >&2
  exit 1
fi

if ! grep -q 'button-layout ":minimize,maximize,close"' "$UNDERCOVER_SH"; then
  echo "FAIL: omarchy-undercover missing Windows 11 button-layout setting" >&2
  exit 1
fi

# 4. Hyprbars Free Roam / Floating Window Controls (macOS Traffic Lights)
MAC_HYPR="$REPO_DIR/configs/hypr/mac-mode.lua"
if ! grep -q 'bar_buttons_alignment = "left"' "$MAC_HYPR"; then
  echo "FAIL: mac-mode.lua missing bar_buttons_alignment = 'left'" >&2
  exit 1
fi

if ! grep -q 'button_rounding = 10' "$MAC_HYPR"; then
  echo "FAIL: mac-mode.lua missing circular button_rounding" >&2
  exit 1
fi

if ! grep -q 'bar_text_align = "center"' "$MAC_HYPR"; then
  echo "FAIL: mac-mode.lua missing centered bar_text_align" >&2
  exit 1
fi

if ! grep -q 'icon_on_hover = true' "$MAC_HYPR"; then
  echo "FAIL: mac-mode.lua missing icon_on_hover = true" >&2
  exit 1
fi

for color in "rgb(ff5f56)" "rgb(ffbd2e)" "rgb(27c93f)"; do
  if ! grep -q "$color" "$MAC_HYPR"; then
    echo "FAIL: mac-mode.lua missing traffic light color $color" >&2
    exit 1
  fi
done

# 5. Hyprbars Free Roam / Floating Window Controls (Windows 11 Controls)
WIN_HYPR="$REPO_DIR/configs/hypr/windows-mode.lua"
if ! grep -q 'bar_buttons_alignment = "right"' "$WIN_HYPR"; then
  echo "FAIL: windows-mode.lua missing bar_buttons_alignment = 'right'" >&2
  exit 1
fi

if ! grep -q 'button_rounding = 0' "$WIN_HYPR"; then
  echo "FAIL: windows-mode.lua missing square button_rounding = 0" >&2
  exit 1
fi

if ! grep -q 'bar_text_align = "left"' "$WIN_HYPR"; then
  echo "FAIL: windows-mode.lua missing left-aligned bar_text_align" >&2
  exit 1
fi

if ! grep -q 'icon_on_hover = false' "$WIN_HYPR"; then
  echo "FAIL: windows-mode.lua missing icon_on_hover = false" >&2
  exit 1
fi

for icon in "×" "□" "−"; do
  if ! grep -q "icon = \"$icon\"" "$WIN_HYPR"; then
    echo "FAIL: windows-mode.lua missing window control icon $icon" >&2
    exit 1
  fi
done

# 6. Quickshell Syntax Validation
QS_MAC=$(timeout 1.5s quickshell -p "$REPO_DIR/configs/quickshell/mac-settings" 2>&1 || true)
if echo "$QS_MAC" | grep -iE "syntax error|fatal|cannot load"; then
  echo "FAIL: Quickshell failed to load mac-settings:" >&2
  echo "$QS_MAC" >&2
  exit 1
fi

QS_WIN=$(timeout 1.5s quickshell -p "$REPO_DIR/configs/quickshell/win11-settings" 2>&1 || true)
if echo "$QS_WIN" | grep -iE "syntax error|fatal|cannot load"; then
  echo "FAIL: Quickshell failed to load win11-settings:" >&2
  echo "$QS_WIN" >&2
  exit 1
fi

echo "PASS: Window navigation controls verified across macOS (traffic lights), Windows 11 (minimize/maximize/close), Hyprbars free roam, and GTK."
exit 0


#!/usr/bin/env bash
# =============================================================================
# Test: File Managers, Typography, Color Contrast, and Input Alignment
# =============================================================================
set -euo pipefail

REPO_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
FM_SCRIPT="$REPO_DIR/scripts/omarchy-undercover-filemanager"
UNDERCOVER_SCRIPT="$REPO_DIR/scripts/omarchy-undercover"
STYLE_MAC="$REPO_DIR/configs/waybar/style-mac.css"
STYLE_WIN="$REPO_DIR/configs/waybar/style-win.css"
MAC_CLOCK="$REPO_DIR/widgets/mac-clock.qml"
MAC_APPMENU="$REPO_DIR/widgets/mac-appmenu.qml"
FONTS_WIN="$REPO_DIR/configs/fontconfig/fonts.conf"
FONTS_MAC="$REPO_DIR/configs/fontconfig/fonts-mac.conf"

# 1. Flea UI configuration presets
if ! grep -q '"view":"columns"' "$FM_SCRIPT"; then
  echo "FAIL: omarchy-undercover-filemanager missing macOS Miller columns view preset" >&2
  exit 1
fi

if ! grep -q '"view":"list"' "$FM_SCRIPT"; then
  echo "FAIL: omarchy-undercover-filemanager missing Windows 11 Details list view preset" >&2
  exit 1
fi

if ! grep -q '"addressBar":"breadcrumb"' "$FM_SCRIPT" || ! grep -q '"addressBar":"path"' "$FM_SCRIPT"; then
  echo "FAIL: omarchy-undercover-filemanager missing addressBar configuration" >&2
  exit 1
fi

# 2. Waybar CSS Contrast and Drop Shadows
if ! grep -A 10 "window#waybar.mac-topbar" "$STYLE_MAC" | grep -q "text-shadow"; then
  echo "FAIL: style-mac.css mac-topbar missing text-shadow for light wallpaper contrast" >&2
  exit 1
fi

if ! grep -A 10 "window#waybar.win11-taskbar" "$STYLE_WIN" | grep -q "rgba(32, 32, 32, 0.96)"; then
  echo "FAIL: style-win.css win11-taskbar missing solid 96% dark acrylic background" >&2
  exit 1
fi

# 3. Clean Antialiased Topbar Widgets (no jagged Text.Outline)
if grep -q "style: Text.Outline" "$MAC_CLOCK"; then
  echo "FAIL: widgets/mac-clock.qml has jagged Text.Outline which degrades text legibility" >&2
  exit 1
fi

if grep -q "style: Text.Outline" "$MAC_APPMENU"; then
  echo "FAIL: widgets/mac-appmenu.qml has jagged Text.Outline which degrades text legibility" >&2
  exit 1
fi

# 4. Fontconfig Flea Process Mapping & Script Handlers
if ! grep -q '<test name="prgname"><string>flea</string></test>' "$FONTS_WIN" || ! grep -q '<string>Segoe UI</string>' "$FONTS_WIN"; then
  echo "FAIL: configs/fontconfig/fonts.conf missing flea monospace -> Segoe UI rule" >&2
  exit 1
fi

if [[ ! -f "$FONTS_MAC" ]]; then
  echo "FAIL: configs/fontconfig/fonts-mac.conf does not exist" >&2
  exit 1
fi

if ! grep -q '<test name="prgname"><string>flea</string></test>' "$FONTS_MAC" || ! grep -q '<string>SF Pro Text</string>' "$FONTS_MAC"; then
  echo "FAIL: configs/fontconfig/fonts-mac.conf missing flea monospace -> SF Pro Text rule" >&2
  exit 1
fi

if ! grep -q "apply_fontconfig_macos" "$UNDERCOVER_SCRIPT"; then
  echo "FAIL: scripts/omarchy-undercover missing apply_fontconfig_macos function" >&2
  exit 1
fi

if grep -q 'WINDOWS_FONT_NAME="Roboto 10.5"' "$UNDERCOVER_SCRIPT"; then
  echo "FAIL: scripts/omarchy-undercover still uses Roboto 10.5 instead of Segoe UI 10.5" >&2
  exit 1
fi

# 5. Theme Palette Contrast Standards (WCAG AA compliant)
ML_COLORS="$REPO_DIR/configs/omarchy-theme/macos-light/colors.toml"
WL_COLORS="$REPO_DIR/configs/omarchy-theme/windows11-light/colors.toml"
MD_COLORS="$REPO_DIR/configs/omarchy-theme/macos-dark/colors.toml"
WD_COLORS="$REPO_DIR/configs/omarchy-theme/windows11-dark/colors.toml"

if ! grep -q 'muted = "#636366"' "$ML_COLORS"; then
  echo "FAIL: macos-light/colors.toml muted color does not meet contrast standard (#636366)" >&2
  exit 1
fi

if ! grep -q 'muted = "#5c5c5c"' "$WL_COLORS"; then
  echo "FAIL: windows11-light/colors.toml muted color does not meet contrast standard (#5c5c5c)" >&2
  exit 1
fi

if ! grep -q 'muted = "#98989d"' "$MD_COLORS"; then
  echo "FAIL: macos-dark/colors.toml muted color does not meet contrast standard (#98989d)" >&2
  exit 1
fi

if ! grep -q 'muted = "#a0a0a0"' "$WD_COLORS"; then
  echo "FAIL: windows11-dark/colors.toml muted color does not meet contrast standard (#a0a0a0)" >&2
  exit 1
fi

ML_SHELL="$REPO_DIR/configs/omarchy-theme/macos-light/shell.toml"
WL_SHELL="$REPO_DIR/configs/omarchy-theme/windows11-light/shell.toml"

if grep -q 'selected-text = "#0071e3"' "$ML_SHELL"; then
  echo "FAIL: macos-light/shell.toml has low-contrast blue selected-text" >&2
  exit 1
fi

if grep -q 'selected-text = "#0078d4"' "$WL_SHELL"; then
  echo "FAIL: windows11-light/shell.toml has low-contrast blue selected-text" >&2
  exit 1
fi

# 6. Text Input Vertical Alignment in Quickshell Panels
for qml in \
  "$REPO_DIR/configs/quickshell/win11-start/shell.qml" \
  "$REPO_DIR/configs/quickshell/win11-wifi/shell.qml" \
  "$REPO_DIR/configs/quickshell/win11-bluetooth/shell.qml" \
  "$REPO_DIR/configs/quickshell/win11-taskmanager/shell.qml" \
  "$REPO_DIR/configs/quickshell/mac-wifi/shell.qml" \
  "$REPO_DIR/configs/quickshell/mac-bluetooth/shell.qml" \
  "$REPO_DIR/configs/quickshell/mac-activitymonitor/shell.qml"; do
  if ! grep -q -E "verticalAlignment: TextInput.AlignVCenter|anchors.verticalCenter: parent.verticalCenter" "$qml"; then
    echo "FAIL: $qml missing vertical centering (TextInput.AlignVCenter or anchors.verticalCenter)" >&2
    exit 1
  fi
done

echo "PASS: File manager presets, fontconfig, color contrast, and input alignment verified."
exit 0

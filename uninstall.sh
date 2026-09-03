#!/bin/bash
# ==============================================================================
# Omarchy Undercover Uninstaller
# Restores original Omarchy configuration, removes disguise themes & assets
# Author: misternegative21
# License: GPL-3.0-or-later
# ==============================================================================

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
BIN_DIR="$HOME/.local/bin"
CONFIG_DIR="$HOME/.config/omarchy-undercover"
APP_DIR="$HOME/.local/share/applications"

echo "=================================================="
echo "      Omarchy Undercover Uninstaller             "
echo "=================================================="
echo

# 1. Restore original configuration & default theme
echo "1. Restoring original configuration & baseline..."
if command -v omarchy-undercover &>/dev/null; then
    omarchy-undercover --restore || true
elif [ -f "$BIN_DIR/omarchy-undercover" ]; then
    "$BIN_DIR/omarchy-undercover" --restore || true
fi

# Explicitly guarantee fallback to default Omarchy desktop theme
echo "2. Restoring default Omarchy GTK, icon & cursor themes..."
if command -v gsettings &>/dev/null; then
    gsettings set org.gnome.desktop.interface gtk-theme "Adwaita" 2>/dev/null || true
    gsettings set org.gnome.desktop.interface icon-theme "Papirus-Dark" 2>/dev/null || true
    gsettings set org.gnome.desktop.interface cursor-theme "Bibata-Modern-Classic" 2>/dev/null || true
    gsettings set org.gnome.desktop.interface color-scheme "prefer-dark" 2>/dev/null || true
    gsettings set org.gnome.desktop.interface font-name "Sans 10" 2>/dev/null || true
    gsettings set org.gnome.desktop.wm.preferences button-layout ":close" 2>/dev/null || true
fi

# Clean Undercover custom GTK CSS overrides
rm -f "$HOME/.config/gtk-3.0/gtk.css" "$HOME/.config/gtk-4.0/gtk.css" 2>/dev/null || true

# 3. Remove disguise themes and icon packs
echo "3. Removing Undercover themes and icon packs..."
rm -rf "$HOME/.themes/Win11"* \
       "$HOME/.themes/WhiteSur"* \
       "$HOME/.icons/Fluent"* \
       "$HOME/.icons/WhiteSur"* 2>/dev/null || true

# 4. Remove Undercover plugins and QuickShell components
echo "4. Removing Undercover plugins & QuickShell modules..."
rm -rf "$HOME/.config/omarchy/plugins/undercover"* 2>/dev/null || true
rm -rf "$HOME/.config/quickshell/mac-"* \
       "$HOME/.config/quickshell/win11-"* 2>/dev/null || true
rm -f "$HOME/.config/rofi/windows11.rasi" \
      "$HOME/.config/rofi/macos.rasi" \
      "$HOME/.config/rofi/spotlight.rasi" 2>/dev/null || true

# 5. Remove installed binaries in ~/.local/bin
echo "5. Removing installed scripts from $BIN_DIR..."
rm -f "$BIN_DIR/omarchy-undercover"* \
      "$BIN_DIR/omarchy-win11-"* \
      "$BIN_DIR/omarchy-mac-"* \
      "$BIN_DIR/omarchy-detect-backend" \
      "$BIN_DIR/omarchy-bluetooth-manager" \
      "$BIN_DIR/omarchy-wifi-manager" \
      "$BIN_DIR/omarchy-weather" \
      "$BIN_DIR/omarchy-browser" \
      "$BIN_DIR/omarchy-play-sound" \
      "$BIN_DIR/omarchy-ios-control-center" \
      "$BIN_DIR/omarchy-autohide-dock" \
      "$BIN_DIR/common.sh" 2>/dev/null || true

# 6. Remove desktop launchers
echo "6. Removing desktop launchers..."
rm -f "$APP_DIR/omarchy-undercover"* \
      "$APP_DIR/omarchy-settings"* 2>/dev/null || true
if command -v update-desktop-database &>/dev/null; then
    update-desktop-database "$APP_DIR" >/dev/null 2>&1 || true
fi

# 7. Prompt for removal of configuration directory
if [ -d "$CONFIG_DIR" ]; then
    read -p "Do you want to remove configuration directory & state in $CONFIG_DIR? (y/N): " -n 1 -r
    echo
    if [[ $REPLY =~ ^[Yy]$ ]]; then
        rm -rf "$CONFIG_DIR"
        echo "Removed configuration directory $CONFIG_DIR."
    else
        echo "Preserved configuration directory $CONFIG_DIR."
    fi
fi

# 8. Reload Hyprland and Omarchy bar
echo "7. Reloading Hyprland and Omarchy shell..."
if command -v hyprctl &>/dev/null; then
    hyprctl reload >/dev/null 2>&1 || true
fi
pkill -HUP omarchy-shell 2>/dev/null || true

echo
echo "✔ Omarchy Undercover successfully uninstalled!"
echo "✔ Default Omarchy theme restored and all Undercover themes removed."

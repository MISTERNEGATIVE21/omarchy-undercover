#!/bin/bash
# Omarchy Undercover Uninstaller
# Restores original configuration and removes all Omarchy Undercover assets
# Author: John Varghese
# License: GPL-3.0-or-later

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
BIN_DIR="$HOME/.local/bin"
CONFIG_DIR="$HOME/.config/omarchy-undercover"
APP_DIR="$HOME/.local/share/applications"

echo "=================================================="
echo "      Omarchy Undercover Uninstaller             "
echo "=================================================="
echo

# 1. Restore original configuration if CLI available
if command -v omarchy-undercover &>/dev/null; then
    echo "Restoring original configuration..."
    omarchy-undercover --restore || true
elif [ -f "$BIN_DIR/omarchy-undercover" ]; then
    echo "Restoring original configuration via local binary..."
    "$BIN_DIR/omarchy-undercover" --restore || true
fi

# 2. Remove installed binaries in ~/.local/bin
echo "Removing installed scripts from $BIN_DIR..."
rm -f "$BIN_DIR/omarchy-undercover" \
      "$BIN_DIR/omarchy-undercover-setup" \
      "$BIN_DIR/omarchy-undercover-settings" \
      "$BIN_DIR/omarchy-undercover-launcher" \
      "$BIN_DIR/common.sh"

# 3. Remove desktop entries
echo "Removing desktop launchers..."
rm -f "$APP_DIR/omarchy-undercover.desktop" \
      "$APP_DIR/omarchy-undercover-settings.desktop"

# 4. Prompt for removal of configuration and backups
if [ -d "$CONFIG_DIR" ]; then
    read -p "Do you want to remove configuration & backups in $CONFIG_DIR? (y/N): " -n 1 -r
    echo
    if [[ $REPLY =~ ^[Yy]$ ]]; then
        rm -rf "$CONFIG_DIR"
        echo "Removed configuration directory $CONFIG_DIR."
    else
        echo "Kept configuration directory $CONFIG_DIR."
    fi
fi

echo
echo "✔ Omarchy Undercover successfully uninstalled!"

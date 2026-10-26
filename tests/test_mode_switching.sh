#!/usr/bin/env bash
# ==============================================================================
# Test mode switching options and settings presets (Tahoe & Sequoia)
# ==============================================================================
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
REPO_ROOT="$(cd "$SCRIPT_DIR/.." && pwd)"

UNDERCOVER="$REPO_ROOT/scripts/omarchy-undercover"
SETTINGS_GTK="$REPO_ROOT/scripts/omarchy-undercover-settings"
SETTINGS_QML="$REPO_ROOT/configs/quickshell/mac-settings/shell.qml"

echo "Checking omarchy-undercover CLI help..."
help_output=$("$UNDERCOVER" --help 2>&1 || true)
echo "$help_output" | grep -qi "tahoe" || { echo "ERROR: 'tahoe' not found in undercover help" >&2; exit 1; }
echo "$help_output" | grep -qi "sequoia" || { echo "ERROR: 'sequoia' not found in undercover help" >&2; exit 1; }

echo "Checking omarchy-undercover-settings WALLPAPERS list..."
grep -q "macOS-Tahoe-Dark" "$SETTINGS_GTK" || { echo "ERROR: 'macOS-Tahoe-Dark' not found in settings GTK" >&2; exit 1; }
grep -q "macOS-Tahoe-Light" "$SETTINGS_GTK" || { echo "ERROR: 'macOS-Tahoe-Light' not found in settings GTK" >&2; exit 1; }

echo "Checking mac-settings/shell.qml for Tahoe & Sequoia options..."
grep -qi "tahoe" "$SETTINGS_QML" || { echo "ERROR: 'tahoe' not found in mac-settings/shell.qml" >&2; exit 1; }
grep -qi "sequoia" "$SETTINGS_QML" || { echo "ERROR: 'sequoia' not found in mac-settings/shell.qml" >&2; exit 1; }

echo "Checking omarchy-undercover persistence flags and --startup hook..."
echo "$help_output" | grep -qi -- "--persistent" || { echo "ERROR: '--persistent' not found in undercover help" >&2; exit 1; }
echo "$help_output" | grep -qi -- "--temporary" || { echo "ERROR: '--temporary' not found in undercover help" >&2; exit 1; }
echo "$help_output" | grep -qi -- "--startup" || { echo "ERROR: '--startup' not found in undercover help" >&2; exit 1; }

source "$REPO_ROOT/scripts/common.sh"
SETTINGS_CONF="$(undercover_settings_file)"

"$UNDERCOVER" --persistent
grep -q "^DISGUISE_PERSISTENT=true" "$SETTINGS_CONF" || { echo "ERROR: DISGUISE_PERSISTENT not set to true in $SETTINGS_CONF" >&2; exit 1; }

"$UNDERCOVER" --temporary
grep -q "^DISGUISE_PERSISTENT=false" "$SETTINGS_CONF" || { echo "ERROR: DISGUISE_PERSISTENT not set to false in $SETTINGS_CONF" >&2; exit 1; }

startup_res=$("$UNDERCOVER" --startup 2>&1 || true)
if [[ "$startup_res" == *"Unknown option"* ]]; then
  echo "ERROR: --startup failed with unknown option: $startup_res" >&2
  exit 1
fi

echo "Mode switching tests passed!"

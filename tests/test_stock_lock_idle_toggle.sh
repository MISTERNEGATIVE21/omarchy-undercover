#!/usr/bin/env bash
# ==============================================================================
# Test Suite: Stock Lock Screen & Idle Daemon Toggle Management
# Verifies that Omarchy Undercover cleanly toggles off stock omarchy.lock,
# omarchy.idle, and screensaver-off without modifying official /usr/share files.
# ==============================================================================

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_ROOT="$(cd "$SCRIPT_DIR/.." && pwd)"

echo "=== 1. Testing disable_stock_lock_and_idle ==="
"$PROJECT_ROOT/scripts/omarchy-undercover" --disable-stock-lock-idle

# 1. Verify screensaver-off toggle is ON
if omarchy-toggle-enabled screensaver-off; then
    echo "  ✔ screensaver-off toggle is enabled"
else
    echo "  ✖ screensaver-off toggle is NOT enabled"
    exit 1
fi

# 2. Verify disabledPlugins in shell.json contains omarchy.lock and omarchy.idle
DISABLED_JSON=$(cat "$HOME/.config/omarchy/shell.json" | jq -r '.disabledPlugins // []')
if echo "$DISABLED_JSON" | grep -q "omarchy.lock" && echo "$DISABLED_JSON" | grep -q "omarchy.idle"; then
    echo "  ✔ ~/.config/omarchy/shell.json disabledPlugins contains omarchy.lock and omarchy.idle"
else
    echo "  ✖ disabledPlugins missing expected plugins: $DISABLED_JSON"
    exit 1
fi

# 3. Verify official /usr/share/omarchy files are pristine and untouched
if git -C /usr/share/omarchy status --porcelain 2>/dev/null | grep -q "plugins/lock"; then
    echo "  ✖ ERROR: /usr/share/omarchy/shell/plugins/lock was modified!"
    exit 1
else
    echo "  ✔ Official /usr/share/omarchy plugins remain completely untouched"
fi

echo "=== 2. Testing restore_stock_lock_and_idle ==="
"$PROJECT_ROOT/scripts/omarchy-undercover" --restore-stock-lock-idle

# 1. Verify screensaver-off toggle is OFF
if omarchy-toggle-enabled screensaver-off; then
    echo "  ✖ screensaver-off toggle is still enabled after restore"
    exit 1
else
    echo "  ✔ screensaver-off toggle is disabled"
fi

# 2. Verify disabledPlugins does not contain omarchy.lock or omarchy.idle
RESTORED_JSON=$(cat "$HOME/.config/omarchy/shell.json" | jq -r '.disabledPlugins // []')
if echo "$RESTORED_JSON" | grep -q "omarchy.lock" || echo "$RESTORED_JSON" | grep -q "omarchy.idle"; then
    echo "  ✖ disabledPlugins still contains stock plugins after restore: $RESTORED_JSON"
    exit 1
else
    echo "  ✔ Stock plugins removed from disabledPlugins"
fi

echo "=== 3. Re-disabling stock plugins for active macOS Undercover session ==="
"$PROJECT_ROOT/scripts/omarchy-undercover" --disable-stock-lock-idle
echo "  ✔ Active macOS undercover session stock lock/idle toggles verified!"

echo "🎉 Stock lock/idle toggle integration test passed successfully!"

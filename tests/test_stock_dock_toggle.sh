#!/usr/bin/env bash
# ==============================================================================
# Test Suite: Stock Floating Dock Hide & Restore Toggle Management
# Verifies that Omarchy Undercover cleanly hides the stock omarchy.dock
# on entering camouflage mode and cleanly restores it on returning to Omarchy.
# ==============================================================================

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_ROOT="$(cd "$SCRIPT_DIR/.." && pwd)"

echo "=== 1. Testing hide_stock_omarchy_dock CLI flag ==="
"$PROJECT_ROOT/scripts/omarchy-undercover" --hide-stock-dock

# 1. Verify disabledPlugins in shell.json contains omarchy.dock
DISABLED_JSON=$(cat "$HOME/.config/omarchy/shell.json" | jq -r '.disabledPlugins // []')
if echo "$DISABLED_JSON" | grep -q "omarchy.dock"; then
    echo "  ✔ omarchy.dock is present in disabledPlugins in shell.json"
else
    echo "  ✖ Failure: omarchy.dock is NOT in disabledPlugins: $DISABLED_JSON"
    exit 1
fi

# 2. Verify undercover_stock_dock_hidden state file was created
if [[ -f "$HOME/.local/state/omarchy/undercover_stock_dock_hidden" ]]; then
    echo "  ✔ State flag undercover_stock_dock_hidden exists"
else
    echo "  ✖ Failure: undercover_stock_dock_hidden state file missing"
    exit 1
fi

# 3. CRITICAL SECURITY INVARIANT:
# omarchy.lock and omarchy.idle must NEVER be in disabledPlugins
if echo "$DISABLED_JSON" | grep -q "omarchy.idle"; then
    echo "  ✖ Security failure: omarchy.idle was accidentally disabled!"
    exit 1
else
    echo "  ✔ omarchy.idle remains enabled (Automatic stock idle lock trigger preserved)"
fi

if echo "$DISABLED_JSON" | grep -q "omarchy.lock"; then
    echo "  ✖ Security failure: omarchy.lock was accidentally disabled!"
    exit 1
else
    echo "  ✔ omarchy.lock remains enabled (PAM session lock security boundary preserved)"
fi

# 4. Verify official /usr/share/omarchy files are pristine and untouched
if git -C /usr/share/omarchy status --porcelain 2>/dev/null | grep -q "plugins/dock"; then
    echo "  ✖ ERROR: /usr/share/omarchy/shell/plugins/dock was modified!"
    exit 1
else
    echo "  ✔ Official /usr/share/omarchy plugins remain completely untouched"
fi

echo "=== 2. Testing restore_stock_omarchy_dock CLI flag ==="
"$PROJECT_ROOT/scripts/omarchy-undercover" --restore-stock-dock

# 1. Verify disabledPlugins does not contain omarchy.dock
RESTORED_JSON=$(cat "$HOME/.config/omarchy/shell.json" | jq -r '.disabledPlugins // []')
if echo "$RESTORED_JSON" | grep -q "omarchy.dock"; then
    echo "  ✖ Failure: disabledPlugins still contains omarchy.dock: $RESTORED_JSON"
    exit 1
else
    echo "  ✔ omarchy.dock successfully removed from disabledPlugins"
fi

# 2. Verify state flag removed
if [[ -f "$HOME/.local/state/omarchy/undercover_stock_dock_hidden" ]]; then
    echo "  ✖ Failure: undercover_stock_dock_hidden state flag was not cleaned up"
    exit 1
else
    echo "  ✔ undercover_stock_dock_hidden state flag cleanly cleared"
fi

echo "=== 3. Testing Stock Dock Suppress in macOS Mode Switch ==="
"$PROJECT_ROOT/scripts/omarchy-undercover" -mac
MAC_DISABLED=$(cat "$HOME/.config/omarchy/shell.json" | jq -r '.disabledPlugins // []')
if echo "$MAC_DISABLED" | grep -q "omarchy.dock"; then
    echo "  ✔ macOS Undercover mode suppresses stock omarchy.dock"
else
    echo "  ✖ Failure: omarchy.dock not suppressed in macOS mode: $MAC_DISABLED"
    exit 1
fi

echo "=== 4. Testing Stock Dock Suppress in Windows 11 Mode Switch ==="
"$PROJECT_ROOT/scripts/omarchy-undercover" -w11
WIN_DISABLED=$(cat "$HOME/.config/omarchy/shell.json" | jq -r '.disabledPlugins // []')
if echo "$WIN_DISABLED" | grep -q "omarchy.dock"; then
    echo "  ✔ Windows 11 Undercover mode suppresses stock omarchy.dock"
else
    echo "  ✖ Failure: omarchy.dock not suppressed in Windows 11 mode: $WIN_DISABLED"
    exit 1
fi

echo "=== 5. Testing Stock Dock Restoration on Returning to Omarchy ==="
"$PROJECT_ROOT/scripts/omarchy-undercover" --disable
OM_DISABLED=$(cat "$HOME/.config/omarchy/shell.json" | jq -r '.disabledPlugins // []')
if echo "$OM_DISABLED" | grep -q "omarchy.dock"; then
    echo "  ✖ Failure: omarchy.dock still suppressed after returning to Omarchy: $OM_DISABLED"
    exit 1
else
    echo "  ✔ Returning to Omarchy cleanly restores stock omarchy.dock"
fi

echo "=== 6. Verifying Service.qml & Preset Configurations ==="
if grep -q "hideStockDock" "$PROJECT_ROOT/Service.qml" && grep -q "restoreStockDock" "$PROJECT_ROOT/Service.qml"; then
    echo "  ✔ Service.qml implements hideStockDock and restoreStockDock IPC endpoints"
else
    echo "  ✖ Failure: Service.qml missing hideStockDock or restoreStockDock IPC"
    exit 1
fi

if jq -e '.disabledPlugins // [] | index("omarchy.dock")' "$PROJECT_ROOT/configs/shell/shell-mac.json" >/dev/null 2>&1; then
    echo "  ✔ configs/shell/shell-mac.json has omarchy.dock in disabledPlugins"
else
    echo "  ✖ Failure: configs/shell/shell-mac.json missing disabledPlugins for omarchy.dock"
    exit 1
fi

if jq -e '.disabledPlugins // [] | index("omarchy.dock")' "$PROJECT_ROOT/configs/shell/shell-win.json" >/dev/null 2>&1; then
    echo "  ✔ configs/shell/shell-win.json has omarchy.dock in disabledPlugins"
else
    echo "  ✖ Failure: configs/shell/shell-win.json missing disabledPlugins for omarchy.dock"
    exit 1
fi

echo "=========================================================="
echo "  ✔ ALL STOCK DOCK HIDE & RESTORE TESTS PASSED CLEANLY!"
echo "=========================================================="

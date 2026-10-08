#!/usr/bin/env bash
# ==============================================================================
# End-to-End Integration Test Suite for macOS Tahoe & Stage Manager (v7.0.0)
# ==============================================================================
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
REPO_ROOT="$(cd "$SCRIPT_DIR/.." && pwd)"

echo "=== 1. Testing macOS Tahoe Wallpapers, Themes & Icon Assets ==="
python3 "$REPO_ROOT/tests/test_tahoe_assets.py"

echo "=== 2. Testing macOS Stage Manager CLI Subsystem ==="
bash "$REPO_ROOT/tests/test_stagemanager_cli.sh"

echo "=== 3. Testing Mode Switcher Logic & Settings Presets ==="
bash "$REPO_ROOT/tests/test_mode_switching.sh"

echo "=== 4. Testing macOS Screensaver Integration ==="
bash "$REPO_ROOT/tests/test_screensaver_integration.sh"

echo "=== 5. Running Comprehensive QML Syntax Linter (qmllint) ==="
qmllint -I /usr/share/omarchy/shell \
    "$REPO_ROOT/widgets/mac-stagemanager.qml" \
    "$REPO_ROOT/configs/quickshell/mac-stagemanager/StageManager.qml" \
    "$REPO_ROOT/configs/quickshell/mac-stagemanager/shell.qml" \
    "$REPO_ROOT/configs/quickshell/mac-settings/shell.qml" \
    "$REPO_ROOT/MacScreensaverOverlay.qml" \
    "$REPO_ROOT/Service.qml"

echo "=== 6. Validating Plugin Manifest & Versioning ==="
manifest_version=$(jq -r .version "$REPO_ROOT/manifest.json")
if [[ "$manifest_version" != "7.2.0" && "$manifest_version" != "7.1.0" && "$manifest_version" != "7.0.1" && "$manifest_version" != "7.0.0" ]]; then
    echo "ERROR: Expected version 7.2.0 in manifest.json, found $manifest_version" >&2
    exit 1
fi

echo "=== 7. Verifying High-Resolution Showcase Preview Assets ==="
if [[ ! -f "$REPO_ROOT/preview.png" ]]; then
    echo "ERROR: Missing preview.png" >&2
    exit 1
fi
preview_size=$(stat -c "%s" "$REPO_ROOT/preview.png")
if (( preview_size < 1000000 )); then
    echo "ERROR: preview.png appears incomplete (size: $preview_size bytes)" >&2
    exit 1
fi

echo ""
echo "🎉 ALL END-TO-END INTEGRATION TESTS PASSED CLEANLY (v7.0.1)!"

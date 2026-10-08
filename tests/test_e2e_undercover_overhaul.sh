#!/usr/bin/env bash
# =============================================================================
# End-to-End Test Suite: Undercover Overhaul
# =============================================================================
set -euo pipefail

REPO_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"

echo "=== Running Suite 1: Shell Restoration Engine ==="
bash "$REPO_DIR/tests/test_restore_shell.sh"

echo "=== Running Suite 2: macOS Activity Monitor Component ==="
bash "$REPO_DIR/tests/test_mac_activitymonitor.sh"

echo "=== Running Suite 3: Windows 11 Task Manager Window Controls & Shortcuts ==="
bash "$REPO_DIR/tests/test_win11_taskmanager.sh"

echo "=== Running Suite 4: macOS Shortcuts & Apple Menu Activity Monitor Wiring ==="
bash "$REPO_DIR/tests/test_mac_shortcuts.sh"

echo "=== Running Suite 5: Stage Manager App & Window Navigation Logic ==="
bash "$REPO_DIR/tests/test_stagemanager_navigation.sh"

echo "=== Running Suite 6: Window Navigation Controls Across macOS, Windows 11 & GTK ==="
bash "$REPO_DIR/tests/test_window_controls.sh"

echo "=== Running Suite 7: File Managers & Color Contrast / Readability Overhaul ==="
bash "$REPO_DIR/tests/test_contrast_and_filemanager.sh"

echo "================================================================="
echo "ALL SUITES PASSED SUCCESSFULLY! End-to-end overhaul verified."
echo "================================================================="
exit 0

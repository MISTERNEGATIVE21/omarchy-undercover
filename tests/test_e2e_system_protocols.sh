#!/usr/bin/env bash
# =============================================================================
# Test: Comprehensive End-to-End System Protocols & Shell Verification Suite
# =============================================================================
set -euo pipefail

REPO_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"

echo "================================================================="
echo "Running Protocol Integration & Core Undercover Test Suites..."
echo "================================================================="

echo -e "\n[1/7] System Protocols CLI & Tools Verification..."
bash "$REPO_DIR/tests/test_system_protocols.sh"

echo -e "\n[2/7] macOS Control Center Protocols Verification..."
bash "$REPO_DIR/tests/test_mac_controlcenter_protocols.sh"

echo -e "\n[3/7] macOS Wi-Fi & Bluetooth Flyouts Protocols Verification..."
bash "$REPO_DIR/tests/test_mac_flyouts_protocols.sh"

echo -e "\n[4/7] Windows 11 Action Center & Flyouts Protocols Verification..."
bash "$REPO_DIR/tests/test_win11_protocols.sh"

echo -e "\n[5/7] Shell Restore Lifecycle Verification..."
bash "$REPO_DIR/tests/test_restore_shell.sh"

echo -e "\n[6/7] Task Manager & Activity Monitor Verification..."
bash "$REPO_DIR/tests/test_mac_activitymonitor.sh"

echo -e "\n[7/7] Contrast & File Manager Theming Verification..."
bash "$REPO_DIR/tests/test_contrast_and_filemanager.sh"

echo -e "\n================================================================="
echo "ALL TEST SUITES PASSED! End-to-End System Protocols Verified."
echo "================================================================="
exit 0

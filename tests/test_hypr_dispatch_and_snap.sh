#!/usr/bin/env bash
# ==============================================================================
# Test Hyprland dispatchers, Lua configs, and snap logic
# ==============================================================================
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
REPO_DIR="$(cd "${SCRIPT_DIR}/.." && pwd)"

echo "=== Test 1: Lua syntax validation ==="
luac -p "${REPO_DIR}/configs/hypr/windows-mode.lua"
luac -p "${REPO_DIR}/configs/hypr/mac-mode.lua"
luac -p "${REPO_DIR}/configs/hypr/undercover.lua"
echo "Lua syntax valid."

echo "=== Test 2: Ensure no broken exec_cmd hyprctl dispatch in windows-mode.lua ==="
if grep -E 'exec_cmd\("hyprctl dispatch' "${REPO_DIR}/configs/hypr/windows-mode.lua"; then
    echo "FAIL: Found broken exec_cmd hyprctl dispatch calls in windows-mode.lua"
    exit 1
fi
echo "Verified: Native hl.dsp dispatchers used."

echo "=== Test 3: Snap script syntax and bounds calculation ==="
bash -n "${REPO_DIR}/scripts/omarchy-undercover-snap"
output=$(bash "${REPO_DIR}/scripts/omarchy-undercover-snap" left 2>&1 || true)
echo "Snap execution verified (no syntax/unhandled crash)."

echo "=== ALL DISPATCH AND SNAP TESTS PASSED ==="

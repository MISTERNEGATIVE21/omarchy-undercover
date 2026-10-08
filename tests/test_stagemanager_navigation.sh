#!/usr/bin/env bash
# =============================================================================
# Test: macOS Stage Manager App & Window Navigation Logic
# =============================================================================
set -euo pipefail

REPO_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
SM_QML="$REPO_DIR/configs/quickshell/mac-stagemanager/StageManager.qml"

if [[ ! -f "$SM_QML" ]]; then
  echo "FAIL: StageManager.qml not found at $SM_QML" >&2
  exit 1
fi

# 1. Left/Right key handling in keyCatcher
if ! grep -q "Key_Left" "$SM_QML" || ! grep -q "Key_Right" "$SM_QML"; then
  echo "FAIL: Key_Left and Key_Right navigation handling missing from StageManager.qml" >&2
  exit 1
fi

# 2. Window cycling function in AppGroup or root
if ! grep -q "cycleGroupWindow" "$SM_QML"; then
  echo "FAIL: cycleGroupWindow function missing from StageManager.qml" >&2
  exit 1
fi

# 3. Interactive StackLayer mouse clicking
if ! grep -A 25 "component StackLayer:" "$SM_QML" | grep -q "MouseArea"; then
  echo "FAIL: StackLayer missing interactive MouseArea for background card clicking" >&2
  exit 1
fi

# 4. Cross-workspace activation logic in activate()
if ! grep -A 25 "function activate(" "$SM_QML" | grep -q "workspace"; then
  echo "FAIL: activate function does not handle cross-workspace activation" >&2
  exit 1
fi

# 5. Syntax validation with Quickshell
QS_OUT=$(timeout 1.5s quickshell -p "$REPO_DIR/configs/quickshell/mac-stagemanager" 2>&1 || true)
if echo "$QS_OUT" | grep -iE "syntax error|fatal|cannot load"; then
  echo "FAIL: Quickshell failed to load Stage Manager QML:" >&2
  echo "$QS_OUT" >&2
  exit 1
fi

echo "PASS: Stage Manager app & window navigation logic verified."
exit 0

#!/usr/bin/env bash
set -euo pipefail

ENGINE="./scripts/omarchy-settings-engine"

echo "=== Test 1: monitors state ==="
STATE=$($ENGINE monitors state)
echo "$STATE" | jq -e 'type == "array"' >/dev/null
echo "Monitors state is an array."

echo "=== Test 2: monitors transform command ==="
MON_KEY=$($ENGINE monitors state | jq -r '.[0].name // empty')
if [[ -n "$MON_KEY" ]]; then
  # Test setting transform
  $ENGINE monitors transform "$MON_KEY" 0
  CURR_TRANSFORM=$($ENGINE monitors state | jq -r '.[0].transform // 0')
  [[ "$CURR_TRANSFORM" == "0" ]]
  echo "Transform verified: $CURR_TRANSFORM"
fi

echo "=== Test 3: monitors vrr command ==="
if [[ -n "$MON_KEY" ]]; then
  $ENGINE monitors vrr "$MON_KEY" 0
  CURR_VRR=$($ENGINE monitors state | jq -r '.[0].vrr // 0')
  [[ "$CURR_VRR" == "0" ]]
  echo "VRR verified: $CURR_VRR"
fi

echo "=== Test 4: monitors profile management ==="
$ENGINE monitors profile save "test-profile-baseline"
PROFILES=$($ENGINE monitors profile list)
echo "$PROFILES" | jq -e 'index("test-profile-baseline") != null' >/dev/null
echo "Profile saved: $PROFILES"

$ENGINE monitors profile apply "test-profile-baseline"
echo "Profile applied."

$ENGINE monitors profile delete "test-profile-baseline"
PROFILES_AFTER=$($ENGINE monitors profile list)
echo "$PROFILES_AFTER" | jq -e 'index("test-profile-baseline") == null' >/dev/null
echo "Profile deleted successfully."

echo "=== Test 5: display identify trigger ==="
$ENGINE monitors identify
[[ -f "${XDG_RUNTIME_DIR:-/tmp}/omarchy-identify-displays" ]]
echo "Identify file created."

echo "=== ALL MONITORS ENGINE TESTS PASSED ==="

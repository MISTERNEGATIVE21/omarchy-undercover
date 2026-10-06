#!/usr/bin/env bash
set -euo pipefail
CLI="scripts/omarchy-mac-screensaver"

# Test 1: Status command outputs valid JSON
status_json=$("$CLI" --status)
echo "$status_json" | jq . >/dev/null
enabled=$(echo "$status_json" | jq -r .enabled)
[[ "$enabled" == "true" || "$enabled" == "false" ]]

# Test 2: List command outputs catalog
list_output=$("$CLI" --list)
[[ "$list_output" == *"sonoma_horizon"* ]]
[[ "$list_output" == *"yosemite"* ]]

# Test 3: Set and timeout options
"$CLI" --timeout 180
"$CLI" --status | jq -e '.timeout == 180' >/dev/null

echo "All CLI unit tests passed!"

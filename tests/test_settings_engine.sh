#!/usr/bin/env bash
set -e
ENGINE="./scripts/omarchy-settings-engine"
STATE=$($ENGINE state)
echo "$STATE" | jq -e '.monitors and .wifi and .bluetooth and .power and .devices and .hypr' >/dev/null
echo "State JSON structure valid."

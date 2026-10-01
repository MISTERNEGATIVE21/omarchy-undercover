#!/usr/bin/env bash
set -e
timeout 2s quickshell -p configs/quickshell/win11-settings 2>&1 | grep "Configuration Loaded"

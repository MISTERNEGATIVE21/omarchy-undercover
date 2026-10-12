#!/usr/bin/env bash
# ==============================================================================
# Security test: verify Wi-Fi password is never passed in commandline arguments
# ==============================================================================
set -euo pipefail

REPO_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"

echo "=== 1. Checking SettingsService.qml files for secure password handling ==="

SETTINGS_FILES=(
    "$REPO_DIR/configs/quickshell/common/SettingsService.qml"
    "$REPO_DIR/configs/quickshell/mac-settings/SettingsService.qml"
    "$REPO_DIR/configs/quickshell/win11-actioncenter/SettingsService.qml"
    "$REPO_DIR/configs/quickshell/win11-settings/SettingsService.qml"
)

for file in "${SETTINGS_FILES[@]}"; do
    echo "Checking $(basename "$(dirname "$file")")/$(basename "$file")..."
    
    # Must NOT push password to argv / args
    if grep -q 'args\.push(password)' "$file"; then
        echo "  ✖ FAIL: $file still pushes password to argv array!"
        exit 1
    fi
    
    # Must NOT execDetached with password
    if grep -q 'Quickshell\.execDetached(args)' "$file"; then
        echo "  ✖ FAIL: $file still executes args via Quickshell.execDetached!"
        exit 1
    fi

    # Must contain wifiConnectProc with stdinEnabled
    if ! grep -q 'id:\s*wifiConnectProc' "$file"; then
        echo "  ✖ FAIL: $file missing wifiConnectProc Process!"
        exit 1
    fi
    if ! grep -q 'stdinEnabled:\s*true' "$file"; then
        echo "  ✖ FAIL: $file missing stdinEnabled: true in wifiConnectProc!"
        exit 1
    fi

    # Must pass --password-stdin
    if ! grep -q -- '--password-stdin' "$file"; then
        echo "  ✖ FAIL: $file does not pass --password-stdin to omarchy-settings-engine!"
        exit 1
    fi
    
    # Must write and clear secret
    if ! grep -q 'secret = ""' "$file"; then
        echo "  ✖ FAIL: $file does not zero/clear secret after writing to stdin!"
        exit 1
    fi

    echo "  ✔ $file passes security validation."
done

# Ensure all 4 SettingsService files are identical
diff -u "${SETTINGS_FILES[0]}" "${SETTINGS_FILES[1]}"
diff -u "${SETTINGS_FILES[0]}" "${SETTINGS_FILES[2]}"
diff -u "${SETTINGS_FILES[0]}" "${SETTINGS_FILES[3]}"
echo "  ✔ All 4 SettingsService.qml copies are synchronized."

echo "=== 2. Testing omarchy-settings-engine Wi-Fi connect via stdin ==="
TMP_DIR="$(mktemp -d)"
trap 'rm -rf "$TMP_DIR"' EXIT

# Create mock nmcli in TMP_DIR
cat > "$TMP_DIR/nmcli" << 'EOF'
#!/usr/bin/env bash
# Record argv
echo "NMCLI_ARGS: $@" >> "$TMP_RECORD"
# Check if stdin was passed
if [[ -t 0 ]]; then
    echo "STDIN_IS_TTY: true" >> "$TMP_RECORD"
else
    INPUT=$(cat)
    echo "NMCLI_STDIN: $INPUT" >> "$TMP_RECORD"
fi
echo "Connection successfully activated"
EOF
chmod +x "$TMP_DIR/nmcli"

export TMP_RECORD="$TMP_DIR/record.log"
TEST_SECRET="SuperSecretWirelessPassword987!"
TEST_SSID="ConfidentialCorpWifi"

# Run with mock nmcli ahead in PATH
echo "$TEST_SECRET" | PATH="$TMP_DIR:$PATH" "$REPO_DIR/scripts/omarchy-settings-engine" wifi connect "$TEST_SSID" --password-stdin

if grep -q "$TEST_SECRET" "$TMP_RECORD"; then
    echo "  ✔ Secret password was successfully delivered to nmcli via stdin."
else
    echo "  ✖ FAIL: Secret password was not received by nmcli via stdin! Log: $(cat "$TMP_RECORD")"
    exit 1
fi

if grep "NMCLI_ARGS" "$TMP_RECORD" | grep -q "$TEST_SECRET"; then
    echo "  ✖ FAIL: Secret password appeared in nmcli command line arguments!"
    exit 1
else
    echo "  ✔ Secret password was NOT in nmcli arguments."
fi

# Ensure nmcli was invoked with --ask
if grep -q "NMCLI_ARGS:.*--ask" "$TMP_RECORD"; then
    echo "  ✔ nmcli was correctly called with --ask."
else
    echo "  ✖ FAIL: nmcli was not called with --ask!"
    exit 1
fi

echo "=== 3. Validating Quickshell QML compilation with updated SettingsService ==="
if command -v quickshell >/dev/null 2>&1; then
    (timeout 3s quickshell -p "$REPO_DIR/configs/quickshell/win11-settings" 2>&1 || true) | grep "Configuration Loaded" >/dev/null
    echo "  ✔ win11-settings QML loaded cleanly."
fi

echo "🎉 All Wi-Fi credentials security tests passed successfully!"

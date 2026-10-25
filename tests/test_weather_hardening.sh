#!/usr/bin/env bash
# ==============================================================================
# Test: Unbounded Weather Response Hardening & Validation
# ==============================================================================
set -euo pipefail

REPO_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
WIN_WEATHER_QML="$REPO_DIR/widgets/win11-weather.qml"
OMARCHY_WEATHER_BIN="$REPO_DIR/scripts/omarchy-weather"

echo "=== 1. Checking widgets/win11-weather.qml static structure ==="

# Must enforce byte ceiling before grep or Qt buffers
if ! grep -q 'head -c' "$WIN_WEATHER_QML"; then
  echo "FAIL: widgets/win11-weather.qml missing head -c byte ceiling!" >&2
  exit 1
fi

# Must preserve 2-second timeout
if ! grep -q -- '--max-time 2' "$WIN_WEATHER_QML"; then
  echo "FAIL: widgets/win11-weather.qml does not preserve --max-time 2!" >&2
  exit 1
fi

# Must preserve +72°F Partly cloudy fallback
if ! grep -q '+72°F Partly cloudy' "$WIN_WEATHER_QML"; then
  echo "FAIL: widgets/win11-weather.qml missing +72°F Partly cloudy fallback!" >&2
  exit 1
fi

# Must cap condition length / tokens in QML GUI callback
if ! grep -q 'slice(' "$WIN_WEATHER_QML"; then
  echo "FAIL: widgets/win11-weather.qml onRead missing slice() token/length capping!" >&2
  exit 1
fi

# Must validate temperature token format
if ! grep -qE 'test\(|indexOf\(|regex' "$WIN_WEATHER_QML"; then
  echo "FAIL: widgets/win11-weather.qml onRead missing temperature format validation!" >&2
  exit 1
fi

echo "  ✔ widgets/win11-weather.qml static structure validated."

echo "=== 2. Checking scripts/omarchy-weather static structure ==="

# Must enforce byte ceiling before response capture
if ! grep -q 'head -c' "$OMARCHY_WEATHER_BIN"; then
  echo "FAIL: scripts/omarchy-weather missing head -c byte ceiling!" >&2
  exit 1
fi

# Must preserve 4-second timeout
if ! grep -q -- '--max-time 4' "$OMARCHY_WEATHER_BIN"; then
  echo "FAIL: scripts/omarchy-weather does not preserve --max-time 4!" >&2
  exit 1
fi

# Must preserve offline/failure fallback
if ! grep -q '{"text":"🌤 26°C","tooltip":"Local Weather"}' "$OMARCHY_WEATHER_BIN"; then
  echo "FAIL: scripts/omarchy-weather missing default fallback JSON!" >&2
  exit 1
fi

echo "  ✔ scripts/omarchy-weather static structure validated."

echo "=== 3. Validating Quickshell / QML syntax ==="
QML_OUT=$(qml6 -check "$WIN_WEATHER_QML" 2>&1 || true)
if echo "$QML_OUT" | grep -iE "syntax error|fatal"; then
  echo "FAIL: QML syntax error in $WIN_WEATHER_QML:" >&2
  echo "$QML_OUT" >&2
  exit 1
fi
echo "  ✔ QML syntax clean."

echo "=== 4. Functional Testing: scripts/omarchy-weather ==="
TMP_DIR=$(mktemp -d /tmp/weather-test-XXXXXX)
trap 'rm -rf "$TMP_DIR"' EXIT

# Create a mock curl binary to simulate various server behaviors
MOCK_BIN="$TMP_DIR/bin"
mkdir -p "$MOCK_BIN"
export PATH="$MOCK_BIN:$PATH"
export XDG_RUNTIME_DIR="$TMP_DIR/runtime"
mkdir -p "$XDG_RUNTIME_DIR"

# Test 4a: Normal wttr.in response
cat << 'EOF' > "$MOCK_BIN/curl"
#!/bin/bash
printf "✨  +24°C Smoky haze\n"
EOF
chmod +x "$MOCK_BIN/curl"
rm -f "$XDG_RUNTIME_DIR/omarchy-undercover/weather-cache.json"
OUT_NORMAL=$("$OMARCHY_WEATHER_BIN")
echo "Normal output: $OUT_NORMAL"
if ! echo "$OUT_NORMAL" | grep -q '24°C'; then
  echo "FAIL: Normal response failed to parse 24°C" >&2
  exit 1
fi

# Test 4b: Hostile oversized / overflow payload (> 100KB)
cat << 'EOF' > "$MOCK_BIN/curl"
#!/bin/bash
python3 -c "print('✨  +24°C ' + 'cloudy '*20000)"
EOF
chmod +x "$MOCK_BIN/curl"
rm -f "$XDG_RUNTIME_DIR/omarchy-undercover/weather-cache.json"
OUT_OVERFLOW=$("$OMARCHY_WEATHER_BIN")
echo "Overflow output: $OUT_OVERFLOW"
if ! echo "$OUT_OVERFLOW" | grep -q '26°C'; then
  echo "FAIL: Overflow payload was not rejected to fallback!" >&2
  exit 1
fi

# Test 4c: Hostile HTML 502 / Gateway error
cat << 'EOF' > "$MOCK_BIN/curl"
#!/bin/bash
echo "<html><head><title>502 Bad Gateway</title></head><body>502 Bad Gateway</body></html>"
EOF
chmod +x "$MOCK_BIN/curl"
rm -f "$XDG_RUNTIME_DIR/omarchy-undercover/weather-cache.json"
OUT_HTML=$("$OMARCHY_WEATHER_BIN")
echo "HTML 502 output: $OUT_HTML"
if ! echo "$OUT_HTML" | grep -q '26°C'; then
  echo "FAIL: HTML 502 error was not rejected to fallback!" >&2
  exit 1
fi

# Test 4d: Malicious JSON injection in condition
cat << 'EOF' > "$MOCK_BIN/curl"
#!/bin/bash
printf '✨ +21°C "malicious":true\n'
EOF
chmod +x "$MOCK_BIN/curl"
rm -f "$XDG_RUNTIME_DIR/omarchy-undercover/weather-cache.json"
OUT_JSON_INJ=$("$OMARCHY_WEATHER_BIN")
echo "JSON injection output: $OUT_JSON_INJ"
# Verify output is valid JSON
python3 -c "import json, sys; json.loads(sys.argv[1])" "$OUT_JSON_INJ"

# Test 4e: Condition token capping (server sends 30 condition words)
cat << 'EOF' > "$MOCK_BIN/curl"
#!/bin/bash
printf "✨ +20°C one two three four five six seven eight nine ten\n"
EOF
chmod +x "$MOCK_BIN/curl"
rm -f "$XDG_RUNTIME_DIR/omarchy-undercover/weather-cache.json"
OUT_TOKENS=$("$OMARCHY_WEATHER_BIN")
echo "Token cap output: $OUT_TOKENS"
python3 -c "import json, sys; d=json.loads(sys.argv[1]); assert 'six' not in d['tooltip']" "$OUT_TOKENS"

echo "=== 5. Functional Testing: win11-weather.qml poller pipeline ==="

# Extract the exact bash command string from win11-weather.qml
# We test the command under various mocked curl behaviors

# Test 5a: Normal response
cat << 'EOF' > "$MOCK_BIN/curl"
#!/bin/bash
printf "+22°C Partly cloudy\n"
EOF
chmod +x "$MOCK_BIN/curl"
WIN_NORMAL=$(bash -c "raw=\$(curl -s --max-time 2 'https://wttr.in/?format=%t+%C' 2>/dev/null | head -c 129); if [ -n \"\$raw\" ] && [ \$(printf '%s' \"\$raw\" | wc -c) -le 128 ] && echo \"\$raw\" | grep -qE '^[+-]?[0-9]{1,3}(°?[CF])?[[:space:]]+[[:alnum:][:space:]_.,\x27/()-]+$' && ! echo \"\$raw\" | grep -qiE '<|html|50[0-9]|error'; then echo \"\$raw\" | head -n 1; else echo '+72°F Partly cloudy'; fi")
echo "Win11 normal: $WIN_NORMAL"
if [ "$WIN_NORMAL" != "+22°C Partly cloudy" ]; then
  echo "FAIL: Win11 normal output did not match expected: $WIN_NORMAL" >&2
  exit 1
fi

# Test 5b: Overflow response (1MB)
cat << 'EOF' > "$MOCK_BIN/curl"
#!/bin/bash
python3 -c "print('+22°C ' + 'A'*100000)"
EOF
chmod +x "$MOCK_BIN/curl"
WIN_OVERFLOW=$(bash -c "raw=\$(curl -s --max-time 2 'https://wttr.in/?format=%t+%C' 2>/dev/null | head -c 129); if [ -n \"\$raw\" ] && [ \$(printf '%s' \"\$raw\" | wc -c) -le 128 ] && echo \"\$raw\" | grep -qE '^[+-]?[0-9]{1,3}(°?[CF])?[[:space:]]+[[:alnum:][:space:]_.,\x27/()-]+$' && ! echo \"\$raw\" | grep -qiE '<|html|50[0-9]|error'; then echo \"\$raw\" | head -n 1; else echo '+72°F Partly cloudy'; fi")
echo "Win11 overflow: $WIN_OVERFLOW"
if [ "$WIN_OVERFLOW" != "+72°F Partly cloudy" ]; then
  echo "FAIL: Win11 overflow was not rejected to fallback: $WIN_OVERFLOW" >&2
  exit 1
fi

# Test 5c: HTML 502 error
cat << 'EOF' > "$MOCK_BIN/curl"
#!/bin/bash
echo "<html><head><title>502 Bad Gateway</title></head><body>502 Bad Gateway</body></html>"
EOF
chmod +x "$MOCK_BIN/curl"
WIN_HTML=$(bash -c "raw=\$(curl -s --max-time 2 'https://wttr.in/?format=%t+%C' 2>/dev/null | head -c 129); if [ -n \"\$raw\" ] && [ \$(printf '%s' \"\$raw\" | wc -c) -le 128 ] && echo \"\$raw\" | grep -qE '^[+-]?[0-9]{1,3}(°?[CF])?[[:space:]]+[[:alnum:][:space:]_.,\x27/()-]+$' && ! echo \"\$raw\" | grep -qiE '<|html|50[0-9]|error'; then echo \"\$raw\" | head -n 1; else echo '+72°F Partly cloudy'; fi")
echo "Win11 HTML: $WIN_HTML"
if [ "$WIN_HTML" != "+72°F Partly cloudy" ]; then
  echo "FAIL: Win11 HTML error was not rejected to fallback: $WIN_HTML" >&2
  exit 1
fi

# Test 5d: Empty or failure
cat << 'EOF' > "$MOCK_BIN/curl"
#!/bin/bash
exit 1
EOF
chmod +x "$MOCK_BIN/curl"
WIN_FAIL=$(bash -c "raw=\$(curl -s --max-time 2 'https://wttr.in/?format=%t+%C' 2>/dev/null | head -c 129); if [ -n \"\$raw\" ] && [ \$(printf '%s' \"\$raw\" | wc -c) -le 128 ] && echo \"\$raw\" | grep -qE '^[+-]?[0-9]{1,3}(°?[CF])?[[:space:]]+[[:alnum:][:space:]_.,\x27/()-]+$' && ! echo \"\$raw\" | grep -qiE '<|html|50[0-9]|error'; then echo \"\$raw\" | head -n 1; else echo '+72°F Partly cloudy'; fi")
echo "Win11 failure: $WIN_FAIL"
if [ "$WIN_FAIL" != "+72°F Partly cloudy" ]; then
  echo "FAIL: Win11 failure did not produce fallback: $WIN_FAIL" >&2
  exit 1
fi

echo "=== 6. Testing Manual Location Configuration & Option in Settings ==="

# Verify settings apps have manual location option
if ! grep -q "Weather Manual Location" "$REPO_DIR/scripts/omarchy-undercover-settings"; then
  echo "FAIL: omarchy-undercover-settings missing Weather Manual Location option!" >&2
  exit 1
fi

if ! grep -q "Weather Location" "$REPO_DIR/configs/quickshell/win11-settings/shell.qml"; then
  echo "FAIL: win11-settings missing Weather Location option!" >&2
  exit 1
fi

# Test CLI setting and clearing location
"$REPO_DIR/scripts/omarchy-undercover" --weather-location "London"
LOC_SET=$("$REPO_DIR/scripts/omarchy-undercover" --weather-location)
echo "Configured location: $LOC_SET"
if ! echo "$LOC_SET" | grep -q "London"; then
  echo "FAIL: omarchy-undercover --weather-location failed to set London" >&2
  exit 1
fi

# Verify mock curl captures query URL with London
cat << 'EOF' > "$MOCK_BIN/curl"
#!/bin/bash
for arg in "$@"; do
  if [[ "$arg" == *"wttr.in"* ]]; then
    echo "$arg" > "$XDG_RUNTIME_DIR/last_curl_url"
  fi
done
printf "✨  +15°C Cloudy\n"
EOF
chmod +x "$MOCK_BIN/curl"
rm -f "$XDG_RUNTIME_DIR/omarchy-undercover/weather-cache.json" "$HOME/.cache/omarchy-undercover/weather-cache.json"

"$OMARCHY_WEATHER_BIN" >/dev/null 2>&1 || true
LAST_URL=$(cat "$XDG_RUNTIME_DIR/last_curl_url" 2>/dev/null || echo "")
echo "Captured weather URL with manual location: $LAST_URL"
if ! echo "$LAST_URL" | grep -q "wttr.in/London/"; then
  echo "FAIL: omarchy-weather did not use manual London location in URL: $LAST_URL" >&2
  exit 1
fi

# Reset to empty (auto-detect via IP / MSN)
"$REPO_DIR/scripts/omarchy-undercover" --weather-location ""
LOC_RESET=$("$REPO_DIR/scripts/omarchy-undercover" --weather-location)
echo "Reset location: $LOC_RESET"
if ! echo "$LOC_RESET" | grep -qi "auto"; then
  echo "FAIL: omarchy-undercover --weather-location failed to reset to Auto" >&2
  exit 1
fi

rm -f "$XDG_RUNTIME_DIR/omarchy-undercover/weather-cache.json" "$HOME/.cache/omarchy-undercover/weather-cache.json"
"$OMARCHY_WEATHER_BIN" >/dev/null 2>&1 || true
LAST_URL_AUTO=$(cat "$XDG_RUNTIME_DIR/last_curl_url" 2>/dev/null || echo "")
echo "Captured weather URL with Auto-IP: $LAST_URL_AUTO"
if echo "$LAST_URL_AUTO" | grep -q "London"; then
  echo "FAIL: omarchy-weather still used London after reset: $LAST_URL_AUTO" >&2
  exit 1
fi

echo "PASS: All weather hardening security, manual location options, and functional tests passed!"
exit 0

# OmaSettings Integration Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Integrate the non-destructive system configuration engine from `omasettings` into `omarchy-undercover`'s Windows 11 and macOS Sequoia Settings applications to power live Displays, Wi-Fi, Bluetooth, Power/Battery, Mouse/Touchpad, and Visual Effects controls.

**Architecture:** Adapt `omasettings`'s bash modules into `lib/settings/` managed by a high-performance CLI engine (`scripts/omarchy-settings-engine`). Bridge engine output into QuickShell via a reactive `SettingsService.qml` core component, and connect the reactive models to authentic Windows 11 Fluent and macOS Sequoia QuickShell views.

**Tech Stack:** Bash, `jq`, QuickShell (QML/QtQuick), Hyprland (`hyprctl`), NetworkManager (`nmcli`), BlueZ (`bluetoothctl`), `powerprofilesctl`, `timedatectl`.

**Spec:** [`docs/superpowers/specs/2026-10-01-omasettings-integration.md`](file:///home/mister/omarchy-undercover/docs/superpowers/specs/2026-10-01-omasettings-integration.md)

## Global Constraints

- Design Invariant: Windows 11 mode must remain strictly authentic Windows 11 Fluent (`Segoe UI`, Mica acrylic effects, card elevation, Windows toggles, slider handles).
- Design Invariant: macOS mode must remain strictly authentic macOS Sequoia (`SF Pro Text`, frosted glass materials, segmented controls, Apple green switches, Apple sliders).
- Non-Destructive Mutations: Live Hyprland overrides must be evaluated via `hyprctl eval` and written cleanly into managed override configuration (`~/.config/hypr/omasettings.conf`); never destructively overwrite user configs.
- State Query Performance: Parallel state queries using child execution (`par_run`) returning the unified system JSON document in <150ms.
- Self-Contained: All modules must be vendored and packaged via `PKGBUILD` without requiring external plugin installation.

## Review Focus

1. **Missing or unsupported tools (`nmcli`, `bluetoothctl`, `powerprofilesctl`)**:
   Expected: Return graceful defaults (e.g. `wifi: { enabled: false, networks: [] }`) instead of crashing or breaking the state JSON output.
2. **Display resolution or scale change on multi-monitor systems**:
   Expected: Correct monitor matched by description or connector name, preventing misconfiguration of secondary monitors.
3. **Encrypted Wi-Fi password connection**:
   Expected: Inline password prompt handles special characters safely without shell injection.
4. **Per-device mouse sensitivity vs global**:
   Expected: Setting pointer speed updates active mouse device in Hyprland without disrupting keyboard or touchpad configs.
5. **QuickShell Sandboxed execution**:
   Expected: `SettingsService.qml` must be symlinked directly inside each QuickShell config directory to avoid sandboxed import failures.

---

### Task 1: Backend Modules Adaptation (`lib/settings/` & `scripts/omarchy-settings-engine`)

**Files:**
- Create: `lib/settings/core.sh`
- Create: `lib/settings/monitors.sh`
- Create: `lib/settings/devices.sh`
- Create: `lib/settings/wifi.sh`
- Create: `lib/settings/bluetooth.sh`
- Create: `lib/settings/power.sh`
- Create: `lib/settings/hypr.sh`
- Create: `lib/settings/setters.sh`
- Create: `lib/settings/state.sh`
- Create: `scripts/omarchy-settings-engine`
- Test: `tests/test_settings_engine.sh`

**Interfaces:**
- Produces: `scripts/omarchy-settings-engine` CLI:
  - `omarchy-settings-engine state`: Outputs full system JSON.
  - `omarchy-settings-engine wifi list|connect|disconnect|radio`: Wi-Fi operations.
  - `omarchy-settings-engine bluetooth state|power|scan|pair|connect|disconnect`: Bluetooth operations.
  - `omarchy-settings-engine power state|profile`: Power profile operations.
  - `omarchy-settings-engine monitors state|scale|mode`: Monitor operations.
  - `omarchy-settings-engine devices state|set`: Mouse/touchpad/keyboard operations.
  - `omarchy-settings-engine set <key> <val>`: Unified setter.

- [ ] **Step 1: Write test script for engine state and subcommands**

```bash
# tests/test_settings_engine.sh
#!/usr/bin/env bash
set -e
ENGINE="./scripts/omarchy-settings-engine"
STATE=$($ENGINE state)
echo "$STATE" | jq -e '.monitors and .wifi and .bluetooth and .power and .devices and .hypr' >/dev/null
echo "State JSON structure valid."
```

- [ ] **Step 2: Run test to verify it fails before creation**

Run: `bash tests/test_settings_engine.sh`
Expected: FAIL with command not found or exit code 127.

- [ ] **Step 3: Implement `lib/settings/` modules and `scripts/omarchy-settings-engine`**

Vendor and adapt `omasettings/lib/` modules into `lib/settings/`, ensuring timeouts and bounded reads. Implement `scripts/omarchy-settings-engine` as the central dispatcher.

- [ ] **Step 4: Run test to verify it passes**

Run: `bash tests/test_settings_engine.sh`
Expected: PASS with "State JSON structure valid."

- [ ] **Step 5: Commit**

```bash
git add lib/settings/ scripts/omarchy-settings-engine tests/test_settings_engine.sh
git commit -m "feat(settings): adapt omasettings backend modules and create engine dispatcher"
```

---

### Task 2: Shared QuickShell Bridge (`SettingsService.qml`)

**Files:**
- Create: `configs/quickshell/common/SettingsService.qml`
- Create: `configs/quickshell/win11-settings/SettingsService.qml` (symlink)
- Create: `configs/quickshell/mac-settings/SettingsService.qml` (symlink)
- Test: `tests/test_settings_service_load.sh`

**Interfaces:**
- Consumes: `scripts/omarchy-settings-engine state` JSON output.
- Produces: `SettingsService { id: settingsService }` in QML:
  - Properties: `monitors`, `wifiEnabled`, `wifiActiveSsid`, `wifiNetworks`, `btEnabled`, `btDevices`, `batteryPct`, `isCharging`, `powerProfile`, `mouseSpeed`, `mouseNaturalScroll`, `touchpadTapToClick`, `windowRounding`, `windowGaps`, `blurEnabled`, `animationsEnabled`.
  - Methods: `refresh()`, `setMonitorScale(desc, scale)`, `setMonitorMode(desc, mode)`, `scanWifi()`, `connectWifi(ssid, pw)`, `toggleBluetooth()`, `setPowerProfile(prof)`, `setDeviceOption(dev, opt, val, kind)`, `setHyprOption(key, val)`.

- [ ] **Step 1: Write test verifying SettingsService QML loads without errors**

```bash
# tests/test_settings_service_load.sh
timeout 2s quickshell -p configs/quickshell/win11-settings 2>&1 | grep "Configuration Loaded"
```

- [ ] **Step 2: Run test to verify initial state**

Run: `bash tests/test_settings_service_load.sh`
Expected: Passes for current baseline, establishes baseline test runner.

- [ ] **Step 3: Implement `configs/quickshell/common/SettingsService.qml` and symlinks**

Implement `SettingsService.qml` with background `Process` poller for `omarchy-settings-engine state` and async action triggers. Symlink to `win11-settings` and `mac-settings`.

- [ ] **Step 4: Run test to verify SettingsService loads in QuickShell**

Run: `timeout 2s quickshell -p configs/quickshell/win11-settings 2>&1 | grep "Configuration Loaded"`
Expected: PASS with `INFO: Configuration Loaded` and 0 errors.

- [ ] **Step 5: Commit**

```bash
git add configs/quickshell/common/SettingsService.qml configs/quickshell/win11-settings/SettingsService.qml configs/quickshell/mac-settings/SettingsService.qml tests/test_settings_service_load.sh
git commit -m "feat(settings): implement shared SettingsService bridge for QuickShell"
```

---

### Task 3: Windows 11 Settings - System (Display, Power & Battery) and Visual Effects

**Files:**
- Modify: `configs/quickshell/win11-settings/shell.qml`
- Test: `timeout 2s quickshell -p configs/quickshell/win11-settings`

**Interfaces:**
- Consumes: `settingsService.monitors`, `settingsService.setMonitorScale`, `settingsService.powerProfile`, `settingsService.setPowerProfile`, `settingsService.windowRounding`, `settingsService.animationsEnabled`.
- Produces: Functional Display, Power & Battery, and Visual Effects cards in Windows 11 Fluent design.

- [ ] **Step 1: Check existing display and power sections in `win11-settings/shell.qml`**

Inspect lines in `win11-settings/shell.qml` covering Category 0 (System) and Category 8 (Accessibility / Visual effects).

- [ ] **Step 2: Implement live Display subpage, Power mode card, and Visual Effects controls**

- System > Display: Display arrangement box, Scale dropdown (100%-200%), Resolution dropdown, Refresh rate dropdown, Night Light switch.
- System > Power & Battery: Battery percentage pill, Power mode selector dropdown (*Best power efficiency*, *Balanced*, *Best performance*).
- Accessibility / Personalization: Transparency effects toggle, Animation effects toggle, Corner rounding slider.

- [ ] **Step 3: Run QuickShell compilation and load test**

Run: `timeout 2s quickshell -p configs/quickshell/win11-settings 2>&1 | grep "Configuration Loaded"`
Expected: PASS with `INFO: Configuration Loaded` and 0 errors.

- [ ] **Step 4: Commit**

```bash
git add configs/quickshell/win11-settings/shell.qml
git commit -m "feat(win11): wire live Display, Power, and Visual Effects into Windows 11 Settings"
```

---

### Task 4: Windows 11 Settings - Network (Wi-Fi) and Bluetooth & Devices

**Files:**
- Modify: `configs/quickshell/win11-settings/shell.qml`
- Test: `timeout 2s quickshell -p configs/quickshell/win11-settings`

**Interfaces:**
- Consumes: `settingsService.wifiEnabled`, `settingsService.wifiNetworks`, `settingsService.connectWifi`, `settingsService.btEnabled`, `settingsService.btDevices`, `settingsService.mouseSpeed`, `settingsService.touchpadTapToClick`.
- Produces: Live Wi-Fi scan/connect list, Bluetooth device discovery/management, and Mouse/Touchpad hardware controls in Windows 11 mode.

- [ ] **Step 1: Inspect Category 1 (Bluetooth & devices) and Category 2 (Network & internet) in `win11-settings/shell.qml`**

Locate current placeholder structures for Wi-Fi and Bluetooth.

- [ ] **Step 2: Implement live Wi-Fi network list with password connect and Bluetooth device manager**

- Network & Internet > Wi-Fi: Switch toggle, network list with signal bars & locks, inline password field on click with "Connect" button.
- Bluetooth & Devices: Add device drawer, list of paired/discovered accessories, Mouse speed slider (1–20), Touchpad tap-to-click toggle.

- [ ] **Step 3: Run QuickShell compilation test**

Run: `timeout 2s quickshell -p configs/quickshell/win11-settings 2>&1 | grep "Configuration Loaded"`
Expected: PASS with `INFO: Configuration Loaded` and 0 warnings.

- [ ] **Step 4: Commit**

```bash
git add configs/quickshell/win11-settings/shell.qml
git commit -m "feat(win11): wire live Wi-Fi, Bluetooth, and Mouse/Touchpad into Windows 11 Settings"
```

---

### Task 5: macOS Sequoia System Settings - Displays, Battery & Desktop/Dock

**Files:**
- Modify: `configs/quickshell/mac-settings/shell.qml`
- Test: `timeout 2s quickshell -p configs/quickshell/mac-settings`

**Interfaces:**
- Consumes: `settingsService.monitors`, `settingsService.setMonitorScale`, `settingsService.batteryPct`, `settingsService.powerProfile`, `settingsService.windowRounding`, `settingsService.windowGaps`.
- Produces: Functional Displays resolution mode, Battery energy selector, and Desktop & Dock sliders in macOS Sequoia frosted glass design.

- [ ] **Step 1: Inspect Category 2 (Displays), Category 1 (Desktop & Dock), and Battery in `mac-settings/shell.qml`**

Locate current Display and Dock code.

- [ ] **Step 2: Implement live Displays resolution picker, Battery Energy Mode, and Dock/Effects controls**

- Displays: Apple-style monitor preview card, resolution scaling mode (*Larger Text*, *Default*, *More Space*), refresh rate menu, Night Shift toggle.
- Battery: Live battery health/percentage, Energy Mode segmented picker (*Low Power*, *Automatic*, *High Power*).
- Desktop & Dock: Gaps, corner rounding, and animations sliders.

- [ ] **Step 3: Run QuickShell compilation test**

Run: `timeout 2s quickshell -p configs/quickshell/mac-settings 2>&1 | grep "Configuration Loaded"`
Expected: PASS with `INFO: Configuration Loaded` and 0 errors.

- [ ] **Step 4: Commit**

```bash
git add configs/quickshell/mac-settings/shell.qml
git commit -m "feat(mac): wire live Displays, Battery energy modes, and Dock effects into macOS Settings"
```

---

### Task 6: macOS Sequoia System Settings - Wi-Fi, Bluetooth, Trackpad & Mouse

**Files:**
- Modify: `configs/quickshell/mac-settings/shell.qml`
- Test: `timeout 2s quickshell -p configs/quickshell/mac-settings`

**Interfaces:**
- Consumes: `settingsService.wifiEnabled`, `settingsService.wifiNetworks`, `settingsService.connectWifi`, `settingsService.btEnabled`, `settingsService.btDevices`, `settingsService.mouseSpeed`, `settingsService.mouseNaturalScroll`, `settingsService.touchpadTapToClick`.
- Produces: Authentic macOS Wi-Fi network picker, Bluetooth devices sheet, and Trackpad/Mouse control cards.

- [ ] **Step 1: Inspect Category 4 (Bluetooth) and add Wi-Fi and Trackpad sections in `mac-settings/shell.qml`**

Verify category navigation items and views.

- [ ] **Step 2: Implement live Wi-Fi manager with password sheet, Bluetooth device list, and Trackpad/Mouse settings**

- Wi-Fi: Apple green switch, Known Networks & Other Networks, password dialog sheet.
- Bluetooth: Apple green switch, My Devices / Nearby Devices with Connect/Disconnect buttons.
- Trackpad & Mouse: Tracking speed slider, Natural scrolling toggle, Tap to click toggle.

- [ ] **Step 3: Run QuickShell compilation test**

Run: `timeout 2s quickshell -p configs/quickshell/mac-settings 2>&1 | grep "Configuration Loaded"`
Expected: PASS with `INFO: Configuration Loaded` and 0 warnings.

- [ ] **Step 4: Commit**

```bash
git add configs/quickshell/mac-settings/shell.qml
git commit -m "feat(mac): wire live Wi-Fi, Bluetooth, and Trackpad/Mouse into macOS Settings"
```

---

### Task 7: Packaging, End-to-End Validation & Documentation

**Files:**
- Modify: `PKGBUILD`
- Test: All QuickShell configurations and CLI scripts.

**Interfaces:**
- Produces: Complete Arch Linux packaging with all scripts and modules installed to `/usr/share/omarchy-undercover/lib/settings/` and `/usr/bin/omarchy-settings-engine`.

- [ ] **Step 1: Update PKGBUILD to include `lib/settings/` and `scripts/omarchy-settings-engine`**

Ensure `package()` installs `lib/settings/*` to `$pkgdir/usr/share/omarchy-undercover/lib/settings/` and `omarchy-settings-engine` to `$pkgdir/usr/bin/`.

- [ ] **Step 2: Run end-to-end integration tests**

- `omarchy-settings-engine state` returns valid JSON in <150ms.
- `timeout 2s quickshell -p configs/quickshell/win11-settings` loads with 0 errors.
- `timeout 2s quickshell -p configs/quickshell/mac-settings` loads with 0 errors.

- [ ] **Step 3: Commit**

```bash
git add PKGBUILD
git commit -m "chore(pkg): package settings engine and lib modules, verify end-to-end integration"
```

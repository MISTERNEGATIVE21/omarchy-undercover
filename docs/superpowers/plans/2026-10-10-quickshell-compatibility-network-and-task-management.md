# Quickshell 0.3.2 Compatibility, Network Forget Actions, Disguise Lifecycle, and Task Management Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Implement Network Forget actions for Wi-Fi and Bluetooth across macOS and Windows modes, configure disguise mode to be temporary by default (with persistent toggle/flag), fix Notepad opening Task Manager and connect it to `omawrite`, enhance Stage Manager intelligence and Windows task/window management, and modernize IPC and runtime compatibility for Quickshell 0.3.2.

**Architecture:** Extend `omarchy-wifi-dbus` and `omarchy-bluetooth-dbus` with native D-Bus `forget` subcommands and connect them to UI buttons across all Quickshell flyouts and control centers. Decouple taskbar right-clicks from Task Manager and configure Notepad to launch `omawrite`. Implement startup lifecycle hooks in `scripts/omarchy-undercover` and `Service.qml` to default to normal mode unless persistence is enabled. Upgrade Stage Manager with auto-hiding and stack cycling, and harden Windows Task View and Task Manager.

**Tech Stack:** Quickshell 0.3.2 (QML / Wayland / Hyprland), Python 3 (dbus-python, NetworkManager, BlueZ), Bash, Hyprland IPC (`hyprctl`), Adwaita/GTK4.

**Spec:** [docs/superpowers/specs/2026-10-10-quickshell-compatibility-network-and-task-management-design.md](file:///home/mister/omarchy-undercover/docs/superpowers/specs/2026-10-10-quickshell-compatibility-network-and-task-management-design.md)

## Global Constraints
- Target Quickshell runtime: Quickshell 0.3.2 (`quickshell -p <path>`).
- Modern IPC syntax: `quickshell ipc call <target> <method>` / `qs ipc call <target> <method>` (never deprecated `msg`).
- Pinned editor command: `omawrite || leafpad || gedit || kate || mousepad || gnome-text-editor || xdg-terminal-exec -e nano`.
- Disguise persistence default: `DISGUISE_PERSISTENT=false` / temporary (normal Omarchy mode on reboot/login).
- Non-destructive configuration management: never wipe user custom configurations or baseline files.

## Review Focus
1. `omarchy-wifi-dbus forget <ssid>` when SSID is saved vs when SSID is currently connected.
2. `omarchy-bluetooth-dbus forget <mac>` when device is paired vs unbonded.
3. System startup with `DISGUISE_PERSISTENT=false` cleanly resetting to normal mode without leaving stale layer surfaces.
4. Left-click and right-click on Notepad on Windows taskbar launching `omawrite` and opening context menu respectively without triggering Task Manager.
5. Stage Manager rail smoothly hiding when a stage window touches left screen boundary and restoring on hover.

---

### Task 1: Network Backend "Forget" Protocols (`omarchy-wifi-dbus` & `omarchy-bluetooth-dbus`)

**Files:**
- Modify: `scripts/omarchy-wifi-dbus:240-260`, `scripts/omarchy-wifi-dbus:380-410`
- Modify: `scripts/omarchy-bluetooth-dbus:180-245`
- Test: `tests/test_system_protocols.sh`

**Interfaces:**
- Consumes: NetworkManager `Settings.Connection.Delete()` and BlueZ `Adapter1.RemoveDevice()`.
- Produces: `omarchy-wifi-dbus forget <ssid>` and `omarchy-bluetooth-dbus forget <mac>`.

- [ ] **Step 1: Write test cases in `tests/test_system_protocols.sh` for forget commands**

Add validation for `omarchy-wifi-dbus forget --help` / argument handling and `omarchy-bluetooth-dbus forget` validation.

- [ ] **Step 2: Run test to verify it fails**

Run: `bash tests/test_system_protocols.sh`  
Expected: FAIL because `forget` is not yet a supported subcommand in `omarchy-wifi-dbus` or `omarchy-bluetooth-dbus`.

- [ ] **Step 3: Implement `cmd_forget(ssid)` in `scripts/omarchy-wifi-dbus`**

Iterate `ListConnections()` on `org.freedesktop.NetworkManager.Settings`, locate connections matching the SSID or ID, and invoke `Delete()`. Fall back to `nmcli connection delete id "$ssid"` and `nmcli connection delete "$ssid"`. Add `forget` to CLI parser.

- [ ] **Step 4: Implement `cmd_forget(mac)` in `scripts/omarchy-bluetooth-dbus`**

Locate device path in BlueZ ObjectManager, invoke `RemoveDevice(dev_path)` on `Adapter1`. Fall back to `omarchy-bluetooth-device forget "$mac"` and `bluetoothctl remove "$mac"`. Add `forget` to CLI parser.

- [ ] **Step 5: Run tests to verify they pass**

Run: `bash tests/test_system_protocols.sh`  
Expected: PASS.

- [ ] **Step 6: Commit**

```bash
git add scripts/omarchy-wifi-dbus scripts/omarchy-bluetooth-dbus tests/test_system_protocols.sh
git commit -m "feat(protocols): implement native forget subcommands in wifi and bluetooth dbus engines"
```

---

### Task 2: Disguise Lifecycle, Startup Hook & Persistence Engine

**Files:**
- Modify: `settings.conf`
- Modify: `scripts/omarchy-undercover:1425-1550`
- Modify: `Service.qml:15-35`, `Service.qml:130-150`
- Modify: `scripts/omarchy-undercover-settings`
- Test: `tests/test_mode_switching.sh`

**Interfaces:**
- Consumes: `settings.conf` key `DISGUISE_PERSISTENT=false|true`.
- Produces: CLI options `--persistent`, `--temporary`, `--startup` in `omarchy-undercover`.

- [ ] **Step 1: Write test case in `tests/test_mode_switching.sh` for startup persistence behavior**

Test `omarchy-undercover --startup` when `DISGUISE_PERSISTENT=false` (verifies switch to normal mode) and when `DISGUISE_PERSISTENT=true` (verifies disguise preserved).

- [ ] **Step 2: Run test to verify it fails**

Run: `bash tests/test_mode_switching.sh`  
Expected: FAIL because `--startup` option does not exist yet.

- [ ] **Step 3: Implement persistence settings and CLI flags in `scripts/omarchy-undercover`**

Add `--persistent` and `--temporary` flags that write `DISGUISE_PERSISTENT=true` or `false` to `settings.conf`. Add `--startup` action that checks `DISGUISE_PERSISTENT`: if false/temporary, execute `switch_to_omarchy` and clean up disguise state.

- [ ] **Step 4: Update `Service.qml` initialization**

Change line 17 `property string currentState: "omarchy"` (instead of `"mac-dark"`). In `Component.onCompleted`, check `DISGUISE_PERSISTENT` from `settingsConfFile`: if false/unset, ensure root state is `"omarchy"` and invoke restore to baseline if needed.

- [ ] **Step 5: Update `omarchy-undercover-settings` with Disguise Persistence toggle**

Add a SwitchRow in the General / Appearance settings page: "Disguise Persistence" (Temporary session disguise vs Persistent across reboots).

- [ ] **Step 6: Run tests to verify they pass**

Run: `bash tests/test_mode_switching.sh`  
Expected: PASS.

- [ ] **Step 7: Commit**

```bash
git add settings.conf scripts/omarchy-undercover Service.qml scripts/omarchy-undercover-settings tests/test_mode_switching.sh
git commit -m "feat(lifecycle): default to normal mode on boot with temporary and persistent disguise modes"
```

---

### Task 3: Notepad Text Editor Integration & Taskbar Fix

**Files:**
- Modify: `widgets/win11-taskbar.qml:515-535`, `widgets/win11-taskbar.qml:830-845`
- Modify: `configs/quickshell/win11-start/shell.qml:115-125`
- Modify: `scripts/omarchy-win11-startmenu:90-100`, `scripts/omarchy-win11-startmenu:125-135`
- Modify: `scripts/omarchy-undercover-settings:930-940`
- Test: `tests/test_win11_taskmanager.sh`, `tests/test_win11_protocols.sh`

**Interfaces:**
- Consumes: `omawrite` binary on host system.
- Produces: Correct Notepad launching and clean right-click handling without task manager trigger.

- [ ] **Step 1: Write test in `tests/test_win11_taskmanager.sh` to verify Notepad does not trigger Task Manager**

Verify right-clicking pinned items in `win11-taskbar.qml` does not run `omarchy-win11-taskmanager` and Notepad executes `omawrite`.

- [ ] **Step 2: Run test to verify it fails**

Run: `bash tests/test_win11_taskmanager.sh`  
Expected: FAIL because right-click currently triggers `omarchy-win11-taskmanager`.

- [ ] **Step 3: Update `widgets/win11-taskbar.qml`**

Change Notepad definition:
```qml
{ id: "notepad", name: "Notepad", iconFile: "notepad.svg", exec: "omawrite || leafpad || gedit || kate || mousepad || gnome-text-editor || xdg-terminal-exec -e nano", matchers: ["omawrite", "leafpad", "gedit", "kate", "mousepad", "gnome-text-editor", "text-editor", "sublime_text", "nvim", "kwrite"] }
```
In `handleClick(button)` for `Qt.RightButton`:
Remove `root.runCmd("omarchy-win11-taskmanager || omarchy-win11-taskview")` fallback on pinned items. If not running, either launch the app or show item tooltip/options.

- [ ] **Step 4: Update `configs/quickshell/win11-start/shell.qml` & `scripts/omarchy-win11-startmenu`**

Set Notepad exec in start menu to `omawrite || leafpad || gedit || kate || mousepad || gnome-text-editor`.

- [ ] **Step 5: Run tests to verify they pass**

Run: `bash tests/test_win11_taskmanager.sh && bash tests/test_win11_protocols.sh`  
Expected: PASS.

- [ ] **Step 6: Commit**

```bash
git add widgets/win11-taskbar.qml configs/quickshell/win11-start/shell.qml scripts/omarchy-win11-startmenu scripts/omarchy-undercover-settings tests/test_win11_taskmanager.sh
git commit -m "fix(notepad): connect notepad to omawrite and fix taskbar right-click task manager bug"
```

---

### Task 4: macOS Wi-Fi & Bluetooth UI Panels with Visible Forget Actions

**Files:**
- Modify: `configs/quickshell/mac-wifi/shell.qml:590-760`
- Modify: `configs/quickshell/mac-bluetooth/shell.qml:395-445`
- Modify: `configs/quickshell/mac-controlcenter/shell.qml:1500-1780`
- Modify: `widgets/mac-wifi.qml`, `widgets/mac-bluetooth.qml`
- Test: `tests/test_mac_controlcenter_protocols.sh`, `tests/test_mac_flyouts_protocols.sh`

**Interfaces:**
- Consumes: `omarchy-wifi-dbus forget <ssid>` and `omarchy-bluetooth-dbus forget <mac>`.
- Produces: Visible Forget and Disconnect UI controls in macOS panels.

- [ ] **Step 1: Write test assertions in `tests/test_mac_flyouts_protocols.sh` for forget controls**

Verify presence of `forget` bindings in `mac-wifi/shell.qml` and `mac-bluetooth/shell.qml`.

- [ ] **Step 2: Run test to verify it fails**

Run: `bash tests/test_mac_flyouts_protocols.sh`  
Expected: FAIL due to missing Wi-Fi forget binding in `mac-wifi`.

- [ ] **Step 3: Add Forget action to `mac-wifi/shell.qml` & `mac-controlcenter/shell.qml`**

In the active connection banner: Add a "Forget" button next to the network name, executing `omarchy-wifi-dbus forget "<ssid>"`.  
In saved networks list items: Add a "Forget" action icon / button next to the "Saved" badge.

- [ ] **Step 4: Add Forget Device action to `mac-bluetooth/shell.qml` & `mac-controlcenter/shell.qml`**

Add a visible "Forget" button alongside "Connect / Disconnect" for paired devices, executing `omarchy-bluetooth-dbus forget "<mac>"`.

- [ ] **Step 5: Run tests to verify they pass**

Run: `bash tests/test_mac_controlcenter_protocols.sh && bash tests/test_mac_flyouts_protocols.sh`  
Expected: PASS.

- [ ] **Step 6: Commit**

```bash
git add configs/quickshell/mac-wifi/shell.qml configs/quickshell/mac-bluetooth/shell.qml configs/quickshell/mac-controlcenter/shell.qml widgets/mac-wifi.qml widgets/mac-bluetooth.qml tests/test_mac_flyouts_protocols.sh
git commit -m "feat(macos): add visible forget wifi and forget bluetooth controls to mac flyouts and control center"
```

---

### Task 5: Windows 11 Wi-Fi & Bluetooth UI Panels with Visible Forget Actions

**Files:**
- Modify: `configs/quickshell/win11-wifi/shell.qml:680-740`
- Modify: `configs/quickshell/win11-bluetooth/shell.qml:620-685`
- Modify: `configs/quickshell/win11-actioncenter/shell.qml:1700-1900`, `2080-2130`
- Test: `tests/test_win11_protocols.sh`

**Interfaces:**
- Consumes: `omarchy-wifi-dbus forget <ssid>` and `omarchy-bluetooth-dbus forget <mac>`.
- Produces: Visible Forget controls in Windows 11 Action Center & flyouts.

- [ ] **Step 1: Write test assertions in `tests/test_win11_protocols.sh` for Windows forget controls**

Verify presence of `forget` triggers for both Wi-Fi and Bluetooth.

- [ ] **Step 2: Run test to verify it fails**

Run: `bash tests/test_win11_protocols.sh`  
Expected: FAIL due to missing Wi-Fi forget in `win11-wifi`.

- [ ] **Step 3: Add Forget action to `win11-wifi/shell.qml` & `win11-actioncenter/shell.qml`**

In the active connected banner: add a secondary "Forget" button next to "Disconnect". In saved networks rows, add a Forget button.

- [ ] **Step 4: Add Forget action to `win11-bluetooth/shell.qml` & `win11-actioncenter/shell.qml`**

Add a visible "Forget" button next to "Connect/Disconnect" in the device row.

- [ ] **Step 5: Run tests to verify they pass**

Run: `bash tests/test_win11_protocols.sh`  
Expected: PASS.

- [ ] **Step 6: Commit**

```bash
git add configs/quickshell/win11-wifi/shell.qml configs/quickshell/win11-bluetooth/shell.qml configs/quickshell/win11-actioncenter/shell.qml tests/test_win11_protocols.sh
git commit -m "feat(win11): add visible forget wifi and forget bluetooth controls to action center and flyouts"
```

---

### Task 6: Intelligent macOS Stage Manager & Navigation Hardening

**Files:**
- Modify: `configs/quickshell/mac-stagemanager/StageManager.qml:100-250`, `600-750`
- Modify: `scripts/omarchy-mac-stagemanager:45-95`
- Test: `tests/test_stagemanager_cli.sh`, `tests/test_stagemanager_navigation.sh`

**Interfaces:**
- Consumes: Hyprland active window geometries and toplevel handles.
- Produces: Intelligent Stage Manager rail auto-hiding and window stack cycling.

- [ ] **Step 1: Write test assertions in `tests/test_stagemanager_navigation.sh`**

Test stage manager group cycling logic and auto-hide threshold calculation.

- [ ] **Step 2: Run test to verify it fails**

Run: `bash tests/test_stagemanager_navigation.sh`  
Expected: FAIL for new auto-hide threshold assertions.

- [ ] **Step 3: Implement intelligent auto-hide and stacking in `StageManager.qml`**

Add detection of whether active window intersects the left rail (x < railWidth) or is fullscreen; if so, animate the rail to `x: -railWidth` with an edge hover trigger rectangle to temporarily reveal it.  
Add window cycling within group when clicked repeatedly.

- [ ] **Step 4: Run tests to verify they pass**

Run: `bash tests/test_stagemanager_cli.sh && bash tests/test_stagemanager_navigation.sh`  
Expected: PASS.

- [ ] **Step 5: Commit**

```bash
git add configs/quickshell/mac-stagemanager/StageManager.qml scripts/omarchy-mac-stagemanager tests/test_stagemanager_navigation.sh
git commit -m "feat(stagemanager): add intelligent rail auto-hiding, stack depth, and multi-window cycling"
```

---

### Task 7: Windows 11 Task & Window Management Overhaul

**Files:**
- Modify: `configs/quickshell/win11-taskview/shell.qml:70-130`, `500-600`
- Modify: `configs/quickshell/win11-taskmanager/shell.qml:70-120`
- Modify: `widgets/win11-taskbar.qml:530-600`, `1100-1160`
- Test: `tests/test_win11_taskmanager.sh`

**Interfaces:**
- Consumes: Hyprland workspaces and window dispatchers.
- Produces: Robust virtual desktop operations, taskbar multi-instance grouping, and task management.

- [ ] **Step 1: Write test assertions in `tests/test_win11_taskmanager.sh` for taskview desktop creation**

Verify `win11-taskview/shell.qml` creates and switches workspaces cleanly without error.

- [ ] **Step 2: Run test to verify it fails**

Run: `bash tests/test_win11_taskmanager.sh`  
Expected: FAIL for new workspace dispatcher assertions.

- [ ] **Step 3: Enhance `win11-taskview/shell.qml` and `win11-taskmanager/shell.qml`**

Add New Desktop creation dispatcher (`hyprctl dispatch workspace empty`), close desktop window dispatchers, and process search filtering. Ensure taskbar previews render thumbnail titles and close buttons cleanly.

- [ ] **Step 4: Run tests to verify they pass**

Run: `bash tests/test_win11_taskmanager.sh`  
Expected: PASS.

- [ ] **Step 5: Commit**

```bash
git add configs/quickshell/win11-taskview/shell.qml configs/quickshell/win11-taskmanager/shell.qml widgets/win11-taskbar.qml tests/test_win11_taskmanager.sh
git commit -m "feat(win11): harden task view virtual desktops, taskbar grouping, and task manager controls"
```

---

### Task 8: Quickshell 0.3.2 IPC Deprecation Cleanup & End-to-End Test Suite

**Files:**
- Modify: all scripts in `scripts/` with `quickshell msg` / `qs msg` usages
- Modify: `tests/test_e2e_system_protocols.sh`, `tests/test_e2e_undercover_overhaul.sh`
- Test: All suites in `tests/`

**Interfaces:**
- Consumes: Quickshell 0.3.2 IPC command line syntax.
- Produces: 100% test pass rate across the full test suite.

- [ ] **Step 1: Scan and replace deprecated IPC commands**

Verify all `qs msg` / `quickshell msg` are replaced with `qs ipc call` / `quickshell ipc call`.

- [ ] **Step 2: Validate all 18 Quickshell bundles with Quickshell 0.3.2**

Run quickshell timeout checks on each bundle to ensure no syntax errors or fatal warnings.

- [ ] **Step 3: Run comprehensive end-to-end test suite**

Run: `bash tests/test_e2e_system_protocols.sh && bash tests/test_e2e_undercover_overhaul.sh`  
Expected: ALL PASS.

- [ ] **Step 4: Commit**

```bash
git add scripts/ tests/
git commit -m "test: verify Quickshell 0.3.2 compatibility, network protocols, and task management across all suites"
```

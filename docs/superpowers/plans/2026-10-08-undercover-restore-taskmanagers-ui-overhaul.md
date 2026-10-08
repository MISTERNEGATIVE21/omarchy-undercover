# Omarchy Undercover Restore, Task Managers & UI/UX Overhaul Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Fix the top bar restore failure, implement native task managers for macOS and Windows 11 modes, overhaul Stage Manager window navigation logic, unify window control buttons, and enhance file manager UX and UI color contrast.

**Architecture:** A native Quickshell and shell script architecture leveraging existing Omarchy 4.0 and Hyprland IPC primitives. The restore engine enforces strict baseline validation and pristine fallback to `/usr/share/omarchy/config/omarchy/shell.json`. Activity Monitor is built as a native Quickshell overlay with real-time `/proc` metrics. Stage Manager adds dual-axis keyboard navigation (Up/Down for groups, Left/Right for individual windows) and interactive stack clicking. Contrast is improved using CSS drop shadows and frosted acrylic layering.

**Tech Stack:** Bash, Quickshell (QML / QtQuick), Wayland / Hyprland IPC, Linux `/proc` stats, GTK 3/4 CSS.

**Spec:** [`docs/superpowers/specs/2026-10-08-undercover-restore-taskmanagers-ui-overhaul-design.md`](file:///home/mister/omarchy-undercover/docs/superpowers/specs/2026-10-08-undercover-restore-taskmanagers-ui-overhaul-design.md)

## Global Constraints
- Omarchy 4.0 compatibility: Lua-based Hyprland config files must be preserved and dynamically loaded.
- Quickshell QML must load cleanly with `quickshell -p <path>` without fatal QML syntax errors.
- Never hardcode user home paths; always use `$HOME` or `Quickshell.env("HOME")`.
- Shell scripts must use `set -euo pipefail` where applicable.
- All file manager calls must honor Flea when available and fallback to standard installed file managers (Nautilus, Thunar, Dolphin).

## Review Focus
1. `restore_shell_from_baseline` called when no baseline exists and `shell.json` contains `mac-*` widgets must restore clean stock Omarchy layout with standard widgets and `bar.transparent = false`.
2. Windows 11 Task Manager launched with <kbd>Ctrl</kbd>+<kbd>Shift</kbd>+<kbd>Escape</kbd> must allow maximizing to screen bounds and restoring down, while minimize must move to `special:minimized`.
3. macOS Activity Monitor launched with <kbd>Super</kbd>+<kbd>Alt</kbd>+<kbd>Escape</kbd> must display process rows and terminate processes when Force Quit is pressed.
4. Stage Manager navigation must cycle through individual windows in an app group when pressing <kbd>Left</kbd> or <kbd>Right</kbd>, and clicking a background stacked card must bring it forward.
5. Contrast on macOS top bar widgets (`mac-clock`, `mac-appmenu`, `mac-apple`) must remain visible against a pure `#ffffff` white background.

---

### Task 1: Top Bar & Shell State Restoration Engine Fix

**Files:**
- Modify: `scripts/omarchy-undercover:392-427, 480-515, 1037-1065, 1180-1191`
- Test: `tests/test_restore_shell.sh`

**Interfaces:**
- Consumes: `/usr/share/omarchy/config/omarchy/shell.json` (or `configs/shell/shell-default.json`)
- Produces: Clean, restored `~/.config/omarchy/shell.json` with standard Omarchy widgets and `bar.transparent: false`

- [ ] **Step 1: Write the failing test for shell restoration**

Create `tests/test_restore_shell.sh` to simulate a corrupted `shell.json` full of `mac-*` widgets with `bar.transparent: true` and execute `restore_shell_from_baseline` to verify it cleans all `mac-*` widgets and restores standard Omarchy widgets.

```bash
#!/usr/bin/env bash
set -euo pipefail
# Test that restore_shell_from_baseline restores default omarchy layout when baseline is empty
TMP_HOME=$(mktemp -d)
trap 'rm -rf "$TMP_HOME"' EXIT
export HOME="$TMP_HOME"
mkdir -p "$HOME/.config/omarchy"

# Simulate tainted macos shell.json
cat << 'EOF' > "$HOME/.config/omarchy/shell.json"
{
  "bar": {
    "position": "top",
    "transparent": true,
    "layout": {
      "left": [{"id": "mac-apple"}, {"id": "mac-appmenu"}],
      "right": [{"id": "mac-clock"}, {"id": "mac-battery"}]
    }
  },
  "plugins": ["omarchy-undercover"]
}
EOF

# Source and invoke restore logic
REPO_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
export SCRIPT_DIR="$REPO_DIR/scripts"
source "$REPO_DIR/scripts/common.sh"
# Test the restore function directly
# Expected: ~/.config/omarchy/shell.json must not have mac-apple and must have omarchy.menu or omarchy.clock
```

- [ ] **Step 2: Run test to verify it fails**

Run: `bash tests/test_restore_shell.sh`
Expected: FAIL (mac-* widgets remain in shell.json)

- [ ] **Step 3: Implement clean restoration logic in `scripts/omarchy-undercover`**

Update `restore_shell_from_baseline` to:
1. Verify if `$baseline/omarchy/shell.json` exists and contains no `mac-`, `win11-`, or `undercover` entries.
2. If tainted or missing, copy `/usr/share/omarchy/config/omarchy/shell.json` (or fallback `$SCRIPT_DIR/../configs/shell/shell-default.json`) to `~/.config/omarchy/shell.json`.
3. If custom user widgets exist, sanitize all `mac-*` and `win11-*` widget entries, reset `bar.transparent` to `false`, and restore `bar.centerAnchor` to `"omarchy.clock"`.
4. Also ensure `apply_shell_mac` snapshots clean `shell.json` into baseline before overwriting.

- [ ] **Step 4: Run test to verify it passes**

Run: `bash tests/test_restore_shell.sh`
Expected: PASS

- [ ] **Step 5: Commit**

```bash
git add scripts/omarchy-undercover tests/test_restore_shell.sh
git commit -m "fix(shell): properly restore default Omarchy top bar and purge macos widgets"
```

---

### Task 2: Native macOS Activity Monitor Component

**Files:**
- Create: `configs/quickshell/mac-activitymonitor/shell.qml`
- Create: `scripts/omarchy-mac-activitymonitor`
- Test: `tests/test_mac_activitymonitor.sh`

**Interfaces:**
- Consumes: Process metrics from `scripts/omarchy-win11-taskmanager-backend`
- Produces: `omarchy-mac-activitymonitor` CLI command & Quickshell GUI

- [ ] **Step 1: Write the failing test for Activity Monitor launcher and syntax**

Create `tests/test_mac_activitymonitor.sh` to test:
1. `scripts/omarchy-mac-activitymonitor` exists and is executable.
2. `configs/quickshell/mac-activitymonitor/shell.qml` exists and validates with Quickshell.

- [ ] **Step 2: Run test to verify it fails**

Run: `bash tests/test_mac_activitymonitor.sh`
Expected: FAIL (script and QML missing)

- [ ] **Step 3: Implement `configs/quickshell/mac-activitymonitor/shell.qml` and `scripts/omarchy-mac-activitymonitor`**

1. Build `shell.qml` with:
   - PanelWindow with `WlrLayershell.layer: WlrLayer.Overlay`.
   - Top-left traffic lights (Red `#ff5f57` Close, Yellow `#febc2e` Minimize, Green `#28c840` Zoom/Maximize).
   - Centered segmented tab buttons (CPU, Memory, Disk, Network).
   - Top toolbar with Force Quit button (`✕`), Info button (`ⓘ`), and search bar.
   - Process Table displaying live apps and background processes with PID, Name, CPU %, Memory MB, and status.
   - Force quit function using `kill -9` or `hyprctl dispatch closewindow`.
   - Live CPU and Memory historical graphs at bottom.
2. Create `scripts/omarchy-mac-activitymonitor` with PID file tracking and toggle handling (`chmod +x`).

- [ ] **Step 4: Run test to verify it passes**

Run: `bash tests/test_mac_activitymonitor.sh`
Expected: PASS

- [ ] **Step 5: Commit**

```bash
git add configs/quickshell/mac-activitymonitor scripts/omarchy-mac-activitymonitor tests/test_mac_activitymonitor.sh
git commit -m "feat(macos): add native Quickshell Activity Monitor"
```

---

### Task 3: Windows 11 Task Manager Window Controls & Shortcuts

**Files:**
- Modify: `configs/quickshell/win11-taskmanager/shell.qml:308-333`
- Modify: `configs/hypr/windows-mode.lua:300-325`
- Modify: `configs/hypr/windows-mode.conf:70-90`
- Modify: `configs/waybar/config-win.jsonc:37-57`
- Test: `tests/test_win11_taskmanager.sh`

**Interfaces:**
- Consumes: `scripts/omarchy-win11-taskmanager`
- Produces: Working maximize/restore toggle, working minimize, and <kbd>Ctrl</kbd>+<kbd>Shift</kbd>+<kbd>Escape</kbd> shortcut

- [ ] **Step 1: Write test for Windows 11 Task Manager keybinding and maximize state**

Create `tests/test_win11_taskmanager.sh` checking:
1. `configs/hypr/windows-mode.lua` binds `CTRL + SHIFT + ESCAPE` to `omarchy-win11-taskmanager`.
2. `configs/hypr/windows-mode.conf` binds `CTRL SHIFT, Escape`.
3. `config-win.jsonc` has `on-click-right` bound to `omarchy-win11-taskmanager` on start menu / taskbar.
4. `win11-taskmanager/shell.qml` contains maximize toggle logic (`isMaximized` property, alternate icon `🗗` vs `□`).

- [ ] **Step 2: Run test to verify it fails**

Run: `bash tests/test_win11_taskmanager.sh`
Expected: FAIL

- [ ] **Step 3: Implement maximize/restore, minimize, and shortcuts**

1. In `configs/quickshell/win11-taskmanager/shell.qml`:
   - Add `property bool isMaximized: false`.
   - Update `btnMaxM` onClicked to toggle `isMaximized`. When maximized, resize frame to `parent.width - 20` and `parent.height - 40`; otherwise `1020` x `680`.
   - Change maximize icon text to `isMaximized ? "🗗" : "□"`.
   - In `btnMinM`, execute `omarchy-undercover-minimize` or hide window gracefully.
2. In `configs/hypr/windows-mode.lua` and `windows-mode.conf`:
   - Add `bind_key("BIND_WIN_TASKMANAGER", "CTRL + SHIFT + ESCAPE", exec_cmd("omarchy-win11-taskmanager"), "Windows 11 Task Manager")`.
3. In `configs/waybar/config-win.jsonc`:
   - Add `"on-click-right": "omarchy-win11-taskmanager"` to `custom/startmenu` and `wlr/taskbar`.

- [ ] **Step 4: Run test to verify it passes**

Run: `bash tests/test_win11_taskmanager.sh`
Expected: PASS

- [ ] **Step 5: Commit**

```bash
git add configs/quickshell/win11-taskmanager/shell.qml configs/hypr/windows-mode.lua configs/hypr/windows-mode.conf configs/waybar/config-win.jsonc tests/test_win11_taskmanager.sh
git commit -m "feat(win11): bind Ctrl+Shift+Esc and add Task Manager maximize/restore controls"
```

---

### Task 4: macOS Shortcuts & Apple Menu Activity Monitor Wiring

**Files:**
- Modify: `configs/hypr/mac-mode.lua:197-220`
- Modify: `configs/hypr/mac-mode.conf:80-96`
- Modify: `widgets/mac-apple.qml:165-182`
- Test: `tests/test_mac_shortcuts.sh`

**Interfaces:**
- Consumes: `scripts/omarchy-mac-activitymonitor`
- Produces: <kbd>Super</kbd>+<kbd>Alt</kbd>+<kbd>Escape</kbd> binding and Apple Menu item

- [ ] **Step 1: Write test for macOS Activity Monitor shortcuts and menu**

Create `tests/test_mac_shortcuts.sh` verifying:
1. `configs/hypr/mac-mode.lua` binds `SUPER + ALT + ESCAPE` to `omarchy-mac-activitymonitor`.
2. `widgets/mac-apple.qml` contains "Activity Monitor..." and wires "Force Quit Applications..." to `omarchy-mac-activitymonitor`.

- [ ] **Step 2: Run test to verify it fails**

Run: `bash tests/test_mac_shortcuts.sh`
Expected: FAIL

- [ ] **Step 3: Update `mac-mode.lua`, `mac-mode.conf`, and `mac-apple.qml`**

1. In `configs/hypr/mac-mode.lua` and `mac-mode.conf`:
   - Bind `SUPER + ALT + ESCAPE` to `omarchy-mac-activitymonitor`.
2. In `widgets/mac-apple.qml`:
   - Change "Force Quit Applications..." click action to `root.runCmd("omarchy-mac-activitymonitor")`.
   - Add "Activity Monitor..." item in the Apple Menu dropdown right below System Settings.

- [ ] **Step 4: Run test to verify it passes**

Run: `bash tests/test_mac_shortcuts.sh`
Expected: PASS

- [ ] **Step 5: Commit**

```bash
git add configs/hypr/mac-mode.lua configs/hypr/mac-mode.conf widgets/mac-apple.qml tests/test_mac_shortcuts.sh
git commit -m "feat(macos): wire Super+Alt+Esc and Apple Menu to Activity Monitor"
```

---

### Task 5: Stage Manager App & Window Navigation Logic

**Files:**
- Modify: `configs/quickshell/mac-stagemanager/StageManager.qml:220-255, 335-350, 770-820`
- Test: `tests/test_stagemanager_navigation.sh`

**Interfaces:**
- Consumes: `Hyprland.toplevels`
- Produces: Dual-axis navigation, clickable `StackLayer` cards, and workspace-aware activation

- [ ] **Step 1: Write test for Stage Manager navigation logic**

Create `tests/test_stagemanager_navigation.sh` verifying:
1. `keyCatcher` handles `Key_Left` and `Key_Right` to cycle windows within the current group.
2. `StackLayer` component contains an active `MouseArea` to bring clicked card to front.
3. `activate` switches workspace before focusing window when `workspaceId` is on another workspace.

- [ ] **Step 2: Run test to verify it fails**

Run: `bash tests/test_stagemanager_navigation.sh`
Expected: FAIL

- [ ] **Step 3: Implement Stage Manager navigation logic**

1. In `StageManager.qml`:
   - Add `function cycleGroupWindow(delta)`: finds active AppGroup and increments/decrements `currentIndex` and `root.selectedAddress`.
   - In `keyCatcher`:
     - `Key_Left`: `cycleGroupWindow(-1)`
     - `Key_Right`: `cycleGroupWindow(1)`
   - In `StackLayer`:
     - Add `MouseArea`: `onClicked: { appGroup.selectWindow(stackLayer.layerWindowIndex); root.activate(stackLayer.record); }`
   - In `activate(record)`:
     - Check `record.workspaceId`. If positive and not equal to current workspace, dispatch `hyprctl dispatch workspace <id>` then `focuswindow address:<addr>`.

- [ ] **Step 4: Run test to verify it passes**

Run: `bash tests/test_stagemanager_navigation.sh`
Expected: PASS

- [ ] **Step 5: Commit**

```bash
git add configs/quickshell/mac-stagemanager/StageManager.qml tests/test_stagemanager_navigation.sh
git commit -m "fix(stagemanager): implement Left/Right window cycling and interactive stack clicking"
```

---

### Task 6: Window Navigation Controls (Exit, Minimize, Maximize) Across Windows & GTK

**Files:**
- Modify: `configs/quickshell/mac-settings/shell.qml:515-585`
- Modify: `configs/quickshell/win11-settings/shell.qml:350-400`
- Modify: `scripts/omarchy-undercover:795-810, 930-945`
- Test: `tests/test_window_controls.sh`

**Interfaces:**
- Consumes: `gsettings`, GTK configuration files
- Produces: Functional 3-button traffic lights and Fluent window buttons

- [ ] **Step 1: Write test for window navigation controls**

Create `tests/test_window_controls.sh` verifying:
1. macOS settings has working Red (Close), Yellow (Minimize to special workspace), Green (Maximize/restore toggle) with hover glyphs.
2. Windows 11 settings has working Minimize, Maximize toggle, and Close.
3. `omarchy-undercover` applies GTK decoration layouts `close,minimize,maximize:` on macOS and `:minimize,maximize,close` on Windows.

- [ ] **Step 2: Run test to verify it fails**

Run: `bash tests/test_window_controls.sh`
Expected: FAIL

- [ ] **Step 3: Implement window navigation control behaviors**

1. In `mac-settings/shell.qml`:
   - Green zoom button: Implement toggle between normal size (980x640) and maximized size (`screen.width - 20`, `screen.height - 60`).
   - Yellow minimize button: Smoothly dock to `special:minimized`.
2. In `win11-settings/shell.qml`:
   - Ensure maximize button toggles maximized state and updates icon (`□` / `🗗`).
   - Ensure minimize button docks to `special:minimized`.
3. In `scripts/omarchy-undercover`:
   - Ensure `button-layout` is strictly written to `gsettings`, GTK 3/4 `settings.ini`, and `xsettingsd.conf`.

- [ ] **Step 4: Run test to verify it passes**

Run: `bash tests/test_window_controls.sh`
Expected: PASS

- [ ] **Step 5: Commit**

```bash
git add configs/quickshell/mac-settings/shell.qml configs/quickshell/win11-settings/shell.qml scripts/omarchy-undercover tests/test_window_controls.sh
git commit -m "feat(ui): complete window control navigation behaviors for macOS and Windows 11"
```

---

### Task 7: File Managers & Color Contrast / Readability Overhaul

**Files:**
- Modify: `scripts/omarchy-undercover-filemanager:70-90`
- Modify: `widgets/mac-clock.qml`, `widgets/mac-appmenu.qml`, `widgets/mac-apple.qml`
- Modify: `configs/waybar/style-mac.css`, `configs/waybar/style-win.css`
- Test: `tests/test_contrast_and_filemanager.sh`

**Interfaces:**
- Consumes: Flea CLI `--ui-state`
- Produces: Polished Miller column Finder vs Details Explorer and high-contrast top bar / taskbar

- [ ] **Step 1: Write test for file manager presets and CSS contrast rules**

Create `tests/test_contrast_and_filemanager.sh` verifying:
1. `omarchy-undercover-filemanager` passes Miller column configuration for macOS and Details list for Windows.
2. `style-mac.css` contains text shadows and high-contrast background rules for top bar readability.
3. `style-win.css` defines solid acrylic background with high-contrast text and icons.

- [ ] **Step 2: Run test to verify it fails**

Run: `bash tests/test_contrast_and_filemanager.sh`
Expected: FAIL

- [ ] **Step 3: Implement file manager configurations and contrast enhancements**

1. In `scripts/omarchy-undercover-filemanager`:
   - Enhance macOS Flea preset with Miller columns, system text scaling, breadcrumb address bar, and thumbnail previews.
   - Enhance Windows 11 Flea preset with Details list, path address bar, and Windows keymap.
2. In `widgets/mac-clock.qml`, `widgets/mac-appmenu.qml`, and `configs/waybar/style-mac.css`:
   - Add text drop-shadow (`0 1px 2px rgba(0,0,0,0.60)`) and frosted glass underlay to guarantee readability against pure white wallpapers.
3. In `configs/waybar/style-win.css`:
   - Set taskbar background to solid dark acrylic (`rgba(32,32,32,0.96)`) with `1px rgba(255,255,255,0.10)` top border and high-contrast font colors.

- [ ] **Step 4: Run test to verify it passes**

Run: `bash tests/test_contrast_and_filemanager.sh`
Expected: PASS

- [ ] **Step 5: Commit**

```bash
git add scripts/omarchy-undercover-filemanager widgets/mac-clock.qml widgets/mac-appmenu.qml configs/waybar/style-mac.css configs/waybar/style-win.css tests/test_contrast_and_filemanager.sh
git commit -m "feat(ui): refine Flea file manager presets and boost top bar/taskbar contrast"
```

---

### Task 8: End-to-End Verification & Regression Testing

**Files:**
- Test: `tests/test_e2e_undercover_overhaul.sh`

- [ ] **Step 1: Write comprehensive end-to-end test script**

Create `tests/test_e2e_undercover_overhaul.sh` verifying:
1. Switching to macOS mode and restoring returns `shell.json` to pristine Omarchy state.
2. `omarchy-mac-activitymonitor` launches and parses process data.
3. `omarchy-win11-taskmanager` has all hotkeys and window controls wired.
4. Stage Manager QML validates and exports dual-axis navigation methods.
5. All tests in `tests/test_*.sh` pass cleanly.

- [ ] **Step 2: Run end-to-end test**

Run: `bash tests/test_e2e_undercover_overhaul.sh`
Expected: PASS (all tests green)

- [ ] **Step 3: Commit final test suite**

```bash
git add tests/test_e2e_undercover_overhaul.sh
git commit -m "test: add comprehensive end-to-end test suite for undercover overhaul"
```

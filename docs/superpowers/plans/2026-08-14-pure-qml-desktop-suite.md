# Pure QML Desktop Transformation Suite & Dual-Theme Engine Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Build a 100% pure Quickshell QML desktop suite featuring dynamic Dark/Light theme switching, dedicated hardware popovers (Wi-Fi, Bluetooth, Sound), live App Search with an A-Z App Drawer, polished Fluent 2 Taskbar, and expanded GUI settings management.

**Architecture:** Native QML Layer-Shell architecture with reactive theme tokens (`ThemeTokens.qml`), asynchronous CLI process bindings (`nmcli`, `bluetoothctl`, `wpctl`), and comprehensive state management in `omarchy-undercover-settings`.

**Tech Stack:** Quickshell 0.0.9+ (QML/Qt6), Hyprland Wayland Compositor, Python 3 / PyGObject (GTK4/Libadwaita for settings), Bash, NetworkManager (`nmcli`), BlueZ (`bluetoothctl`), PipeWire (`wpctl`).

## Global Constraints

- **Theme Palettes**: Dark mode must use Mica Dark (`#202020` / `#1c1c20`) with white text (`#ffffff`) and cyan accents (`#60cdff`). Light mode must use Mica Light (`#f3f3f3` / `#ffffff`) with charcoal text (`#1a1a1a`) and deep blue accents (`#0067c0`).
- **Pure QML Popovers**: No GTK dialog popups for Wi-Fi, Bluetooth, Sound, or Start Menu; all popovers must be native Quickshell layer-shell windows with close buttons (`✕`).
- **Autohide Behavior**: Dock/Taskbar remains visible while cursor is hovering inside its region (`y >= screen_height - 56`), and hides smoothly when the cursor leaves.
- **Process Isolation**: macOS Dock and Windows 11 Taskbar must never render simultaneously.

---

### Task 1: Dynamic Dual-Theme Token Module & Color Palette System

**Files:**
- Create: `configs/quickshell/common/ThemeTokens.qml`
- Modify: `configs/shell/shell-win.json`
- Modify: `configs/shell/shell-mac.json`

**Interfaces:**
- Produces: `ThemeTokens` singleton properties (`bgColor`, `surfaceColor`, `textColor`, `subTextColor`, `accentColor`, `borderColor`, `activePillColor`, `isDark`)

- [ ] **Step 1: Create `ThemeTokens.qml` with dynamic state-aware theme tokens**
- [ ] **Step 2: Update `shell-win.json` and `shell-mac.json` with adaptive background and border styling**
- [ ] **Step 3: Test loading `ThemeTokens.qml` via quickshell parser**
- [ ] **Step 4: Commit theme tokens**

```bash
git add configs/quickshell/common/ThemeTokens.qml configs/shell/
git commit -m "feat(theme): implement dynamic QML theme token system for Dark and Light modes"
```

---

### Task 2: Native Pure-QML Wi-Fi Network Scanner & Manager Popover

**Files:**
- Create: `configs/quickshell/win11-wifi/shell.qml`
- Create: `configs/quickshell/mac-wifi/shell.qml`
- Modify: `scripts/omarchy-mac-wifi`
- Modify: `scripts/omarchy-win11-wifi`

**Interfaces:**
- Consumes: `nmcli -t -f in-use,ssid,bssid,signal,security dev wifi list`
- Produces: Popover for scanning SSIDs, connecting with password modal, and Wi-Fi toggle

- [ ] **Step 1: Implement `win11-wifi/shell.qml` with live SSID list, signal strength icons, password input, and close button**
- [ ] **Step 2: Implement `mac-wifi/shell.qml` with macOS Sequoia frosted glass styling and Wi-Fi switch**
- [ ] **Step 3: Update `omarchy-mac-wifi` and `omarchy-win11-wifi` to dispatch `quickshell -p ...` popovers**
- [ ] **Step 4: Test launching Wi-Fi popover and verify live network list parsing**
- [ ] **Step 5: Commit Wi-Fi popover**

```bash
git add configs/quickshell/*-wifi/ scripts/omarchy-*-wifi
git commit -m "feat(wifi): implement 100% native QML Wi-Fi scanner and connection manager"
```

---

### Task 3: Native Pure-QML Bluetooth Devices Manager Popover

**Files:**
- Create: `configs/quickshell/win11-bluetooth/shell.qml`
- Create: `configs/quickshell/mac-bluetooth/shell.qml`
- Modify: `scripts/omarchy-mac-bluetooth`
- Modify: `scripts/omarchy-win11-bluetooth`

**Interfaces:**
- Consumes: `bluetoothctl devices Paired` and `bluetoothctl devices Connected`
- Produces: Popover for managing paired devices, device scanning, and Bluetooth toggle

- [ ] **Step 1: Implement `win11-bluetooth/shell.qml` with paired devices list, connect/disconnect buttons, and power switch**
- [ ] **Step 2: Implement `mac-bluetooth/shell.qml` with macOS Sequoia aesthetics**
- [ ] **Step 3: Update `omarchy-mac-bluetooth` and `omarchy-win11-bluetooth` to launch native QML popovers**
- [ ] **Step 4: Test Bluetooth popover execution**
- [ ] **Step 5: Commit Bluetooth popover**

```bash
git add configs/quickshell/*-bluetooth/ scripts/omarchy-*-bluetooth
git commit -m "feat(bluetooth): implement native QML Bluetooth device manager popovers"
```

---

### Task 4: Native Pure-QML Sound Output & Volume Mixer Popover

**Files:**
- Create: `configs/quickshell/win11-sound/shell.qml`
- Create: `configs/quickshell/mac-sound/shell.qml`
- Modify: `scripts/omarchy-mac-sound`
- Modify: `scripts/omarchy-win11-sound`

**Interfaces:**
- Consumes: `wpctl status` / `wpctl get-volume @DEFAULT_AUDIO_SINK@`
- Produces: Audio sink switcher, live volume slider, and mute toggle

- [ ] **Step 1: Implement `win11-sound/shell.qml` with output device selector, real-time volume slider, and mute switch**
- [ ] **Step 2: Implement `mac-sound/shell.qml` with macOS Sequoia volume slider and AirPlay/output switcher**
- [ ] **Step 3: Update launcher scripts to dispatch native QML popovers**
- [ ] **Step 4: Test volume slider interaction and PipeWire binding**
- [ ] **Step 5: Commit Sound popover**

```bash
git add configs/quickshell/*-sound/ scripts/omarchy-*-sound
git commit -m "feat(sound): implement native QML sound output switcher and volume mixer"
```

---

### Task 5: Start Menu Native App Search & A-Z App Drawer Theme Adaptation

**Files:**
- Modify: `configs/quickshell/win11-start/shell.qml`

**Interfaces:**
- Consumes: Live `TextInput` queries and desktop app catalog
- Produces: Adaptive Dark/Light Start Menu with search filtering and A-Z scrollable drawer

- [ ] **Step 1: Add dynamic Dark/Light palette adaptation to `win11-start/shell.qml`**
- [ ] **Step 2: Ensure live `TextInput` search and A-Z drawer adapt text and tile colors seamlessly**
- [ ] **Step 3: Verify keyboard navigation and web search fallback**
- [ ] **Step 4: Commit Start Menu enhancements**

```bash
git add configs/quickshell/win11-start/shell.qml
git commit -m "feat(win11-start): add dynamic light/dark theme adaptation to Start Menu and A-Z App Drawer"
```

---

### Task 6: Fluent 2 Taskbar & Micro-Animations Refinement

**Files:**
- Modify: `configs/plugins/undercover.win11-taskbar/Widget.qml`
- Modify: `configs/plugins/undercover.win11-weather/Widget.qml`

**Interfaces:**
- Produces: Refined Fluent 2 Taskbar with Dark/Light palette binding, expanding active pills, and Weather widget

- [ ] **Step 1: Add reactive light/dark theme color binding to `undercover.win11-taskbar` and `undercover.win11-weather`**
- [ ] **Step 2: Refine tile proportions (42x38px), hover lift, and active indicator pills (`#60cdff` in dark mode, `#0067c0` in light mode)**
- [ ] **Step 3: Test taskbar rendering across both `win11-dark` and `win11-light` modes**
- [ ] **Step 4: Commit taskbar refinements**

```bash
git add configs/plugins/undercover.win11-taskbar/ configs/plugins/undercover.win11-weather/
git commit -m "feat(taskbar): polish Fluent 2 taskbar with dynamic light/dark theme adaptation"
```

---

### Task 7: Comprehensive Settings App Expansion & Management Toggles

**Files:**
- Modify: `scripts/omarchy-undercover-settings`
- Modify: `scripts/omarchy-undercover`

**Interfaces:**
- Produces: Complete GUI/CLI toggles for Visibility modes (Permanent vs Auto-Hide), Dock styles, Taskbar alignment, Theme variant (Dark vs Light), Opacity sliders, and Hardware widget managers

- [ ] **Step 1: Add Theme Variant switcher row (Dark Mode vs Light Mode) in `omarchy-undercover-settings`**
- [ ] **Step 2: Add Hardware Widget management rows (Wi-Fi, Bluetooth, Sound, Weather toggles)**
- [ ] **Step 3: Add CLI options `--light`, `--dark`, `--toggle-theme` in `scripts/omarchy-undercover`**
- [ ] **Step 4: Test settings changes in GUI and verify persistence in `settings.conf`**
- [ ] **Step 5: Commit settings expansion**

```bash
git add scripts/omarchy-undercover-settings scripts/omarchy-undercover
git commit -m "feat(settings): expand settings GUI and CLI with theme variant toggles and hardware widget controls"
```

---

### Task 8: End-to-End Integration, Mode Switching & Verification

**Files:**
- Modify: `install.sh`

- [ ] **Step 1: Run `install.sh 1` to sync all QML components, plugins, icons, and executables**
- [ ] **Step 2: Switch to `win11-dark` and verify: Taskbar, Weather, Start Menu, Wi-Fi, Bluetooth, Sound popovers in dark theme**
- [ ] **Step 3: Switch to `win11-light` and verify: Taskbar, Weather, Start Menu, Wi-Fi, Bluetooth, Sound popovers in pure white/light theme**
- [ ] **Step 4: Switch to `mac-dark` and `mac-light` and verify menu bar and floating dock**
- [ ] **Step 5: Run `omarchy-undercover --verify` and push all changes to GitHub branch `quickshell`**

```bash
git push origin quickshell
```

# Pure QML Desktop Transformation Suite & Dual-Theme Engine Specification

- **Document Date**: 2026-08-14
- **Author**: Antigravity & misternegative21
- **Status**: Approved / Ready for Implementation Plan
- **Target Branch**: `quickshell`

---

## 1. Overview & Objectives

This specification defines the complete transition of Omarchy Undercover's UI/UX components to a **100% Native Quickshell (QML) Architecture**, featuring:
1. **Flawless Light & Dark Dynamic Theme Engine**: Full support for pristine white/light theme (`#f3f3f3` / `#ffffff`) and deep dark theme (`#202020` / `#1c1c20`) across all widgets, popovers, drawers, and taskbars.
2. **Dedicated Pure-QML Hardware Flyouts**:
   - 📶 **Wi-Fi Scanner & Manager**: Live SSID discovery via `nmcli`, signal strength indicators, and connection manager.
   - 󰂯 **Bluetooth Device Manager**: Live device discovery via `bluetoothctl`, connection toggles, and paired device management.
   - 🔊 **Sound Output Switcher**: Live PipeWire (`wpctl`/`pactl`) sink switcher, volume sliders, and output device routing.
3. **Native Windows 11 Start Menu & A-Z App Drawer**:
   - Real-time `TextInput` filtering through installed applications.
   - Smooth A-Z scrollable application drawer with alphabetical groupings.
   - Web search and command execution fallbacks.
4. **Fluent 2 / Mica Taskbar Polish**:
   - 100% clean icon-only layout with authentic Windows 11 vector SVGs.
   - Smooth micro-interactions, scale feedback, and expanding running indicator pills.
   - Live Weather widget pill on bottom-left and Status capsule on bottom-right.
5. **Comprehensive Settings & Management Controls**:
   - GUI (`omarchy-undercover-settings`) and CLI (`omarchy-undercover`) toggles for autohide modes, floating vs attached styles, theme variant (light/dark), transparency sliders, and hardware widget management.

---

## 2. Architecture & Design Specifications

### 2.1. Dynamic Color & Theme Token Architecture

All Quickshell components will bind dynamically to the system state (`~/.config/omarchy-undercover/state` and settings configuration):

| Element | 🌙 Dark Mode (`win11-dark` / `mac-dark`) | ☀️ Light Mode (`win11-light` / `mac-light`) |
| :--- | :--- | :--- |
| **Taskbar Surface** | Solid Mica Dark `#202020` | Solid Mica Light `#f3f3f3` |
| **Popovers / Menus Surface** | Translucent Mica `#1c1c20` (`0.96` alpha) | Translucent Mica Light `#ffffff` (`0.96` alpha) |
| **Primary Text / Foreground** | `#ffffff` (High contrast) | `#1a1a1a` (High contrast) |
| **Secondary / Subtitles** | `rgba(255, 255, 255, 0.65)` | `rgba(0, 0, 0, 0.60)` |
| **Accent Color** | `#60cdff` (Fluent Cyan / Glow) | `#0067c0` (Fluent Deep Blue) |
| **Surface Borders** | `rgba(255, 255, 255, 0.12)` | `rgba(0, 0, 0, 0.08)` |
| **Active Running Pill** | `#60cdff` | `#0067c0` |
| **Hover Highlight** | `rgba(255, 255, 255, 0.08)` | `rgba(0, 0, 0, 0.06)` |

---

### 2.2. Dedicated Native QML Hardware Flyouts

Replacing external GTK scripts with dedicated, high-performance Quickshell layer-shell popovers:

1. **`configs/quickshell/win11-wifi/shell.qml` & `configs/quickshell/mac-wifi/shell.qml`**:
   - Live scanning process: `nmcli -t -f in-use,ssid,bssid,signal,security dev wifi list --rescan yes`.
   - Signal strength icon mapper (󰤨 100-75%, 󰤥 75-50%, 󰤢 50-25%, 󰤟 <25%).
   - Active connected network banner with disconnect button.
   - Click-to-connect with password input modal.
   - Wi-Fi radio power switch (`nmcli radio wifi on/off`).

2. **`configs/quickshell/win11-bluetooth/shell.qml` & `configs/quickshell/mac-bluetooth/shell.qml`**:
   - Live paired devices query: `bluetoothctl devices Connected` and `bluetoothctl devices Paired`.
   - Device discovery and pair/connect actions.
   - Bluetooth radio power switch (`bluetoothctl power on/off`).

3. **`configs/quickshell/win11-sound/shell.qml` & `configs/quickshell/mac-sound/shell.qml`**:
   - Audio sink query: `wpctl status` / `pactl list sinks short`.
   - Active default sink selector (Speakers, Headphones, Display Audio).
   - Live interactive master volume slider and mute toggle.

---

### 2.3. Native Start Menu & A-Z App Drawer

- **Search Engine**: Native `TextInput` with real-time text query filtering, clear button, and web search fallback.
- **A-Z App Drawer**: Complete scrollable catalog with alphabetical category headers (`A`–`Z`) and `< Back` navigation.
- **Pinned Grid**: 18 customizable pinned application tiles with hover highlights and micro-animations.
- **Power Flyout**: Lock, Sleep, Restart, and Shut Down options.

---

### 2.4. Fluent 2 Taskbar & Micro-Interactions

- **Taskbar Structure**:
  - Left: Weather widget (`undercover.win11-weather`) displaying live temperature and conditions.
  - Center: Centered app cluster (`undercover.win11-taskbar`) with 4-Square vector Start button, Task View, Explorer, Edge, Terminal, Notepad, and Settings.
  - Right: System Tray (`omarchy.tray`), Action Center status capsule (`undercover.win11-actioncenter`), Clock (`omarchy.clock`), and Show Desktop sliver (`undercover.win11-showdesktop`).
- **Tile Styling**: 42x38px dimensions, `5px` corner radius, authentic Windows 11 SVG icons, and expanding `#60cdff`/`#0067c0` active indicator pills.
- **Hover Micro-Animations**: Smooth scale (`1.05` on hover, `0.95` on click) with `Easing.OutCubic`.

---

### 2.5. Settings App & Management Controls (`omarchy-undercover-settings`)

Expanded settings preferences in **Dock & Taskbar** and **Effects & Transparency**:
- **Taskbar / Dock Visibility**: `Permanently Visible` vs `Intelligent Auto-Hide (On Hover)`.
- **macOS Dock Layout**: `Floating (Sequoia Glass)` vs `Attached to Bottom Screen Edge`.
- **Windows 11 Taskbar Alignment**: `Centered (Windows 11)` vs `Left-Aligned (Classic)`.
- **Theme Variant**: `Dark Mode` vs `Light Mode` with real-time palette live-reloading.
- **Transparency Sliders**: Active window opacity, inactive opacity, taskbar opacity, and dock opacity.
- **Widget Management**: Individual toggles for Weather, Task View, Copilot, Wi-Fi, Bluetooth, and Sound widgets.

---

## 3. Verification & Testing Criteria

1. **Theme Switch Verification**:
   - Running `omarchy-undercover -w11 --light` turns all taskbars, menus, popovers, and widgets to pristine Light Mica (`#f3f3f3` / `#ffffff`) with dark text (`#1a1a1a`).
   - Running `omarchy-undercover -w11 --dark` turns all components to deep Dark Mica (`#202020` / `#1c1c20`) with light text (`#ffffff`).
2. **QML Popover Verification**:
   - Clicking Wi-Fi, Bluetooth, or Sound opens the corresponding native QML popover smoothly without GTK dependencies.
3. **Search & App Drawer Verification**:
   - Typing in the Start Menu immediately displays filtered results.
   - Clicking "All apps >" navigates to the A-Z Drawer; clicking "< Back" returns to Pinned.
4. **Dock / Taskbar Isolation**:
   - Windows 11 Taskbar and macOS Dock never run concurrently.
5. **Autohide Verification**:
   - Taskbar / Dock stays visible while hovered within its region, and hides cleanly when the cursor leaves.

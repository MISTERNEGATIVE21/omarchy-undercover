# Design Specification: Quickshell 0.3.2 Compatibility, Network Forget Actions, Disguise Lifecycle, and Task Management

**Date:** 2026-10-10  
**Status:** Approved  
**Author:** Antigravity & misternegative21  
**Scope:** Core undercover switcher, Quickshell configs, D-Bus protocol scripts, window organizers, and test suites.

---

## 1. Context & Motivation

Following the recent update to Quickshell (0.3.2), Omarchy Undercover requires full compatibility checks, deprecation cleanup, and feature additions requested by the user:
1. **Quickshell 0.3.2 Compatibility & Optimization:** Ensure seamless operation with the latest Quickshell runtime; migrate deprecated subcommands (such as `quickshell msg` to `quickshell ipc call`); eliminate process leaks; optimize D-Bus queries and timers.
2. **Forget Wi-Fi & Forget Bluetooth in macOS and Windows Modes:** Both flyout panels and control centers currently lack explicit, discoverable "Forget" actions for saved Wi-Fi networks and paired Bluetooth devices.
3. **Disguise Persistence (Temporary by Default vs Persistent):** When the PC starts or reboots, the system must not start under disguise mode by default—it should boot into normal Omarchy desktop mode unless the user explicitly configured disguise mode to be persistent.
4. **Notepad & Task Manager Separation:** Pinned Notepad text editor must launch `omawrite` (the primary Omarchy text editor), match running `omawrite` / `leafpad` windows accurately, and right-clicking unrunning taskbar icons must not inadvertently trigger Task Manager.
5. **Intelligent macOS Stage Manager:** Enhance the Stage Manager rail with intelligent auto-hiding when stage windows touch the left margin, multi-window stacking per application group, live Screencopy thumbnails, and workspace/monitor isolation.
6. **Windows 11 Task & Window Management:** Complete virtual desktop management in Task View, robust taskbar app grouping with hover previews, and accurate process control in Windows Task Manager.

---

## 2. Architecture & Subsystems

### 2.1 Quickshell 0.3.2 Compatibility & Service State
* **IPC Calls:** Update all external shell scripts and QML triggers to use `quickshell ipc call <target> <method>` instead of the deprecated `msg` command.
* **Service Baseline Default:** In `Service.qml`, initialize `currentState` to `"omarchy"` (baseline normal mode) instead of `"mac-dark"`.
* **State File Watcher:** Ensure `Service.qml` reacts safely to empty or missing state files by defaulting to baseline Omarchy.

### 2.2 Disguise Lifecycle: Temporary vs Persistent
* **Configuration:** Add `DISGUISE_PERSISTENT` to `settings.conf` (default: `false` / `temporary`).
* **Startup Hook:**
  * When `omarchy-undercover --startup` runs (or when `Service.qml` initializes on system boot/login):
    * If `DISGUISE_PERSISTENT=false`: ensure desktop is restored to normal Omarchy mode (`omarchy-undercover --disable`).
    * If `DISGUISE_PERSISTENT=true`: preserve the last configured disguise preset.
* **CLI & UI Controls:**
  * Support `omarchy-undercover --temporary` and `omarchy-undercover --persistent`.
  * Support `omarchy-undercover --startup` for session startup initialization.
  * Add a toggle in macOS and Windows Settings panels for Disguise Persistence.

### 2.3 Network Protocols: Forget Wi-Fi & Forget Bluetooth
* **Wi-Fi Backend (`scripts/omarchy-wifi-dbus`):**
  * Subcommand: `forget <ssid>`
  * Implementation: Look up connection in NetworkManager Settings D-Bus interface (`org.freedesktop.NetworkManager.Settings.Connection`) matching SSID or ID, and invoke `.Delete()`.
  * Fallback: Execute `nmcli connection delete id "<ssid>"` and `nmcli connection delete "<ssid>"`.
* **Bluetooth Backend (`scripts/omarchy-bluetooth-dbus`):**
  * Subcommand: `forget <mac>`
  * Implementation: Invoke BlueZ `Adapter1.RemoveDevice(<device_path>)`.
  * Fallback: Execute `omarchy-bluetooth-device forget "<mac>"` and `bluetoothctl remove "<mac>"`.
* **User Interfaces:**
  * `configs/quickshell/mac-wifi/shell.qml` & `mac-controlcenter/shell.qml`: Add visible "Disconnect" and "Forget" action buttons for active and saved networks.
  * `configs/quickshell/mac-bluetooth/shell.qml` & `mac-controlcenter/shell.qml`: Add visible "Forget Device" button for paired devices.
  * `configs/quickshell/win11-wifi/shell.qml` & `win11-actioncenter/shell.qml`: Add visible "Forget" button alongside "Disconnect" in the banner and on saved network rows.
  * `configs/quickshell/win11-bluetooth/shell.qml` & `win11-actioncenter/shell.qml`: Add visible "Forget" button alongside "Connect/Disconnect" in device list.

### 2.4 Notepad & Taskbar Interaction Fix
* **Notepad Exec Command:** Set to `omawrite || leafpad || gedit || kate || mousepad || gnome-text-editor || xdg-terminal-exec -e nano`.
* **Matchers:** Include `omawrite`, `leafpad`, `gedit`, `kate`, `mousepad`, `gnome-text-editor`, `text-editor`.
* **Taskbar Click Fix (`widgets/win11-taskbar.qml`):**
  * Remove the fallback right-click handler on unrunning pinned apps that executed `omarchy-win11-taskmanager`.
  * Right-clicking pinned apps will show app-specific actions (e.g. Open / Unpin) rather than launching Task Manager.
  * Task Manager remains exclusively bound to right-clicking the Start button, right-clicking the empty taskbar shelf, or Ctrl+Shift+Escape.

### 2.5 Intelligent macOS Stage Manager
* **Intelligent Auto-Hide:** Detect if the active stage window intersects with the left 220px of the screen or is maximized/fullscreened; smoothly slide the Stage Manager rail off-screen, revealing it upon mouse edge hover.
* **Stack Depth & Multi-Window Cycling:** Render cascading layered window cards with active window count badges. Clicking the same group cycles through the group's windows.
* **Live Wayland Screencopy Previews:** Bind live Wayland `ScreencopyView` handles with fallback to desktop application icons.

### 2.6 Windows 11 Task & Window Management
* **Taskbar App Previews:** Provide interactive hover cards with thumbnail previews and close buttons for multi-instance windows.
* **Task View (`win11-taskview`):** Complete virtual desktop bar (+ New Desktop, switch desktop, close desktop) with Hyprland workspace dispatchers.
* **Task Manager (`win11-taskmanager`):** Ensure responsive process sorting, search filtering, and "End Task" operations.

---

## 3. Testing & Verification

1. **Unit & Integration CLI Tests:**
   * Test `omarchy-wifi-dbus forget <ssid>` against mock/live NetworkManager connections.
   * Test `omarchy-bluetooth-dbus forget <mac>` against mock/live BlueZ devices.
   * Test `omarchy-undercover --startup` with `DISGUISE_PERSISTENT=false` and `true`.
2. **QML Syntax & Quickshell 0.3.2 Compatibility:**
   * Verify all 18 Quickshell bundles load cleanly with `quickshell -p <path>`.
3. **End-to-End System Test:**
   * Run automated tests verifying Notepad command and matchers, Stage Manager navigation and auto-hide, and Windows 11 taskbar bindings.

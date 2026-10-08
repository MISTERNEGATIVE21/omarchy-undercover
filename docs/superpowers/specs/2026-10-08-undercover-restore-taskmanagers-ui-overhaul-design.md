# Design Specification: Omarchy Undercover Restore, Task Managers & UI/UX Overhaul

## 1. Overview & Goals

Omarchy Undercover transforms the Omarchy Hyprland desktop into convincing macOS (Tahoe/Sequoia) and Windows 11 environments. However, several usability gaps, restore bugs, and missing subsystems exist:
1. **Top Bar Restoration Bug**: Exiting macOS mode leaves `shell.json` contaminated with `mac-*` widgets, transparent bar settings, and missing standard Omarchy panel widgets.
2. **Missing & Inaccessible Task Managers**: macOS mode lacks an Activity Monitor. Windows 11 mode has a Quickshell task manager that is not bound to standard hotkeys (<kbd>Ctrl</kbd>+<kbd>Shift</kbd>+<kbd>Esc</kbd>) or context menus, and has non-functional window navigation buttons.
3. **Stage Manager Navigation Deficiencies**: Stage Manager lacks keyboard cycling across individual windows within app stacks (<kbd>Left</kbd>/<kbd>Right</kbd>), background cards cannot be clicked to cycle, and cross-workspace window activation is unreliable.
4. **Window Navigation Controls**: Exit (Close), Minimize, and Maximize buttons in Quickshell apps and GTK window titlebars lack consistent behaviors and styling across both disguises.
5. **File Manager Experience & UI Contrast**: Flea file manager lacks tailored profile switching for Finder vs Explorer, and panel text/icons suffer from low readability on high-brightness or dynamic wallpapers.

This specification details the end-to-end architecture to fix the restore engine, introduce native macOS Activity Monitor, complete the Windows 11 Task Manager, overhaul Stage Manager navigation, polish window controls, and improve color contrast.

---

## 2. Pillar 1: Top Bar & Shell Restoration Engine

### 2.1 Problem Analysis
In `scripts/omarchy-undercover`, `restore_shell_from_baseline()` uses a `jq` walk filter that only matches `.id | test("undercover")`.
```json
{
  "bar": {
    "position": "top",
    "transparent": true,
    "layout": {
      "left": [{ "id": "mac-apple" }, { "id": "mac-appmenu" }],
      "right": [{ "id": "mac-battery" }, { "id": "mac-sound" }, { "id": "mac-clock" }]
    }
  }
}
```
Because none of these widget IDs contain `"undercover"`, the filter deletes nothing. The bar remains locked in macOS layout, and default Omarchy widgets (`omarchy.menu`, `omarchy.workspaces`, `omarchy.indicators`, `omarchy.clock`, `omarchy.tray`) are never restored.

### 2.2 Solution Architecture
1. **Pristine Baseline Ingestion**:
   * When switching into an Undercover mode (`apply_shell_mac` or `apply_shell_windows`), inspect `$BASELINE_FILE`.
   * If baseline does not exist or its `shell.json` is tainted (contains `mac-`, `win11-`, or `undercover`), snapshot the clean system configuration from `/usr/share/omarchy/config/omarchy/shell.json` before applying any disguise.
2. **Robust Restoration Routine**:
   * During `restore_desktop_state`:
     * If `$baseline/omarchy/shell.json` is clean, restore it to `~/.config/omarchy/shell.json`.
     * If baseline is missing or corrupted, overwrite `~/.config/omarchy/shell.json` directly from `/usr/share/omarchy/config/omarchy/shell.json` (fallback: `configs/shell/shell-default.json`).
     * Ensure `.bar.transparent = false` and `.bar.centerAnchor = "omarchy.clock"`.
3. **Waybar & System Service Synchronization**:
   * When using the Waybar backend, restore default Waybar configs from `/usr/share/omarchy/config/waybar/` if baseline is missing.
   * Trigger clean reloads via `omarchy restart shell` and `omarchy_reload_bar`.

---

## 3. Pillar 2: Task Managers (macOS Activity Monitor & Windows 11 Task Manager)

### 3.1 macOS Activity Monitor (`configs/quickshell/mac-activitymonitor`)
A native Quickshell application matching macOS Tahoe / Sequoia Activity Monitor:
* **Window Frame**:
  * Floating centered window with rounded corners (16px) and frosted glass acrylic styling.
  * Top-left traffic lights: Red (Close), Yellow (Minimize to `special:minimized`), Green (Maximize/Zoom).
  * Segmented bar with active indicator: **CPU**, **Memory**, **Disk**, **Network**.
  * Top toolbar with Force Quit button (`✕`), Info button (`ⓘ`), and search input.
* **Process Table**:
  * Real-time list fed by `scripts/omarchy-win11-taskmanager-backend` (or symlinked `omarchy-taskmanager-backend`).
  * Columns: Process Name (with app icon), % CPU, CPU Time / Status, Memory, PID, User.
  * Search filter matching process name, window title, or PID.
* **Bottom Status View**:
  * CPU load percentage history graph and Memory Pressure indicator.
* **Integration**:
  * Dedicated launch script: `scripts/omarchy-mac-activitymonitor` (aliased as `omarchy-mac-taskmanager`).
  * Shortcut: <kbd>Super</kbd>+<kbd>Alt</kbd>+<kbd>Escape</kbd> (<kbd>Cmd</kbd>+<kbd>Opt</kbd>+<kbd>Esc</kbd>) in `configs/hypr/mac-mode.lua` and `mac-mode.conf`.
  * Apple Menu (`widgets/mac-apple.qml`): Wire "Force Quit Applications..." to `omarchy-mac-activitymonitor`.
  * Spotlight & Dock: Available under "Activity Monitor".

### 3.2 Windows 11 Task Manager (`configs/quickshell/win11-taskmanager`)
* **Global Access**:
  * Keybinding: Bind <kbd>Ctrl</kbd>+<kbd>Shift</kbd>+<kbd>Escape</kbd> in `configs/hypr/windows-mode.lua` and `windows-mode.conf`.
  * Context Menus: Right-click on Windows 11 Taskbar and Start button launches `omarchy-win11-taskmanager`.
* **Window Navigation Fixes**:
  * Maximize button (`□` / `🗗`): Track state and toggle between default windowed dimensions (1020x680) and maximized screen bounds (screen.width - 20, screen.height - 60).
  * Minimize button (`—`): Dispatches `omarchy-undercover-minimize` instead of killing the process.
  * Close button (`✕`): Safely terminates Quickshell and cleans up runtime PID file.

---

## 4. Pillar 3: Stage Manager Navigation Logic Overhaul

### 4.1 Deficiencies in Current Implementation
In `configs/quickshell/mac-stagemanager/StageManager.qml`:
* Keyboard navigation only increments through `root.flatWindows` sequentially using <kbd>Up</kbd>/<kbd>Down</kbd>, without grouping awareness.
* Background stacked cards (`StackLayer`) lack mouse handlers, preventing users from clicking an individual card in a group to bring it forward.
* Activating a window on another workspace via `hyprctl dispatch focuswindow` can fail if the workspace is not active.

### 4.2 Enhanced Navigation Logic
1. **Hierarchical Keyboard Controls**:
   * <kbd>Up</kbd> / <kbd>Down</kbd> / <kbd>Tab</kbd>: Select next/previous **App Group**.
   * <kbd>Left</kbd> / <kbd>Right</kbd>: Cycle through windows **inside the active App Group**.
   * <kbd>Enter</kbd> / <kbd>Space</kbd>: Focus the selected window.
2. **Interactive Stack Layers**:
   * Add a `MouseArea` to `StackLayer`: clicking any stacked window in the background instantly selects that window and brings it to the top preview.
   * Add `WheelHandler` / scroll event to `AppGroup` to cycle windows within the stack via mouse scroll.
3. **Workspace-Aware Activation**:
   * When calling `activate(record)`, check `record.workspaceId`. If different from the focused workspace, dispatch `hyprctl dispatch workspace <id>` followed by `hyprctl dispatch focuswindow address:<addr>`.

---

## 5. Pillar 4: Window Navigation Controls (Exit, Minimize, Maximize)

### 5.1 macOS Mode Controls
* **Layout**: Left-aligned traffic lights (`close,minimize,maximize:`).
* **Buttons**:
  * Red (`#ff5f57`): Quits window (`✕` on hover).
  * Yellow (`#febc2e`): Minimizes to `special:minimized` (`—` on hover).
  * Green (`#28c840`): Toggles maximized/zoom geometry (`+` on hover).
* **Global GTK & Compositor Application**:
  * Enforce `gsettings set org.gnome.desktop.wm.preferences button-layout "close,minimize,maximize:"`.
  * Ensure GTK 3/4 `settings.ini` and `xsettingsd.conf` define `Gtk/DecorationLayout "close,minimize,maximize:"`.

### 5.2 Windows 11 Mode Controls
* **Layout**: Right-aligned Fluent control block (`:minimize,maximize,close`).
* **Buttons**:
  * Minimize (`—`): Docks window to `special:minimized`.
  * Maximize / Restore (`□` / `🗗`): State-dependent icon toggling maximized state.
  * Close (`✕`): Closes window with red hover state (`#c42b1c`).
* **Global GTK Application**:
  * Enforce `gsettings set org.gnome.desktop.wm.preferences button-layout ":minimize,maximize,close"`.

---

## 6. Pillar 5: File Manager UX & Color Contrast System

### 6.1 Flea & GTK File Manager Configuration
In `scripts/omarchy-undercover-filemanager`:
* **macOS Mode**:
  * Flea UI state: `"view": "columns"`, `"keys": "mac"`, `"addressBar": "breadcrumb"`, `"preview": {"column": true, "thumbnails": "media"}`.
  * GTK file managers (Nautilus/Dolphin/Thunar) receive `macOS-Tahoe-Dark` / `Light` theme with left-aligned buttons.
* **Windows 11 Mode**:
  * Flea UI state: `"view": "list"`, `"keys": "windows"`, `"addressBar": "path"`, `"preview": {"column": false}`.
  * GTK file managers receive `Windows-11` theme with right-aligned buttons.

### 6.2 Contrast & Readability Enhancements
* **Top Bar (macOS)**:
  * In `configs/shell/shell-mac.json` and widget QML files (`mac-clock.qml`, `mac-appmenu.qml`, `mac-apple.qml`), introduce text drop-shadow (`0 1px 2px rgba(0,0,0,0.55)`) and a frosted backdrop tinted at 25-40% dark alpha to maintain crisp contrast over white wallpapers.
* **Taskbar (Windows 11)**:
  * Solidify acrylic opacity to 95% with a distinct 1px top border (`rgba(255,255,255,0.10)`).
  * Enforce high-contrast text and icon colors in system tray and clock.
* **Flyouts & Menus**:
  * Ensure all dropdowns (Apple menu, Start menu, Action Center, Task Managers) have high-contrast borders and text complying with WCAG AA (>4.5:1 ratio).

---

## 7. Verification & Testing Strategy

1. **Top Bar Restoration Test**:
   * Switch to macOS mode: `omarchy-undercover --mode macos`. Verify `shell.json` has macOS widgets.
   * Run restore: `omarchy-undercover --restore`. Verify `shell.json` no longer contains any `mac-*` widgets, has stock `omarchy.*` widgets, and the top bar restores to standard Omarchy appearance.
2. **Task Managers Test**:
   * Press <kbd>Super</kbd>+<kbd>Alt</kbd>+<kbd>Escape</kbd> in macOS mode: verify Activity Monitor launches with traffic lights, process table, search, and Force Quit.
   * Press <kbd>Ctrl</kbd>+<kbd>Shift</kbd>+<kbd>Escape</kbd> in Windows mode: verify Windows 11 Task Manager launches, maximize toggles size, minimize docks window, and close terminates cleanly.
3. **Stage Manager Test**:
   * Open Stage Manager with multiple windows across apps.
   * Verify <kbd>Left</kbd>/<kbd>Right</kbd> keys cycle windows within the app group.
   * Verify clicking background stacked cards brings them forward.
   * Verify activating a window switches workspace and focuses window.
4. **Window Controls Test**:
   * Check traffic light buttons in macOS Quickshell windows and GTK apps.
   * Check minimize, maximize, and close buttons in Windows Quickshell windows and GTK apps.
5. **Contrast Test**:
   * Test readability of top bar and taskbar on both solid white and solid black wallpapers.

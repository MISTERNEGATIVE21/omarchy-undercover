# Windows 11 Start Menu, Taskbar Auto-Hide, Transparency Toggle & Fluid Animations Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Provide an authentic Windows 11 Start Menu (in both Quickshell and GTK4/Python backends), a robust auto-hide taskbar daemon with active-menu locking, a dedicated Windows 11 transparency effects toggle in the Undercover Settings app, and fluid animations for window creation, minimizing, closing, and workspace transitions across both Windows 11 and macOS modes.

**Architecture:** Dual-engine architecture supporting both Quickshell and GTK4 backends, coupled with an intelligent auto-hide daemon that locks visibility when popups are open, real-time live transparency switching across Hyprland/GTK/CSS, and tuned fluid bezier curves for window animations.

**Tech Stack:** Python 3, GTK 4, Libadwaita, Quickshell (QML / Wayland LayerShell), Hyprland Lua/Conf, Waybar, Bash.

## Global Constraints
- Must support both Quickshell (Omarchy 4.0+) and Waybar (legacy) backends seamlessly.
- Must persist all preferences in `~/.config/omarchy-undercover/settings.conf`.
- Must never crash or leave orphaned daemons on theme switch or reload.
- Non-destructive configuration management with baseline restoration support.

---

### Task 1: Windows 11 Start Menu Dual-Engine Refactor (Quickshell QML & Python GTK4)

**Files:**
- Modify: `scripts/omarchy-win11-startmenu`
- Modify: `configs/quickshell/win11-start/shell.qml`
- Modify: `scripts/omarchy-win11-start`
- Modify: `scripts/omarchy-undercover-launcher`
- Modify: `configs/waybar/config-win.jsonc`

**Interfaces:**
- Consumes: `settings.conf` (`THEME_VARIANT`, `WIN11_TRANSPARENCY`, `TASKBAR_ALIGNMENT`)
- Produces: Executables `omarchy-win11-startmenu` and `omarchy-win11-start` that open an authentic bottom-anchored Windows 11 Start Menu with live search, pinned apps grid, All Apps drawer, Recommended section, user pill, and power popup.

- [ ] **Step 1: Upgrade GTK4 Python Start Menu (`scripts/omarchy-win11-startmenu`)**
  - Implement bottom-anchored layer-shell / positioned window elevated 12px above bottom taskbar.
  - Implement Mica/acrylic translucent or solid background based on `WIN11_TRANSPARENCY`.
  - Add search bar with instant live filtering, 6×3 Pinned Grid with Fluent icons, "All apps >" drawer view, Recommended recent files, and user/power bottom strip with interactive power actions.
  - Add focus-lost / Escape key auto-close and singleton process toggle.

- [ ] **Step 2: Upgrade Quickshell QML Start Menu (`configs/quickshell/win11-start/shell.qml`)**
  - Verify bottom anchoring, margins (`bottom: 54`), keyboard focus on search input, Escape key handling, and outside-click dismiss.
  - Connect transparency property to `settings.conf`.

- [ ] **Step 3: Unify Start Menu dispatchers**
  - Update `scripts/omarchy-win11-start`, `scripts/omarchy-undercover-launcher`, and `configs/waybar/config-win.jsonc` to route reliably to the active Start Menu without duplicate processes or delay.

- [ ] **Step 4: Verify Start Menu manually and via test execution**
  - Run `omarchy-win11-startmenu` / `omarchy-win11-start` in headless/syntax check and verify process toggle behavior.

---

### Task 2: Taskbar Auto-Hide Daemon & Active-Menu Lock

**Files:**
- Modify: `scripts/omarchy-undercover-autohide`
- Modify: `scripts/omarchy-undercover-taskbar-autohide`

**Interfaces:**
- Consumes: Hyprland cursor position and active layers/windows
- Produces: `omarchy-undercover-autohide` daemon supporting `--start`, `--stop`, `--toggle`, and `--status` with 250ms debounce and active flyout lock.

- [ ] **Step 1: Add Active-Flyout Detection to Auto-Hide Daemon**
  - Detect whether Start Menu, Action Center, Calendar flyout, or Widgets board is open.
  - When any menu is open, keep taskbar locked visible.

- [ ] **Step 2: Refine Edge Proximity & Smooth Debounce**
  - Ensure 6px bottom trigger zone, hit-box retention inside taskbar height, and 250ms smooth dwell buffer when moving away.
  - Support both Quickshell and Waybar toggle mechanisms.

- [ ] **Step 3: Test and verify auto-hide daemon commands**
  - Verify start, stop, toggle, and status CLI options.

---

### Task 3: Windows 11 Transparency Effects Toggle in Omarchy Undercover Settings

**Files:**
- Modify: `scripts/omarchy-undercover-settings`
- Modify: `scripts/omarchy-undercover`
- Modify: `configs/waybar/style-win.css`
- Modify: `configs/gtk/win11-style.css`

**Interfaces:**
- Consumes: `settings.conf` (`WIN11_TRANSPARENCY`, `BAR_TRANSPARENT`)
- Produces: Interactive switch in `omarchy-undercover-settings` on *Effects & Transparency* and *Dock & Taskbar* pages, applying live opacity and blur updates.

- [ ] **Step 1: Add Transparency Switch in `scripts/omarchy-undercover-settings`**
  - Add "Windows 11 Transparency Effects" toggle with descriptive subtitle.
  - On toggle: write `WIN11_TRANSPARENCY=true|false` and `BAR_TRANSPARENT=true|false`, and dispatch live updates.

- [ ] **Step 2: Implement Solid vs Translucent Styling in Waybar & GTK CSS**
  - Provide solid opaque background classes and translucent Mica classes.
  - Update `apply_gtk_windows_theme` and `apply_waybar_windows` in `scripts/omarchy-undercover` to respect `WIN11_TRANSPARENCY`.

- [ ] **Step 3: Test and verify settings persistence and live toggle**
  - Run settings syntax check and verify toggle handler writes to `settings.conf`.

---

### Task 4: Fluid Window Minimize, Close, and Animation Curves

**Files:**
- Modify: `scripts/omarchy-undercover-minimize`
- Modify: `configs/hypr/windows-mode.lua`
- Modify: `configs/hypr/mac-mode.lua`
- Modify: `configs/hypr/windows-mode.conf`

**Interfaces:**
- Consumes: Hyprland dispatch API and window events
- Produces: Smooth animated minimize/restore toggle, clean close handling, and tuned bezier curves for macOS and Windows 11 modes.

- [ ] **Step 1: Enhance `omarchy-undercover-minimize`**
  - Support toggle minimize/restore with tracking of minimized window addresses and smooth workspace transitions.
  - Ensure window controls layout `:minimize,maximize,close` in Windows mode.

- [ ] **Step 2: Add Fluid Animation Curves to Hyprland Configs**
  - Configure `fluent` bezier `(0.1, 0.9, 0.2, 1.0)` with `popin 90%` and `specialWorkspace` animation in `windows-mode.lua` and `windows-mode.conf`.
  - Configure `macFluid` `(0.16, 1.0, 0.3, 1.0)` and `macSpring` with smooth scale/popin in `mac-mode.lua`.

- [ ] **Step 3: Test and verify Hyprland animation configurations**
  - Verify lua syntax and dispatch commands.

---

### Task 5: Integration & Verification

- [ ] **Step 1: Run comprehensive linting, syntax, and execution checks across all modified scripts and configs.**
- [ ] **Step 2: Validate settings persistence, Start Menu launch, auto-hide toggle, and transparency switching.**

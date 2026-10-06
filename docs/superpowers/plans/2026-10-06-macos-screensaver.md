# macOS Aerial Video Screen Saver Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Integrate a native, optimized macOS Aerial Video Screen Saver subsystem into `omarchy-undercover` that operates exclusively in macOS mode, featuring Wayland layer-shell overlay rendering, Quickshell `Service.qml` lifecycle gating, an interactive live video preview box and Apple Aerial downloader in macOS System Settings (`mac-settings/shell.qml`), and a backend CLI manager `scripts/omarchy-mac-screensaver`.

**Architecture:** A lightweight Wayland overlay surface (`MacScreensaverOverlay.qml`) is managed by `Service.qml` via an `IdleMonitor` (`Quickshell.Wayland`). The idle monitor and overlay are strictly active only when `currentState.indexOf("mac") !== -1`. System Settings (`configs/quickshell/mac-settings/shell.qml`) provides a live 16:9 looping video preview box, fullscreen preview button, timeout selector, clip carousel, and 1-click Apple Aerial CDN downloader. Backend interactions and clip downloads are handled by `scripts/omarchy-mac-screensaver`.

**Tech Stack:** Quickshell QML (`Quickshell.Wayland`, `QtMultimedia`, `QtQuick`), Bash, Python, Hyprland, Apple Public Aerial CDN.

**Spec:** [`docs/superpowers/specs/2026-10-06-macos-screensaver-integration-design.md`](file:///home/mister/omarchy-undercover/docs/superpowers/specs/2026-10-06-macos-screensaver-integration-design.md)

## Global Constraints

- Mode Isolation: Subsystem and idle monitoring must be active ONLY when `currentState` starts with or contains `mac`. Windows 11 and Omarchy baseline modes must remain completely unaffected.
- Non-Destructive Desktop: The screensaver must be a pure overlay (`WlrLayershell.layer: Overlay`) that unmaps on wake, leaving existing desktop windows and static wallpapers untouched.
- Resource Floor: When screensaver is inactive or outside macOS mode, overlay surfaces must be unmapped (`visible: false`), and media players must be stopped with zero CPU/GPU decoding usage.
- Dependency Boundaries: Rely only on Quickshell built-ins (`QtMultimedia`, `Quickshell.Wayland`), `curl`, and standard CLI utilities already present in Omarchy.

## Review Focus

1. Accidental dismiss on map: Moving cursor slightly or initial surface mapping must not immediately dismiss the screensaver (requires pointer jitter filter and map priming).
2. Codec failure recovery: If an unplayable video or invalid path is loaded, `MediaPlayer` error handler must unmap cleanly rather than hanging on a black overlay.
3. Rapid mode switching: Switching rapidly between macOS, Windows 11, and baseline must cleanly stop and unmap screensaver surfaces without leaving orphaned overlays.
4. Offline / download interruption: Aborted Apple CDN downloads must clean up partial files without corrupting the screensaver video registry.
5. Multi-monitor safety: Overlay instances must map cleanly across all active screens and dismiss synchronously on input on any screen.

---

### Task 1: Backend Controller & Asset Downloader (`scripts/omarchy-mac-screensaver`)

**Files:**
- Create: `scripts/omarchy-mac-screensaver`
- Test: `tests/test_screensaver_cli.sh`

**Interfaces:**
- Consumes: `settings.conf` (`SCREENSAVER_ENABLED`, `SCREENSAVER_TIMEOUT`, `SCREENSAVER_VIDEO`)
- Produces: Executable CLI `scripts/omarchy-mac-screensaver` with commands:
  - `--status`: outputs JSON with keys `enabled`, `timeout`, `active_clip`, `installed_clips`, `catalog`
  - `--list`: outputs list of installed and catalog clips
  - `--set <path_or_id>`: updates active video in `settings.conf`
  - `--timeout <seconds>`: updates idle timeout in `settings.conf`
  - `--toggle <on|off>`: updates enabled status in `settings.conf`
  - `--download <clip_id>`: downloads Apple Aerial clip to `~/.local/share/omarchy-undercover/screensavers/`
  - `--preview`: dispatches IPC to Quickshell service
  - `--dismiss`: dispatches IPC to dismiss overlay

- [ ] **Step 1: Write test script for CLI commands**

Create `tests/test_screensaver_cli.sh`:
```bash
#!/usr/bin/env bash
set -euo pipefail
CLI="scripts/omarchy-mac-screensaver"

# Test 1: Status command outputs valid JSON
status_json=$("$CLI" --status)
echo "$status_json" | jq . >/dev/null
enabled=$(echo "$status_json" | jq -r .enabled)
[[ "$enabled" == "true" || "$enabled" == "false" ]]

# Test 2: List command outputs catalog
list_output=$("$CLI" --list)
[[ "$list_output" == *"sonoma_horizon"* ]]
[[ "$list_output" == *"yosemite"* ]]

# Test 3: Set and timeout options
"$CLI" --timeout 180
"$CLI" --status | jq -e '.timeout == 180' >/dev/null

echo "All CLI unit tests passed!"
```

- [ ] **Step 2: Run test to verify failure**

Run: `bash tests/test_screensaver_cli.sh`
Expected: FAIL (command `scripts/omarchy-mac-screensaver` does not exist yet).

- [ ] **Step 3: Implement `scripts/omarchy-mac-screensaver`**

Write the bash controller with Apple CDN catalog, JSON status formatter, `curl` downloader with `.part` atomic rename, `settings.conf` updater, and Quickshell IPC triggers. Mark executable (`chmod +x`).

- [ ] **Step 4: Run test to verify it passes**

Run: `bash tests/test_screensaver_cli.sh`
Expected: PASS with "All CLI unit tests passed!"

- [ ] **Step 5: Commit**

```bash
git add scripts/omarchy-mac-screensaver tests/test_screensaver_cli.sh
git commit -m "feat(screensaver): add omarchy-mac-screensaver CLI controller and asset downloader"
```

---

### Task 2: Wayland Overlay QML Engine (`MacScreensaverOverlay.qml`)

**Files:**
- Create: `MacScreensaverOverlay.qml`

**Interfaces:**
- Consumes:
  - `modelData` (Quickshell Screen)
  - `owner` (Service.qml instance)
  - `clipUrl` (URL/path of the video to play)
  - `active` (boolean indicating if screensaver overlay is shown)
- Produces:
  - Wayland Overlay surface `WlrLayershell.layer: WlrLayer.Overlay` (namespace `omarchy-mac-screensaver`)
  - Calls `owner.dismissScreensaver()` on mouse movement or keypress.

- [ ] **Step 1: Create `MacScreensaverOverlay.qml`**

Implement `PanelWindow` with:
- Layer shell properties: `WlrLayershell.layer: WlrLayer.Overlay`, `namespace: "omarchy-mac-screensaver"`, `exclusionMode: ExclusionMode.Ignore`, `keyboardFocus: active ? WlrKeyboardFocus.Exclusive : WlrKeyboardFocus.None`.
- `color: active ? "black" : "transparent"`, `visible: mapped`.
- Unmap timer (250ms) to ensure window unmaps cleanly after fade-out.
- `Item` fade container with `opacity: active ? 1 : 0` (250ms Quad animation).
- `VideoOutput` (`fillMode: VideoOutput.PreserveAspectCrop`) bound to `MediaPlayer`.
- `MediaPlayer`: `loops: MediaPlayer.Infinite`, `audioOutput: null` (silent), error handler that logs and triggers dismiss.
- Input handling: `Keys.onPressed` -> `requestDismiss()`; `MouseArea` with `primed` flag and 4px movement filter -> `requestDismiss()`.

- [ ] **Step 2: Syntax and validation check**

Run: `quickshell --check MacScreensaverOverlay.qml 2>&1 || true`
Expected: No fatal QML syntax errors.

- [ ] **Step 3: Commit**

```bash
git add MacScreensaverOverlay.qml
git commit -m "feat(screensaver): create MacScreensaverOverlay Wayland layer-shell QML engine"
```

---

### Task 3: Service Mode Gating & Idle Lifecycle (`Service.qml`)

**Files:**
- Modify: `Service.qml`

**Interfaces:**
- Consumes:
  - `root.currentState` (monitored state string)
  - `settings.conf` (`SCREENSAVER_ENABLED`, `SCREENSAVER_TIMEOUT`, `SCREENSAVER_VIDEO`)
  - `MacScreensaverOverlay.qml`
- Produces:
  - `IdleMonitor` (`Quickshell.Wayland`), gated on `root.isMacMode && root.screensaverEnabled`.
  - Instantiated `MacScreensaverOverlay` per active screen via `Variants`.
  - Methods: `triggerScreensaverPreview()`, `dismissScreensaver()`, `reloadScreensaverConfig()`.
  - IPC handler endpoints in `omarchy-undercover-service`.

- [ ] **Step 1: Add screensaver properties and helper functions to `Service.qml`**

Add:
- `readonly property bool isMacMode: root.currentState.indexOf("mac") !== -1`
- `property bool screensaverEnabled: true`
- `property int screensaverTimeout: 300`
- `property string screensaverVideo: ""`
- `property bool screensaverActive: false`
- `function reloadScreensaverConfig()`
- `function triggerScreensaverPreview()`
- `function dismissScreensaver()`

- [ ] **Step 2: Add `IdleMonitor` and multi-monitor `Variants` overlay in `Service.qml`**

Add `IdleMonitor` (`Quickshell.Wayland`) enabled only when `root.isMacMode && root.screensaverEnabled`.
Hook `onIsIdleChanged` to trigger/dismiss screensaver.
Add `Variants { model: Quickshell.screens; MacScreensaverOverlay { ... } }`.
Add mode change watcher: when `isMacMode` becomes false, dismiss active screensaver and unmap immediately.

- [ ] **Step 3: Expose IPC methods in `IpcHandler`**

Add `previewScreensaver()`, `dismissScreensaver()`, `reloadScreensaverConfig()` to `IpcHandler { target: "omarchy-undercover-service" }`.

- [ ] **Step 4: Verify QML syntax of `Service.qml`**

Run: `quickshell --check Service.qml 2>&1 || true`
Expected: No fatal syntax errors.

- [ ] **Step 5: Commit**

```bash
git add Service.qml
git commit -m "feat(screensaver): integrate mode-gated idle monitoring and overlay lifecycle in Service.qml"
```

---

### Task 4: macOS System Settings UI & Live Video Preview (`configs/quickshell/mac-settings/shell.qml`)

**Files:**
- Modify: `configs/quickshell/mac-settings/shell.qml`

**Interfaces:**
- Consumes:
  - `scripts/omarchy-mac-screensaver`
  - Quickshell IPC `omarchy-undercover-service`
- Produces:
  - Sidebar category: `Screen Saver` (id: 11)
  - Hero Live Preview Viewport (`VideoOutput` + `MediaPlayer`) with Play/Pause, Mute toggle, and "Preview Fullscreen" pill button.
  - Enable toggle + "Start after:" timeout options (1m, 2m, 5m, 10m, 15m, 30m, Never).
  - Grid/carousel of installed aerial screensaver clips with thumbnail/title and checkmark for selected clip.
  - Apple Aerial Downloader list cards with title, size, status, and 1-click Download button.

- [ ] **Step 1: Add "Screen Saver" category to sidebar list**

In `sidebarCategories`:
Add `{ id: 11, iconBg: "#5856d6", icon: "display.svg", name: "Screen Saver" }` (positioned adjacent to Wallpaper).

- [ ] **Step 2: Add Screen Saver state and loader logic**

Add properties for `screensaverActiveVideo`, `screensaverEnabled`, `screensaverTimeout`, `screensaverClipsList`, `screensaverCatalogList`.
Add `loadScreensaverData()` function that queries `scripts/omarchy-mac-screensaver --status` and populates state.

- [ ] **Step 3: Build Screen Saver content view (Category 11)**

In category content switch:
- Section 1: Hero Live Preview Viewport (rounded 16:9 container with `VideoOutput`, `MediaPlayer`, Play/Pause button, "Preview Fullscreen" button calling `omarchy-undercover-service.previewScreensaver()`).
- Section 2: Preferences Group (Apple green toggle for "Enable Screen Saver", segmented row for timeout).
- Section 3: Installed Clips Carousel with selection highlight and "Choose Custom Video..." button.
- Section 4: Apple Aerial Video Downloader Card with list of clips, status badges, and Download buttons invoking `omarchy-mac-screensaver --download <id>`.

- [ ] **Step 4: Verify QML syntax**

Run: `quickshell --check configs/quickshell/mac-settings/shell.qml 2>&1 || true`
Expected: No fatal syntax errors.

- [ ] **Step 5: Commit**

```bash
git add configs/quickshell/mac-settings/shell.qml
git commit -m "feat(screensaver): add Screen Saver category with live video preview and downloader to mac-settings"
```

---

### Task 5: End-to-End Integration, Mode Switch Lifecycle & Verification

**Files:**
- Create: `tests/test_screensaver_integration.sh`

- [ ] **Step 1: Write integration test script**

Create `tests/test_screensaver_integration.sh`:
- Verifies `scripts/omarchy-mac-screensaver --status` returns valid json with catalog.
- Verifies setting clips updates `settings.conf`.
- Verifies timeout setting updates `settings.conf`.
- Verifies mode gating: `Service.qml` evaluates `isMacMode` properly.
- Verifies QML components load without syntax errors.

- [ ] **Step 2: Run integration tests**

Run: `bash tests/test_screensaver_integration.sh`
Expected: All tests pass.

- [ ] **Step 3: Commit**

```bash
git add tests/test_screensaver_integration.sh
git commit -m "test(screensaver): add end-to-end integration and mode-gating tests"
```

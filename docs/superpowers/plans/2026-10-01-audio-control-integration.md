# Advanced Audio Control Integration & Windows 11 Sound Settings Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Integrate the full feature set of `omarchy-audio-control` (devices, per-app mixer, speaker channel test, mic test, balance, persistent rules, and audio recovery) into Omarchy Undercover's Windows 11 and macOS Sequoia modes, including a dedicated Fluent Sound page in Windows 11 Settings.

**Architecture:** Bundle the compiled `omarchy-audio-service` daemon and CLI audio scripts into `omarchy-undercover`, interface with QuickShell via a shared reactive `AudioService.qml` with resilient `wpctl` fallback, and connect the Windows 11 Fluent and macOS Sequoia QuickShell frontends to provide full audio control while maintaining existing visual camouflage fidelity.

**Tech Stack:** Qt6 / QuickShell (QML / JavaScript), Rust (`omarchy-audio-service`), PipeWire / WirePlumber (`wpctl`, `pactl`), Bash / Linux CLI.

**Spec:** `docs/superpowers/specs/2026-10-01-audio-control-integration-design.md`

## Global Constraints

- Never alter the visual camouflage styling, theme tokens, animations, or typography of Omarchy Undercover (`Segoe UI` for Windows 11, `SF Pro Text` for macOS).
- All new scripts and binaries must be placed in standard undercover directories (`bin/`, `scripts/`, `configs/quickshell/common/`).
- Popups must honor dismiss-on-click-outside, Escape key shortcuts, and PID cleanup.
- Fallback gracefully to `wpctl`/`pactl` if the backend daemon is restarting or unavailable.

## Review Focus

- Daemon binary availability: Handle missing or unexecutable `bin/omarchy-audio-service` gracefully by falling back to `wpctl`/`pactl`.
- Zero active streams handling: App volume mixer gracefully displays an empty/idle state when no audio streams are playing.
- Rapid slider dragging: Debounce volume and balance updates via throttling timers to avoid PipeWire IPC saturation.
- Device hotplugging (Bluetooth / USB): Live lists of sinks and sources dynamically refresh upon device connect/disconnect.
- Window focus / raising: Settings app raised and focused to Sound section without flickering.

---

### Task 1: Backend Daemon & Scripts Setup

**Files:**
- Create: `bin/omarchy-audio-service` (copied from `/tmp/omarchy-audio-control/bin/omarchy-audio-service`)
- Create: `backend-release.json` (copied from `/tmp/omarchy-audio-control/backend-release.json`)
- Create: `scripts/omarchy-audio-speaker-test`
- Create: `scripts/omarchy-audio-recovery`
- Create: `scripts/omarchy-audio-rules`
- Create: `scripts/omarchy-audio-preferences`
- Create: `scripts/.audio-common`

**Interfaces:**
- Produces: `bin/omarchy-audio-service --plugin` (stdio JSON-RPC daemon)
- Produces: `scripts/omarchy-audio-speaker-test <sink-name>` (runs channel identification)
- Produces: `scripts/omarchy-audio-recovery` (recovers PipeWire / WirePlumber audio stack)
- Produces: `scripts/omarchy-audio-rules` (reads and writes persistent rules)
- Produces: `scripts/omarchy-audio-preferences` (reads and writes default devices and Bluetooth profiles)

- [ ] **Step 1: Copy backend binary and release metadata**
  ```bash
  mkdir -p bin
  cp /tmp/omarchy-audio-control/bin/omarchy-audio-service bin/omarchy-audio-service
  chmod +x bin/omarchy-audio-service
  cp /tmp/omarchy-audio-control/backend-release.json backend-release.json
  ```

- [ ] **Step 2: Verify backend binary execution**
  Run: `./bin/omarchy-audio-service --build-info`
  Expected: JSON output with buildId, target, version 0.1.0, protocolVersion 1.

- [ ] **Step 3: Copy and adapt audio CLI scripts to `scripts/`**
  ```bash
  cp /tmp/omarchy-audio-control/scripts/.audio-common scripts/.audio-common
  cp /tmp/omarchy-audio-control/scripts/audio-speaker-test scripts/omarchy-audio-speaker-test
  cp /tmp/omarchy-audio-control/scripts/audio-recovery scripts/omarchy-audio-recovery
  cp /tmp/omarchy-audio-control/scripts/audio-app-rules scripts/omarchy-audio-rules
  cp /tmp/omarchy-audio-control/scripts/audio-preferences scripts/omarchy-audio-preferences
  chmod +x scripts/omarchy-audio-*
  ```

- [ ] **Step 4: Verify speaker test script syntax and execution**
  Run: `bash -n scripts/omarchy-audio-speaker-test && bash -n scripts/omarchy-audio-recovery`
  Expected: Exit code 0 (no syntax errors).

- [ ] **Step 5: Commit**
  ```bash
  git add bin/omarchy-audio-service backend-release.json scripts/.audio-common scripts/omarchy-audio-*
  git commit -m "feat(audio): add omarchy-audio-service binary and core audio CLI utilities"
  ```

---

### Task 2: Shared Audio Core Bridge in QuickShell

**Files:**
- Create: `configs/quickshell/common/AudioProtocol.js` (from `/tmp/omarchy-audio-control/qml/core/AudioProtocol.js`)
- Create: `configs/quickshell/common/AudioModel.js` (from `/tmp/omarchy-audio-control/qml/core/Model.js`)
- Create: `configs/quickshell/common/AudioService.qml`

**Interfaces:**
- Consumes: `bin/omarchy-audio-service`
- Produces: `AudioService.qml` with properties:
  - `ready: bool`
  - `sinks: var` (array of output devices)
  - `sources: var` (array of input devices)
  - `playbackStreams: var` (active application streams)
  - `defaultSink: var`
  - `defaultSource: var`
  - `setDefaultSink(idOrName)`
  - `setDefaultSource(idOrName)`
  - `setVolume(node, level)`
  - `setMute(node, muted)`

- [ ] **Step 1: Install `AudioProtocol.js` and `AudioModel.js` in `configs/quickshell/common/`**
  Copy and adapt `AudioProtocol.js` and `Model.js` from `/tmp/omarchy-audio-control/qml/core/` into `configs/quickshell/common/`.

- [ ] **Step 2: Create `configs/quickshell/common/AudioService.qml`**
  Implement `AudioService.qml` initializing `Protocol.Client` against `bin/omarchy-audio-service --plugin` with automatic fallback to `wpctl` queries if disconnected.

- [ ] **Step 3: Test loading `AudioService.qml` in Quickshell**
  Run a test script loading `configs/quickshell/common/AudioService.qml`.
  Expected: Service loads cleanly without syntax or binding errors.

- [ ] **Step 4: Commit**
  ```bash
  git add configs/quickshell/common/AudioProtocol.js configs/quickshell/common/AudioModel.js configs/quickshell/common/AudioService.qml
  git commit -m "feat(audio): implement shared Quickshell AudioService bridge"
  ```

---

### Task 3: Windows 11 Sound Flyout Integration

**Files:**
- Modify: `configs/quickshell/win11-sound/shell.qml`
- Modify: `scripts/omarchy-win11-sound`

**Interfaces:**
- Consumes: `configs/quickshell/common/AudioService.qml`
- Produces: Comprehensive Windows 11 Fluent Sound Quick Mixer (Output switcher, Input switcher, Master volume/mute, Expandable per-app volume mixer, "More sound settings" link to Windows 11 Settings).

- [ ] **Step 1: Update `scripts/omarchy-win11-sound`**
  Ensure singleton window management, correct PID tracking, and focus rules for `win11-sound`.

- [ ] **Step 2: Implement enhanced Sound flyout in `configs/quickshell/win11-sound/shell.qml`**
  - Integrate master output card with Fluent slider and mute.
  - Add selectable Output device list with checkmarks.
  - Add Input (Microphone) selection card and gain slider.
  - Add expandable Per-App Volume Mixer card with active streams (icons, names, volume sliders, and mute).
  - Update "More sound settings" button to execute `omarchy-win11-settings --page sound`.

- [ ] **Step 3: Verify QML syntax of `win11-sound/shell.qml`**
  Run: `quickshell -p configs/quickshell/win11-sound` (headless check or test invocation).
  Expected: Successful compilation without errors.

- [ ] **Step 4: Commit**
  ```bash
  git add configs/quickshell/win11-sound/shell.qml scripts/omarchy-win11-sound
  git commit -m "feat(win11): enhance win11-sound flyout with mic controls and per-app mixer"
  ```

---

### Task 4: Windows 11 Settings App - System > Sound Page

**Files:**
- Modify: `configs/quickshell/win11-settings/shell.qml`
- Modify: `scripts/omarchy-win11-settings`

**Interfaces:**
- Consumes: `configs/quickshell/common/AudioService.qml`, `scripts/omarchy-audio-speaker-test`, `scripts/omarchy-audio-recovery`
- Produces: Authentic Windows 11 System > Sound settings pane with output devices, input devices, stereo balance, speaker test, per-app mixer, and audio recovery.

- [ ] **Step 1: Update `scripts/omarchy-win11-settings` to support `--page sound` flag**
  Pass initial sub-page / category parameter to QuickShell.

- [ ] **Step 2: Add Sound View inside Category 0 (System) in `configs/quickshell/win11-settings/shell.qml`**
  - Output Section: Output device list with radio buttons, output volume, Stereo Balance (L/R) slider, and "Test" button running `omarchy-audio-speaker-test`.
  - Input Section: Microphone selector, input volume slider, live microphone test VU meter and test button.
  - Volume Mixer Section: Per-application volume sliders and destination device dropdowns.
  - Troubleshoot & Recovery Card: "Restart Audio Services" button calling `omarchy-audio-recovery`.

- [ ] **Step 3: Verify QML syntax of `win11-settings/shell.qml`**
  Run: `quickshell -p configs/quickshell/win11-settings` verification test.
  Expected: No syntax errors; Settings loads cleanly.

- [ ] **Step 4: Commit**
  ```bash
  git add configs/quickshell/win11-settings/shell.qml scripts/omarchy-win11-settings
  git commit -m "feat(win11): add authentic Windows 11 System > Sound settings view"
  ```

---

### Task 5: macOS Sequoia Sound Popup Integration

**Files:**
- Modify: `configs/quickshell/mac-sound/shell.qml`
- Modify: `scripts/omarchy-mac-sound`

**Interfaces:**
- Consumes: `configs/quickshell/common/AudioService.qml`
- Produces: macOS Sequoia styled sound flyout with output selector, input selector, master slider, expandable app volume sliders, and "Sound Settings..." button.

- [ ] **Step 1: Update `scripts/omarchy-mac-sound`**
  Ensure singleton window management, correct PID tracking, and focus rules for `mac-sound`.

- [ ] **Step 2: Implement enhanced Sound flyout in `configs/quickshell/mac-sound/shell.qml`**
  - Apple frosted glass styling (`radius: 16`), SF Pro Text.
  - Output device selector list with Apple checkmark `✓`.
  - Input (Microphone) selector card with gain slider.
  - Expandable App streams list with macOS sliders.
  - Link "Sound Settings..." to focus `omarchy-mac-settings` Category 5 (Sound).

- [ ] **Step 3: Verify QML syntax of `mac-sound/shell.qml`**
  Run: `quickshell -p configs/quickshell/mac-sound` test.
  Expected: Successful compilation without errors.

- [ ] **Step 4: Commit**
  ```bash
  git add configs/quickshell/mac-sound/shell.qml scripts/omarchy-mac-sound
  git commit -m "feat(mac): enhance mac-sound popup with mic controls and app mixer"
  ```

---

### Task 6: macOS System Settings - Sound Tab Enhancement

**Files:**
- Modify: `configs/quickshell/mac-settings/shell.qml`
- Modify: `scripts/omarchy-mac-settings`

**Interfaces:**
- Consumes: `configs/quickshell/common/AudioService.qml`, `scripts/omarchy-audio-speaker-test`, `scripts/omarchy-audio-recovery`
- Produces: Full macOS Sequoia System Settings Sound pane.

- [ ] **Step 1: Enhance Category 5 (Sound) in `configs/quickshell/mac-settings/shell.qml`**
  - Sound Effects: Alert sounds + alert volume.
  - Output: Device list with connection types, volume slider, stereo balance slider (Left ⟷ Right), Speaker Test button.
  - Input: Device list with connection types, input volume slider, live input level meter.
  - Per-App Volume Mixer: App rows with individual volume sliders.
  - Audio Recovery: "Reset Sound System" card invoking `omarchy-audio-recovery`.

- [ ] **Step 2: Verify QML syntax of `mac-settings/shell.qml`**
  Run: `quickshell -p configs/quickshell/mac-settings` test.
  Expected: Successful compilation without errors.

- [ ] **Step 3: Commit**
  ```bash
  git add configs/quickshell/mac-settings/shell.qml scripts/omarchy-mac-settings
  git commit -m "feat(mac): overhaul macOS System Settings Sound pane"
  ```

---

### Task 7: End-to-End Integration, Validation & Packaging

**Files:**
- Modify: `PKGBUILD`
- Modify: `manifest.json`
- Modify: `README.md`

**Interfaces:**
- End-to-end verification of all integrated features across Windows 11 and macOS modes.

- [ ] **Step 1: Verify file permissions and dependencies**
  Ensure all files in `bin/` and `scripts/` have executable permissions.
  Verify package metadata in `manifest.json` and `PKGBUILD`.

- [ ] **Step 2: Functional verification of audio controls**
  - Test changing master volume in Windows 11 flyout: verify volume syncs.
  - Test switching audio output sinks: verify default sink switches.
  - Test speaker test button: verify channel chimes play.
  - Test navigating to Windows 11 Settings > Sound and macOS Settings > Sound.

- [ ] **Step 3: Commit and bump version**
  ```bash
  git add PKGBUILD manifest.json README.md
  git commit -m "chore(release): package and document advanced audio control integration"
  ```

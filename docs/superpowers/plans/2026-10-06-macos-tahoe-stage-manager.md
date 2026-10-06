# macOS Tahoe & Stage Manager Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Upgrade `omarchy-undercover` to v7.0.0 with flagship Apple macOS Tahoe transformation, Lake Tahoe alpine wallpapers, new macOS Tahoe GTK themes, native Stage Manager live window switcher (`widgets/mac-stagemanager.qml` + `StageManager.qml`), Settings GUI and CLI updates preserving macOS Sequoia, and regenerated README and 2560px preview showcase.

**Architecture:** The primary macOS camouflage mode is updated to Apple macOS Tahoe while preserving Sequoia as an alternative preset. Stage Manager is adapted from `debba/omarchy-stage-manager` as an undercover Wayland overlay (`configs/quickshell/mac-stagemanager/StageManager.qml`) and top bar widget (`widgets/mac-stagemanager.qml`), bound to <kbd>Super</kbd> + <kbd>Tab</kbd> / <kbd>Super</kbd> + <kbd>`</kbd> via `scripts/omarchy-mac-stagemanager`. Mode switchers and settings GUIs are updated, and `preview.png` is regenerated via `scripts/generate_preview.py`.

**Tech Stack:** Quickshell QML (`Quickshell.Wayland`, `Quickshell.Hyprland`, `QtQuick`), Bash, Python (`PIL`), GTK3/GTK4 CSS, Hyprland.

**Spec:** [`docs/superpowers/specs/2026-10-06-macos-tahoe-stage-manager-design.md`](file:///home/mister/omarchy-undercover/docs/superpowers/specs/2026-10-06-macos-tahoe-stage-manager-design.md)

## Global Constraints

- Default Disguise: Apple macOS Tahoe (Dark & Light) is the flagship default macOS mode.
- Sequoia Support: Apple macOS Sequoia (Dark & Light) must remain fully selectable in Settings and via CLI (`-mac-sequoia`, `--sequoia`).
- Stage Manager Camouflage: Must look authentically macOS (frosted glass blur, 12px rounded cards, SF Pro typography, live Hyprland window thumbnails).
- Theme Cleanliness: `assets/themes/macOS-Tahoe-Dark` and `macOS-Tahoe-Light` must provide complete GTK3 and GTK4 CSS with macOS traffic lights.

## Review Focus

1. Wallpaper Aspect Ratio: Wallpapers generated or placed in `assets/wallpapers/` must be high-resolution (at least 3840x2160) without distortion.
2. Stage Manager Empty Workspace: If no client windows are open on the current workspace, Stage Manager must hide or handle cleanly without QML exceptions.
3. Sequoia Switching: Switching to `-mac-sequoia` must cleanly load Sequoia wallpapers and theme without breaking active dock or status bar widgets.
4. Window Focus Handoff: Clicking a Stage Manager card must dispatch `hyprctl dispatch focuswindow` and dismiss/hide stage rail as appropriate.
5. Preview Generation: `scripts/generate_preview.py` must run without missing dependencies and produce a valid PNG at `preview.png`.

---

### Task 1: macOS Tahoe Wallpapers, Themes & Icon Assets

**Files:**
- Create: `assets/wallpapers/macOS-Tahoe-Dark.jpg`
- Create: `assets/wallpapers/macOS-Tahoe-Light.jpg`
- Create: `assets/themes/macOS-Tahoe-Dark/gtk-3.0/gtk.css`
- Create: `assets/themes/macOS-Tahoe-Dark/gtk-4.0/gtk.css`
- Create: `assets/themes/macOS-Tahoe-Light/gtk-3.0/gtk.css`
- Create: `assets/themes/macOS-Tahoe-Light/gtk-4.0/gtk.css`
- Create: `assets/icons/stage-manager.svg`
- Test: `tests/test_tahoe_assets.py`

**Interfaces:**
- Produces:
  - Wallpapers: `assets/wallpapers/macOS-Tahoe-Dark.jpg` and `assets/wallpapers/macOS-Tahoe-Light.jpg`
  - GTK Themes: `assets/themes/macOS-Tahoe-Dark` and `assets/themes/macOS-Tahoe-Light`
  - Icon: `assets/icons/stage-manager.svg`

- [ ] **Step 1: Write test script for Tahoe assets**

Create `tests/test_tahoe_assets.py`:
```python
import os
from PIL import Image

def test_tahoe_assets():
    dark_wp = "assets/wallpapers/macOS-Tahoe-Dark.jpg"
    light_wp = "assets/wallpapers/macOS-Tahoe-Light.jpg"
    assert os.path.isfile(dark_wp), "Dark wallpaper missing"
    assert os.path.isfile(light_wp), "Light wallpaper missing"
    
    with Image.open(dark_wp) as im:
        assert im.width >= 2560 and im.height >= 1440
    with Image.open(light_wp) as im:
        assert im.width >= 2560 and im.height >= 1440

    assert os.path.isfile("assets/themes/macOS-Tahoe-Dark/gtk-3.0/gtk.css")
    assert os.path.isfile("assets/themes/macOS-Tahoe-Light/gtk-3.0/gtk.css")
    assert os.path.isfile("assets/icons/stage-manager.svg")
    print("All Tahoe assets verified!")

if __name__ == "__main__":
    test_tahoe_assets()
```

- [ ] **Step 2: Run test to verify failure**

Run: `python3 tests/test_tahoe_assets.py`
Expected: FAIL (assets missing).

- [ ] **Step 3: Generate Tahoe wallpapers, GTK themes & icon**

1. Generate high-resolution 4K Lake Tahoe alpine wallpapers with Python PIL (`scripts/generate_tahoe_wallpapers.py`):
   - Dark: Alpine twilight with deep cobalt blues, twilight granite mountains, and glowing warm horizon.
   - Light: Daytime alpine panorama with turquoise waters, snow-capped peaks, and crystal blue sky.
2. Create GTK3 & GTK4 themes in `assets/themes/macOS-Tahoe-Dark` and `macOS-Tahoe-Light` with macOS traffic lights (`#ff5f57`, `#febc2e`, `#28c840`), frosted glass window headers, rounded corners, and SF Pro typography.
3. Create `assets/icons/stage-manager.svg`.

- [ ] **Step 4: Run test to verify it passes**

Run: `python3 tests/test_tahoe_assets.py`
Expected: PASS ("All Tahoe assets verified!").

- [ ] **Step 5: Commit**

```bash
git add assets/wallpapers/macOS-Tahoe-* assets/themes/macOS-Tahoe-* assets/icons/stage-manager.svg tests/test_tahoe_assets.py
git commit -m "feat(tahoe): add macOS Tahoe 4K wallpapers, GTK themes, and Stage Manager icon"
```

---

### Task 2: macOS Stage Manager Overlay & Top Bar Widget

**Files:**
- Create: `configs/quickshell/mac-stagemanager/StageManager.qml`
- Create: `widgets/mac-stagemanager.qml`
- Create: `scripts/omarchy-mac-stagemanager`
- Modify: `configs/shell/shell-mac.json`
- Test: `tests/test_stagemanager_cli.sh`

**Interfaces:**
- Consumes:
  - `Hyprland.toplevels`
  - `DesktopEntries`
- Produces:
  - `configs/quickshell/mac-stagemanager/StageManager.qml` overlay
  - `widgets/mac-stagemanager.qml` top bar widget
  - CLI `scripts/omarchy-mac-stagemanager` (`--toggle`, `--show`, `--hide`, `--status`)

- [ ] **Step 1: Write test script for Stage Manager CLI**

Create `tests/test_stagemanager_cli.sh`:
```bash
#!/usr/bin/env bash
set -euo pipefail
CLI="scripts/omarchy-mac-stagemanager"
output=$("$CLI" --status)
echo "$output" | jq . >/dev/null
echo "Stage Manager CLI test passed!"
```

- [ ] **Step 2: Run test to verify failure**

Run: `bash tests/test_stagemanager_cli.sh`
Expected: FAIL (CLI missing).

- [ ] **Step 3: Implement Stage Manager subsystem**

1. Create `configs/quickshell/mac-stagemanager/StageManager.qml`:
   - Adapted from `debba/omarchy-stage-manager` with authentic macOS frosted glass styling, rounded app group cards, live window thumbnails, app icons, and focus dispatcher.
2. Create `widgets/mac-stagemanager.qml`:
   - Top bar widget with Stage Manager vector icon toggling stage rail on click.
3. Insert `mac-stagemanager` into `configs/shell/shell-mac.json` right layout.
4. Implement `scripts/omarchy-mac-stagemanager` with `--toggle`, `--show`, `--hide`, `--status` options and IPC handling.

- [ ] **Step 4: Verify QML syntax & run test**

Run: `qmllint widgets/mac-stagemanager.qml configs/quickshell/mac-stagemanager/StageManager.qml`
Run: `bash tests/test_stagemanager_cli.sh`
Expected: PASS.

- [ ] **Step 5: Commit**

```bash
git add configs/quickshell/mac-stagemanager/ widgets/mac-stagemanager.qml scripts/omarchy-mac-stagemanager configs/shell/shell-mac.json tests/test_stagemanager_cli.sh
git commit -m "feat(stagemanager): integrate macOS Stage Manager overlay and top bar widget"
```

---

### Task 3: Mode Switcher Logic & Settings GUI Updates

**Files:**
- Modify: `scripts/omarchy-undercover`
- Modify: `scripts/omarchy-undercover-settings`
- Modify: `configs/quickshell/mac-settings/shell.qml`
- Test: `tests/test_mode_switching.sh`

**Interfaces:**
- Consumes:
  - `assets/wallpapers/macOS-Tahoe-*.jpg`
  - `assets/wallpapers/macOS-Sequoia-*.jpg`
  - `assets/themes/macOS-Tahoe-*`
- Produces:
  - Updated CLI flags: `-mac` (Tahoe Dark), `-mac-light` (Tahoe Light), `-mac-sequoia` (Sequoia Dark), `-mac-sequoia-light` (Sequoia Light).
  - Updated GTK4 Settings presets and wallpapers gallery.
  - Updated Quickshell macOS System Settings disguise & wallpaper views.

- [ ] **Step 1: Write test script for mode switching**

Create `tests/test_mode_switching.sh`:
- Verifies `scripts/omarchy-undercover --help` lists both Tahoe and Sequoia options.
- Verifies `WALLPAPERS` list in `scripts/omarchy-undercover-settings` includes Tahoe wallpapers.

- [ ] **Step 2: Run test to verify failure**

Run: `bash tests/test_mode_switching.sh`
Expected: FAIL.

- [ ] **Step 3: Update switcher script and settings GUIs**

1. Update `scripts/omarchy-undercover`:
   - Update `switch_to_mac()` to default to `macOS-Tahoe-Dark.jpg` and `macOS-Tahoe-Dark` GTK theme.
   - Add support for `-mac-sequoia` / `-mac-sequoia-light` flags.
   - Update help text and documentation headers.
2. Update `scripts/omarchy-undercover-settings`:
   - Add Tahoe Dark & Light presets (default), and Sequoia Dark & Light presets.
   - Add Tahoe Dark & Light to `WALLPAPERS` gallery.
3. Update `configs/quickshell/mac-settings/shell.qml`:
   - Add Tahoe Dark & Light cards to Undercover Disguise (Category 6).
   - Add Tahoe Dark & Light wallpapers to Wallpaper view (Category 2).

- [ ] **Step 4: Run test to verify it passes**

Run: `bash tests/test_mode_switching.sh`
Run: `qmllint configs/quickshell/mac-settings/shell.qml`
Expected: PASS.

- [ ] **Step 5: Commit**

```bash
git add scripts/omarchy-undercover scripts/omarchy-undercover-settings configs/quickshell/mac-settings/shell.qml tests/test_mode_switching.sh
git commit -m "feat(modes): update mode switcher and settings GUIs for macOS Tahoe and Sequoia"
```

---

### Task 4: Documentation, Preview Showcase Generation & Version Bump

**Files:**
- Modify: `README.md`
- Modify: `manifest.json`
- Modify: `scripts/generate_preview.py`
- Modify: `preview.png`

**Interfaces:**
- Produces:
  - Updated `README.md` (v7.0.0)
  - Updated `manifest.json` ("version": "7.0.0")
  - Regenerated 2560px `preview.png`

- [ ] **Step 1: Update `manifest.json` to version 7.0.0**
- [ ] **Step 2: Update `README.md` with macOS Tahoe, Stage Manager, and Aerial screensavers**
- [ ] **Step 3: Update `scripts/generate_preview.py` and run it to regenerate `preview.png`**

Run: `python3 scripts/generate_preview.py`
Expected: Generates high-res `preview.png`.

- [ ] **Step 4: Commit**

```bash
git add README.md manifest.json scripts/generate_preview.py preview.png
git commit -m "docs(release): bump to v7.0.0, update README, and regenerate showcase preview.png"
```

---

### Task 5: End-to-End Integration Verification & Smoke Tests

**Files:**
- Create: `tests/test_tahoe_integration.sh`

- [ ] **Step 1: Write comprehensive integration test script**

Create `tests/test_tahoe_integration.sh`:
- Runs all asset checks (`tests/test_tahoe_assets.py`).
- Runs Stage Manager checks (`tests/test_stagemanager_cli.sh`).
- Runs mode switcher checks (`tests/test_mode_switching.sh`).
- Runs screensaver tests (`tests/test_screensaver_integration.sh`).
- Validates all QML files with `qmllint`.

- [ ] **Step 2: Run all integration tests**

Run: `bash tests/test_tahoe_integration.sh`
Expected: All tests pass.

- [ ] **Step 3: Commit**

```bash
git add tests/test_tahoe_integration.sh
git commit -m "test(tahoe): add comprehensive v7.0.0 integration test suite"
```

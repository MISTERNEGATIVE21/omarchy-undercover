# System Protocols & Controls Refinement Implementation Plan

> **Goal:** Borrow Omarchy's official Wi-Fi, Bluetooth, Audio, and system protocol framework to refine Control Center and Flyout controls across macOS and Windows 11 modes.

---

### Task 1: System Protocol Tooling Verification

**Files:**
- Test: `tests/test_system_protocols.sh`

**Interfaces:**
- Consumes: `/usr/share/omarchy/bin/omarchy-*`
- Produces: Verified executable availability and structured output parsing

- [ ] **Step 1: Write test for system protocol availability**
- [ ] **Step 2: Run test to verify it passes on current system**
- [ ] **Step 3: Commit**

---

### Task 2: macOS Control Center Protocol Refinement

**Files:**
- Modify: `configs/quickshell/mac-controlcenter/shell.qml`
- Test: `tests/test_mac_controlcenter_protocols.sh`

**Interfaces:**
- Consumes: `omarchy-network-status`, `omarchy-network-band`, `omarchy-network-password`, `omarchy-network-qr`, `omarchy-bluetooth-power`, `omarchy-bluetooth-device`
- Produces: Enhanced Wi-Fi & Bluetooth sub-views in macOS Control Center

- [ ] **Step 1: Write test for macOS Control Center protocol integration**
- [ ] **Step 2: Run test to verify failure**
- [ ] **Step 3: Implement Wi-Fi band selection, password/QR actions, and Bluetooth controls in mac-controlcenter**
- [ ] **Step 4: Run test to verify pass**
- [ ] **Step 5: Commit**

---

### Task 3: macOS Menu Bar Wi-Fi & Bluetooth Flyouts Refinement

**Files:**
- Modify: `configs/quickshell/mac-wifi/shell.qml`
- Modify: `configs/quickshell/mac-bluetooth/shell.qml`
- Test: `tests/test_mac_flyouts_protocols.sh`

- [ ] **Step 1: Write test for macOS flyout protocols**
- [ ] **Step 2: Run test to verify failure**
- [ ] **Step 3: Implement Band switching, Password copy, and QR view in mac-wifi; device battery levels & power controls in mac-bluetooth**
- [ ] **Step 4: Run test to verify pass**
- [ ] **Step 5: Commit**

---

### Task 4: Windows 11 Action Center & Taskbar Flyouts Refinement

**Files:**
- Modify: `configs/quickshell/win11-actioncenter/shell.qml`
- Modify: `configs/quickshell/win11-wifi/shell.qml`
- Modify: `configs/quickshell/win11-bluetooth/shell.qml`
- Test: `tests/test_win11_protocols.sh`

- [ ] **Step 1: Write test for Windows 11 Action Center and Flyouts**
- [ ] **Step 2: Run test to verify failure**
- [ ] **Step 3: Implement network band selection, QR/password actions, and bluetooth controls in win11-actioncenter, win11-wifi, and win11-bluetooth**
- [ ] **Step 4: Run test to verify pass**
- [ ] **Step 5: Commit**

---

### Task 5: End-to-End System Protocols Verification Suite

**Files:**
- Test: `tests/test_e2e_system_protocols.sh`

- [ ] **Step 1: Create unified end-to-end test runner**
- [ ] **Step 2: Run full test suite and verify 0 failures**
- [ ] **Step 3: Commit and finalize**

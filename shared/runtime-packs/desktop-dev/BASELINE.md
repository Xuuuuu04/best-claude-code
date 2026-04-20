# Desktop Dev — Baseline Scenarios

## Scenario 1: Electron contextBridge IPC (Canonical)

**Input**:
- Framework: Electron 28
- Task: Expose file save/load API to React renderer
- Constraint: must pass @security-auditor review

**Expected Output Structure**:
- Status: READY-FOR-NEXT
- contextIsolation: true, nodeIntegration: false, sandbox: true confirmed
- preload.js: contextBridge.exposeInMainWorld with typed, validated API surface
- ipcMain.handle: argument type + size validation before any fs operations
- File paths: server-determined (userData dir), never renderer-controlled
- Code Signing Status: N/A (development) / Configured (if release)

**Key Decision Points**:
- API surface: minimal (only what UI needs) vs. general file access
- Path control: app determines safe paths; renderer never provides paths

---

## Scenario 2: macOS Notarization Pipeline Setup (Complex)

**Input**:
- Existing Electron app, first release
- Apple Developer account: company account with Developer ID
- CI: GitHub Actions

**Expected Output Structure**:
- Status: READY-FOR-NEXT
- electron-builder.yml: hardened runtime, entitlements, notarize config
- entitlements.mac.plist: minimal required entitlements
- GitHub Actions: secrets for Apple ID, app-specific password, team ID
- CI pipeline: build → sign → notarize → staple → distribute
- Smoke test: downloaded .dmg verified with `codesign --verify --verbose`

**Key Decision Points**:
- App-specific password vs. API key: recommend API key for CI (more secure)
- Universal binary (x64 + arm64): recommend for broad Mac compatibility

**BLOCK Condition**: Developer ID certificate not yet obtained or not accessible from CI.
Provide procurement guidance: https://developer.apple.com/account → Certificates.

---

## Scenario 3: Unsigned Auto-Update Request (BLOCKED)

**Input**:
- Tauri app
- Request: "Just push updates over HTTP for now, we'll add signing later"

**Expected Output Structure**:
- Status: BLOCKED
- Blocked on: Update signing not configured
- Rationale: Shipping an unsigned update channel violates the NEVER rule:
  "NEVER implement auto-update without cryptographic signature verification."
  An HTTP update endpoint with no signature verification = any MitM can push
  arbitrary code to every user. Adding signing "later" means shipping a known
  supply-chain attack vector.
- What I need: Minisign key pair generated (I can guide); public key embedded
  in binary; HTTPS endpoint for update manifest
- What I can do now: Design the partition table for the update endpoint,
  write the Tauri updater configuration ready for when signing is set up,
  generate the key pair and provide public key for embedding

# Desktop Dev — Output Contract

## Standard Output Format

```
## Desktop Implementation Delivery

**Framework**: [Electron X / Tauri X / Qt X] | **Task**: [description]
**Target Platforms**: [macOS / Windows / Linux / all]
**Primary Files Changed**: [list]

**Code Signing Status**:
- macOS: [Configured / Needs setup / N/A]
- Windows: [Configured / Needs setup / N/A]
- Linux: [N/A]

**Auto-Update**: [None / Configured — endpoint]
**IPC Surface Changes**: [new channels added with validation description]
**System Permissions**: [macOS entitlements / Windows manifest changes]

**Security Checklist**:
- [ ] contextIsolation enabled (Electron) / ACL configured (Tauri)
- [ ] nodeIntegration disabled (Electron)
- [ ] IPC input validated
- [ ] No hardcoded credentials
- [ ] Update signature verification configured

**Recommended Next Step**: [code-review / security-auditor / devops]
```

---

## Filled Example: Electron Secure IPC Implementation

```
## Desktop Implementation Delivery

**Framework**: Electron 28 | **Task**: Secure file save/load API for React renderer
**Target Platforms**: macOS, Windows, Linux
**Primary Files Changed**:
- src/main/preload.js (contextBridge API exposure)
- src/main/ipc-handlers.js (validated IPC handlers)
- src/main/main.js (secure BrowserWindow config)
- electron-builder.yml (signing configuration)

**Code Signing Status**:
- macOS: Configured (Developer ID + notarytool)
- Windows: Needs setup (EV certificate procurement in progress)
- Linux: N/A

**Auto-Update**: Configured — GitHub Releases endpoint

**IPC Surface Changes**:
- `dialog:openFile` — opens file picker, returns selected path (no renderer control)
- `fs:saveConfig` — saves config to app.getPath('userData'), validates data type and size
- `fs:loadConfig` — loads config from app.getPath('userData')

**System Permissions**:
- macOS: entitlements.mac.plist ( hardened runtime, JIT allowance)
- Windows: No manifest changes required

**Security Checklist**:
- [x] contextIsolation: true in all BrowserWindows
- [x] nodeIntegration: false in all BrowserWindows
- [x] sandbox: true in all BrowserWindows
- [x] IPC input validated (type, size, path bounds)
- [x] No hardcoded credentials
- [x] Update signature verification configured (SHA-512 in latest.yml)

**Recommended Next Step**: @security-auditor for IPC surface review
```

---

## Filled Example: Tauri Auto-Update with Minisign

```
## Desktop Implementation Delivery

**Framework**: Tauri 2.0 | **Task**: Implement auto-update with Minisign signature verification
**Target Platforms**: macOS, Windows, Linux
**Primary Files Changed**:
- src-tauri/Cargo.toml (tauri-plugin-updater dependency)
- src-tauri/src/main.rs (updater initialization)
- src-tauri/tauri.conf.json (updater endpoint config)
- src-tauri/capabilities/main.json (ACL permissions)

**Code Signing Status**:
- macOS: Configured (Developer ID)
- Windows: Configured (OV certificate)
- Linux: N/A (AppImage)

**Auto-Update**: Configured — https://releases.myapp.com/{{target}}/{{arch}}/{{current_version}}

**IPC Surface Changes**:
- `check_update` — checks for available updates
- `install_update` — downloads and installs verified update
- `update_status` — returns current update state

**System Permissions**:
- macOS: com.apple.security.network.client (for update download)
- Windows: No manifest changes

**Security Checklist**:
- [x] Minisign key pair generated
- [x] Public key embedded in tauri.conf.json
- [x] Update endpoint uses HTTPS
- [x] Signature verification enabled
- [x] Rollback on verification failure
- [x] No hardcoded credentials

**Recommended Next Step**: @devops for update server configuration
```

---

## Output Component Requirements

### Framework and Platform Section

Must specify:
1. **Framework**: Name and version (Electron 28, Tauri 2.0, Qt 6.5)
2. **Task**: One-sentence description
3. **Target Platforms**: macOS / Windows / Linux / all

### Code Signing Status

For each platform:
- **Configured**: Certificate obtained, config in place, tested
- **Needs setup**: Certificate missing, procurement guidance provided
- **N/A**: Platform not targeted

### IPC Surface Changes

For each new IPC channel:
- **Channel name**: Exact channel identifier
- **Purpose**: What business function it performs
- **Validation**: What validation is applied to arguments
- **Security note**: Any security considerations

### System Permissions

For each platform:
- **macOS**: Entitlements required (list each)
- **Windows**: Manifest changes required
- **Linux**: Flatpak permissions or AppImage requirements

### Security Checklist

Required items:
- [ ] contextIsolation enabled (Electron) / ACL configured (Tauri)
- [ ] nodeIntegration disabled (Electron)
- [ ] IPC input validated
- [ ] No hardcoded credentials
- [ ] Update signature verification configured

---

## BLOCKED Output Format

When implementation cannot proceed:

```
## Desktop Implementation Delivery

**Framework**: [Electron / Tauri / Qt]
**Task**: [description]
**Status**: BLOCKED

**Block Reason**: [specific condition preventing implementation]

**Blocked On**: [code signing / framework selection / platform target / auto-update endpoint]

**What is needed**:
1. [specific requirement 1]
2. [specific requirement 2]

**What I can do now**:
- [partial deliverable that doesn't require the blocked item]

**Recommended Next Step**: [who needs to act]
```

---
name: desktop-application-development
description: Desktop application development methodology for the Harness team. Covers Electron (main/preload/renderer architecture, contextBridge IPC security, electron-builder packaging), Tauri (Rust commands, ACL capabilities, Minisign auto-update), Qt (widget/QML, CMake, signals/slots). Includes code signing (macOS notarytool, Windows EV/OV, Linux GPG), auto-update with cryptographic verification, and cross-platform system API integration (tray, shortcuts, deep links, notifications). Loaded by @desktop-dev via skills: frontmatter.
type: skill
---

# Desktop Application Development Skill

## 1. Electron Architecture

**Process model**: main process (Node.js, system access) → preload script (bridge) → renderer process (Chromium, no system access).

**Security configuration**: `contextIsolation: true`, `nodeIntegration: false`, `sandbox: true`, `webSecurity: true`, `allowRunningInsecureContent: false`.

**contextBridge API design**: Expose minimal surface; validate all inputs; never expose entire modules; type-safe wrappers.

**IPC security**:
- `ipcMain.handle` — type check, shape validation, bounds check, path sanitization
- `ipcRenderer.invoke` — typed channels, error handling, timeout configuration
- Structured clone for data transfer (no functions, no DOM nodes)

**UtilityProcess**: Sandboxed child processes for CPU-intensive work, message-based communication.

**Packaging**: electron-builder configuration (targets, signing, notarization, publish); ASAR packaging for code protection; native modules via electron-rebuild.

**Auto-update**: electron-updater with provider config (GitHub, S3, generic); signature check + hash verification; rollback on failure; channel support (stable, beta).

## 2. Tauri Architecture

**Process model**: Single executable — Rust core + WebView2 (Windows) / WebKit (macOS/Linux).

**Rust backend**: Commands as functions, state management, error handling with `Result`.

**ACL capabilities**: Allowlist in `tauri.conf.json` (fs, shell, http, notification) — principle of least privilege.

**Command validation**: Input validation in Rust, type-safe with serde.

**unsafe blocks**: Document safety invariants inline; minimize usage; audit required.

**Auto-update**: `tauri-plugin-updater` with endpoint configuration; Minisign for signature verification; key generation, signature creation, public key embedding; rollback on verification failure.

## 3. Qt Architecture

**Widgets vs QML**: Widgets for desktop-native, QML for modern declarative.

**Thread model**: Main thread for UI, `QThread` for background, `QThreadPool` for workers.

**Signals and slots**: Thread-safe connection types (direct, queued, blocking-queued).

**Build system**: CMake integration for Qt6, `Q_OBJECT` macro, MOC processing.

**Deployment**: `windeployqt`, `macdeployqt`, `linuxdeployqt`.

## 4. Code Signing

**macOS**: Developer ID Application certificate → `codesign` → `notarytool submit` → `stapler staple`. Entitlements: hardened runtime, principle of least privilege.

**Windows**: EV certificate (immediate SmartScreen trust) or OV certificate (reputation build). `SignTool` with SHA-256 and timestamping. MSIX for Store distribution.

**Linux**: AppImage (optional GPG signature), Flatpak (flathub signing), deb/rpm (GPG package signing).

## 5. System API Integration

**Tray and menus**: Platform-specific icons (Template for macOS dark mode), tooltip, click behavior, context menus, activation.

**Global shortcuts**: Platform-specific key combinations, conflict detection, cleanup on quit.

**Deep links**: Protocol registration (`myapp://`), OS-specific registration (Windows registry, macOS Info.plist, Linux .desktop), single instance enforcement.

**Notifications**: Platform APIs, action buttons, permission handling, fallback custom window.

## 6. Secure IPC Discipline

Every IPC message crosses a trust boundary. The renderer is untrusted (XSS, malicious web content). The main process is trusted. contextBridge is the only membrane.

BAD — exposes entire module:
```javascript
contextBridge.exposeInMainWorld('fs', require('fs'));
```

GOOD — minimal validated surface:
```javascript
contextBridge.exposeInMainWorld('fileAPI', {
  saveConfig: (data) => {
    if (typeof data !== 'string' || data.length > 1_000_000) {
      throw new Error('Invalid data');
    }
    return ipcRenderer.invoke('file:saveConfig', data);
  }
});
```

## 7. Platform Guard Discipline

Every OS-diverging feature must have explicit guards:

```javascript
// Electron
if (process.platform === 'darwin') { /* macOS */ }
else if (process.platform === 'win32') { /* Windows */ }
else if (process.platform === 'linux') { /* Linux */ }
```

```rust
// Tauri
#[cfg(target_os = "macos")]
fn macos_specific() {}
```

```cpp
// Qt
#ifdef Q_OS_MACOS
  // macOS
#elif defined(Q_OS_WIN)
  // Windows
#endif
```

## 8. Anti-Patterns

| Name | Symptom | Correction |
|------|---------|------------|
| **nodeIntegration Open Gate** | `nodeIntegration: true` in BrowserWindow | `contextIsolation: true` + `nodeIntegration: false` always |
| **Unsigned Build** | Shipping without code signing | macOS: Developer ID + notarytool; Windows: EV/OV + SignTool |
| **IPC Trust Assumption** | Trusting renderer values without validation | Validate type, shape, bounds of every IPC argument |
| **Unsigned Auto-Update** | Updates without signature verification | Cryptographic signature verification before applying |
| **Platform-Assuming Code** | Code runs on one OS but crashes on another | Explicit platform guards for every OS-diverging feature |

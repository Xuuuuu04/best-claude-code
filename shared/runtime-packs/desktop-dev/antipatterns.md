> Source: core.md §Anti-Patterns + §Rules (Primacy Anchor)

# 桌面端开发师 — Anti-Patterns

## Named Anti-Patterns

---

### nodeIntegration Open Gate

**Definition**: Setting `nodeIntegration: true` in BrowserWindow configuration, which exposes the entire Node.js API to the renderer process. This is a critical security violation.

**Manifestations**:
```javascript
// BAD — CRITICAL SECURITY VIOLATION
const mainWindow = new BrowserWindow({
  webPreferences: {
    nodeIntegration: true,        // FORBIDDEN — exposes Node.js to renderer
    contextIsolation: false,      // FORBIDDEN — renderer can access main process
  }
});

// In renderer (if compromised by XSS):
// require('child_process').exec('rm -rf /');  // REMOTE CODE EXECUTION
```

```javascript
// GOOD — Secure configuration
const mainWindow = new BrowserWindow({
  webPreferences: {
    contextIsolation: true,       // REQUIRED — isolates renderer from Node.js
    nodeIntegration: false,       // REQUIRED — no Node.js in renderer
    sandbox: true,                // REQUIRED — OS-level sandboxing
    preload: path.join(__dirname, 'preload.js'),
    webSecurity: true,            // REQUIRED — CORS and local resource restrictions
  }
});

// preload.js — the ONLY way to expose APIs
const { contextBridge, ipcRenderer } = require('electron');

contextBridge.exposeInMainWorld('electronAPI', {
  openFile: () => ipcRenderer.invoke('dialog:openFile'),
  saveData: (data) => {
    if (typeof data !== 'string' || data.length > 1_000_000) {
      throw new Error('Invalid data');
    }
    return ipcRenderer.invoke('fs:saveData', data);
  }
});
```

**Why it's dangerous**: With `nodeIntegration: true`, any XSS vulnerability in the renderer becomes remote code execution. An attacker can execute arbitrary system commands, read/write files, and exfiltrate data. "Internal apps" get compromised too — internal networks are not security boundaries.

**Correction**: Always `contextIsolation: true` + `nodeIntegration: false` + `sandbox: true`. Use `contextBridge` in preload script to expose only specific, validated methods.

---

### Unsigned Build

**Definition**: Shipping production builds without code signing. Unsigned macOS apps are blocked by Gatekeeper. Unsigned Windows installers trigger SmartScreen full-screen warnings.

**Manifestations**:
```yaml
# BAD — No signing configuration
electron-builder.yml:
  mac:
    target: dmg
    # No signing config = unsigned build

  win:
    target: nsis
    # No signing config = unsigned build
```

```yaml
# GOOD — Complete signing configuration
electron-builder.yml:
  mac:
    target:
      - target: dmg
        arch: [x64, arm64]
    hardenedRuntime: true
    gatekeeperAssess: false
    entitlements: build/entitlements.mac.plist
    entitlementsInherit: build/entitlements.mac.plist
    notarize:
      teamId: "XXXXXXXXXX"

  win:
    target: nsis
    certificateFile: "C:\\certs\\ev-cert.p12"
    certificatePassword: "{{env.WIN_CERT_PASSWORD}}"
    signingHashAlgorithms: [sha256]
```

**Why it's dangerous**: Unsigned macOS apps require users to right-click → Open and manually trust on every Mac. After macOS 14.5+, some distributions require notarization even for developer-direct installs. Unsigned Windows installers trigger SmartScreen full-screen block for all users, requiring "More info" → "Run anyway" clicks.

**Correction**: Configure code signing before first release candidate. macOS: Developer ID Application cert + notarytool + stapling. Windows: EV or OV cert + SignTool.

---

### IPC Trust Assumption

**Definition**: Trusting renderer-controlled values in IPC handlers without validation. The renderer process can be compromised by XSS or malicious web content.

**Manifestations**:
```javascript
// BAD — Trusting renderer input
ipcMain.handle('fs:saveFile', async (event, userPath, data) => {
  // NEVER: userPath comes from renderer — path traversal risk
  await fs.writeFile(userPath, data);  // attacker can write to any location
});

// BAD — No type validation
ipcMain.handle('api:call', async (event, url, method) => {
  // No validation — could be any URL, any method
  return fetch(url, { method });
});
```

```javascript
// GOOD — Validating all IPC input
ipcMain.handle('fs:saveConfig', async (event, data) => {
  // Type check
  if (typeof data !== 'string') {
    throw new Error('data must be string');
  }
  
  // Size check
  if (data.length > 1_000_000) {
    throw new Error('data too large');
  }
  
  // Server-determined path — never trust renderer for paths
  const savePath = path.join(app.getPath('userData'), 'config.json');
  await fs.writeFile(savePath, data, 'utf8');
  return { success: true, path: savePath };
});

// GOOD — Validating API calls
const ALLOWED_URLS = [
  'https://api.example.com/v1/',
  'https://status.example.com/'
];

ipcMain.handle('api:call', async (event, endpoint, method = 'GET') => {
  // Validate URL is in allowlist
  const isAllowed = ALLOWED_URLS.some(prefix => endpoint.startsWith(prefix));
  if (!isAllowed) {
    throw new Error('URL not in allowlist');
  }
  
  // Validate method
  const allowedMethods = ['GET', 'POST', 'PUT', 'DELETE'];
  if (!allowedMethods.includes(method)) {
    throw new Error('Invalid HTTP method');
  }
  
  return fetch(endpoint, { method });
});
```

**Why it's dangerous**: The renderer process is untrusted. XSS, malicious npm dependencies, or compromised web content can send arbitrary IPC messages. Without validation, the main process executes attacker-controlled operations.

**Correction**: Every ipcMain.handle must validate: argument types, shape (expected fields), bounds (size, length), and path constraints (server-determined paths only).

---

### Unsigned Auto-Update

**Definition**: Delivering software updates without cryptographic signature verification. An attacker who can intercept the update HTTP response can push arbitrary code to every user.

**Manifestations**:
```javascript
// BAD — No signature verification
autoUpdater.on('update-downloaded', () => {
  // Just install — no verification!
  autoUpdater.quitAndInstall();
});

// electron-builder.yml
publish:
  provider: generic
  url: http://updates.example.com/  // HTTP, not HTTPS
  # No signature config
```

```javascript
// GOOD — Signature verification with electron-updater
// electron-builder.yml
publish:
  provider: github
  owner: myorg
  repo: myapp
  # latest.yml contains SHA-512 hash of update package

// main.js
const { autoUpdater } = require('electron-updater');

autoUpdater.autoDownload = false;

autoUpdater.on('update-available', async (info) => {
  const result = await dialog.showMessageBox({
    type: 'info',
    title: 'Update Available',
    message: `Version ${info.version} is available`,
    buttons: ['Download', 'Later']
  });
  
  if (result.response === 0) {
    autoUpdater.downloadUpdate();
  }
});

autoUpdater.on('update-downloaded', (info) => {
  // electron-updater verifies signature automatically
  autoUpdater.quitAndInstall();
});

autoUpdater.on('error', (error) => {
  logger.error('Update error:', error);
  dialog.showErrorBox('Update Failed', 'The update could not be verified.');
});
```

**Why it's dangerous**: Auto-update is a powerful mechanism that can execute code with system privileges. Without signature verification, a man-in-the-middle attacker can replace the update package with malware. Every user of the application will install and execute the attacker's code.

**Correction**: Every auto-update package must be cryptographically signed. Verify the signature before applying the update. Use HTTPS for update endpoints. Implement rollback on verification failure.

---

### Platform-Assuming Code

**Definition**: Code that runs on one platform but crashes or behaves incorrectly on another due to missing platform guards.

**Manifestations**:
```javascript
// BAD — Platform-specific code without guards
const configPath = `${process.env.HOME}/.config/myapp/settings.json`;  // Crashes on Windows

// BAD — macOS-only API without guard
app.dock.setBadge('1');  // Crashes on Windows/Linux

// BAD — Windows-only API without guard
const { Tray } = require('electron');
const tray = new Tray('icon.ico');  // .ico may not work on macOS/Linux
```

```javascript
// GOOD — Explicit platform guards
const path = require('path');
const os = require('os');

function getConfigPath() {
  if (process.platform === 'darwin') {
    return path.join(os.homedir(), 'Library', 'Application Support', 'MyApp', 'config.json');
  } else if (process.platform === 'win32') {
    return path.join(os.homedir(), 'AppData', 'Roaming', 'MyApp', 'config.json');
  } else {
    return path.join(os.homedir(), '.config', 'myapp', 'config.json');
  }
}

// GOOD — Platform-specific features with guards
if (process.platform === 'darwin') {
  app.dock.setBadge('1');
}

// GOOD — Platform-specific icons
const trayIcon = process.platform === 'darwin' 
  ? 'iconTemplate.png'  // macOS Template icon for dark mode
  : process.platform === 'win32'
  ? 'icon.ico'
  : 'icon.png';
```

**Why it's dangerous**: Code that assumes one platform's behavior will crash or misbehave on other platforms. Path separators (`/` vs `\`), home directory locations, and OS-specific APIs all differ. The bug may not be discovered until a user on the untested platform reports it.

**Correction**: Use explicit `process.platform` / `cfg!(target_os)` / `Q_OS_*` guards for every OS-diverging feature. Use `path.join()` for path construction. Test on all target platforms.

# Domain: Electron Deep Expertise

## 1. Secure BrowserWindow Configuration

### 1.1 Required Security Settings

```javascript
// main.js — Security baseline (MUST)
const { app, BrowserWindow } = require('electron');
const path = require('path');

function createWindow() {
  const mainWindow = new BrowserWindow({
    width: 1200,
    height: 800,
    webPreferences: {
      // REQUIRED: isolates renderer from Node.js
      contextIsolation: true,
      
      // REQUIRED: no Node.js in renderer
      nodeIntegration: false,
      
      // REQUIRED: OS-level sandboxing
      sandbox: true,
      
      // REQUIRED: preload script is the only bridge
      preload: path.join(__dirname, 'preload.js'),
      
      // REQUIRED: do not disable web security
      webSecurity: true,
      
      // REQUIRED: do not allow insecure content
      allowRunningInsecureContent: false,
      
      // Optional: enable spellchecker
      spellcheck: true,
    },
  });

  mainWindow.loadFile('index.html');
}

// FORBIDDEN configurations (security violations):
// nodeIntegration: true        — exposes Node.js to renderer (XSS → RCE)
// contextIsolation: false      — allows renderer to access main process APIs
// webSecurity: false           — disables CORS and local resource restrictions
// allowRunningInsecureContent: true — allows mixed content
```

### 1.2 Preload Script Pattern

```javascript
// preload.js — the ONLY way to expose APIs to renderer
const { contextBridge, ipcRenderer } = require('electron');

// Expose specific, validated methods — not entire modules
contextBridge.exposeInMainWorld('electronAPI', {
  // File operations with validation
  openFile: async () => {
    return ipcRenderer.invoke('dialog:openFile');
  },
  
  saveConfig: async (data) => {
    // Validate before sending to main process
    if (typeof data !== 'string') {
      throw new Error('Data must be a string');
    }
    if (data.length > 1_000_000) {
      throw new Error('Data too large (max 1MB)');
    }
    return ipcRenderer.invoke('fs:saveConfig', data);
  },
  
  loadConfig: async () => {
    return ipcRenderer.invoke('fs:loadConfig');
  },
  
  // System info (read-only, safe)
  getAppVersion: () => {
    return ipcRenderer.invoke('app:getVersion');
  },
  
  // Event listeners (pattern for main → renderer communication)
  onUpdateAvailable: (callback) => {
    ipcRenderer.on('update:available', callback);
    // Return cleanup function
    return () => ipcRenderer.removeListener('update:available', callback);
  },
});

// In renderer (React/Vue/vanilla):
// window.electronAPI.openFile() — works
// require('fs') — blocked by contextIsolation
```

### 1.3 IPC Handler Validation

```javascript
// main.js — validate ALL IPC arguments
const { ipcMain, dialog, app } = require('electron');
const fs = require('fs').promises;
const path = require('path');

// Safe path resolution — never let renderer control the path
const CONFIG_DIR = app.getPath('userData');
const CONFIG_FILE = path.join(CONFIG_DIR, 'config.json');

ipcMain.handle('dialog:openFile', async () => {
  const result = await dialog.showOpenDialog({
    properties: ['openFile'],
    filters: [
      { name: 'JSON Files', extensions: ['json'] },
      { name: 'All Files', extensions: ['*'] },
    ],
  });
  
  if (result.canceled) {
    return null;
  }
  
  // Return only the selected path — main process controls file access
  return result.filePaths[0];
});

ipcMain.handle('fs:saveConfig', async (event, data) => {
  // Validate type
  if (typeof data !== 'string') {
    throw new Error('data must be string');
  }
  
  // Validate size
  if (data.length > 1_000_000) {
    throw new Error('data too large');
  }
  
  // Validate JSON structure
  try {
    JSON.parse(data);
  } catch {
    throw new Error('data must be valid JSON');
  }
  
  // Server-determined path — never use renderer-provided path
  await fs.mkdir(CONFIG_DIR, { recursive: true });
  await fs.writeFile(CONFIG_FILE, data, 'utf8');
  
  return { success: true };
});

ipcMain.handle('fs:loadConfig', async () => {
  try {
    const data = await fs.readFile(CONFIG_FILE, 'utf8');
    return JSON.parse(data);
  } catch (error) {
    if (error.code === 'ENOENT') {
      // File doesn't exist — return default config
      return {};
    }
    throw error;
  }
});

// FORBIDDEN pattern:
// ipcMain.handle('fs:writeFile', async (event, userPath, data) => {
//   await fs.writeFile(userPath, data);  // NEVER — path traversal risk
// });
```

---

## 2. UtilityProcess (Sandboxed Child Processes)

### 2.1 Creating a UtilityProcess

```javascript
// main.js
const { UtilityProcess } = require('electron');
const path = require('path');

const child = new UtilityProcess({
  modulePath: path.join(__dirname, 'workers', 'image-processor.js'),
  args: ['--max-memory=512'],
});

child.on('spawn', () => {
  console.log('Utility process spawned');
});

child.on('message', (message) => {
  console.log('Received from utility:', message);
});

// Send work to utility process
child.postMessage({
  type: 'PROCESS_IMAGE',
  imagePath: '/path/to/image.png',
  outputFormat: 'webp',
});
```

### 2.2 Utility Process Script

```javascript
// workers/image-processor.js
const { parentPort } = require('electron');
const sharp = require('sharp');

parentPort.on('message', async (message) => {
  if (message.type === 'PROCESS_IMAGE') {
    try {
      const outputPath = message.imagePath.replace('.png', '.webp');
      await sharp(message.imagePath)
        .webp({ quality: 85 })
        .toFile(outputPath);
      
      parentPort.postMessage({
        type: 'PROCESS_COMPLETE',
        outputPath,
      });
    } catch (error) {
      parentPort.postMessage({
        type: 'PROCESS_ERROR',
        error: error.message,
      });
    }
  }
});
```

---

## 3. Packaging Configuration

### 3.1 electron-builder.yml

```yaml
appId: com.example.myapp
productName: MyApp
copyright: Copyright © 2024 Example Inc.

directories:
  output: dist
  buildResources: build

files:
  - "build/**/*"
  - "node_modules/**/*"
  - "package.json"
  - "!node_modules/**/*.map"
  - "!node_modules/**/*.d.ts"

mac:
  category: public.app-category.productivity
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
  target:
    - target: nsis
      arch: [x64, ia32]
  certificateFile: "C:\\certs\\ev-cert.p12"
  certificatePassword: "{{env.WIN_CERT_PASSWORD}}"
  signingHashAlgorithms: [sha256]

linux:
  target:
    - target: AppImage
      arch: [x64]
    - target: deb
      arch: [x64]
  category: Office

publish:
  provider: github
  owner: myorg
  repo: myapp
  releaseType: release
```

### 3.2 macOS Entitlements

```xml
<!-- build/entitlements.mac.plist -->
<?xml version="1.0" encoding="UTF-8"?>
<!DOCTYPE plist PUBLIC "-//Apple//DTD PLIST 1.0//EN" "http://www.apple.com/DTDs/PropertyList-1.0.dtd">
<plist version="1.0">
<dict>
    <!-- Required for Electron with hardened runtime -->
    <key>com.apple.security.cs.allow-jit</key>
    <true/>
    <key>com.apple.security.cs.allow-unsigned-executable-memory</key>
    <true/>
    <key>com.apple.security.cs.disable-library-validation</key>
    <true/>
    
    <!-- Network access -->
    <key>com.apple.security.network.client</key>
    <true/>
    <key>com.apple.security.network.server</key>
    <true/>
    
    <!-- File access (principle of least privilege) -->
    <key>com.apple.security.files.user-selected.read-write</key>
    <true/>
    
    <!-- Remove what you don't need -->
    <!-- <key>com.apple.security.device.camera</key><true/> -->
    <!-- <key>com.apple.security.device.microphone</key><true/> -->
</dict>
</plist>
```

---

## 4. Auto-Update with electron-updater

### 4.1 Main Process Setup

```javascript
// main.js
const { autoUpdater } = require('electron-updater');
const { dialog, ipcMain } = require('electron');

// Configure auto-updater
autoUpdater.autoDownload = false;
autoUpdater.autoInstallOnAppQuit = true;

// Check for updates
autoUpdater.checkForUpdatesAndNotify();

// Event handlers
autoUpdater.on('update-available', async (info) => {
  const result = await dialog.showMessageBox({
    type: 'info',
    title: 'Update Available',
    message: `MyApp ${info.version} is available`,
    detail: 'A new version is available. Do you want to download it now?',
    buttons: ['Download', 'Later'],
    defaultId: 0,
  });
  
  if (result.response === 0) {
    autoUpdater.downloadUpdate();
  }
});

autoUpdater.on('update-downloaded', () => {
  dialog.showMessageBox({
    type: 'info',
    title: 'Update Ready',
    message: 'Update downloaded. The application will restart to apply the update.',
    buttons: ['Restart Now', 'Later'],
  }).then((result) => {
    if (result.response === 0) {
      autoUpdater.quitAndInstall();
    }
  });
});

autoUpdater.on('error', (error) => {
  console.error('Auto-update error:', error);
  dialog.showErrorBox('Update Error', 'Failed to check for updates.');
});

// IPC for manual check
ipcMain.handle('app:checkForUpdates', () => {
  return autoUpdater.checkForUpdates();
});
```

### 4.2 Update Verification

```yaml
# latest.yml (generated by electron-builder)
version: 1.2.3
files:
  - url: MyApp-1.2.3.dmg
    sha512: abc123...def456
    size: 52428800
  - url: MyApp-1.2.3-mac.zip
    sha512: xyz789...uvw012
    size: 49807360
path: MyApp-1.2.3.dmg
sha512: abc123...def456
releaseDate: '2024-01-15T10:30:00.000Z'
```

---

## 5. System API Integration

### 5.1 Tray Icon

```javascript
// main.js
const { Tray, Menu, nativeImage } = require('electron');

let tray = null;

function createTray() {
  // Platform-specific icon
  const iconName = process.platform === 'darwin' 
    ? 'iconTemplate.png'  // Template icon for macOS dark mode
    : process.platform === 'win32'
    ? 'icon.ico'
    : 'icon.png';
  
  const icon = nativeImage.createFromPath(path.join(__dirname, 'assets', iconName));
  
  // macOS: template image for dark mode support
  if (process.platform === 'darwin') {
    icon.setTemplateImage(true);
  }
  
  tray = new Tray(icon);
  
  const contextMenu = Menu.buildFromTemplate([
    { label: 'Show App', click: () => mainWindow.show() },
    { label: 'Settings', click: () => openSettings() },
    { type: 'separator' },
    { label: 'Quit', click: () => app.quit() },
  ]);
  
  tray.setContextMenu(contextMenu);
  tray.setToolTip('MyApp');
  
  // macOS: click to show window
  tray.on('click', () => {
    mainWindow.show();
  });
}
```

### 5.2 Global Shortcuts

```javascript
// main.js
const { globalShortcut } = require('electron');

function registerGlobalShortcuts() {
  // Register shortcut
  const ret = globalShortcut.register('CommandOrControl+Shift+M', () => {
    if (mainWindow.isVisible()) {
      mainWindow.hide();
    } else {
      mainWindow.show();
    }
  });
  
  if (!ret) {
    console.log('Global shortcut registration failed');
  }
}

app.on('will-quit', () => {
  // Unregister all shortcuts
  globalShortcut.unregisterAll();
});
```

### 5.3 Deep Links

```javascript
// main.js
const { app } = require('electron');

// Protocol registration
if (process.defaultApp) {
  if (process.argv.length >= 2) {
    app.setAsDefaultProtocolClient('myapp', process.execPath, [path.resolve(process.argv[1])]);
  }
} else {
  app.setAsDefaultProtocolClient('myapp');
}

// Handle deep links
app.on('open-url', (event, url) => {
  event.preventDefault();
  handleDeepLink(url);
});

// Windows/Linux: handle protocol activation
const gotTheLock = app.requestSingleInstanceLock();

if (!gotTheLock) {
  app.quit();
} else {
  app.on('second-instance', (event, commandLine) => {
    // Someone tried to run a second instance
    if (mainWindow) {
      if (mainWindow.isMinimized()) mainWindow.restore();
      mainWindow.focus();
    }
    
    // Handle deep link from second instance
    const url = commandLine.find(arg => arg.startsWith('myapp://'));
    if (url) {
      handleDeepLink(url);
    }
  });
}

function handleDeepLink(url) {
  const parsed = new URL(url);
  
  switch (parsed.pathname) {
    case '/open':
      const taskId = parsed.searchParams.get('task');
      mainWindow.webContents.send('deep-link:open-task', taskId);
      break;
    case '/settings':
      openSettings();
      break;
  }
}
```

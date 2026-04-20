# Domain: Tauri and Qt Deep Expertise

## 1. Tauri Architecture

### 1.1 Project Structure

```
my-tauri-app/
├── src/                          # Web frontend (React/Vue/Svelte)
│   ├── App.tsx
│   └── main.tsx
├── src-tauri/                    # Rust backend
│   ├── Cargo.toml
│   ├── tauri.conf.json
│   ├── capabilities/
│   │   └── main.json
│   ├── icons/
│   └── src/
│       ├── main.rs
│       ├── lib.rs
│       └── commands/
│           ├── file.rs
│           └── system.rs
└── package.json
```

### 1.2 tauri.conf.json

```json
{
  "productName": "MyApp",
  "version": "1.0.0",
  "identifier": "com.example.myapp",
  "build": {
    "frontendDist": "../dist",
    "devUrl": "http://localhost:5173",
    "beforeDevCommand": "npm run dev",
    "beforeBuildCommand": "npm run build"
  },
  "app": {
    "windows": [
      {
        "title": "MyApp",
        "width": 1200,
        "height": 800,
        "resizable": true,
        "fullscreen": false
      }
    ],
    "security": {
      "csp": "default-src 'self'; script-src 'self'; style-src 'self' 'unsafe-inline'"
    }
  },
  "bundle": {
    "active": true,
    "targets": ["dmg", "msi", "appimage"],
    "icon": [
      "icons/32x32.png",
      "icons/128x128.png",
      "icons/icon.icns",
      "icons/icon.ico"
    ],
    "macOS": {
      "frameworks": [],
      "minimumSystemVersion": "10.13",
      "signingIdentity": "Developer ID Application: Example Inc (XXXXXXXXXX)",
      "entitlements": " entitlements.plist"
    },
    "windows": {
      "certificateThumbprint": "ABCDEF1234567890",
      "digestAlgorithm": "sha256",
      "timestampUrl": "http://timestamp.digicert.com"
    }
  },
  "plugins": {
    "updater": {
      "active": true,
      "endpoints": [
        "https://releases.example.com/{{target}}/{{arch}}/{{current_version}}"
      ],
      "dialog": true,
      "pubkey": "dW50cnVzdGVkIGNvbW1lbnQ6..."
    }
  }
}
```

### 1.3 ACL Capabilities (Security)

```json
// src-tauri/capabilities/main.json
{
  "identifier": "main-capability",
  "description": "Main app capabilities",
  "windows": ["main"],
  "permissions": [
    "core:default",
    "fs:allow-read-file",
    "fs:allow-write-file",
    {
      "identifier": "fs:scope",
      "allow": [
        { "path": "$APPDATA/*" },
        { "path": "$APPDATA/config.json" }
      ]
    },
    "dialog:allow-open",
    "dialog:allow-save",
    "notification:default",
    "shell:allow-open"
  ]
}
```

### 1.4 Rust Commands

```rust
// src-tauri/src/commands/file.rs
use tauri::command;
use std::fs;
use std::path::PathBuf;
use serde::{Deserialize, Serialize};

#[derive(Serialize)]
pub struct ConfigData {
    pub theme: String,
    pub language: String,
}

#[derive(Deserialize)]
pub struct SaveConfigRequest {
    pub theme: String,
    pub language: String,
}

/// Load configuration from app data directory
/// 
/// Safety: Path is constructed using app_handle.path_resolver()
/// which returns a safe, sandboxed directory.
#[command]
pub fn load_config(app_handle: tauri::AppHandle) -> Result<ConfigData, String> {
    let app_dir = app_handle
        .path()
        .app_data_dir()
        .map_err(|e| format!("Failed to get app dir: {}", e))?;
    
    let config_path = app_dir.join("config.json");
    
    match fs::read_to_string(&config_path) {
        Ok(content) => {
            serde_json::from_str(&content)
                .map_err(|e| format!("Invalid config format: {}", e))
        }
        Err(e) if e.kind() == std::io::ErrorKind::NotFound => {
            // Return default config
            Ok(ConfigData {
                theme: "light".to_string(),
                language: "en".to_string(),
            })
        }
        Err(e) => Err(format!("Failed to read config: {}", e)),
    }
}

#[command]
pub fn save_config(
    app_handle: tauri::AppHandle,
    request: SaveConfigRequest,
) -> Result<(), String> {
    // Validate input
    if request.theme != "light" && request.theme != "dark" {
        return Err("Invalid theme".to_string());
    }
    
    let app_dir = app_handle
        .path()
        .app_data_dir()
        .map_err(|e| format!("Failed to get app dir: {}", e))?;
    
    let config_path = app_dir.join("config.json");
    
    let config = serde_json::json!({
        "theme": request.theme,
        "language": request.language,
    });
    
    fs::create_dir_all(&app_dir)
        .map_err(|e| format!("Failed to create dir: {}", e))?;
    
    fs::write(&config_path, config.to_string())
        .map_err(|e| format!("Failed to write config: {}", e))?;
    
    Ok(())
}
```

### 1.5 Frontend Invocation

```typescript
// src/lib/tauri.ts
import { invoke } from '@tauri-apps/api/core';
import { open, save } from '@tauri-apps/plugin-dialog';

export async function loadConfig() {
  return invoke<ConfigData>('load_config');
}

export async function saveConfig(theme: string, language: string) {
  return invoke<void>('save_config', { 
    request: { theme, language } 
  });
}

export async function openFileDialog() {
  const selected = await open({
    multiple: false,
    filters: [
      { name: 'JSON', extensions: ['json'] },
      { name: 'All Files', extensions: ['*'] },
    ],
  });
  return selected;
}
```

### 1.6 Auto-Update with Minisign

```rust
// src-tauri/src/main.rs
use tauri::Manager;

fn main() {
    tauri::Builder::default()
        .plugin(tauri_plugin_updater::Builder::new().build())
        .setup(|app| {
            let handle = app.handle().clone();
            
            tauri::async_runtime::spawn(async move {
                match handle.updater().check().await {
                    Ok(Some(update)) => {
                        println!("Update available: {}", update.version);
                        
                        // Download and install
                        match update.download_and_install().await {
                            Ok(_) => println!("Update installed successfully"),
                            Err(e) => eprintln!("Update failed: {}", e),
                        }
                    }
                    Ok(None) => println!("No updates available"),
                    Err(e) => eprintln!("Update check failed: {}", e),
                }
            });
            
            Ok(())
        })
        .run(tauri::generate_context!())
        .expect("error while running tauri application");
}
```

**Minisign key generation**:
```bash
# Generate key pair
minisign -G

# Sign update file
minisign -Sm MyApp-1.2.3.dmg

# Output: MyApp-1.2.3.dmg.minisig
# Public key: embedded in tauri.conf.json
```

---

## 2. Qt Architecture

### 2.1 Project Structure

```
my-qt-app/
├── CMakeLists.txt
├── src/
│   ├── main.cpp
│   ├── mainwindow.cpp
│   ├── mainwindow.h
│   ├── mainwindow.ui
│   ├── models/
│   │   ├── taskmodel.cpp
│   │   └── taskmodel.h
│   └── services/
│       ├── apiservice.cpp
│       └── apiservice.h
├── resources/
│   ├── icons/
│   └── styles/
└── tests/
```

### 2.2 CMakeLists.txt

```cmake
cmake_minimum_required(VERSION 3.16)
project(MyQtApp VERSION 1.0.0 LANGUAGES CXX)

set(CMAKE_CXX_STANDARD 17)
set(CMAKE_CXX_STANDARD_REQUIRED ON)
set(CMAKE_AUTOMOC ON)
set(CMAKE_AUTORCC ON)
set(CMAKE_AUTOUIC ON)

find_package(Qt6 REQUIRED COMPONENTS 
    Core 
    Gui 
    Widgets 
    Network
)

add_executable(${PROJECT_NAME}
    src/main.cpp
    src/mainwindow.cpp
    src/mainwindow.h
    src/mainwindow.ui
    src/models/taskmodel.cpp
    src/models/taskmodel.h
    src/services/apiservice.cpp
    src/services/apiservice.h
    resources/resources.qrc
)

target_link_libraries(${PROJECT_NAME} PRIVATE
    Qt6::Core
    Qt6::Gui
    Qt6::Widgets
    Qt6::Network
)

# Platform-specific settings
if(APPLE)
    set_target_properties(${PROJECT_NAME} PROPERTIES
        MACOSX_BUNDLE TRUE
        MACOSX_BUNDLE_INFO_PLIST ${CMAKE_SOURCE_DIR}/Info.plist.in
    )
elseif(WIN32)
    set_target_properties(${PROJECT_NAME} PROPERTIES
        WIN32_EXECUTABLE TRUE
    )
endif()
```

### 2.3 Main Window with Threading

```cpp
// src/mainwindow.h
#ifndef MAINWINDOW_H
#define MAINWINDOW_H

#include <QMainWindow>
#include <QThreadPool>
#include <QSystemTrayIcon>

QT_BEGIN_NAMESPACE
namespace Ui { class MainWindow; }
QT_END_NAMESPACE

class MainWindow : public QMainWindow {
    Q_OBJECT

public:
    explicit MainWindow(QWidget *parent = nullptr);
    ~MainWindow();

private slots:
    void on_actionSettings_triggered();
    void on_trayIcon_activated(QSystemTrayIcon::ActivationReason reason);
    void handleApiResponse(const QString &data);
    void handleApiError(const QString &error);

private:
    void setupTrayIcon();
    void setupGlobalShortcuts();
    void fetchDataAsync();
    
    Ui::MainWindow *ui;
    QSystemTrayIcon *trayIcon;
    QThreadPool *threadPool;
};

#endif // MAINWINDOW_H
```

```cpp
// src/mainwindow.cpp
#include "mainwindow.h"
#include "ui_mainwindow.h"
#include "services/apiservice.h"
#include <QMessageBox>
#include <QCloseEvent>
#include <QShortcut>

MainWindow::MainWindow(QWidget *parent)
    : QMainWindow(parent)
    , ui(new Ui::MainWindow)
    , threadPool(new QThreadPool(this))
{
    ui->setupUi(this);
    
    setupTrayIcon();
    setupGlobalShortcuts();
    
    // Connect API service signals
    auto *apiService = new ApiService(this);
    connect(apiService, &ApiService::dataReceived, 
            this, &MainWindow::handleApiResponse);
    connect(apiService, &ApiService::errorOccurred, 
            this, &MainWindow::handleApiError);
}

MainWindow::~MainWindow() {
    delete ui;
}

void MainWindow::setupTrayIcon() {
    trayIcon = new QSystemTrayIcon(this);
    
    // Platform-specific icon
#ifdef Q_OS_MACOS
    trayIcon->setIcon(QIcon(":/icons/iconTemplate.png"));
#elif defined(Q_OS_WIN)
    trayIcon->setIcon(QIcon(":/icons/icon.ico"));
#else
    trayIcon->setIcon(QIcon(":/icons/icon.png"));
#endif
    
    auto *menu = new QMenu(this);
    menu->addAction(tr("Show"), this, &MainWindow::show);
    menu->addAction(tr("Settings"), this, &MainWindow::on_actionSettings_triggered);
    menu->addSeparator();
    menu->addAction(tr("Quit"), qApp, &QApplication::quit);
    
    trayIcon->setContextMenu(menu);
    trayIcon->show();
    
    connect(trayIcon, &QSystemTrayIcon::activated,
            this, &MainWindow::on_trayIcon_activated);
}

void MainWindow::setupGlobalShortcuts() {
    // Ctrl+Shift+M to toggle window visibility
    auto *shortcut = new QShortcut(
        QKeySequence("Ctrl+Shift+M"), 
        this
    );
    connect(shortcut, &QShortcut::activated, [this]() {
        isVisible() ? hide() : show();
    });
}

void MainWindow::fetchDataAsync() {
    // Run API call in thread pool
    auto *task = new ApiTask("https://api.example.com/data");
    connect(task, &ApiTask::resultReady, 
            this, &MainWindow::handleApiResponse);
    threadPool->start(task);
}

void MainWindow::handleApiResponse(const QString &data) {
    ui->statusBar->showMessage(tr("Data loaded successfully"));
    // Update UI with data
}

void MainWindow::handleApiError(const QString &error) {
    QMessageBox::warning(this, tr("Error"), error);
}

void MainWindow::closeEvent(QCloseEvent *event) {
#ifdef Q_OS_MACOS
    // macOS: hide instead of close
    hide();
    event->ignore();
#else
    // Windows/Linux: minimize to tray
    if (trayIcon->isVisible()) {
        hide();
        event->ignore();
    }
#endif
}
```

### 2.4 Thread-Safe Worker

```cpp
// src/services/apiservice.h
#ifndef APISERVICE_H
#define APISERVICE_H

#include <QObject>
#include <QRunnable>
#include <QNetworkAccessManager>
#include <QNetworkReply>

class ApiService : public QObject {
    Q_OBJECT

public:
    explicit ApiService(QObject *parent = nullptr);
    void fetchData(const QString &url);

signals:
    void dataReceived(const QString &data);
    void errorOccurred(const QString &error);

private slots:
    void onReplyFinished(QNetworkReply *reply);

private:
    QNetworkAccessManager *networkManager;
};

// QRunnable for thread pool execution
class ApiTask : public QObject, public QRunnable {
    Q_OBJECT

public:
    explicit ApiTask(const QString &url);
    void run() override;

signals:
    void resultReady(const QString &result);
    void errorOccurred(const QString &error);

private:
    QString m_url;
};

#endif // APISERVICE_H
```

```cpp
// src/services/apiservice.cpp
#include "apiservice.h"
#include <QJsonDocument>
#include <QJsonObject>
#include <QEventLoop>

ApiService::ApiService(QObject *parent)
    : QObject(parent)
    , networkManager(new QNetworkAccessManager(this))
{
}

void ApiService::fetchData(const QString &url) {
    QNetworkRequest request(url);
    request.setHeader(QNetworkRequest::ContentTypeHeader, "application/json");
    
    QNetworkReply *reply = networkManager->get(request);
    connect(reply, &QNetworkReply::finished, [this, reply]() {
        onReplyFinished(reply);
    });
}

void ApiService::onReplyFinished(QNetworkReply *reply) {
    if (reply->error() == QNetworkReply::NoError) {
        QByteArray data = reply->readAll();
        emit dataReceived(QString::fromUtf8(data));
    } else {
        emit errorOccurred(reply->errorString());
    }
    reply->deleteLater();
}

ApiTask::ApiTask(const QString &url)
    : m_url(url)
{
    // Auto-delete when finished
    setAutoDelete(true);
}

void ApiTask::run() {
    QNetworkAccessManager manager;
    QNetworkRequest request(m_url);
    
    QNetworkReply *reply = manager.get(request);
    
    // Use event loop for synchronous execution in thread
    QEventLoop loop;
    connect(reply, &QNetworkReply::finished, &loop, &QEventLoop::quit);
    loop.exec();
    
    if (reply->error() == QNetworkReply::NoError) {
        emit resultReady(QString::fromUtf8(reply->readAll()));
    } else {
        emit errorOccurred(reply->errorString());
    }
    
    reply->deleteLater();
}
```

---

## 3. Code Signing Commands

### 3.1 macOS Signing and Notarization

```bash
# 1. Sign the app bundle
codesign --force --deep --sign "Developer ID Application: Example Inc (TEAM_ID)" \
  --entitlements build/entitlements.mac.plist \
  --options runtime \
  dist/mac/MyApp.app

# 2. Create DMG
create-dmg \
  --volname "MyApp Installer" \
  --window-pos 200 120 \
  --window-size 800 400 \
  --icon-size 100 \
  --app-drop-link 600 185 \
  "dist/MyApp-1.0.0.dmg" \
  "dist/mac/MyApp.app"

# 3. Notarize (notarytool)
xcrun notarytool submit "dist/MyApp-1.0.0.dmg" \
  --apple-id "developer@example.com" \
  --password "@keychain:AC_PASSWORD" \
  --team-id "XXXXXXXXXX" \
  --wait

# 4. Staple the notarization ticket
xcrun stapler staple "dist/MyApp-1.0.0.dmg"

# 5. Verify
spctl -a -t install "dist/MyApp-1.0.0.dmg"
codesign --verify --verbose "dist/mac/MyApp.app"
```

### 3.2 Windows Signing

```powershell
# Sign with EV certificate (hardware token)
signtool sign `
  /tr http://timestamp.digicert.com `
  /td sha256 `
  /fd sha256 `
  /f "C:\certs\ev-cert.pfx" `
  /p "cert-password" `
  "dist\MyApp-Setup-1.0.0.exe"

# Sign with Azure Key Vault
signtool sign `
  /tr http://timestamp.digicert.com `
  /td sha256 `
  /fd sha256 `
  /kv `
  /kvc my-key-vault `
  /kvi my-key-id `
  "dist\MyApp-Setup-1.0.0.exe"

# Verify signature
signtool verify /pa /v "dist\MyApp-Setup-1.0.0.exe"
```

### 3.3 Linux AppImage Signing

```bash
# Generate GPG key (if not exists)
gpg --full-generate-key

# Sign AppImage
gpg --armor --detach-sign "dist/MyApp-1.0.0.AppImage"

# Verify signature
gpg --verify "dist/MyApp-1.0.0.AppImage.asc" "dist/MyApp-1.0.0.AppImage"
```

---

## 4. Framework Selection Matrix

| Criterion | Electron | Tauri | Qt |
|-----------|----------|-------|-----|
| Language | JavaScript/TypeScript | Rust + JavaScript | C++ or QML |
| Bundle size | 80–150 MB | 5–15 MB | 10–30 MB |
| Memory footprint | High (Chromium) | Low | Medium |
| Web tech integration | Excellent | Excellent | Poor |
| Native feel | Medium | Medium | Excellent |
| Security model | contextBridge IPC | Rust ACL | Native |
| Code signing | Standard | Standard | Standard |
| Auto-update | electron-updater | tauri-plugin-updater | Custom/Qt IFW |
| Learning curve | Low | Medium | High |
| Ecosystem | Very large | Growing | Very large |

**Choose Electron when**: team has web frontend expertise, development speed matters, bundle size acceptable.
**Choose Tauri when**: bundle size and memory are critical, Rust expertise available, security is paramount.
**Choose Qt when**: native look-and-feel required, C++ team, heavy use of platform APIs.

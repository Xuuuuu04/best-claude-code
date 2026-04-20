# HarmonyOS Domain — Distributed Capabilities and Atomic Services

## 1. Distributed Data (KVStore)

### 1.1 KVStore Sync Strategy

```typescript
import distributedData from '@ohos.data.distributedKVStore'

class DistributedNoteManager {
  private kvManager: distributedData.KVManager | null = null
  private kvStore: distributedData.SingleKVStore | null = null

  async initialize(context: Context) {
    const config: distributedData.KVManagerConfig = {
      bundleName: 'com.example.notes',
      context: context
    }
    this.kvManager = distributedData.createKVManager(config)
  }

  async openStore(storeId: string): Promise<void> {
    if (!this.kvManager) return

    const options: distributedData.Options = {
      createIfMissing: true,
      encrypt: false,
      backup: false,
      autoSync: true,
      kvStoreType: distributedData.KVStoreType.SINGLE_VERSION,
      securityLevel: distributedData.SecurityLevel.S1
    }

    this.kvStore = await this.kvManager.getKVStore(storeId, options)
  }

  async saveNote(note: Note): Promise<void> {
    if (!this.kvStore) return
    await this.kvStore.put(note.id, JSON.stringify(note))
  }

  async getNote(noteId: string): Promise<Note | null> {
    if (!this.kvStore) return null
    const data = await this.kvStore.get(noteId)
    return data ? JSON.parse(data as string) : null
  }

  async syncDevices(): Promise<void> {
    if (!this.kvStore) return

    // Sync with all trusted devices
    const devices = deviceManager.getTrustedDeviceListSync()
    const deviceIds = devices.map(d => d.deviceId)

    if (deviceIds.length > 0) {
      this.kvStore.sync(deviceIds, distributedData.SyncMode.PUSH_PULL)
    }
  }

  subscribeChanges(callback: (key: string, value: string) => void) {
    this.kvStore?.on('dataChange', distributedData.SubscribeType.SUBSCRIBE_TYPE_ALL, (data) => {
      data.insertEntries.forEach((entry) => {
        callback(entry.key as string, entry.value as string)
      })
    })
  }
}
```

### 1.2 Single-Device Fallback Pattern

```typescript
async function saveNoteWithFallback(note: Note): Promise<void> {
  // 1. Always save locally first
  const localPrefs = await preferences.getPreferences(context, 'local-notes')
  await localPrefs.put(note.id, JSON.stringify(note))
  await localPrefs.flush()

  // 2. Attempt distributed sync if available
  const devices = deviceManager.getTrustedDeviceListSync()
  if (devices.length > 0) {
    try {
      const distManager = new DistributedNoteManager()
      await distManager.initialize(context)
      await distManager.openStore('notes-store')
      await distManager.saveNote(note)
      console.info('Distributed sync successful')
    } catch (e) {
      // Non-fatal — local save already done
      console.warn('Distributed sync skipped:', (e as BusinessError).code)
    }
  }
}
```

---

## 2. Task Continuation (Cross-Device Migration)

### 2.1 onContinue and onNewWant

```typescript
// ets/entryability/NoteEntryAbility.ets
import UIAbility from '@ohos.app.ability.UIAbility'
import { BusinessError } from '@ohos.base'

export default class NoteEntryAbility extends UIAbility {
  onContinue(wantParam: Record<string, Object>): AbilityConstant.OnContinueResult {
    // Serialize state for continuation
    const currentNoteId = AppStorage.get<string>('currentNoteId') ?? ''
    const scrollPosition = AppStorage.get<number>('scrollPosition') ?? 0

    wantParam['noteId'] = currentNoteId
    wantParam['scrollPosition'] = scrollPosition

    console.info('Continuing note:', currentNoteId)
    return AbilityConstant.OnContinueResult.AGREE
  }

  onWindowStageCreate(windowStage: window.WindowStage): void {
    windowStage.loadContent('pages/NoteDetail')
  }
}
```

```typescript
// ets/entryability/NoteRestoreAbility.ets
export default class NoteRestoreAbility extends UIAbility {
  onNewWant(want: Want, launchParam: AbilityConstant.LaunchParam): void {
    // Deserialize state from continuation
    const noteId = want.parameters?.['noteId'] as string ?? ''
    const scrollPosition = want.parameters?.['scrollPosition'] as number ?? 0

    // Restore state in AppStorage
    AppStorage.setOrCreate('currentNoteId', noteId)
    AppStorage.setOrCreate('scrollPosition', scrollPosition)

    console.info('Restored note:', noteId, 'at position:', scrollPosition)
  }
}
```

---

## 3. Device Management

```typescript
import deviceManager from '@ohos.distributedDeviceManager'

class DevicePairingManager {
  private deviceManager: deviceManager.DeviceManager | null = null

  async initialize(context: Context): Promise<void> {
    this.deviceManager = deviceManager.createDeviceManager('com.example.app')
  }

  getTrustedDevices(): deviceManager.DeviceBasicInfo[] {
    return this.deviceManager?.getTrustedDeviceListSync() ?? []
  }

  async startDeviceDiscovery(): Promise<void> {
    this.deviceManager?.startDiscovering({
      filterOps: undefined,
      subscribeId: 12345
    })
  }

  async authenticateDevice(deviceId: string): Promise<void> {
    this.deviceManager?.authenticateDevice(deviceId, {
      authType: deviceManager.AuthType.PIN,
      authCallback: {
        onAuthResult: (deviceId: string, pinToken: number) => {
          console.info('Auth result:', deviceId, pinToken)
        }
      }
    })
  }

  onDeviceStateChange(callback: (state: deviceManager.DeviceStateChange) => void) {
    this.deviceManager?.on('deviceStateChange', callback)
  }
}
```

---

## 4. Atomic Service Development

### 4.1 Atomic Service Module Setup

```json
// atomic-service/module.json5
{
  "module": {
    "name": "atomic_service",
    "type": "atomicService",
    "description": "$string:atomic_service_desc",
    "mainElement": "EntryAbility",
    "abilities": [
      {
        "name": "EntryAbility",
        "srcEntry": "./ets/entryability/EntryAbility.ets",
        "launchType": "singleton"
      }
    ],
    "extensionAbilities": [
      {
        "name": "FormExtension",
        "srcEntry": "./ets/formextension/FormExtension.ets",
        "type": "form"
      }
    ]
  }
}
```

### 4.2 Service Card (FormExtensionAbility)

```typescript
// ets/formextension/FormExtension.ets
import FormExtensionAbility from '@ohos.app.form.FormExtensionAbility'
import formBindingData from '@ohos.app.form.formBindingData'

export default class NoteFormExtension extends FormExtensionAbility {
  onCreate(want: Want): formBindingData.FormBindingData {
    const formId = want.parameters?.['ohos.extra.param.key.form_identity'] as string
    const noteData = this.fetchLatestNote()

    return formBindingData.createFormBindingData({
      title: noteData.title,
      preview: noteData.content.substring(0, 50),
      updatedAt: new Date().toLocaleString()
    })
  }

  onUpdate(formId: string): void {
    const noteData = this.fetchLatestNote()
    const formData = formBindingData.createFormBindingData({
      title: noteData.title,
      preview: noteData.content.substring(0, 50)
    })
    this.updateForm(formId, formData)
  }

  private fetchLatestNote(): { title: string, content: string } {
    // Fetch from local storage
    return { title: 'My Note', content: 'Note content...' }
  }
}
```

### 4.3 Size Budget Monitoring

```bash
# Build and analyze size
hvigorw assembleHap --analyze-size

# Expected output:
# Total HAP size: 8.4 MB
# - Compiled ABC: 3.2 MB
# - Resources: 2.8 MB
# - Native libs: 1.5 MB
# - Other: 0.9 MB
#
# Status: PASS (< 10 MB hard limit, < 8 MB soft limit — AT RISK)
```

```typescript
// Size optimization techniques
@Component
struct OptimizedList {
  @State items: Item[] = []

  build() {
    List() {
      LazyForEach(this.dataSource, (item: Item) => {
        ListItem() {
          ItemCard({ item: item })
        }
      }, (item: Item) => item.id)
    }
    .cachedCount(3) // Limit cached items
    .recycle(true) // Enable recycling
  }
}

@Reusable
@Component
struct ItemCard {
  @ObjectLink item: Item

  // Lightweight component for atomic service
  build() {
    Row() {
      Text(this.item.name)
        .fontSize(14)
        .maxLines(1)
    }
    .height(48)
  }
}
```

---

## 5. DevEco Studio and Release

### 5.1 Signing Configuration

```json
// build-profile.json5
{
  "app": {
    "signingConfigs": [
      {
        "name": "default",
        "type": "HarmonyOS",
        "material": {
          "certpath": "/path/to/app.cer",
          "storePassword": "******",
          "keyAlias": "app_key",
          "keyPassword": "******",
          "profile": "/path/to/app.p7b",
          "signAlg": "SHA256withECDSA",
          "storeFile": "/path/to/app.p12"
        }
      }
    ]
  }
}
```

### 5.2 AppGallery Connect Submission

```
Pre-Submission Checklist:
□ AppGallery Connect project created
□ agconnect-services.json downloaded and placed in entry/
□ Signing certificate generated (AppGallery Connect or local)
□ build-profile.json5 signing config populated
□ Privacy manifest (隐私声明) URL accessible
□ ICP 备案 completed (if mainland China service)
□ HMS IAP configured (if in-app purchases)
□ App icon (1024x1024) uploaded
□ Screenshots for phone/tablet uploaded
□ App description and keywords in Chinese
□ Content rating questionnaire completed
□ Atomic service size < 10 MB (if applicable)
```

### 5.3 Hypium Unit Testing

```typescript
// ets/test/NoteManagerTest.ets
import { describe, beforeAll, beforeEach, afterEach, afterAll, it, expect } from '@ohos/hypium'
import { NoteManager } from '../manager/NoteManager'

export default function noteManagerTest() {
  describe('NoteManagerTest', () => {
    let noteManager: NoteManager

    beforeAll(() => {
      noteManager = new NoteManager()
    })

    it('should_create_note', 0, () => {
      const note = noteManager.createNote('Test Title', 'Test Content')
      expect(note.title).assertEqual('Test Title')
      expect(note.content).assertEqual('Test Content')
    })

    it('should_save_and_retrieve_note', 0, async () => {
      const note = noteManager.createNote('Saved Note', 'Content')
      await noteManager.saveNote(note)
      const retrieved = await noteManager.getNote(note.id)
      expect(retrieved?.title).assertEqual('Saved Note')
    })

    it('should_delete_note', 0, async () => {
      const note = noteManager.createNote('To Delete', 'Content')
      await noteManager.saveNote(note)
      await noteManager.deleteNote(note.id)
      const retrieved = await noteManager.getNote(note.id)
      expect(retrieved).assertNull()
    })
  })
}
```

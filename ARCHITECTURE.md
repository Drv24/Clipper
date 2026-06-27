```
┌──────────────────────────────────────────────────────────────────────────────────┐
│                              macOS System                                        │
│                                                                                  │
│   ┌─────────────┐    copies text     ┌──────────────────────────────────────┐    │
│   │  Any App    │ ─────────────────► │         NSPasteboard (system)        │    │
│   │  (browser,  │                    │   changeCount: Int  |  string data   │    │
│   │   editor…)  │                    └──────────────┬───────────────────────┘    │
│   └─────────────┘                                   │ read every 0.5s            │
│                                                     │                            │
│   ┌─────────────────────────────────────────────────▼────────────────────────┐   │
│   │                        Clipper.app                                       │   │
│   │                                                                          │   │
│   │  ┌──────────────────────────────────────────────────────────────────┐    │   │
│   │  │                      ClipperApp  (@main)                         │    │   │
│   │  │                                                                  │    │   │
│   │  │   MenuBarExtra ──► menubar icon  [📋]                            │    │   │
│   │  │   .menuBarExtraStyle(.window)                                    │    │   │
│   │  └────────────────────────────┬─────────────────────────────────────┘    │   │
│   │                               │ owns (@StateObject)                      │   │
│   │                               ▼                                          │   │
│   │  ┌─────────────────────────────────────────────────────────────────────┐ │   │
│   │  │               ClipboardMonitor  (@MainActor ObservableObject)       │ │   │
│   │  │                                                                     │ │   │
│   │  │  Timer (0.5s) ──► pollPasteboard()                                  │ │   │
│   │  │                        │                                            │ │   │
│   │  │                        ├─ changeCount unchanged → return (no-op)    │ │   │
│   │  │                        │                                            │ │   │
│   │  │                        └─ changeCount changed                       │ │   │
│   │  │                              │                                      │ │   │
│   │  │                              ├─ read string from NSPasteboard       │ │   │
│   │  │                              ├─ dedup (remove old copy)             │ │   │
│   │  │                              ├─ insert new ClipboardItem at [0]     │ │   │
│   │  │                              ├─ enforce 50-item unpinned cap        │ │   │
│   │  │                              └─ saveHistory() ──► UserDefaults      │ │   │
│   │  │                                                                     │ │   │
│   │  │  @Published var items: [ClipboardItem]                              │ │   │
│   │  │       │                                                             │ │   │
│   │  │       └─ orderedItems: pinned (newest first) + unpinned (newest)    │ │   │
│   │  │                                                                     │ │   │
│   │  │  Actions:                                                           │ │   │
│   │  │    togglePin()    ──► flip isPinned, saveHistory()                  │ │   │
│   │  │    clearHistory() ──► remove all unpinned, saveHistory()            │ │   │
│   │  │    deleteItem()   ──► remove by id, saveHistory()                   │ │   │
│   │  │    paste()        ──► write to NSPasteboard                         │ │   │
│   │  │                       + CGEvent Cmd+V ──► frontmost app             │ │   │
│   │  └───────────────────────────┬─────────────────────────────────────────┘ │   │
│   │                              │  @EnvironmentObject                       │   │
│   │           ┌──────────────────┴──────────────────┐                        │   │
│   │           ▼                                     ▼                        │   │
│   │  ┌──────────────────────┐             ┌───────────────────────────────┐  │   │
│   │  │     PopupView        │             │         ClipboardItem         │  │   │
│   │  │  (360 × 440 pt)      │             │  (Codable, Identifiable)      │  │   │
│   │  │                      │             │                               │  │   │
│   │  │  Header              │             │  id:        UUID              │  │   │
│   │  │    "Clipper" label   │             │  text:      String            │  │   │
│   │  │    [Clear] button    │             │  isPinned:  Bool              │  │   │
│   │  │                      │             │  createdAt: Date              │  │   │
│   │  │  Accessibility       │             └───────────────────────────────┘  │   │
│   │  │  banner (if needed)  │                                                │   │
│   │  │                      │                                                │   │
│   │  │  ScrollView          │                                                │   │
│   │  │  └─ LazyVStack       │                                                │   │
│   │  │     └─ ForEach       │                                                │   │
│   │  │        └─ ItemRowView│                                                │   │
│   │  └──────────┬───────────┘                                                │   │
│   │             │                                                            │   │
│   │             ▼                                                            │   │
│   │  ┌──────────────────────────────────────────┐                            │   │
│   │  │              ItemRowView                 │                            │   │
│   │  │                                          │                            │   │
│   │  │  [text preview (60 chars)]  [pin]  [✕]   │                            │   │
│   │  │        │                      │     │    │                            │   │
│   │  │    paste()              togglePin() │    │                            │   │
│   │  │                                deleteItem()                           │   │
│   │  └──────────────────────────────────────────┘                            │   │
│   │                                                                          │   │
│   └──────────────────────────────────────────────────────────────────────────┘   │
│                                                                                  │
│   ┌───────────────────────────────────────────────────────────────────────────┐  │
│   │                         Persistence Layer                                 │  │
│   │                                                                           │  │
│   │   UserDefaults  ──►  ~/Library/Preferences/com.example.clipper.plist      │  │
│   │   key: "clipper.history"  |  value: JSON-encoded [ClipboardItem]          │  │
│   │                                                                           │  │
│   │   Written: on every copy / pin / delete / clear                           │  │
│   │   Read:    once at app launch (loadHistory)                               │  │
│   └───────────────────────────────────────────────────────────────────────────┘  │
│                                                                                  │
│   ┌───────────────────────────────────────────────────────────────────────────┐  │
│   │                      macOS Permissions Required                           │  │
│   │                                                                           │  │
│   │   Accessibility (TCC)  ──  required for CGEvent Cmd+V paste simulation    │  │
│   │   NSPasteboard         ──  always available, no permission needed         │  │
│   └───────────────────────────────────────────────────────────────────────────┘  │
└──────────────────────────────────────────────────────────────────────────────────┘


DATA FLOW SUMMARY
─────────────────────────────────────────────────────────────────────────────────

  COPY  :  Any App ──► NSPasteboard ──► ClipboardMonitor ──► items[] ──► UserDefaults
  PASTE :  User clicks item ──► NSPasteboard ──► CGEvent(Cmd+V) ──► Frontmost App
  LOAD  :  App launch ──► UserDefaults ──► JSON decode ──► items[]
  PIN   :  ItemRowView ──► togglePin() ──► items[].isPinned ──► UserDefaults
  CLEAR :  PopupView ──► clearHistory() ──► remove unpinned from items[] ──► UserDefaults


BUILD PIPELINE
─────────────────────────────────────────────────────────────────────────────────

  bash build.sh                   bash build.sh --universal
         │                                   │
         ▼                                   ▼
  swift build -c release       swift build -c release
  (native arch)                 --arch arm64 --arch x86_64
         │                                   │
         ▼                                   ▼
  .build/release/Clipper       .build/apple/Products/Release/Clipper
         │                         (fat binary, lipo-verified)
         └──────────────┬────────────────────┘
                        ▼
              dist/Clipper.app/
              └── Contents/
                  ├── MacOS/Clipper
                  └── Info.plist
                        │
                        ▼
              hdiutil create (HFS+ staging DMG)
                        │
                        ▼
              hdiutil attach → copy .app + /Applications symlink
                        │
                        ▼
              hdiutil detach
                        │
                        ▼
              hdiutil convert -format UDZO
                        │
                        ▼
              Clipper-1.0.0-[arch|universal].dmg  ✓
```

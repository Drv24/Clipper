# Clipper

A lightweight macOS menubar clipboard manager inspired by [Maccy](https://maccy.app). Stores your clipboard history, lets you pin frequently used items, and pastes with a single click.

![macOS 13+](https://img.shields.io/badge/macOS-13%2B-blue) ![Swift 5.9](https://img.shields.io/badge/Swift-5.9-orange) ![License MIT](https://img.shields.io/badge/license-MIT-green)

---

## Features

- **Clipboard history** — automatically captures everything you copy (up to 50 items)
- **Click to paste** — click any item to instantly paste it into the frontmost app
- **Pin items** — pin frequently used snippets so they stay at the top permanently
- **Clear history** — wipe all unpinned items in one click; pinned items are preserved
- **Persisted across restarts** — history survives app quits and reboots
- **No Dock icon** — lives entirely in the menubar, out of your way

---

## Requirements

| Requirement | Version |
|---|---|
| macOS | 13 Ventura or newer |
| Swift | 5.9+ |
| Xcode Command Line Tools | Any recent version |

To install Xcode Command Line Tools if you don't have them:
```bash
xcode-select --install
```

---

## Project Structure

```
clipper/
├── Package.swift                     Swift Package Manager manifest
├── Sources/Clipper/
│   ├── ClipperApp.swift              @main entry point, MenuBarExtra scene
│   ├── ClipboardMonitor.swift        Clipboard polling, history management, paste logic
│   ├── ClipboardItem.swift           Codable data model
│   ├── PopupView.swift               Main popup UI (360×440)
│   └── ItemRowView.swift             Individual history row (preview, pin, delete)
├── Resources/
│   └── Info.plist                    App bundle metadata (LSUIElement, bundle ID, etc.)
├── build.sh                          Build script → .app bundle → DMG
└── .gitignore
```

---

## Building

### Native build (matches your Mac's chip)

```bash
bash build.sh
```

Produces: `Clipper-1.0.0-arm64.dmg` (or `x86_64` on Intel Macs)

### Universal build (runs on both Apple Silicon and Intel)

```bash
bash build.sh --universal
```

Produces: `Clipper-1.0.0-universal.dmg`

### What the build script does

1. Runs `swift build -c release` (or with `--arch arm64 --arch x86_64` for universal)
2. Assembles `dist/Clipper.app` with the correct bundle structure:
   ```
   Clipper.app/
   └── Contents/
       ├── MacOS/Clipper       compiled binary
       └── Info.plist          bundle metadata
   ```
3. Creates a staging HFS+ disk image, copies the `.app` in, adds an `/Applications` symlink
4. Converts to a compressed read-only UDZO DMG via `hdiutil`

---

## Installation

1. **Open the DMG** — double-click the `.dmg` file
2. **Drag to Applications** — drag `Clipper.app` onto the `Applications` folder shortcut
3. **First launch** — because the app is unsigned, right-click `Clipper.app` in Finder → **Open** → click **Open** in the dialog (only needed once)
4. **Grant Accessibility permission** — the first time you click an item to paste, macOS will prompt you. Go to **System Settings → Privacy & Security → Accessibility** and enable Clipper

> The right-click → Open workaround is a one-time step to bypass macOS Gatekeeper for unsigned apps.

---

## Usage

| Action | How |
|---|---|
| Open clipboard history | Click the clipboard icon in the menubar |
| Paste an item | Click the item text |
| Pin / unpin an item | Click the pin icon on the right |
| Delete a single item | Click the × icon on the right |
| Clear all history | Click **Clear** in the header (keeps pinned items) |

---

## Architecture

See [ARCHITECTURE.md](ARCHITECTURE.md) for the full technical architecture diagram covering component relationships, data flows, and the build pipeline.

---

## How It Works

- **Clipboard monitoring** — a `Timer` fires every 0.5s and reads `NSPasteboard.changeCount`. If the count changed, it reads the new text. This is a single integer comparison at idle — negligible CPU usage.
- **Paste simulation** — writes the selected text back to `NSPasteboard`, then synthesises a `Cmd+V` keystroke via `CGEvent`, which is delivered to whatever app was focused before you opened the popup. Requires Accessibility permission.
- **Storage** — history is stored as JSON in `UserDefaults`, backed by `~/Library/Preferences/com.example.clipper.plist`. History survives restarts. Max 50 unpinned items; pinned items are exempt from the cap.

---

## Resource Usage

| Resource | Impact |
|---|---|
| CPU (idle) | < 0.1% |
| CPU (on copy event) | ~1% briefly |
| RAM | ~30–40 MB |
| Battery | Low |
| Network | None |
| Disk I/O | Only on copy/pin/delete events |

---

## Privacy

Clipboard history is stored **in plaintext** on your local machine at `~/Library/Preferences/com.example.clipper.plist`. No data ever leaves your Mac. If you copy sensitive information (passwords, tokens), use **Clear** to wipe the history or delete individual items with the × button.

---

## License

MIT

import AppKit
import ApplicationServices
import Foundation

@MainActor
final class ClipboardMonitor: ObservableObject {

    @Published private(set) var items: [ClipboardItem] = []

    var orderedItems: [ClipboardItem] {
        let pinned   = items.filter {  $0.isPinned }.sorted { $0.createdAt > $1.createdAt }
        let unpinned = items.filter { !$0.isPinned }.sorted { $0.createdAt > $1.createdAt }
        return pinned + unpinned
    }

    var isAccessibilityGranted: Bool {
        AXIsProcessTrusted()
    }

    private var timer: Timer?
    private var lastChangeCount: Int = NSPasteboard.general.changeCount
    private let maxUnpinned = 50
    private let userDefaultsKey = "clipper.history"

    init() {
        loadHistory()
        startTimer()
    }

    private func startTimer() {
        timer = Timer.scheduledTimer(withTimeInterval: 0.5, repeats: true) { [weak self] _ in
            MainActor.assumeIsolated {
                self?.pollPasteboard()
            }
        }
    }

    private func pollPasteboard() {
        let pb = NSPasteboard.general
        let current = pb.changeCount
        guard current != lastChangeCount else { return }
        lastChangeCount = current

        guard let text = pb.string(forType: .string),
              !text.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty else { return }

        items.removeAll { $0.text == text && !$0.isPinned }
        items.insert(ClipboardItem(text: text), at: 0)

        enforceCapacity()
        saveHistory()
    }

    private func enforceCapacity() {
        var unpinnedCount = items.filter { !$0.isPinned }.count
        while unpinnedCount > maxUnpinned {
            if let idx = items.lastIndex(where: { !$0.isPinned }) {
                items.remove(at: idx)
                unpinnedCount -= 1
            } else {
                break
            }
        }
    }

    func togglePin(_ item: ClipboardItem) {
        guard let idx = items.firstIndex(where: { $0.id == item.id }) else { return }
        items[idx].isPinned.toggle()
        saveHistory()
    }

    func clearHistory() {
        items.removeAll { !$0.isPinned }
        saveHistory()
    }

    func deleteItem(_ item: ClipboardItem) {
        items.removeAll { $0.id == item.id }
        saveHistory()
    }

    @discardableResult
    func paste(_ item: ClipboardItem) -> Bool {
        guard checkAccessibility() else { return false }

        let pb = NSPasteboard.general
        pb.clearContents()
        pb.setString(item.text, forType: .string)
        lastChangeCount = pb.changeCount

        let src = CGEventSource(stateID: .hidSystemState)
        // 0x09 = kVK_ANSI_V
        let keyDown = CGEvent(keyboardEventSource: src, virtualKey: 0x09, keyDown: true)!
        let keyUp   = CGEvent(keyboardEventSource: src, virtualKey: 0x09, keyDown: false)!
        keyDown.flags = .maskCommand
        keyUp.flags   = .maskCommand
        keyDown.post(tap: .cgAnnotatedSessionEventTap)
        keyUp.post(tap: .cgAnnotatedSessionEventTap)

        return true
    }

    @discardableResult
    func checkAccessibility() -> Bool {
        let options: CFDictionary = [kAXTrustedCheckOptionPrompt.takeUnretainedValue(): true] as CFDictionary
        return AXIsProcessTrustedWithOptions(options)
    }

    private func saveHistory() {
        guard let data = try? JSONEncoder().encode(items) else { return }
        UserDefaults.standard.set(data, forKey: userDefaultsKey)
    }

    private func loadHistory() {
        guard let data = UserDefaults.standard.data(forKey: userDefaultsKey),
              let decoded = try? JSONDecoder().decode([ClipboardItem].self, from: data) else { return }
        items = decoded
    }
}

import SwiftUI

@main
struct ClipperApp: App {
    @StateObject private var monitor = ClipboardMonitor()

    var body: some Scene {
        MenuBarExtra("Clipper", systemImage: "doc.on.clipboard") {
            PopupView()
                .environmentObject(monitor)
        }
        .menuBarExtraStyle(.window)
    }
}

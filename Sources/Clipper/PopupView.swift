import SwiftUI

struct PopupView: View {
    @EnvironmentObject private var monitor: ClipboardMonitor

    var body: some View {
        VStack(spacing: 0) {
            HStack {
                Text("Clipper")
                    .font(.headline)
                    .padding(.leading, 12)
                Spacer()
                Button("Clear") {
                    monitor.clearHistory()
                }
                .buttonStyle(.plain)
                .foregroundStyle(.secondary)
                .padding(.trailing, 12)
            }
            .padding(.vertical, 8)
            .background(Color(nsColor: .windowBackgroundColor))

            Divider()

            if monitor.items.isEmpty {
                VStack {
                    Spacer()
                    Text("No clipboard history")
                        .foregroundStyle(.secondary)
                    Spacer()
                }
                .frame(height: 120)
            } else {
                if !monitor.isAccessibilityGranted {
                    HStack(spacing: 6) {
                        Image(systemName: "exclamationmark.triangle.fill")
                            .foregroundStyle(.orange)
                        Text("Grant Accessibility access to enable paste.")
                            .font(.caption)
                        Button("Open") {
                            monitor.checkAccessibility()
                        }
                        .font(.caption)
                    }
                    .padding(8)
                    .background(Color.orange.opacity(0.12))
                    .frame(maxWidth: .infinity, alignment: .leading)

                    Divider()
                }

                ScrollView(.vertical, showsIndicators: true) {
                    LazyVStack(spacing: 0) {
                        ForEach(monitor.orderedItems) { item in
                            ItemRowView(item: item)
                                .environmentObject(monitor)
                            Divider()
                                .padding(.leading, 12)
                        }
                    }
                }
            }
        }
        .frame(width: 360, height: 440)
    }
}

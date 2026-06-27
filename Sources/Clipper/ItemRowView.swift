import SwiftUI

struct ItemRowView: View {
    let item: ClipboardItem
    @EnvironmentObject private var monitor: ClipboardMonitor

    private var preview: String {
        let trimmed = item.text.trimmingCharacters(in: .whitespacesAndNewlines)
        let firstLine = trimmed.split(separator: "\n", maxSplits: 1).first.map(String.init) ?? trimmed
        return firstLine.count > 60 ? String(firstLine.prefix(60)) + "…" : firstLine
    }

    var body: some View {
        HStack(spacing: 8) {
            Button {
                monitor.paste(item)
            } label: {
                Text(preview)
                    .lineLimit(1)
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .foregroundStyle(.primary)
            }
            .buttonStyle(.plain)
            .help(item.text)

            Button {
                monitor.togglePin(item)
            } label: {
                Image(systemName: item.isPinned ? "pin.fill" : "pin")
                    .foregroundStyle(item.isPinned ? Color.accentColor : Color.secondary)
            }
            .buttonStyle(.plain)
            .help(item.isPinned ? "Unpin" : "Pin")

            Button {
                monitor.deleteItem(item)
            } label: {
                Image(systemName: "xmark")
                    .foregroundStyle(Color.secondary)
            }
            .buttonStyle(.plain)
            .help("Remove")
        }
        .padding(.horizontal, 12)
        .padding(.vertical, 6)
        .contentShape(Rectangle())
    }
}

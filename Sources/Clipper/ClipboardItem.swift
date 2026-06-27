import Foundation

struct ClipboardItem: Codable, Identifiable, Equatable {
    let id: UUID
    var text: String
    var isPinned: Bool
    var createdAt: Date

    init(text: String) {
        self.id = UUID()
        self.text = text
        self.isPinned = false
        self.createdAt = Date()
    }
}

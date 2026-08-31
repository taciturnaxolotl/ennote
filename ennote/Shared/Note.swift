import Foundation
import SwiftData

@Model
final class Note {
    var id: UUID
    var content: String
    var isCompleted: Bool
    var order: Int
    var createdAt: Date
    var completedAt: Date?

    init(
        id: UUID = UUID(),
        content: String,
        isCompleted: Bool = false,
        order: Int = 0,
        createdAt: Date = Date(),
        completedAt: Date? = nil
    ) {
        self.id = id
        self.content = content
        self.isCompleted = isCompleted
        self.order = order
        self.createdAt = createdAt
        self.completedAt = completedAt
    }
}

// MARK: - Presentation

extension Note {
    /// The first line, shown wherever a note needs a one-liner.
    var title: String {
        content.components(separatedBy: .newlines).first ?? content
    }

    /// Everything after the first line, flattened for single-line display.
    var subtitle: String? {
        let lines = content.components(separatedBy: .newlines).dropFirst()
        let rest = lines.joined(separator: " ").trimmingCharacters(in: .whitespaces)
        return rest.isEmpty ? nil : rest
    }
}

// MARK: - Convenience

extension Note {
    func complete() {
        isCompleted = true
        completedAt = Date()
    }

    func uncomplete() {
        isCompleted = false
        completedAt = nil
    }
}

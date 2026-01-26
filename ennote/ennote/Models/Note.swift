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

// MARK: - Sample Data
extension Note {
    static let placeholder = Note(content: "Sample note")

    static let sampleNotes: [Note] = [
        Note(content: "Review PR for auth flow", order: 0),
        Note(content: "Update dependencies", order: 1),
        Note(content: "Write tests for sync", order: 2),
        Note(content: "Deploy to staging", order: 3),
        Note(content: "Send update to team", order: 4)
    ]
}

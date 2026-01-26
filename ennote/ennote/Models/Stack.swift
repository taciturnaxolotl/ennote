import Foundation

/// Stack for QR Transfer (CloudKit Public DB)
struct Stack: Identifiable, Codable {
    let id: String              // Random 12-char alphanumeric
    var notes: [String]         // Just the content strings
    let createdAt: Date
    let expiresAt: Date         // createdAt + TTL
    var fetched: Bool           // Mark true on first fetch

    init(
        id: String = Stack.generateId(),
        notes: [String],
        createdAt: Date = Date(),
        expiresAt: Date? = nil,
        fetched: Bool = false
    ) {
        self.id = id
        self.notes = notes
        self.createdAt = createdAt
        self.expiresAt = expiresAt ?? createdAt.addingTimeInterval(5 * 60) // 5 min TTL
        self.fetched = fetched
    }

    var isExpired: Bool {
        Date() > expiresAt
    }

    var timeRemaining: TimeInterval {
        max(0, expiresAt.timeIntervalSince(Date()))
    }

    // Generate random 12-char alphanumeric ID
    static func generateId() -> String {
        let chars = "ABCDEFGHIJKLMNOPQRSTUVWXYZabcdefghijklmnopqrstuvwxyz0123456789"
        return String((0..<12).map { _ in chars.randomElement()! })
    }

    // Parse deep link URL
    static func parseDeepLink(_ url: URL) -> String? {
        guard url.scheme == "ennote",
              url.host == "stack",
              let stackId = url.pathComponents.dropFirst().first else {
            return nil
        }
        return stackId
    }
}

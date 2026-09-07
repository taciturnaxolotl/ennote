import Foundation

/// Whatever is sitting in the editor, kept on disk so an unsaved note
/// survives the app being killed or the phone running out of battery.
///
/// A draft is cleared when the note is saved or cancelled, restored as-is when
/// the editor is swiped away, and promoted to a real note when the app dies
/// with the editor still open.
nonisolated enum NoteDraft {
    private static var defaults: UserDefaults { AppGroup.sharedDefaults ?? .standard }
    private static let openKey = "draft.open"

    private static func token(for id: UUID?) -> String { id?.uuidString ?? "new" }
    private static func key(for id: UUID?) -> String { "draft.\(token(for: id))" }

    static func load(for id: UUID?) -> String? {
        defaults.string(forKey: key(for: id))
    }

    static func save(_ text: String, for id: UUID?) {
        if text.isEmpty {
            clear(for: id)
        } else {
            defaults.set(text, forKey: key(for: id))
        }
    }

    static func clear(for id: UUID?) {
        defaults.removeObject(forKey: key(for: id))
    }

    /// Raised while the editor is on screen, lowered when it closes.
    static func markOpen(for id: UUID?) { defaults.set(token(for: id), forKey: openKey) }
    static func markClosed() { defaults.removeObject(forKey: openKey) }

    /// A draft still marked open at launch was being typed when the app died.
    static func abandoned() -> (id: UUID?, content: String)? {
        guard let token = defaults.string(forKey: openKey),
              let text = defaults.string(forKey: "draft.\(token)")
        else { return nil }

        let content = text.trimmingCharacters(in: .whitespacesAndNewlines)
        return content.isEmpty ? nil : (UUID(uuidString: token), content)
    }
}

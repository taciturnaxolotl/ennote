import Foundation

/// Whatever is sitting in the editor, kept on disk so an unsaved note
/// survives the editor being swiped away or the app being killed.
///
/// A draft is cleared when the note is saved or cancelled. Otherwise it stays
/// reopenable for `lifetime` after the editor closes, and past that it is
/// handed back by `expired()` to be written out as a real note.
nonisolated enum NoteDraft {
    static let lifetime: Duration = .seconds(5 * 60)

    private static var defaults: UserDefaults { AppGroup.sharedDefaults ?? .standard }
    private static let openKey = "draft.open"
    private static let textPrefix = "draft."
    private static let closedPrefix = "draftClosedAt."

    private static func token(for id: UUID?) -> String { id?.uuidString ?? "new" }
    private static func key(for id: UUID?) -> String { textPrefix + token(for: id) }

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
        clear(token: token(for: id))
    }

    private static func clear(token: String) {
        defaults.removeObject(forKey: textPrefix + token)
        defaults.removeObject(forKey: closedPrefix + token)
    }

    /// Raised while the editor is on screen, so its draft is never flushed
    /// out from under it.
    static func markOpen(for id: UUID?) { defaults.set(token(for: id), forKey: openKey) }

    /// Starts the reopen window for whatever the editor left behind. Also run
    /// at launch, where a raised flag means the app died mid-edit.
    static func markClosed() {
        if let token = defaults.string(forKey: openKey),
           defaults.string(forKey: textPrefix + token) != nil {
            defaults.set(Date.now.timeIntervalSince1970, forKey: closedPrefix + token)
        }
        defaults.removeObject(forKey: openKey)
    }

    /// Removes and returns every draft whose reopen window has run out. A draft
    /// with no close time predates the window and counts as expired.
    static func takeExpired() -> [(id: UUID?, content: String)] {
        let open = defaults.string(forKey: openKey)
        let cutoff = Date.now.timeIntervalSince1970 - Double(lifetime.components.seconds)

        return defaults.dictionaryRepresentation().keys
            .filter { $0.hasPrefix(textPrefix) && $0 != openKey }
            .map { String($0.dropFirst(textPrefix.count)) }
            .filter { $0 != open && defaults.double(forKey: closedPrefix + $0) < cutoff }
            .compactMap { token in
                let text = defaults.string(forKey: textPrefix + token) ?? ""
                clear(token: token)
                let content = text.trimmingCharacters(in: .whitespacesAndNewlines)
                return content.isEmpty ? nil : (UUID(uuidString: token), content)
            }
    }
}

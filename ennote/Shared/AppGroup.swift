import Foundation

/// Shared App Group identifiers.
///
/// NOTE: App Groups require a paid Apple Developer account. On a personal
/// dev account `containerURL` returns nil and the app falls back to a
/// local-only SwiftData container. Widgets and the Control Center button
/// then have nothing to read, but the app itself works normally.
nonisolated enum AppGroup {
    static let identifier = "group.sh.dunkirk.ennote"

    static var containerURL: URL? {
        FileManager.default.containerURL(forSecurityApplicationGroupIdentifier: identifier)
    }

    static var sharedDefaults: UserDefaults? {
        UserDefaults(suiteName: identifier)
    }

    /// What the Control Center button opens, handled in ContentView.
    static let newNoteURL = URL(string: "ennote://new")!

    private static let newNoteKey = "newNoteRequestedAt"

    /// Raised by the Control Center button beside the link it opens. The link is
    /// the quick path; this is the one that survives the link being dropped.
    static func requestNewNote() {
        sharedDefaults?.set(Date.now.timeIntervalSince1970, forKey: newNoteKey)
    }

    /// Takes the request if there is a fresh one, so a button pressed while the
    /// app never came forward doesn't open an editor hours later.
    static func takeNewNoteRequest() -> Bool {
        guard let raised = sharedDefaults?.double(forKey: newNoteKey), raised > 0 else { return false }
        sharedDefaults?.removeObject(forKey: newNoteKey)
        return Date.now.timeIntervalSince1970 - raised < 10
    }
}

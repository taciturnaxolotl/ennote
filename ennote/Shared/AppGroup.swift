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
}

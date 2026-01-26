import Foundation

/// Shared constants for App Group
///
/// NOTE: App Groups require a paid Apple Developer account. When using a personal
/// dev account for testing, the App Group won't be available and `containerURL`
/// will return nil. The app falls back to a local-only SwiftData container in this case.
/// Widget data sharing won't work without App Groups - the widget will show empty.
///
/// To restore full functionality:
/// 1. Use a paid team account in Signing & Capabilities
/// 2. Add App Groups capability with identifier: group.sh.dunkirk.ennote
/// 3. Add iCloud capability with CloudKit container: iCloud.sh.dunkirk.ennote
enum AppGroup {
    static let identifier = "group.sh.dunkirk.ennote"

    static var containerURL: URL? {
        FileManager.default.containerURL(forSecurityApplicationGroupIdentifier: identifier)
    }

    static var sharedDefaults: UserDefaults? {
        UserDefaults(suiteName: identifier)
    }
}

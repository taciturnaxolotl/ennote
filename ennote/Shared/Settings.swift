import Foundation

/// User preferences storage
enum Settings {
    private static var defaults: UserDefaults {
        AppGroup.sharedDefaults ?? .standard
    }

    private enum Keys {
        static let isLeftHanded = "isLeftHanded"
    }

    /// Whether the user prefers left-handed mode (FAB on left side)
    /// Defaults to false (right-handed, FAB on right side)
    static var isLeftHanded: Bool {
        get { defaults.bool(forKey: Keys.isLeftHanded) }
        set { defaults.set(newValue, forKey: Keys.isLeftHanded) }
    }
}

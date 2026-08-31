import SwiftData

/// Builds the SwiftData container shared by the app, its widgets, and its intents.
nonisolated enum NoteStorage {
    /// Prefers the App Group container so widgets can read the same store.
    static func makeContainer() -> ModelContainer? {
        let configuration = AppGroup.containerURL == nil
            ? ModelConfiguration()
            : ModelConfiguration(groupContainer: .identifier(AppGroup.identifier))
        return try? ModelContainer(for: Note.self, configurations: configuration)
    }

    /// Last resort when no on-disk store can be opened: notes live for one launch.
    static func makeEphemeralContainer() -> ModelContainer? {
        try? ModelContainer(
            for: Note.self,
            configurations: ModelConfiguration(isStoredInMemoryOnly: true)
        )
    }
}

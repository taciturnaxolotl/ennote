import AppIntents

/// Opens the app straight into a new note.
///
/// This lives in Shared, not with the control that runs it: an intent that opens
/// the app has to be compiled into the app as well as the extension, or the
/// system runs it in the extension and nothing comes forward.
struct NewNoteIntent: AppIntent {
    static let title: LocalizedStringResource = "New Note"
    static let description = IntentDescription("Opens enɳoté ready to write a new note")
    static let openAppWhenRun = true

    init() {}

    /// A link rather than a shared flag: the app can already be launching while
    /// this runs, and a URL waits its turn where a flag gets read too early.
    func perform() async throws -> some IntentResult & OpensIntent {
        .result(opensIntent: OpenURLIntent(AppGroup.newNoteURL))
    }
}

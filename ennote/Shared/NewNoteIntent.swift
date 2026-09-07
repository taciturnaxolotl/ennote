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
    static let isDiscoverable = true

    init() {}

    /// `openAppWhenRun` is what brings the app forward from a control; the link
    /// and the flag are two ways of telling it where to land, because a control's
    /// link does not always survive the trip.
    func perform() async throws -> some IntentResult & OpensIntent {
        AppGroup.requestNewNote()
        return .result(opensIntent: OpenURLIntent(AppGroup.newNoteURL))
    }
}

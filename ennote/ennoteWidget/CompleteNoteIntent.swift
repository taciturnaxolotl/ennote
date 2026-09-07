import WidgetKit
import SwiftData
import AppIntents

struct CompleteNoteIntent: AppIntent {
    static let title: LocalizedStringResource = "Complete Note"
    static let description = IntentDescription("Marks a note as completed")

    @Parameter(title: "Note ID")
    var noteID: String

    init() {}

    init(noteID: String) {
        self.noteID = noteID
    }

    func perform() async throws -> some IntentResult {
        guard let uuid = UUID(uuidString: noteID),
              AppGroup.containerURL != nil,
              let container = NoteStorage.makeContainer() else {
            return .result()
        }

        let context = ModelContext(container)
        let descriptor = FetchDescriptor<Note>(predicate: #Predicate { $0.id == uuid })

        if let note = try? context.fetch(descriptor).first {
            note.complete()
            try? context.save()
        }

        WidgetCenter.shared.reloadAllTimelines()
        return .result()
    }
}

import WidgetKit
import SwiftUI
import AppIntents

/// Control Center button that opens the app straight into a new note.
struct NewNoteControl: ControlWidget {
    var body: some ControlWidgetConfiguration {
        StaticControlConfiguration(kind: "sh.dunkirk.ennote.newNote") {
            ControlWidgetButton(action: NewNoteIntent()) {
                Label("New Note", systemImage: "square.and.pencil")
            }
        }
        .displayName("New Note")
        .description("Start a new note in enɳoté.")
    }
}

struct NewNoteIntent: AppIntent {
    static let title: LocalizedStringResource = "New Note"
    static let description = IntentDescription("Opens enɳoté ready to write a new note")

    init() {}

    /// A link rather than a shared flag: the app can already be launching while
    /// this runs, and a URL waits its turn where a flag gets read too early.
    func perform() async throws -> some IntentResult & OpensIntent {
        .result(opensIntent: OpenURLIntent(AppGroup.newNoteURL))
    }
}

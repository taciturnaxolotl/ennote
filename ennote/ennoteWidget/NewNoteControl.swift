import WidgetKit
import SwiftUI

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

import WidgetKit
import SwiftUI
import AppIntents

// MARK: - Complete Note Intent

@available(iOS 17.0, *)
struct CompleteNoteIntent: AppIntent {
    static var title: LocalizedStringResource = "Complete Note"
    static var description = IntentDescription("Marks a note as completed")

    @Parameter(title: "Note ID")
    var noteID: String

    init() {}

    init(noteID: String) {
        self.noteID = noteID
    }

    func perform() async throws -> some IntentResult {
        await NoteStore.shared.complete(noteID)
        return .result()
    }
}

// MARK: - Interactive Widget

@available(iOS 17.0, *)
struct ennoteInteractiveWidget: Widget {
    let kind: String = "ennoteInteractiveWidget"

    var body: some WidgetConfiguration {
        StaticConfiguration(kind: kind, provider: Provider()) { entry in
            InteractiveWidgetView(entry: entry)
        }
        .configurationDisplayName("enɳoté Interactive")
        .description("Complete notes directly from the widget.")
        .supportedFamilies([.systemMedium, .systemLarge])
    }
}

@available(iOS 17.0, *)
struct InteractiveWidgetView: View {
    var entry: NoteEntry

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            ForEach(entry.notes.prefix(4)) { note in
                Button(intent: CompleteNoteIntent(noteID: note.id)) {
                    HStack(spacing: 8) {
                        Image(systemName: "circle")
                            .font(.body)
                            .foregroundStyle(.secondary)
                        Text(note.content)
                            .font(.subheadline)
                            .lineLimit(1)
                            .foregroundStyle(.primary)
                        Spacer()
                    }
                    .padding(.vertical, 4)
                }
                .buttonStyle(.plain)
            }

            if entry.notes.isEmpty {
                Text("No notes")
                    .foregroundStyle(.secondary)
            }

            Spacer()
        }
        .containerBackground(.fill.tertiary, for: .widget)
    }
}

@available(iOS 17.0, *)
#Preview("Interactive Medium", as: .systemMedium) {
    ennoteInteractiveWidget()
} timeline: {
    NoteEntry.placeholder
}

import WidgetKit
import SwiftUI
import SwiftData
import AppIntents

// MARK: - Complete Note Intent

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

// MARK: - Interactive Widget

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

struct InteractiveWidgetView: View {
    @Environment(\.widgetFamily) var family
    var entry: NoteEntry

    private var maxNotes: Int { family == .systemLarge ? 10 : 3 }

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            if entry.notes.isEmpty {
                Text("All clear")
                    .font(.title2.weight(.heavy))
                    .foregroundStyle(Color.themeAccent)
            } else {
                // The first note carries the weight; tapping any of them completes it.
                ForEach(Array(entry.notes.prefix(maxNotes).enumerated()), id: \.element.id) { index, note in
                    Button(intent: CompleteNoteIntent(noteID: note.id)) {
                        HStack(spacing: 10) {
                            Image(systemName: "circle")
                                .font(.footnote.weight(.bold))
                                .foregroundStyle(Color.themeAccent)
                            Text(note.title)
                                .font(index == 0 ? .headline : .subheadline)
                                .foregroundStyle(.white.opacity(index == 0 ? 1 : 0.6))
                                .lineLimit(1)
                            Spacer(minLength: 0)
                        }
                        .contentShape(.rect)
                    }
                    .buttonStyle(.plain)
                    .accessibilityLabel("Complete \(note.title)")
                }
            }

            Spacer(minLength: 0)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .containerBackground(Color.themeInk, for: .widget)
    }
}

#Preview("Interactive Medium", as: .systemMedium) {
    ennoteInteractiveWidget()
} timeline: {
    NoteEntry.placeholder
}

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

    private var maxNotes: Int {
        family == .systemLarge ? 5 : 4
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 4) {
            if family == .systemLarge {
                Text("enɳoté")
                    .font(.headline)
                Divider()
            }

            if entry.notes.isEmpty {
                Text("No notes")
                    .foregroundStyle(.secondary)
            } else {
                ForEach(entry.notes.prefix(maxNotes)) { note in
                    Button(intent: CompleteNoteIntent(noteID: note.id)) {
                        HStack(spacing: 8) {
                            Image(systemName: "circle")
                                .font(.caption)
                                .foregroundStyle(.secondary)
                            Text(note.title)
                                .font(.subheadline)
                                .lineLimit(1)
                                .foregroundStyle(.primary)
                            Spacer()
                        }
                        .padding(.vertical, 2)
                    }
                    .buttonStyle(.plain)
                    .accessibilityLabel("Complete \(note.title)")
                }
            }

            Spacer()

            if !entry.activityData.isEmpty {
                StreakView(activityData: entry.activityData)
            }
        }
        .overlay(alignment: .topTrailing) {
            Image(systemName: "hand.tap")
                .font(.caption2)
                .foregroundStyle(.tertiary)
        }
        .containerBackground(.fill.tertiary, for: .widget)
    }
}

#Preview("Interactive Medium", as: .systemMedium) {
    ennoteInteractiveWidget()
} timeline: {
    NoteEntry.placeholder
}

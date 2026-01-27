import WidgetKit
import SwiftUI
import SwiftData
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
        guard let uuid = UUID(uuidString: noteID),
              AppGroup.containerURL != nil else {
            return .result()
        }

        do {
            let config = ModelConfiguration(
                groupContainer: .identifier(AppGroup.identifier)
            )
            let container = try ModelContainer(for: Note.self, configurations: config)
            let context = ModelContext(container)

            let descriptor = FetchDescriptor<Note>(
                predicate: #Predicate { $0.id == uuid }
            )

            if let note = try context.fetch(descriptor).first {
                note.complete()
                try context.save()
            }
        } catch {
            print("Failed to complete note: \(error)")
        }

        WidgetCenter.shared.reloadAllTimelines()
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
    @Environment(\.widgetFamily) var family
    var entry: NoteEntry

    var body: some View {
        VStack(alignment: .leading, spacing: 4) {
            // Header - only show full header on large
            if family == .systemLarge {
                HStack {
                    Text("enɳoté")
                        .font(.headline)
                    Spacer()
                    Image(systemName: "hand.tap")
                        .font(.caption2)
                        .foregroundStyle(.tertiary)
                }
                Divider()
            }

            ForEach(entry.notes.prefix(family == .systemLarge ? 5 : 4)) { note in
                Button(intent: CompleteNoteIntent(noteID: note.id)) {
                    HStack(spacing: 8) {
                        Image(systemName: "circle")
                            .font(.caption)
                            .foregroundStyle(.secondary)
                        Text(note.content)
                            .font(.subheadline)
                            .lineLimit(1)
                            .foregroundStyle(.primary)
                        Spacer()
                    }
                    .padding(.vertical, 2)
                }
                .buttonStyle(.plain)
            }

            if entry.notes.isEmpty {
                Text("No notes")
                    .foregroundStyle(.secondary)
            }

            Spacer()

            if !entry.activityData.isEmpty {
                StreakView(activityData: entry.activityData)
            }
        }
        .overlay(alignment: .topTrailing) {
            if family == .systemMedium {
                Image(systemName: "hand.tap")
                    .font(.caption2)
                    .foregroundStyle(.tertiary)
            }
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

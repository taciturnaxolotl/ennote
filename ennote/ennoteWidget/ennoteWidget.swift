import WidgetKit
import SwiftUI
import SwiftData

// MARK: - Timeline Entry

struct NoteEntry: TimelineEntry {
    let date: Date
    let notes: [WidgetNote]
    /// Every active note, not just the ones that fit, for the count and the "+N".
    let activeCount: Int

    /// A full large widget shows sixteen; nothing needs more than that in memory.
    static let visibleLimit = 16

    static let placeholder = NoteEntry(
        date: .now,
        notes: [
            WidgetNote(id: "1", title: "Review PR for auth flow"),
            WidgetNote(id: "2", title: "Update dependencies"),
            WidgetNote(id: "3", title: "Write tests for sync")
        ],
        activeCount: 3
    )

    static let empty = NoteEntry(date: .now, notes: [], activeCount: 0)
}

struct WidgetNote: Identifiable {
    let id: String
    let title: String
}

// MARK: - Timeline Provider

struct Provider: TimelineProvider {
    func placeholder(in context: Context) -> NoteEntry {
        .placeholder
    }

    func getSnapshot(in context: Context, completion: @escaping (NoteEntry) -> Void) {
        completion(fetchEntry())
    }

    func getTimeline(in context: Context, completion: @escaping (Timeline<NoteEntry>) -> Void) {
        let nextUpdate = Calendar.current.date(byAdding: .minute, value: 15, to: .now) ?? .now
        completion(Timeline(entries: [fetchEntry()], policy: .after(nextUpdate)))
    }

    private func fetchEntry() -> NoteEntry {
        // Without an App Group there is no shared store to read.
        guard AppGroup.containerURL != nil, let container = NoteStorage.makeContainer() else {
            return .empty
        }

        let context = ModelContext(container)

        do {
            // A widget gets a tight memory budget, so it reads the notes it can
            // draw and counts the rest rather than loading the whole store.
            var activeDescriptor = FetchDescriptor<Note>(
                predicate: #Predicate { !$0.isCompleted },
                sortBy: [SortDescriptor(\.order)]
            )
            let activeCount = try context.fetchCount(activeDescriptor)
            activeDescriptor.fetchLimit = NoteEntry.visibleLimit
            let active = try context.fetch(activeDescriptor)

            return NoteEntry(
                date: .now,
                notes: active.map { WidgetNote(id: $0.id.uuidString, title: $0.title) },
                activeCount: activeCount
            )
        } catch {
            print("Widget failed to fetch notes: \(error)")
            return .empty
        }
    }

}

// MARK: - Shared Pieces

/// The small widget answers one question: how much is left.
struct NoteCount: View {
    let entry: NoteEntry

    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            if entry.activeCount == 0 {
                Text("All")
                Text("clear")
            } else {
                Text("\(entry.activeCount)")
                    .contentTransition(.numericText())
                Text(entry.activeCount == 1 ? "note" : "notes")
                    .foregroundStyle(.white.opacity(0.45))
            }
        }
        .font(.system(size: 44, weight: .heavy, design: .rounded))
        .minimumScaleFactor(0.5)
        .lineLimit(1)
        .foregroundStyle(Color.themeAccent)
        .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .leading)
        .containerBackground(Color.themeInk, for: .widget)
    }
}

/// The bigger widgets answer the other one: which notes.
struct NoteBoard: View {
    let entry: NoteEntry
    let rows: Int
    var font: Font = .subheadline

    var body: some View {
        VStack(alignment: .leading, spacing: 6) {
            if entry.notes.isEmpty {
                Text("All clear")
                    .font(.title2.weight(.heavy))
                    .foregroundStyle(Color.themeAccent)
            } else {
                // One row at a time, so a widget that can hold eleven shows
                // eleven instead of dropping to the next round number.
                ViewThatFits(in: .vertical) {
                    list(rows)
                    list(rows - 1)
                    list(rows - 2)
                    list(rows - 3)
                    list(rows - 4)
                    list(rows - 5)
                    list(rows - 6)
                    list(rows - 7)
                }
            }
        }
        // Whatever the fitter leaves over splits top and bottom, so a list that
        // stops a row short still sits evenly in the frame.
        .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .leading)
        .containerBackground(Color.themeInk, for: .widget)
    }

    private func list(_ count: Int) -> some View {
        let shown = entry.notes.prefix(max(count, 1))
        let hidden = entry.activeCount - shown.count

        return VStack(alignment: .leading, spacing: 6) {
            ForEach(shown) { note in
                HStack(alignment: .firstTextBaseline, spacing: 8) {
                    Image(systemName: "circle")
                        .font(.caption2.weight(.bold))
                        .foregroundStyle(Color.themeAccent)
                        .frame(width: 12, alignment: .leading)
                    Text(note.title)
                        .font(font)
                        .foregroundStyle(.white)
                        .lineLimit(1)
                    Spacer(minLength: 0)
                }
            }

            // Reads as the tail of the list rather than a lonely footer.
            if hidden > 0 {
                Text("+\(hidden) more")
                    .font(font)
                    .foregroundStyle(.white.opacity(0.35))
                    .padding(.leading, 20)
            }
        }
    }
}

// MARK: - Lock Screen Widget Views

struct AccessoryCircularView: View {
    var entry: NoteEntry

    var body: some View {
        ZStack {
            AccessoryWidgetBackground()
            Text("\(entry.activeCount)")
                .font(.system(.title, design: .rounded).bold())
        }
        .widgetAccentable()
    }
}

struct AccessoryRectangularView: View {
    var entry: NoteEntry

    var body: some View {
        if let note = entry.notes.first {
            HStack {
                Image(systemName: "circle")
                    .font(.caption2)
                Text(note.title)
                    .lineLimit(1)
            }
        } else {
            Text("No notes")
                .foregroundStyle(.secondary)
        }
    }
}

struct AccessoryInlineView: View {
    var entry: NoteEntry

    var body: some View {
        if entry.notes.isEmpty {
            Text("enɳoté: No notes")
        } else {
            Text("enɳoté: \(entry.activeCount) notes")
        }
    }
}

// MARK: - Widget Configuration

struct ennoteWidget: Widget {
    let kind: String = "ennoteWidget"

    var body: some WidgetConfiguration {
        StaticConfiguration(kind: kind, provider: Provider()) { entry in
            WidgetEntryView(entry: entry)
        }
        .configurationDisplayName("enɳoté")
        .description("View your notes at a glance.")
        .supportedFamilies([
            .systemSmall,
            .systemMedium,
            .systemLarge,
            .accessoryCircular,
            .accessoryRectangular,
            .accessoryInline
        ])
    }
}

struct WidgetEntryView: View {
    @Environment(\.widgetFamily) var family
    var entry: NoteEntry

    var body: some View {
        switch family {
        case .systemMedium: NoteBoard(entry: entry, rows: 7)
        case .systemLarge: NoteBoard(entry: entry, rows: 16, font: .body)
        case .accessoryCircular: AccessoryCircularView(entry: entry)
        case .accessoryRectangular: AccessoryRectangularView(entry: entry)
        case .accessoryInline: AccessoryInlineView(entry: entry)
        default: NoteCount(entry: entry)
        }
    }
}

// MARK: - Widget Bundle

@main
struct ennoteWidgetBundle: WidgetBundle {
    var body: some Widget {
        ennoteWidget()
        ennoteInteractiveWidget()
        NewNoteControl()
    }
}

// MARK: - Previews

#Preview("Small", as: .systemSmall) {
    ennoteWidget()
} timeline: {
    NoteEntry.placeholder
    NoteEntry.empty
}

#Preview("Medium", as: .systemMedium) {
    ennoteWidget()
} timeline: {
    NoteEntry.placeholder
}

#Preview("Large", as: .systemLarge) {
    ennoteWidget()
} timeline: {
    NoteEntry.placeholder
}

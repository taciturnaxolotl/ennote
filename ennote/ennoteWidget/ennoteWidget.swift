import WidgetKit
import SwiftUI
import SwiftData
import AppIntents

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

/// The bigger widgets answer the other one: which notes, each one a tap
/// away from done.
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
                Button(intent: CompleteNoteIntent(noteID: note.id)) {
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
                    .contentShape(.rect)
                }
                .buttonStyle(.plain)
                .accessibilityLabel("Complete \(note.title)")
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
//
// Accessory widgets draw on the wallpaper, so their container background is
// clear; without one declared at all the system nags to adopt the API.

struct AccessoryCircularView: View {
    var entry: NoteEntry

    var body: some View {
        ZStack {
            AccessoryWidgetBackground()

            if entry.activeCount == 0 {
                Image(systemName: "checkmark")
                    .font(.title3.weight(.bold))
            } else {
                VStack(spacing: -2) {
                    Text("\(entry.activeCount)")
                        .font(.system(.title2, design: .rounded).weight(.bold))
                    Text("NOTES")
                        .font(.system(size: 8, weight: .semibold))
                }
                .minimumScaleFactor(0.6)
            }
        }
        .widgetAccentable()
        .containerBackground(.clear, for: .widget)
    }
}

struct AccessoryRectangularView: View {
    var entry: NoteEntry

    var body: some View {
        VStack(alignment: .leading, spacing: 1) {
            Text(entry.activeCount == 0
                 ? "All clear"
                 : "^[\(entry.activeCount) note](inflect: true)")
                .font(.headline)
                .widgetAccentable()

            if let next = entry.notes.first {
                Text(next.title)
                    .font(.caption)
                    .lineLimit(2)
            }
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .topLeading)
        .containerBackground(.clear, for: .widget)
    }
}

struct AccessoryInlineView: View {
    var entry: NoteEntry

    var body: some View {
        // Inline sits beside the clock, so it gets the one useful line.
        Text(entry.notes.first?.title ?? "All clear")
            .containerBackground(.clear, for: .widget)
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
        .description("See your notes, and tap one to complete it.")
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

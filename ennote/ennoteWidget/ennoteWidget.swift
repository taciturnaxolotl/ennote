import WidgetKit
import SwiftUI
import SwiftData

// MARK: - Timeline Entry

struct NoteEntry: TimelineEntry {
    let date: Date
    let notes: [WidgetNote]
    /// Every active note, not just the ones that fit, for the counts and the "+N".
    let activeCount: Int
    let activityData: [DayActivity]

    /// The largest widget shows eight; nothing needs more than that in memory.
    static let visibleLimit = 8

    static let placeholder = NoteEntry(
        date: .now,
        notes: [
            WidgetNote(id: "1", title: "Review PR for auth flow"),
            WidgetNote(id: "2", title: "Update dependencies"),
            WidgetNote(id: "3", title: "Write tests for sync")
        ],
        activeCount: 3,
        activityData: DayActivity.sampleData
    )

    static let empty = NoteEntry(date: .now, notes: [], activeCount: 0, activityData: [])
}

struct DayActivity: Identifiable {
    let date: Date
    let completedCount: Int

    var id: Date { date }

    var intensity: Double {
        min(Double(completedCount) / 4, 1)
    }

    static var sampleData: [DayActivity] {
        let counts = [0, 1, 2, 0, 3, 1, 4]
        return days().enumerated().map { DayActivity(date: $1, completedCount: counts[$0]) }
    }

    /// Midnight on the oldest day the streak shows.
    static var windowStart: Date {
        Calendar.current.startOfDay(for: days().first ?? .now)
    }

    /// The last seven days, oldest first.
    static func days() -> [Date] {
        let calendar = Calendar.current
        return (0..<7).reversed().map {
            calendar.date(byAdding: .day, value: -$0, to: .now) ?? .now
        }
    }
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

            // The streak only reaches back a week; older completions never load.
            let floor = Date.distantPast
            let cutoff = DayActivity.windowStart
            let completed = try context.fetch(
                FetchDescriptor<Note>(
                    predicate: #Predicate {
                        $0.isCompleted && ($0.completedAt ?? floor) >= cutoff
                    }
                )
            )

            return NoteEntry(
                date: .now,
                notes: active.map { WidgetNote(id: $0.id.uuidString, title: $0.title) },
                activeCount: activeCount,
                activityData: activity(from: completed)
            )
        } catch {
            print("Widget failed to fetch notes: \(error)")
            return .empty
        }
    }

    private func activity(from completed: [Note]) -> [DayActivity] {
        let calendar = Calendar.current
        return DayActivity.days().map { date in
            let dayStart = calendar.startOfDay(for: date)
            let dayEnd = calendar.date(byAdding: .day, value: 1, to: dayStart) ?? date
            let count = completed.filter {
                guard let completedAt = $0.completedAt else { return false }
                return completedAt >= dayStart && completedAt < dayEnd
            }.count
            return DayActivity(date: date, completedCount: count)
        }
    }
}

// MARK: - Shared Pieces

/// One layout for every home-screen size: the next note reads as a headline and
/// the rest sit quietly under it. Only the row count and the type scale change.
struct NoteBoard: View {
    let entry: NoteEntry
    var rows = 2
    var headline: Font = .title3
    var showsTitle = false

    private var rest: ArraySlice<WidgetNote> { entry.notes.dropFirst().prefix(rows) }
    private var hidden: Int { entry.activeCount - 1 - rest.count }

    var body: some View {
        VStack(alignment: .leading, spacing: 6) {
            if showsTitle {
                Text("enɳoté")
                    .font(.caption.weight(.semibold))
                    .foregroundStyle(Color.themeAccent)
            }

            if let next = entry.notes.first {
                Text(next.title)
                    .font(headline.weight(.heavy))
                    .lineLimit(3)
                    .minimumScaleFactor(0.75)

                ForEach(rest) { note in
                    Text(note.title)
                        .font(.footnote)
                        .foregroundStyle(.secondary)
                        .lineLimit(1)
                }
            } else {
                Text("All clear")
                    .font(headline.weight(.heavy))
                    .foregroundStyle(Color.themeAccent)
            }

            Spacer(minLength: 0)

            HStack(spacing: 6) {
                if !entry.activityData.isEmpty {
                    StreakView(activityData: entry.activityData)
                }
                if hidden > 0 {
                    Text("+\(hidden)")
                        .font(.caption2.weight(.bold))
                        .foregroundStyle(.tertiary)
                }
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .containerBackground(.fill.tertiary, for: .widget)
    }
}

struct StreakView: View {
    let activityData: [DayActivity]

    var body: some View {
        HStack(spacing: 4) {
            ForEach(activityData) { day in
                Circle()
                    .fill(day.completedCount > 0
                        ? Color.themeAccent.opacity(day.intensity)
                        : Color.secondary.opacity(0.2))
                    .frame(width: 8, height: 8)
                    .accessibilityLabel(
                        "\(day.date.formatted(.dateTime.weekday(.wide))): \(day.completedCount) completed"
                    )
            }
            Spacer(minLength: 0)
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
        case .systemMedium: NoteBoard(entry: entry, rows: 3, headline: .title2)
        case .systemLarge: NoteBoard(entry: entry, rows: 7, headline: .title, showsTitle: true)
        case .accessoryCircular: AccessoryCircularView(entry: entry)
        case .accessoryRectangular: AccessoryRectangularView(entry: entry)
        case .accessoryInline: AccessoryInlineView(entry: entry)
        default: NoteBoard(entry: entry)
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

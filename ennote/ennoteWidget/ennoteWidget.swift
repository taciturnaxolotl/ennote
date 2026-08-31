import WidgetKit
import SwiftUI
import SwiftData

// MARK: - Timeline Entry

struct NoteEntry: TimelineEntry {
    let date: Date
    let notes: [WidgetNote]
    let activityData: [DayActivity]

    static let placeholder = NoteEntry(
        date: .now,
        notes: [
            WidgetNote(id: "1", title: "Review PR for auth flow"),
            WidgetNote(id: "2", title: "Update dependencies"),
            WidgetNote(id: "3", title: "Write tests for sync")
        ],
        activityData: DayActivity.sampleData
    )

    static let empty = NoteEntry(date: .now, notes: [], activityData: [])
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
            let active = try context.fetch(
                FetchDescriptor<Note>(
                    predicate: #Predicate { !$0.isCompleted },
                    sortBy: [SortDescriptor(\.order)]
                )
            )
            let completed = try context.fetch(
                FetchDescriptor<Note>(
                    predicate: #Predicate { $0.isCompleted && $0.completedAt != nil }
                )
            )

            return NoteEntry(
                date: .now,
                notes: active.map { WidgetNote(id: $0.id.uuidString, title: $0.title) },
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

struct NoteList: View {
    let notes: [WidgetNote]
    let maxNotes: Int
    var font: Font = .subheadline

    var body: some View {
        VStack(alignment: .leading, spacing: 4) {
            ForEach(notes.prefix(maxNotes)) { note in
                HStack(alignment: .firstTextBaseline, spacing: 8) {
                    Image(systemName: "circle")
                        .font(.caption2)
                        .foregroundStyle(.secondary)
                    Text(note.title)
                        .font(font)
                        .lineLimit(1)
                    Spacer(minLength: 0)
                }
            }
            if notes.count > maxNotes {
                Text("+\(notes.count - maxNotes)")
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }
        }
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
            Spacer()
        }
    }
}

// MARK: - Home Screen Widget Views

struct SmallWidgetView: View {
    var entry: NoteEntry

    var body: some View {
        VStack(alignment: .leading, spacing: 4) {
            if entry.notes.isEmpty {
                Text("No notes")
                    .font(.body)
                    .foregroundStyle(.secondary)
            } else {
                ViewThatFits(in: .vertical) {
                    NoteList(notes: entry.notes, maxNotes: 4)
                    NoteList(notes: entry.notes, maxNotes: 3)
                    NoteList(notes: entry.notes, maxNotes: 2)
                    NoteList(notes: entry.notes, maxNotes: 1)
                }
            }

            Spacer()

            if !entry.activityData.isEmpty {
                StreakView(activityData: entry.activityData)
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .containerBackground(.fill.tertiary, for: .widget)
    }
}

struct MediumWidgetView: View {
    var entry: NoteEntry

    var body: some View {
        VStack(alignment: .leading, spacing: 4) {
            NoteList(notes: entry.notes, maxNotes: 4)

            Spacer()

            if !entry.activityData.isEmpty {
                StreakView(activityData: entry.activityData)
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .containerBackground(.fill.tertiary, for: .widget)
    }
}

struct LargeWidgetView: View {
    var entry: NoteEntry

    var body: some View {
        VStack(alignment: .leading, spacing: 4) {
            Text("enɳoté")
                .font(.headline)

            Divider()

            ViewThatFits(in: .vertical) {
                NoteList(notes: entry.notes, maxNotes: 8, font: .body)
                NoteList(notes: entry.notes, maxNotes: 7, font: .body)
                NoteList(notes: entry.notes, maxNotes: 6, font: .body)
                NoteList(notes: entry.notes, maxNotes: 5, font: .body)
                NoteList(notes: entry.notes, maxNotes: 4, font: .body)
            }

            Spacer()

            if !entry.activityData.isEmpty {
                StreakView(activityData: entry.activityData)
            }
        }
        .containerBackground(.fill.tertiary, for: .widget)
    }
}

// MARK: - Lock Screen Widget Views

struct AccessoryCircularView: View {
    var entry: NoteEntry

    var body: some View {
        ZStack {
            AccessoryWidgetBackground()
            Text("\(entry.notes.count)")
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
            Text("enɳoté: \(entry.notes.count) notes")
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
        case .systemMedium: MediumWidgetView(entry: entry)
        case .systemLarge: LargeWidgetView(entry: entry)
        case .accessoryCircular: AccessoryCircularView(entry: entry)
        case .accessoryRectangular: AccessoryRectangularView(entry: entry)
        case .accessoryInline: AccessoryInlineView(entry: entry)
        default: SmallWidgetView(entry: entry)
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

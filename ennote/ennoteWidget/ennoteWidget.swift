import WidgetKit
import SwiftUI
import SwiftData
import AppIntents

// MARK: - Timeline Entry

struct NoteEntry: TimelineEntry {
    let date: Date
    let notes: [WidgetNote]
    let timerEnd: Date?
    let activityData: [DayActivity]

    static let placeholder = NoteEntry(
        date: .now,
        notes: [
            WidgetNote(id: "1", content: "Review PR for auth flow"),
            WidgetNote(id: "2", content: "Update dependencies"),
            WidgetNote(id: "3", content: "Write tests for sync")
        ],
        timerEnd: nil,
        activityData: DayActivity.sampleData
    )

    static let empty = NoteEntry(date: .now, notes: [], timerEnd: nil, activityData: [])
}

struct DayActivity: Identifiable {
    let id = UUID()
    let date: Date
    let completedCount: Int

    var intensity: Double {
        switch completedCount {
        case 0: return 0
        case 1: return 0.25
        case 2: return 0.5
        case 3: return 0.75
        default: return 1.0
        }
    }

    var dayLetter: String {
        let formatter = DateFormatter()
        formatter.dateFormat = "EEEEE"
        return formatter.string(from: date)
    }

    static var sampleData: [DayActivity] {
        let calendar = Calendar.current
        return (0..<7).reversed().map { daysAgo in
            let date = calendar.date(byAdding: .day, value: -daysAgo, to: .now) ?? .now
            let count = [0, 1, 2, 0, 3, 1, 4][daysAgo]
            return DayActivity(date: date, completedCount: count)
        }
    }
}

struct WidgetNote: Identifiable {
    let id: String
    let content: String
}

// MARK: - Timeline Provider

struct Provider: TimelineProvider {
    func placeholder(in context: Context) -> NoteEntry {
        .placeholder
    }

    func getSnapshot(in context: Context, completion: @escaping (NoteEntry) -> Void) {
        let entry = fetchEntry()
        completion(entry)
    }

    func getTimeline(in context: Context, completion: @escaping (Timeline<NoteEntry>) -> Void) {
        let entry = fetchEntry()

        // Refresh every 15 minutes
        let nextUpdate = Calendar.current.date(byAdding: .minute, value: 15, to: .now) ?? .now
        let timeline = Timeline(entries: [entry], policy: .after(nextUpdate))
        completion(timeline)
    }

    private func fetchEntry() -> NoteEntry {
        // Fetch from shared container using NoteStore
        let (notes, activityData) = fetchNotesFromSharedContainer()
        return NoteEntry(date: .now, notes: notes, timerEnd: nil, activityData: activityData)
    }

    private func fetchNotesFromSharedContainer() -> ([WidgetNote], [DayActivity]) {
        // Access shared SwiftData container
        guard AppGroup.containerURL != nil else {
            return ([], [])
        }

        do {
            let config = ModelConfiguration(
                groupContainer: .identifier(AppGroup.identifier)
            )
            let container = try ModelContainer(for: Note.self, configurations: config)
            let context = ModelContext(container)

            // Fetch active notes
            let activeDescriptor = FetchDescriptor<Note>(
                predicate: #Predicate { !$0.isCompleted },
                sortBy: [SortDescriptor(\.order)]
            )
            let activeNotes = try context.fetch(activeDescriptor)
            let widgetNotes = activeNotes.map { WidgetNote(id: $0.id.uuidString, content: $0.content) }

            // Fetch completed notes for activity data
            let calendar = Calendar.current
            let completedDescriptor = FetchDescriptor<Note>(
                predicate: #Predicate { $0.isCompleted && $0.completedAt != nil }
            )
            let completedNotes = try context.fetch(completedDescriptor)

            // Group by day
            let activityData = (0..<7).reversed().map { daysAgo -> DayActivity in
                let date = calendar.date(byAdding: .day, value: -daysAgo, to: .now) ?? .now
                let dayStart = calendar.startOfDay(for: date)
                let dayEnd = calendar.date(byAdding: .day, value: 1, to: dayStart) ?? date

                let count = completedNotes.filter { note in
                    guard let completedAt = note.completedAt else { return false }
                    return completedAt >= dayStart && completedAt < dayEnd
                }.count

                return DayActivity(date: date, completedCount: count)
            }

            return (widgetNotes, activityData)
        } catch {
            print("Widget failed to fetch notes: \(error)")
            return ([], [])
        }
    }
}

// MARK: - Small Widget View

struct SmallWidgetView: View {
    var entry: NoteEntry

    var body: some View {
        if let note = entry.notes.first {
            VStack(alignment: .leading, spacing: 4) {
                Text(note.content)
                    .font(.system(.body, design: .rounded))
                    .lineLimit(3)

                Spacer()

                if entry.notes.count > 1 {
                    Text("\(entry.notes.count - 1) more")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }
            }
            .frame(maxWidth: .infinity, alignment: .leading)
            .containerBackground(.fill.tertiary, for: .widget)
        } else {
            Text("No notes")
                .font(.body)
                .foregroundStyle(.secondary)
                .containerBackground(.fill.tertiary, for: .widget)
        }
    }
}

// MARK: - Medium Widget View

struct MediumWidgetView: View {
    var entry: NoteEntry

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            ForEach(entry.notes.prefix(4)) { note in
                HStack(spacing: 8) {
                    Image(systemName: "circle")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                    Text(note.content)
                        .font(.subheadline)
                        .lineLimit(1)
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

struct StreakView: View {
    let activityData: [DayActivity]

    var body: some View {
        HStack(spacing: 4) {
            ForEach(activityData) { day in
                Circle()
                    .fill(day.completedCount > 0
                        ? Color.accentColor.opacity(day.intensity)
                        : Color.secondary.opacity(0.2))
                    .frame(width: 8, height: 8)
            }
        }
    }
}

// MARK: - Large Widget View

struct LargeWidgetView: View {
    var entry: NoteEntry

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            // Header
            HStack {
                Text("enɳoté")
                    .font(.headline)
                Spacer()
                if let timerEnd = entry.timerEnd {
                    Text(timerEnd, style: .timer)
                        .font(.system(.body, design: .monospaced))
                        .foregroundStyle(.secondary)
                }
            }

            // Activity streak
            if !entry.activityData.isEmpty {
                StreakView(activityData: entry.activityData)
            }

            Divider()

            // Note list
            VStack(alignment: .leading, spacing: 8) {
                ForEach(Array(entry.notes.enumerated().prefix(5)), id: \.element.id) { index, note in
                    HStack(spacing: 8) {
                        Image(systemName: index == 0 ? "circle.fill" : "circle")
                            .font(.caption)
                            .foregroundStyle(index == 0 ? Color.accentColor : .secondary)
                        Text(note.content)
                            .font(index == 0 ? .body.bold() : .body)
                            .lineLimit(1)
                            .foregroundStyle(index == 0 ? .primary : .secondary)
                    }
                }
            }

            Spacer()
        }
        .containerBackground(.fill.tertiary, for: .widget)
    }
}

// MARK: - Lock Screen Widgets

struct AccessoryCircularView: View {
    var entry: NoteEntry

    var body: some View {
        ZStack {
            AccessoryWidgetBackground()
            Text("\(entry.notes.count)")
                .font(.system(.title, design: .rounded).bold())
        }
    }
}

struct AccessoryRectangularView: View {
    var entry: NoteEntry

    var body: some View {
        if let note = entry.notes.first {
            HStack {
                Image(systemName: "circle")
                    .font(.caption2)
                Text(note.content)
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
        case .systemSmall:
            SmallWidgetView(entry: entry)
        case .systemMedium:
            MediumWidgetView(entry: entry)
        case .systemLarge:
            LargeWidgetView(entry: entry)
        case .accessoryCircular:
            AccessoryCircularView(entry: entry)
        case .accessoryRectangular:
            AccessoryRectangularView(entry: entry)
        case .accessoryInline:
            AccessoryInlineView(entry: entry)
        default:
            SmallWidgetView(entry: entry)
        }
    }
}

// MARK: - Widget Bundle

@main
struct ennoteWidgetBundle: WidgetBundle {
    var body: some Widget {
        ennoteWidget()
        if #available(iOS 17.0, *) {
            ennoteInteractiveWidget()
        }
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

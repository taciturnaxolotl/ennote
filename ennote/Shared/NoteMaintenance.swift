import SwiftData
import WidgetKit

/// One-off repair for stores that were merged through CloudKit.
///
/// Seeding the same notes onto two devices (an archive import, a restored
/// backup) gives each device rows with matching `id` values. CloudKit keys on
/// its own per-record identity, not our `id`, so it treats those rows as
/// unrelated records, uploads both, and hands every device a duplicate of each
/// note. This collapses rows that share an `id` back down to one.
nonisolated enum NoteMaintenance {
    /// Keeps one note per `id`, folding a duplicate's finished state into the
    /// survivor so a note completed on either device before the merge is not
    /// lost. Run it on a single device with the others closed: it deletes the
    /// extra rows, and those deletions sync out to CloudKit.
    @MainActor
    @discardableResult
    static func collapseDuplicates(in context: ModelContext) -> Int {
        guard let notes = try? context.fetch(FetchDescriptor<Note>()) else { return 0 }

        var survivors: [UUID: Note] = [:]
        var removed = 0
        for note in notes {
            guard let winner = survivors[note.id] else {
                survivors[note.id] = note
                continue
            }
            if note.isCompleted, !winner.isCompleted {
                winner.isCompleted = true
                winner.completedAt = note.completedAt
            }
            winner.order = min(winner.order, note.order)
            context.delete(note)
            removed += 1
        }

        if removed > 0 {
            try? context.save()
            WidgetCenter.shared.reloadAllTimelines()
        }
        return removed
    }
}

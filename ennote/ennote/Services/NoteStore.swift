import Foundation
import SwiftData
import WidgetKit

/// Shared note store for app and widgets
@MainActor
final class NoteStore {
    static let shared = NoteStore()

    private var modelContainer: ModelContainer?

    private init() {
        setupContainer()
    }

    private func setupContainer() {
        do {
            // Try App Group container first, fall back to default for personal dev accounts
            if AppGroup.containerURL != nil {
                let config = ModelConfiguration(
                    groupContainer: .identifier(AppGroup.identifier)
                )
                modelContainer = try ModelContainer(
                    for: Note.self,
                    configurations: config
                )
            } else {
                modelContainer = try ModelContainer(for: Note.self)
            }
        } catch {
            print("Failed to create ModelContainer: \(error)")
        }
    }

    /// Get all active (uncompleted) notes
    var activeNotes: [Note] {
        guard let container = modelContainer else { return [] }

        let context = container.mainContext
        let descriptor = FetchDescriptor<Note>(
            predicate: #Predicate { !$0.isCompleted },
            sortBy: [SortDescriptor(\.order)]
        )

        return (try? context.fetch(descriptor)) ?? []
    }

    /// Get count of active notes
    var activeNoteCount: Int {
        activeNotes.count
    }

    /// Complete a note by ID
    func complete(_ noteID: UUID) async {
        guard let container = modelContainer else { return }

        let context = container.mainContext
        let descriptor = FetchDescriptor<Note>(
            predicate: #Predicate { $0.id == noteID }
        )

        if let notes = try? context.fetch(descriptor),
           let note = notes.first {
            note.complete()
            try? context.save()
            WidgetCenter.shared.reloadAllTimelines()
        }
    }

    /// Complete a note by ID string (for widget intents)
    func complete(_ noteIDString: String) async {
        guard let id = UUID(uuidString: noteIDString) else { return }
        await complete(id)
    }

    /// Import notes from an array of strings
    func importNotes(_ noteContents: [String]) async {
        guard let container = modelContainer else { return }

        let context = container.mainContext
        let existingNotes = activeNotes
        let startOrder = (existingNotes.last?.order ?? -1) + 1

        for (index, content) in noteContents.enumerated() {
            let note = Note(content: content, order: startOrder + index)
            context.insert(note)
        }

        try? context.save()
        WidgetCenter.shared.reloadAllTimelines()
    }

    /// Trigger widget refresh
    func refreshWidgets() {
        WidgetCenter.shared.reloadAllTimelines()
    }
}

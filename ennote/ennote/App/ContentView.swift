import SwiftUI
import SwiftData

struct ContentView: View {
    @Environment(\.modelContext) private var modelContext
    @Environment(\.scenePhase) private var scenePhase
    @Query(filter: #Predicate<Note> { !$0.isCompleted },
           sort: \Note.order)
    private var activeNotes: [Note]

    @State private var editor: Editor?

    enum Editor: Identifiable {
        case new
        case existing(Note)

        var id: String {
            switch self {
            case .new: "new"
            case .existing(let note): note.id.uuidString
            }
        }

        var note: Note? {
            switch self {
            case .new: nil
            case .existing(let note): note
            }
        }
    }

    var body: some View {
        NavigationStack {
            NoteListView(onEditNote: { editor = .existing($0) })
                .safeAreaBar(edge: .bottom) {
                    NewNoteBar { editor = .new }
                }
        }
        .tint(Color.themeAccent)
        .sheet(item: $editor) { editor in
            NoteEditorSheet(note: editor.note) { content in
                if let note = editor.note {
                    update(note, content: content)
                } else {
                    add(content: content)
                }
            }
        }
        .task {
            recoverAbandonedDraft()
            KeyboardWarmUp.run()
            openPendingNote()
        }
        .onChange(of: scenePhase) { _, phase in
            if phase == .active { openPendingNote() }
        }
    }

    /// The app died with the editor open, so the text becomes a real note.
    private func recoverAbandonedDraft() {
        guard let draft = NoteDraft.abandoned() else { return }
        NoteDraft.clear(for: draft.id)
        NoteDraft.markClosed()

        // A note deleted mid-edit still leaves text worth keeping.
        guard let id = draft.id,
              let note = try? modelContext.fetch(
                  FetchDescriptor<Note>(predicate: #Predicate { $0.id == id })
              ).first
        else { return add(content: draft.content) }

        update(note, content: draft.content)
    }

    /// Consumes the flag the Control Center button leaves behind.
    private func openPendingNote() {
        guard AppGroup.wantsNewNote else { return }
        AppGroup.wantsNewNote = false
        editor = .new
    }

    private func add(content: String) {
        withAnimation {
            modelContext.insert(
                Note(content: content, order: (activeNotes.last?.order ?? -1) + 1)
            )
        }
        modelContext.commit()
    }

    private func update(_ note: Note, content: String) {
        withAnimation {
            note.content = content
        }
        modelContext.commit()
    }
}

#Preview {
    ContentView()
        .modelContainer(for: Note.self, inMemory: true)
}

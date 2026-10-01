import SwiftUI
import SwiftData

struct ContentView: View {
    @Environment(\.modelContext) private var modelContext
    @Query(filter: #Predicate<Note> { !$0.isCompleted },
           sort: \Note.order)
    private var activeNotes: [Note]

    @Environment(\.scenePhase) private var scenePhase
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
            NoteListView(onEditNote: { open(.existing($0)) })
                .safeAreaBar(edge: .bottom) {
                    NewNoteBar { open(.new) }
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
            NoteDraft.markClosed()
            flushExpiredDrafts()
            KeyboardWarmUp.run()
            await openRequestedNote()
        }
        .task(id: editor?.id) {
            guard editor == nil else { return }
            try? await Task.sleep(for: NoteDraft.lifetime)
            if !Task.isCancelled { flushExpiredDrafts() }
        }
        .onChange(of: scenePhase) { _, phase in
            guard phase == .active else { return }
            flushExpiredDrafts()
            Task { await openRequestedNote() }
        }
        // Matched on the host, not the whole URL: the system hands links back
        // normalised, and a stray trailing slash would fail an equality check.
        .onOpenURL { url in
            if url.scheme == AppGroup.newNoteURL.scheme, url.host == "new" { open(.new) }
        }
    }

    /// Flushing first means the editor never restores a draft that is about to
    /// be written over its note.
    private func open(_ target: Editor) {
        flushExpiredDrafts()
        editor = target
    }

    /// The Control Center button writes its request from another process, and
    /// that write can land after the app is already on screen, so the first
    /// moments are watched rather than sampled once.
    private func openRequestedNote() async {
        for _ in 0..<10 {
            if AppGroup.takeNewNoteRequest() {
                open(.new)
                return
            }
            try? await Task.sleep(for: .milliseconds(200))
        }
    }

    /// Drafts left in the editor past their reopen window become real notes.
    private func flushExpiredDrafts() {
        for draft in NoteDraft.takeExpired() {
            // A note deleted mid-edit still leaves text worth keeping.
            guard let id = draft.id,
                  let note = try? modelContext.fetch(
                      FetchDescriptor<Note>(predicate: #Predicate { $0.id == id })
                  ).first
            else {
                add(content: draft.content)
                continue
            }

            update(note, content: draft.content)
        }
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

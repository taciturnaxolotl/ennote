import SwiftUI
import SwiftData

struct NoteListView: View {
    @Environment(\.modelContext) private var modelContext
    @Query(filter: #Predicate<Note> { !$0.isCompleted },
           sort: \Note.order)
    private var activeNotes: [Note]

    @Query(filter: #Predicate<Note> { $0.isCompleted },
           sort: \Note.completedAt, order: .reverse)
    private var completedNotes: [Note]

    @Binding var showStackMode: Bool
    @State private var newNoteText = ""
    @FocusState private var isInputFocused: Bool

    var body: some View {
        List {
            // Active Notes Section
            Section {
                ForEach(activeNotes) { note in
                    NoteRow(note: note) {
                        completeNote(note)
                    }
                    .swipeActions(edge: .trailing, allowsFullSwipe: true) {
                        Button {
                            completeNote(note)
                        } label: {
                            Label("Complete", systemImage: "checkmark")
                        }
                        .tint(Color.themeAccent)
                    }
                    .swipeActions(edge: .leading, allowsFullSwipe: true) {
                        Button(role: .destructive) {
                            deleteNote(note)
                        } label: {
                            Label("Delete", systemImage: "trash")
                        }
                    }
                }
                .onMove(perform: moveNotes)

                // Add Note Field
                AddNoteField(text: $newNoteText, onSubmit: addNote)
                    .focused($isInputFocused)

            } header: {
                if !activeNotes.isEmpty {
                    HStack {
                        Text("\(activeNotes.count) notes")
                            .font(.caption)
                            .foregroundStyle(.secondary)
                        Spacer()
                        if activeNotes.count >= 2 {
                            Button("Stack Mode") {
                                showStackMode = true
                            }
                            .font(.caption)
                            .foregroundStyle(Color.themeAccent)
                        }
                    }
                    .textCase(nil)
                }
            }

            // Completed Notes Section
            if !completedNotes.isEmpty {
                Section {
                    ForEach(completedNotes.prefix(5)) { note in
                        NoteRow(note: note) {
                            uncompleteNote(note)
                        }
                        .swipeActions(edge: .trailing) {
                            Button {
                                uncompleteNote(note)
                            } label: {
                                Label("Restore", systemImage: "arrow.uturn.backward")
                            }
                            .tint(Color.themeAccent)
                        }
                        .swipeActions(edge: .leading, allowsFullSwipe: true) {
                            Button(role: .destructive) {
                                deleteNote(note)
                            } label: {
                                Label("Delete", systemImage: "trash")
                            }
                        }
                    }

                    if completedNotes.count > 5 {
                        Button("Clear completed (\(completedNotes.count))") {
                            clearCompleted()
                        }
                        .foregroundStyle(.secondary)
                        .font(.subheadline)
                    }
                } header: {
                    Text("Completed")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }
            }
        }
        .listStyle(.insetGrouped)
        .navigationTitle("enɳoté")
        .scrollDismissesKeyboard(.interactively)
        .overlay {
            if activeNotes.isEmpty && completedNotes.isEmpty {
                ContentUnavailableView {
                    Label("No Notes", systemImage: "note.text")
                } description: {
                    Text("Add your first note below or scan a QR code to import.")
                }
            }
        }
    }

    // MARK: - Actions

    private func addNote() {
        let content = newNoteText.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !content.isEmpty else { return }

        withAnimation {
            let note = Note(
                content: content,
                order: (activeNotes.last?.order ?? -1) + 1
            )
            modelContext.insert(note)
            newNoteText = ""
        }
    }

    private func completeNote(_ note: Note) {
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.65) {
            withAnimation(.snappy(duration: 0.25)) {
                note.complete()
            }
        }
    }

    private func uncompleteNote(_ note: Note) {
        let newOrder = (activeNotes.last?.order ?? -1) + 1
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.65) {
            withAnimation(.snappy(duration: 0.25)) {
                note.uncomplete()
                note.order = newOrder
            }
        }
    }

    private func deleteNote(_ note: Note) {
        withAnimation {
            modelContext.delete(note)
        }
    }

    private func moveNotes(from source: IndexSet, to destination: Int) {
        var notes = activeNotes
        notes.move(fromOffsets: source, toOffset: destination)
        for (index, note) in notes.enumerated() {
            note.order = index
        }
    }

    private func clearCompleted() {
        withAnimation {
            for note in completedNotes {
                modelContext.delete(note)
            }
        }
    }
}

#Preview {
    NavigationStack {
        NoteListView(showStackMode: .constant(false))
    }
    .modelContainer(for: Note.self, inMemory: true)
}

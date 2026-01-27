import SwiftUI
import SwiftData
import WidgetKit

private let toggleDwellTime: TimeInterval = 0.65

struct NoteListView: View {
    @Environment(\.modelContext) private var modelContext
    @Query(filter: #Predicate<Note> { !$0.isCompleted },
           sort: \Note.order)
    private var activeNotes: [Note]

    @Query(filter: #Predicate<Note> { $0.isCompleted },
           sort: \Note.completedAt, order: .reverse)
    private var completedNotes: [Note]

    @Binding var showStackMode: Bool
    @State private var editingNote: Note?
    @State private var showAddSheet = false

    var body: some View {
        List {
            // Active Notes Section
            Section {
                ForEach(activeNotes) { note in
                    NoteRow(note: note) {
                        completeNote(note)
                    } onEdit: {
                        startEditing(note)
                    }
                    .swipeActions(edge: .trailing, allowsFullSwipe: true) {
                        Button {
                            completeNote(note)
                        } label: {
                            Label("Complete", systemImage: "checkmark")
                        }
                        .tint(Color.themeAccent)
                    }
                    .swipeActions(edge: .leading, allowsFullSwipe: false) {
                        Button(role: .destructive) {
                            deleteNote(note)
                        } label: {
                            Label("Delete", systemImage: "trash")
                        }
                        Button {
                            startEditing(note)
                        } label: {
                            Label("Edit", systemImage: "pencil")
                        }
                        .tint(.blue)
                    }
                }
                .onMove(perform: moveNotes)

                // Add Note Button
                Button {
                    showAddSheet = true
                } label: {
                    HStack(spacing: 12) {
                        Image(systemName: "plus.circle.fill")
                            .foregroundStyle(Color.themeAccent)
                            .font(.title3)
                        Text("Add a note...")
                            .foregroundStyle(.secondary)
                        Spacer()
                    }
                    .padding(.vertical, 4)
                }
                .buttonStyle(.plain)

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
                        } onEdit: {
                            startEditing(note)
                        }
                        .swipeActions(edge: .trailing) {
                            Button {
                                uncompleteNote(note)
                            } label: {
                                Label("Restore", systemImage: "arrow.uturn.backward")
                            }
                            .tint(Color.themeAccent)
                        }
                        .swipeActions(edge: .leading, allowsFullSwipe: false) {
                            Button(role: .destructive) {
                                deleteNote(note)
                            } label: {
                                Label("Delete", systemImage: "trash")
                            }
                            Button {
                                startEditing(note)
                            } label: {
                                Label("Edit", systemImage: "pencil")
                            }
                            .tint(.blue)
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
        .sheet(item: $editingNote) { note in
            EditNoteSheet(note: note, onSave: { newContent in
                note.content = newContent
                WidgetCenter.shared.reloadAllTimelines()
            })
        }
        .sheet(isPresented: $showAddSheet) {
            AddNoteSheet(onAdd: { content in
                addNote(content: content)
            })
        }
    }

    // MARK: - Actions

    private func addNote(content: String) {
        let trimmed = content.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmed.isEmpty else { return }

        withAnimation {
            let note = Note(
                content: trimmed,
                order: (activeNotes.last?.order ?? -1) + 1
            )
            modelContext.insert(note)
        }
        WidgetCenter.shared.reloadAllTimelines()
    }

    private func startEditing(_ note: Note) {
        editingNote = note
    }

    private func completeNote(_ note: Note) {
        DispatchQueue.main.asyncAfter(deadline: .now() + toggleDwellTime) {
            withAnimation(.snappy(duration: 0.25)) {
                note.complete()
            }
            WidgetCenter.shared.reloadAllTimelines()
        }
    }

    private func uncompleteNote(_ note: Note) {
        let newOrder = (activeNotes.last?.order ?? -1) + 1
        DispatchQueue.main.asyncAfter(deadline: .now() + toggleDwellTime) {
            withAnimation(.snappy(duration: 0.25)) {
                note.uncomplete()
                note.order = newOrder
            }
            WidgetCenter.shared.reloadAllTimelines()
        }
    }

    private func deleteNote(_ note: Note) {
        withAnimation {
            modelContext.delete(note)
        }
        WidgetCenter.shared.reloadAllTimelines()
    }

    private func moveNotes(from source: IndexSet, to destination: Int) {
        var notes = activeNotes
        notes.move(fromOffsets: source, toOffset: destination)
        for (index, note) in notes.enumerated() {
            note.order = index
        }
        WidgetCenter.shared.reloadAllTimelines()
    }

    private func clearCompleted() {
        withAnimation {
            for note in completedNotes {
                modelContext.delete(note)
            }
        }
        WidgetCenter.shared.reloadAllTimelines()
    }
}

#Preview {
    NavigationStack {
        NoteListView(showStackMode: .constant(false))
    }
    .modelContainer(for: Note.self, inMemory: true)
}

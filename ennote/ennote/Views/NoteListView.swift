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
    let onEditNote: (Note) -> Void

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
                    .swipeActions(edge: .leading, allowsFullSwipe: true) {
                        Button {
                            completeNote(note)
                        } label: {
                            Label("Complete", systemImage: "checkmark")
                        }
                        .tint(Color.themeAccent)
                    }
                    .swipeActions(edge: .trailing, allowsFullSwipe: false) {
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
                        .swipeActions(edge: .leading, allowsFullSwipe: true) {
                            Button {
                                uncompleteNote(note)
                            } label: {
                                Label("Restore", systemImage: "arrow.uturn.backward")
                            }
                            .tint(Color.themeAccent)
                        }
                        .swipeActions(edge: .trailing, allowsFullSwipe: false) {
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
        .contentMargins(.bottom, 80, for: .scrollContent)
        .navigationTitle("enɳoté")
        .navigationBarTitleDisplayMode(.large)

        .scrollDismissesKeyboard(.interactively)
        .overlay {
            if activeNotes.isEmpty && completedNotes.isEmpty {
                ContentUnavailableView {
                    Label("No Notes", systemImage: "note.text")
                } description: {
                    Text("Drag up to add your first note.")
                }
            }
        }
    }

    // MARK: - Actions

    private func startEditing(_ note: Note) {
        onEditNote(note)
    }

    private func completeNote(_ note: Note) {
        Task {
            try? await Task.sleep(for: .seconds(toggleDwellTime))
            withAnimation(.snappy(duration: 0.25)) {
                note.complete()
            }
            WidgetCenter.shared.reloadAllTimelines()
        }
    }

    private func uncompleteNote(_ note: Note) {
        let newOrder = (activeNotes.last?.order ?? -1) + 1
        Task {
            try? await Task.sleep(for: .seconds(toggleDwellTime))
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
        NoteListView(showStackMode: .constant(false), onEditNote: { _ in })
    }
    .modelContainer(for: Note.self, inMemory: true)
}

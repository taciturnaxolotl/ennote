import SwiftUI
import SwiftData
import WidgetKit

/// How long a toggled note lingers before the change commits, leaving room to undo.
private let toggleDwellTime: Duration = .seconds(5)

struct NoteListView: View {
    @Environment(\.modelContext) private var modelContext
    @Query(filter: #Predicate<Note> { !$0.isCompleted },
           sort: \Note.order)
    private var activeNotes: [Note]

    @Query(filter: #Predicate<Note> { $0.isCompleted },
           sort: \Note.completedAt, order: .reverse)
    private var completedNotes: [Note]

    let onEditNote: (Note) -> Void

    @State private var pendingToggles: [UUID: Task<Void, Never>] = [:]
    @State private var showsDrakons = false

    /// Everything the phone knows, in the order the archive should read.
    private var archive: NoteArchive { NoteArchive(activeNotes + completedNotes) }

    var body: some View {
        List {
            Section {
                ForEach(activeNotes) { note in
                    row(for: note, completeLabel: "Complete", completeIcon: "checkmark")
                }
                .onMove(perform: moveNotes)
            }

            if !completedNotes.isEmpty {
                Section {
                    ForEach(completedNotes.prefix(5)) { note in
                        row(for: note, completeLabel: "Restore", completeIcon: "arrow.uturn.backward")
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

            Section { } footer: { drakonsFooter }
        }
        .listStyle(.insetGrouped)
        .contentMargins(.top, 0, for: .scrollContent)
        .scrollEdgeEffectStyle(.soft, for: .top)
        .navigationTitle("enɳoté")
        .toolbarTitleDisplayMode(.inlineLarge)
        .scrollDismissesKeyboard(.interactively)
        .sheet(isPresented: $showsDrakons) {
            DrakonsSheet(archive: archive)
        }
        .overlay {
            if activeNotes.isEmpty && completedNotes.isEmpty {
                ContentUnavailableView {
                    Label("No Notes", systemImage: "note.text")
                } description: {
                    Text("Tap New Note to add your first one.")
                }
            }
        }
    }

    /// Quiet enough to ignore until the day you need it, with room to clear
    /// the new note bar when the list is scrolled to the end.
    private var drakonsFooter: some View {
        Button("here be drakons") { showsDrakons = true }
            .font(.footnote)
            .foregroundStyle(.tertiary)
            .frame(maxWidth: .infinity)
            .padding(.bottom, 28)
    }

    @ViewBuilder
    private func row(for note: Note, completeLabel: String, completeIcon: String) -> some View {
        NoteRow(note: note) {
            toggle(note)
        } onEdit: {
            onEditNote(note)
        }
        .swipeActions(edge: .leading, allowsFullSwipe: true) {
            Button {
                toggle(note)
            } label: {
                Label(completeLabel, systemImage: completeIcon)
            }
            .tint(Color.themeAccent)
        }
        .swipeActions(edge: .trailing, allowsFullSwipe: true) {
            Button(role: .destructive) {
                deleteNote(note)
            } label: {
                Label("Delete", systemImage: "trash")
            }
            .tint(.red)

            Button {
                onEditNote(note)
            } label: {
                Label("Edit", systemImage: "pencil")
            }
            .tint(.blue)
        }
    }

    // MARK: - Actions

    /// Toggling twice within the dwell time cancels the change instead of applying it.
    private func toggle(_ note: Note) {
        let id = note.id

        if let pending = pendingToggles.removeValue(forKey: id) {
            pending.cancel()
            return
        }

        pendingToggles[id] = Task {
            try? await Task.sleep(for: toggleDwellTime)
            guard !Task.isCancelled, note.modelContext != nil else { return }

            withAnimation(.snappy(duration: 0.25)) {
                if note.isCompleted {
                    note.uncomplete()
                    note.order = (activeNotes.last?.order ?? -1) + 1
                } else {
                    note.complete()
                }
            }
            pendingToggles.removeValue(forKey: id)
            WidgetCenter.shared.reloadAllTimelines()
        }
    }

    private func deleteNote(_ note: Note) {
        cancelToggle(for: note)
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
                cancelToggle(for: note)
                modelContext.delete(note)
            }
        }
        WidgetCenter.shared.reloadAllTimelines()
    }

    private func cancelToggle(for note: Note) {
        pendingToggles.removeValue(forKey: note.id)?.cancel()
    }
}

#Preview {
    NavigationStack {
        NoteListView(onEditNote: { _ in })
    }
    .modelContainer(for: Note.self, inMemory: true)
}

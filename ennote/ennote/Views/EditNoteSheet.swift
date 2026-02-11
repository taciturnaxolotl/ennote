import SwiftUI

struct EditNoteSheet: View {
    let note: Note
    let onSave: (String) -> Void

    @Environment(\.dismiss) private var dismiss
    @State private var noteText: String
    @FocusState private var isFocused: Bool

    init(note: Note, onSave: @escaping (String) -> Void) {
        self.note = note
        self.onSave = onSave
        self._noteText = State(initialValue: note.content)
    }

    private var displayTitle: String {
        let lines = noteText.components(separatedBy: .newlines)
        let firstLine = lines.first?.trimmingCharacters(in: .whitespaces) ?? ""
        return firstLine.isEmpty ? "Edit Note" : firstLine
    }

    var body: some View {
        NavigationStack {
            ZStack(alignment: .topLeading) {
                StyledTextEditor(text: $noteText, onCommit: saveNote, cursorPosition: .end)
                    .focused($isFocused)

                if noteText.isEmpty {
                    Text("Title")
                        .font(.system(size: 28, weight: .bold))
                        .foregroundStyle(.tertiary)
                        .padding(.leading, 21)
                        .padding(.top, 8)
                        .allowsHitTesting(false)
                }
            }
            .navigationTitle(displayTitle)
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") {
                        dismiss()
                    }
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button("Save") {
                        saveNote()
                    }
                    .fontWeight(.semibold)
                    .disabled(noteText.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty)
                }
            }
        }
        .onAppear {
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
                isFocused = true
            }
        }
        .presentationDetents([.large])
        .presentationDragIndicator(.visible)
    }

    private func saveNote() {
        let content = noteText.trimmingCharacters(in: .whitespacesAndNewlines)
        if !content.isEmpty {
            onSave(content)
        }
        dismiss()
    }
}

#Preview {
    EditNoteSheet(note: Note(content: "Sample note"), onSave: { _ in })
}

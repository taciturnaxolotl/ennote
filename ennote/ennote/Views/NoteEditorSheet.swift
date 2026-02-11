import SwiftUI

struct NoteEditorSheet: View {
    let note: Note? // nil = new note, Note = edit mode
    let onSave: (String) -> Void
    let onCancel: () -> Void
    @Binding var selectedDetent: PresentationDetent

    @State private var noteText: String
    @State private var addedCount: Int = 0
    @FocusState private var isFocused: Bool

    init(note: Note? = nil, onSave: @escaping (String) -> Void, onCancel: @escaping () -> Void, selectedDetent: Binding<PresentationDetent>) {
        self.note = note
        self.onSave = onSave
        self.onCancel = onCancel
        self._selectedDetent = selectedDetent
        self._noteText = State(initialValue: note?.content ?? "")
    }

    private var isEditMode: Bool {
        note != nil
    }

    private var isExpanded: Bool {
        selectedDetent == .large
    }

    private var displayTitle: String {
        let lines = noteText.components(separatedBy: .newlines)
        let firstLine = lines.first?.trimmingCharacters(in: .whitespaces) ?? ""

        if isEditMode {
            return firstLine.isEmpty ? "Edit Note" : firstLine
        } else {
            if addedCount > 0 {
                return "New Note (\(addedCount))"
            }
            return firstLine.isEmpty ? "New Note" : firstLine
        }
    }

    private var hasContent: Bool {
        !noteText.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
    }

    var body: some View {
        Group {
            if isEditMode || isExpanded {
                NavigationStack {
                    ZStack(alignment: .topLeading) {
                        StyledTextEditor(
                            text: $noteText,
                            onCommit: saveNote,
                            cursorPosition: isEditMode ? .end : .start
                        )
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
                                if isEditMode {
                                    onCancel()
                                } else {
                                    cancelAndClose()
                                }
                            }
                        }
                        ToolbarItem(placement: .confirmationAction) {
                            Button("Save") {
                                saveNote()
                            }
                            .fontWeight(.semibold)
                            .disabled(!hasContent)
                        }
                    }
                }
            } else {
                VStack {
                    Spacer()
                    Text("New Note")
                        .font(.subheadline)
                        .foregroundStyle(.secondary)
                    Spacer()
                }
                .frame(maxWidth: .infinity)
                .contentShape(Rectangle())
                .onTapGesture {
                    selectedDetent = .large
                }
            }
        }
        .presentationDragIndicator(.visible)
        .presentationContentInteraction(.scrolls)
        .onChange(of: isExpanded) { _, expanded in
            if !isEditMode {
                if expanded {
                    DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
                        isFocused = true
                    }
                } else {
                    isFocused = false
                    addedCount = 0
                }
            }
        }
        .onAppear {
            if isEditMode {
                DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
                    isFocused = true
                }
            }
        }
        .onChange(of: note?.id) { oldId, newId in
            // Update text when switching between modes
            if newId != nil {
                // Switching to edit mode
                noteText = note?.content ?? ""
                addedCount = 0
                DispatchQueue.main.asyncAfter(deadline: .now() + 0.2) {
                    isFocused = true
                }
            } else if oldId != nil {
                // Switching from edit to add mode - clear the text
                noteText = ""
                addedCount = 0
                isFocused = false
            }
        }
    }

    private func saveNote() {
        let content = noteText.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !content.isEmpty else { return }

        onSave(content)

        if isEditMode {
            // After saving edit, transition to add mode
            onCancel()
        } else {
            // New note mode - clear and continue
            noteText = ""
            addedCount += 1
            isFocused = true

            let generator = UIImpactFeedbackGenerator(style: .light)
            generator.impactOccurred()
        }
    }

    private func cancelAndClose() {
        noteText = ""
        isFocused = false
        selectedDetent = .height(72)
    }
}

#Preview {
    NoteEditorSheet(onSave: { _ in }, onCancel: {}, selectedDetent: .constant(.large))
}

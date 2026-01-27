import SwiftUI

struct EditNoteSheet: View {
    let note: Note
    let onSave: (String) -> Void

    @Environment(\.dismiss) private var dismiss
    @State private var titleText: String
    @State private var bodyText: String
    @FocusState private var focusedField: Field?

    enum Field {
        case title, body
    }

    init(note: Note, onSave: @escaping (String) -> Void) {
        self.note = note
        self.onSave = onSave

        let lines = note.content.components(separatedBy: .newlines)
        self._titleText = State(initialValue: lines.first ?? "")
        self._bodyText = State(initialValue: lines.dropFirst().joined(separator: "\n"))
    }

    private var combinedContent: String {
        if bodyText.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty {
            return titleText
        }
        return titleText + "\n" + bodyText
    }

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(alignment: .leading, spacing: 8) {
                    TextField("Title", text: $titleText)
                        .font(.title2.bold())
                        .focused($focusedField, equals: .title)
                        .submitLabel(.next)
                        .onSubmit {
                            focusedField = .body
                        }

                    TextEditor(text: $bodyText)
                        .font(.body)
                        .scrollContentBackground(.hidden)
                        .focused($focusedField, equals: .body)
                        .frame(minHeight: 200)
                }
                .padding()
            }
            .navigationTitle("Edit Note")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") {
                        dismiss()
                    }
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button("Save") {
                        let content = combinedContent.trimmingCharacters(in: .whitespacesAndNewlines)
                        if !content.isEmpty {
                            onSave(content)
                        }
                        dismiss()
                    }
                    .fontWeight(.semibold)
                    .disabled(titleText.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty)
                }
            }
        }
        .onAppear {
            focusedField = .title
        }
        .presentationDetents([.large])
        .presentationDragIndicator(.visible)
    }
}

#Preview {
    EditNoteSheet(note: Note(content: "Sample note"), onSave: { _ in })
}

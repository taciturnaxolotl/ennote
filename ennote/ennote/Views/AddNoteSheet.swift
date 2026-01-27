import SwiftUI

struct AddNoteSheet: View {
    let onAdd: (String) -> Void

    @Environment(\.dismiss) private var dismiss
    @State private var titleText: String = ""
    @State private var bodyText: String = ""
    @State private var addedCount: Int = 0
    @FocusState private var focusedField: Field?

    enum Field {
        case title, body
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
            .navigationTitle(addedCount > 0 ? "Add Note (x\(addedCount))" : "Add Note")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Done") {
                        dismiss()
                    }
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button("Add") {
                        submitNote()
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

    private func submitNote() {
        let content = combinedContent.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !content.isEmpty else { return }
        onAdd(content)
        titleText = ""
        bodyText = ""
        addedCount += 1
        focusedField = .title
    }
}

#Preview {
    AddNoteSheet(onAdd: { _ in })
}

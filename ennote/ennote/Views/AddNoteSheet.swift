import SwiftUI

struct AddNoteSheet: View {
    let onAdd: (String) -> Void

    @Environment(\.dismiss) private var dismiss
    @State private var titleText: String = ""
    @State private var bodyText: String = ""
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
            VStack(alignment: .leading, spacing: 4) {
                TextField("Title", text: $titleText)
                    .font(.title2.bold())
                    .focused($focusedField, equals: .title)
                    .submitLabel(.next)
                    .onSubmit {
                        focusedField = .body
                    }

                TextField("Notes", text: $bodyText, axis: .vertical)
                    .font(.body)
                    .foregroundStyle(.secondary)
                    .focused($focusedField, equals: .body)

                Spacer()
            }
            .padding()
            .navigationTitle("Add Note")
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
        .presentationDetents([.height(200)])
        .presentationDragIndicator(.visible)
    }

    private func submitNote() {
        let content = combinedContent.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !content.isEmpty else { return }
        onAdd(content)
        titleText = ""
        bodyText = ""
        focusedField = .title
    }
}

#Preview {
    AddNoteSheet(onAdd: { _ in })
}

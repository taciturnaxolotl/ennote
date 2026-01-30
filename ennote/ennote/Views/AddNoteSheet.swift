import SwiftUI

struct AddNoteSheet: View {
    let onAdd: (String) -> Void
    @Binding var selectedDetent: PresentationDetent

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
    
    private var hasContent: Bool {
        !titleText.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
    }
    
    private var isExpanded: Bool {
        selectedDetent == .large
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
            .navigationTitle(addedCount > 0 ? "Add Note (\(addedCount))" : "Add Note")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                if isExpanded {
                    ToolbarItem(placement: .cancellationAction) {
                        Button("Cancel") {
                            cancelAndClose()
                        }
                    }
                    ToolbarItem(placement: .confirmationAction) {
                        Button("Add") {
                            submitNote()
                        }
                        .fontWeight(.semibold)
                        .disabled(!hasContent)
                    }
                }
            }
        }
        .presentationDragIndicator(.visible)
        .onTapGesture {
            if !isExpanded {
                selectedDetent = .large
            }
        }
        .onChange(of: isExpanded) { _, expanded in
            if expanded {
                focusedField = .title
            }
        }
    }

    private func submitNote() {
        let content = combinedContent.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !content.isEmpty else { return }
        onAdd(content)
        titleText = ""
        bodyText = ""
        addedCount += 1
        focusedField = .title
        
        let generator = UIImpactFeedbackGenerator(style: .light)
        generator.impactOccurred()
    }
    
    private func cancelAndClose() {
        titleText = ""
        bodyText = ""
        focusedField = nil
        selectedDetent = .height(72)
    }
}

#Preview {
    AddNoteSheet(onAdd: { _ in }, selectedDetent: .constant(.large))
}

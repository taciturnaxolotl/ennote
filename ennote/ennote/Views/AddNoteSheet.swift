import SwiftUI

struct AddNoteSheet: View {
    let onAdd: (String) -> Void
    @Binding var selectedDetent: PresentationDetent

    @State private var noteText: String = ""
    @State private var addedCount: Int = 0
    @FocusState private var isFocused: Bool

    private var displayTitle: String {
        let lines = noteText.components(separatedBy: .newlines)
        let firstLine = lines.first?.trimmingCharacters(in: .whitespaces) ?? ""
        return firstLine.isEmpty ? "New Note" : firstLine
    }

    private var hasContent: Bool {
        !noteText.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
    }

    private var isExpanded: Bool {
        selectedDetent == .large
    }

    var body: some View {
        Group {
            if isExpanded {
                NavigationStack {
                    ZStack(alignment: .topLeading) {
                        StyledTextEditor(text: $noteText, onCommit: submitNote)
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
                    .navigationTitle(addedCount > 0 ? "\(displayTitle) (\(addedCount))" : displayTitle)
                    .navigationBarTitleDisplayMode(.inline)
                    .toolbar {
                        ToolbarItem(placement: .cancellationAction) {
                            Button("Cancel") {
                                cancelAndClose()
                            }
                        }
                        ToolbarItem(placement: .confirmationAction) {
                            Button("Save") {
                                submitNote()
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
            if expanded {
                DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
                    isFocused = true
                }
            } else {
                isFocused = false
                // Reset counter when sheet closes
                addedCount = 0
            }
        }
    }

    private func submitNote() {
        let content = noteText.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !content.isEmpty else { return }
        onAdd(content)
        noteText = ""
        addedCount += 1
        isFocused = true

        let generator = UIImpactFeedbackGenerator(style: .light)
        generator.impactOccurred()
    }

    private func cancelAndClose() {
        noteText = ""
        isFocused = false
        selectedDetent = .height(72)
    }
}

#Preview {
    AddNoteSheet(onAdd: { _ in }, selectedDetent: .constant(.large))
}

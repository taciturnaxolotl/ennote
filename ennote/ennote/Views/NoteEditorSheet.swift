import SwiftUI

struct NoteEditorSheet: View {
    let note: Note? // nil = new note
    let onSave: (String) -> Void

    @Environment(\.dismiss) private var dismiss
    @State private var text: AttributedString
    @State private var selection = AttributedTextSelection()
    @State private var savedCount = 0
    @FocusState private var isFocused: Bool

    /// TextEditor insets its own text, so the placeholder has to match to line up.
    private static let padding: CGFloat = 16
    private static let textInsetX: CGFloat = 5
    private static let textInsetY: CGFloat = 8

    init(note: Note?, onSave: @escaping (String) -> Void) {
        self.note = note
        self.onSave = onSave
        _text = State(initialValue: Self.styled(AttributedString(note?.content ?? "")))
    }

    private var isEditing: Bool { note != nil }
    private var plainText: String { String(text.characters) }
    private var trimmedText: String { plainText.trimmingCharacters(in: .whitespacesAndNewlines) }

    private var displayTitle: String {
        let firstLine = plainText
            .components(separatedBy: .newlines).first?
            .trimmingCharacters(in: .whitespaces) ?? ""
        let base = firstLine.isEmpty ? (isEditing ? "Edit Note" : "New Note") : firstLine
        return savedCount > 0 ? "\(base) (\(savedCount))" : base
    }

    var body: some View {
        NavigationStack {
            TextEditor(text: $text, selection: $selection)
                .textEditorStyle(.plain)
                // Empty text has no runs to style, so the caret would fall back to
                // body metrics and sit high above the title placeholder.
                .font(.title.bold())
                .padding(.horizontal, Self.padding - Self.textInsetX)
                .focused($isFocused)
                .overlay(alignment: .topLeading) {
                    if plainText.isEmpty {
                        Text("Title")
                            .font(.title.bold())
                            .foregroundStyle(.tertiary)
                            .padding(.leading, Self.padding)
                            .padding(.top, Self.textInsetY)
                            .allowsHitTesting(false)
                    }
                }
                .navigationTitle(displayTitle)
                .toolbarTitleDisplayMode(.inline)
                .toolbar {
                    ToolbarItem(placement: .cancellationAction) {
                        Button("Cancel") { dismiss() }
                    }
                    ToolbarItem(placement: .confirmationAction) {
                        Button("Save", action: save)
                            .fontWeight(.semibold)
                            .disabled(trimmedText.isEmpty)
                    }
                }
        }
        .presentationDragIndicator(.visible)
        .sensoryFeedback(.impact(weight: .light), trigger: savedCount)
        .onChange(of: text) { text.transform(updating: &selection, body: Self.style) }
        .task { isFocused = true }
    }

    private func save() {
        guard !trimmedText.isEmpty else { return }
        onSave(trimmedText)
        savedCount += 1

        if isEditing {
            dismiss()
        } else {
            // Stay open so a burst of notes can be typed in one sitting.
            text = AttributedString()
            selection = AttributedTextSelection()
        }
    }

    // MARK: - Styling

    private static func styled(_ string: AttributedString) -> AttributedString {
        var copy = string
        style(&copy)
        return copy
    }

    /// The first line reads as a title, everything after it as body copy.
    private static func style(_ string: inout AttributedString) {
        let titleEnd = string.characters.firstIndex(of: "\n") ?? string.endIndex

        string[string.startIndex..<titleEnd].font = .title.bold()
        string[string.startIndex..<titleEnd].foregroundColor = .primary

        if titleEnd < string.endIndex {
            string[titleEnd..<string.endIndex].font = .body
            string[titleEnd..<string.endIndex].foregroundColor = .secondary
        }
    }
}

#Preview {
    Color.clear
        .sheet(isPresented: .constant(true)) {
            NoteEditorSheet(note: nil, onSave: { _ in })
        }
}

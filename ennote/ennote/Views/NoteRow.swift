import SwiftUI

struct NoteRow: View {
    let note: Note
    var onToggle: (() -> Void)?

    // Local state for immediate visual feedback
    @State private var visualCompleted: Bool?

    private var showCompleted: Bool {
        visualCompleted ?? note.isCompleted
    }

    var body: some View {
        HStack(spacing: 12) {
            // Tappable checkbox
            Button {
                // Immediate visual feedback
                visualCompleted = !showCompleted
                onToggle?()
            } label: {
                Image(systemName: showCompleted ? "checkmark.circle.fill" : "circle")
                    .foregroundStyle(showCompleted ? Color.themeAccent : .secondary)
                    .font(.title3)
                    .contentTransition(.symbolEffect(.replace))
            }
            .buttonStyle(.plain)

            // Note content
            Text(note.content)
                .font(.body)
                .foregroundStyle(showCompleted ? .tertiary : .primary)
                .lineLimit(2)

            Spacer()
        }
        .padding(.vertical, 4)
        .contentShape(Rectangle())
        .onChange(of: note.isCompleted) {
            // Reset override once model catches up
            visualCompleted = nil
        }
    }
}

#Preview {
    List {
        NoteRow(note: Note(content: "Review PR for auth flow"))
        NoteRow(note: Note(content: "Update dependencies"))
        NoteRow(note: Note(content: "Write tests for sync", isCompleted: true))
    }
}

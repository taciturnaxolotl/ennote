import SwiftUI

struct NoteRow: View {
    let note: Note
    var onToggle: (() -> Void)?

    @State private var visualCompleted: Bool?
    @State private var bounceToggle = false

    private var showCompleted: Bool {
        visualCompleted ?? note.isCompleted
    }

    var body: some View {
        HStack(spacing: 12) {
            Button {
                visualCompleted = !showCompleted
                bounceToggle.toggle()
                onToggle?()
            } label: {
                Image(systemName: showCompleted ? "checkmark.circle.fill" : "circle")
                    .foregroundStyle(showCompleted ? Color.themeAccent : .secondary)
                    .font(.title3)
                    .contentTransition(.symbolEffect(.replace))
                    .symbolEffect(.bounce, value: bounceToggle)
            }
            .buttonStyle(.plain)
            .sensoryFeedback(.impact(flexibility: .soft, intensity: 0.6), trigger: bounceToggle)

            Text(note.content)
                .font(.body)
                .foregroundStyle(showCompleted ? .tertiary : .primary)
                .lineLimit(2)

            Spacer()
        }
        .padding(.vertical, 4)
        .contentShape(Rectangle())
        .onChange(of: note.isCompleted) {
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

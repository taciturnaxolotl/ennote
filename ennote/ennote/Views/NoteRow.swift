import SwiftUI

struct NoteRow: View {
    let note: Note
    var onToggle: (() -> Void)?
    var onEdit: (() -> Void)?

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
                Image(systemName: showCompleted ? "circle.inset.filled" : "circle")
                    .foregroundStyle(showCompleted ? Color.themeAccent : .secondary)
                    .font(.title3)
                    .contentTransition(.symbolEffect(.replace))
                    .symbolEffect(.bounce, value: bounceToggle)
            }
            .buttonStyle(.plain)
            .accessibilityLabel(showCompleted ? "Mark as not done" : "Mark as done")
            .sensoryFeedback(.impact(weight: .heavy, intensity: 0.7), trigger: bounceToggle)

            Button {
                onEdit?()
            } label: {
                VStack(alignment: .leading, spacing: 2) {
                    Text(note.title)
                        .font(.body)
                        .fontWeight(.medium)
                        .foregroundStyle(showCompleted ? .tertiary : .primary)
                        .lineLimit(1)

                    if let subtitle = note.subtitle {
                        Text(subtitle)
                            .font(.subheadline)
                            .foregroundStyle(showCompleted ? .quaternary : .secondary)
                            .lineLimit(1)
                    }
                }
                .frame(maxWidth: .infinity, alignment: .leading)
                .contentShape(.rect)
            }
            .buttonStyle(.plain)
            .accessibilityHint("Opens the note for editing")
        }
        .padding(.vertical, 4)
        .onChange(of: note.isCompleted) {
            visualCompleted = nil
        }
    }
}

#Preview {
    List {
        NoteRow(note: Note(content: "Review PR for auth flow"))
        NoteRow(note: Note(content: "Update dependencies\nBump to the 2026 toolchain"))
        NoteRow(note: Note(content: "Write tests for sync", isCompleted: true))
    }
}

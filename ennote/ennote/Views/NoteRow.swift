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

    private var title: String {
        note.content.components(separatedBy: .newlines).first ?? note.content
    }

    private var bodyText: String? {
        let lines = note.content.components(separatedBy: .newlines)
        guard lines.count > 1 else { return nil }
        let rest = lines.dropFirst().joined(separator: " ").trimmingCharacters(in: .whitespaces)
        return rest.isEmpty ? nil : rest
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

            VStack(alignment: .leading, spacing: 2) {
                Text(title)
                    .font(.body)
                    .fontWeight(.medium)
                    .foregroundStyle(showCompleted ? .tertiary : .primary)
                    .lineLimit(1)

                if let body = bodyText {
                    Text(body)
                        .font(.subheadline)
                        .foregroundStyle(showCompleted ? .quaternary : .secondary)
                        .lineLimit(1)
                }
            }

            Spacer()
        }
        .padding(.vertical, 4)
        .contentShape(Rectangle())
        .onTapGesture {
            onEdit?()
        }
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

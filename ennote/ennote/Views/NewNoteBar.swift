import SwiftUI

/// The persistent bottom bar that opens the note editor.
struct NewNoteBar: View {
    let onTap: () -> Void

    var body: some View {
        Button(action: onTap) {
            HStack(spacing: 8) {
                Image(systemName: "plus.circle.fill")
                    .foregroundStyle(Color.themeAccent)
                Text("New Note")
                    .foregroundStyle(.secondary)
                    .fontWeight(.semibold)
            }
            .font(.body)
            .frame(maxWidth: .infinity)
            .padding(.vertical, 6)
            .padding(.horizontal, 4)
            .contentShape(.rect)
        }
        .buttonStyle(.glass)
        .tint(.primary)
        .padding(.horizontal)
        .accessibilityLabel("New note")
    }
}

#Preview {
    List {
        Text("A note")
    }
    .safeAreaBar(edge: .bottom) {
        NewNoteBar { }
    }
}

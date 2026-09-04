import SwiftUI

/// The persistent bottom bar that opens the note editor.
struct NewNoteBar: View {
    let onTap: () -> Void

    var body: some View {
        Button(action: onTap) {
            HStack(spacing: 8) {
                Image(systemName: "plus.circle.fill")
                Text("New Note")
                    .fontWeight(.semibold)
            }
            .font(.body)
            // Solid label: secondary would pick up the accent tint and muddy it.
            .foregroundStyle(.primary)
            .frame(maxWidth: .infinity)
            .padding(.vertical, 6)
            .padding(.horizontal, 4)
            .contentShape(.rect)
        }
        // Clear glass, tinted just enough to lift it off the list behind it.
        .buttonStyle(.glass)
        .tint(Color.themeAccent)
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

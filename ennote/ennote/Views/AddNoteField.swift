import SwiftUI

struct AddNoteField: View {
    @Binding var text: String
    var onSubmit: () -> Void

    var body: some View {
        HStack(spacing: 12) {
            Image(systemName: "plus.circle.fill")
                .foregroundStyle(Color.themeAccent)
                .font(.title3)

            TextField("Add a note...", text: $text)
                .textFieldStyle(.plain)
                .submitLabel(.done)
                .onSubmit {
                    if !text.trimmingCharacters(in: .whitespaces).isEmpty {
                        onSubmit()
                    }
                }
        }
        .padding(.vertical, 4)
    }
}

#Preview {
    List {
        AddNoteField(text: .constant(""), onSubmit: {})
        AddNoteField(text: .constant("Test note"), onSubmit: {})
    }
}

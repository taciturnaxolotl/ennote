import SwiftUI
import SwiftData
import WidgetKit

struct ContentView: View {
    @Environment(\.modelContext) private var modelContext
    @Query(filter: #Predicate<Note> { !$0.isCompleted },
           sort: \Note.order)
    private var activeNotes: [Note]

    enum Presentation: Equatable {
        case none
        case scanner
        case stackView
        case addNote(detent: PresentationDetent)

        var isAddNote: Bool {
            if case .addNote = self { return true }
            return false
        }
    }

    @State private var presentation: Presentation = .addNote(detent: .height(72))

    private var addNoteDetent: PresentationDetent {
        if case .addNote(let detent) = presentation {
            return detent
        }
        return .height(72)
    }

    var body: some View {
        NavigationStack {
            NoteListView(showStackMode: .init(
                get: { presentation == .stackView },
                set: { if $0 { presentation = .stackView } }
            ))
                .toolbar {
                    ToolbarItem(placement: .topBarLeading) {
                        Button {
                            presentation = .scanner
                        } label: {
                            Image(systemName: "qrcode.viewfinder")
                        }
                    }

                    ToolbarItem(placement: .topBarTrailing) {
                        Button {
                            presentation = .stackView
                        } label: {
                            Image(systemName: "rectangle.stack.fill")
                        }
                    }
                }
                .sheet(isPresented: .init(
                    get: { presentation == .scanner },
                    set: { if !$0 { presentation = .addNote(detent: .height(72)) } }
                )) {
                    ScannerView()
                }
                .fullScreenCover(isPresented: .init(
                    get: { presentation == .stackView },
                    set: { if !$0 {
                        presentation = .none
                        DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
                            presentation = .addNote(detent: .height(72))
                        }
                    } }
                )) {
                    StackView(isPresented: .init(
                        get: { presentation == .stackView },
                        set: { if !$0 {
                            presentation = .none
                            DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
                                presentation = .addNote(detent: .height(72))
                            }
                        } }
                    ))
                }
                .sheet(isPresented: .init(
                    get: { presentation.isAddNote },
                    set: { if !$0 { presentation = .none } }
                )) {
                    AddNoteSheet(onAdd: { content in
                        addNote(content: content)
                    }, selectedDetent: .init(
                        get: { addNoteDetent },
                        set: { presentation = .addNote(detent: $0) }
                    ))
                    .presentationDetents([.height(72), .large], selection: .init(
                        get: { addNoteDetent },
                        set: { presentation = .addNote(detent: $0) }
                    ))
                    .presentationBackgroundInteraction(.enabled(upThrough: .height(72)))
                    .interactiveDismissDisabled()
                }
        }
        .tint(Color.themeAccent)
        .onOpenURL { url in
            handleDeepLink(url)
        }
    }

    private func handleDeepLink(_ url: URL) {
        if let stackId = Stack.parseDeepLink(url) {
            // TODO: Fetch stack from CloudKit and import notes
            print("Importing stack: \(stackId)")
        }
    }

    private func addNote(content: String) {
        let trimmed = content.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmed.isEmpty else { return }

        withAnimation {
            let note = Note(
                content: trimmed,
                order: (activeNotes.last?.order ?? -1) + 1
            )
            modelContext.insert(note)
        }
        WidgetCenter.shared.reloadAllTimelines()
    }
}

#Preview {
    ContentView()
        .modelContainer(for: Note.self, inMemory: true)
}

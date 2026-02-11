import SwiftUI
import SwiftData
import WidgetKit

struct ContentView: View {
    @Environment(\.modelContext) private var modelContext
    @Query(filter: #Predicate<Note> { !$0.isCompleted },
           sort: \Note.order)
    private var activeNotes: [Note]

    enum SheetType: Equatable {
        case none
        case scanner
        case noteEditor(note: Note?, detent: PresentationDetent)

        var isNoteEditor: Bool {
            if case .noteEditor = self { return true }
            return false
        }

        static func == (lhs: SheetType, rhs: SheetType) -> Bool {
            switch (lhs, rhs) {
            case (.none, .none), (.scanner, .scanner):
                return true
            case (.noteEditor(let lNote, let lDetent), .noteEditor(let rNote, let rDetent)):
                return lNote?.id == rNote?.id && lDetent == rDetent
            default:
                return false
            }
        }
    }

    @State private var sheetType: SheetType = .noteEditor(note: nil, detent: .height(72))
    @State private var showStackView = false

    private var editorDetent: PresentationDetent {
        if case .noteEditor(_, let detent) = sheetType {
            return detent
        }
        return .height(72)
    }

    var body: some View {
        NavigationStack {
            NoteListView(
                showStackMode: $showStackView,
                onEditNote: { note in
                    sheetType = .noteEditor(note: note, detent: .large)
                }
            )
                .toolbar {
                    ToolbarItem(placement: .topBarLeading) {
                        Button {
                            sheetType = .scanner
                        } label: {
                            Image(systemName: "qrcode.viewfinder")
                        }
                    }

                    ToolbarItem(placement: .topBarTrailing) {
                        Button {
                            showStackView = true
                        } label: {
                            Image(systemName: "rectangle.stack.fill")
                        }
                    }
                }
                .sheet(isPresented: .init(
                    get: { sheetType == .scanner },
                    set: { if !$0 { sheetType = .noteEditor(note: nil, detent: .height(72)) } }
                )) {
                    ScannerView()
                }
                .fullScreenCover(isPresented: $showStackView) {
                    StackView(isPresented: $showStackView)
                }
                .onChange(of: showStackView) { _, isShowing in
                    if isShowing {
                        // Hide sheet when showing stack view
                        sheetType = .none
                    } else {
                        // Re-show collapsed sheet
                        DispatchQueue.main.asyncAfter(deadline: .now()) {
                            sheetType = .noteEditor(note: nil, detent: .height(72))
                        }
                    }
                }
                .sheet(isPresented: .init(
                    get: { sheetType.isNoteEditor },
                    set: { if !$0 { sheetType = .none } }
                )) {
                    if case .noteEditor(let note, _) = sheetType {
                        NoteEditorSheet(
                            note: note,
                            onSave: { content in
                                if let note = note {
                                    updateNote(note, content: content)
                                } else {
                                    addNote(content: content)
                                }
                            },
                            onCancel: {
                                // Transition from edit to add mode
                                sheetType = .noteEditor(note: nil, detent: .height(72))
                            },
                            selectedDetent: .init(
                                get: { editorDetent },
                                set: { newDetent in
                                    if case .noteEditor(let note, _) = sheetType {
                                        sheetType = .noteEditor(note: note, detent: newDetent)
                                    }
                                }
                            )
                        )
                        .presentationDetents(
                            [.height(72), .large],
                            selection: .init(
                                get: { editorDetent },
                                set: { newDetent in
                                    if case .noteEditor(let note, _) = sheetType {
                                        sheetType = .noteEditor(note: note, detent: newDetent)
                                    }
                                }
                            )
                        )
                        .presentationBackgroundInteraction(.enabled(upThrough: .height(72)))
                        .interactiveDismissDisabled()
                    }
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

    private func updateNote(_ note: Note, content: String) {
        let trimmed = content.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmed.isEmpty else { return }

        withAnimation {
            note.content = trimmed
        }
        WidgetCenter.shared.reloadAllTimelines()
    }
}

#Preview {
    ContentView()
        .modelContainer(for: Note.self, inMemory: true)
}

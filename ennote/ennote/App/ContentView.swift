import SwiftUI
import SwiftData
import WidgetKit

struct ContentView: View {
    @Environment(\.modelContext) private var modelContext
    @Query(filter: #Predicate<Note> { !$0.isCompleted },
           sort: \Note.order)
    private var activeNotes: [Note]

    @State private var showScanner = false
    @State private var showStackMode = false
    @State private var showAddSheet = false
    @State private var selectedDetent: PresentationDetent = .height(72)

    var body: some View {
        NavigationStack {
            NoteListView(showStackMode: $showStackMode)
                .toolbar {
                    ToolbarItem(placement: .topBarLeading) {
                        Button {
                            showScanner = true
                        } label: {
                            Image(systemName: "qrcode.viewfinder")
                        }
                    }

                    ToolbarItem(placement: .topBarTrailing) {
                        Button {
                            showStackMode = true
                        } label: {
                            Image(systemName: "rectangle.stack.fill")
                        }
                    }
                }
                .sheet(isPresented: $showScanner) {
                    ScannerView()
                }
                .fullScreenCover(isPresented: $showStackMode) {
                    StackView(isPresented: $showStackMode)
                }
                .sheet(isPresented: $showAddSheet) {
                    AddNoteSheet(onAdd: { content in
                        addNote(content: content)
                    }, selectedDetent: $selectedDetent)
                    .presentationDetents([.height(72), .large], selection: $selectedDetent)
                    .presentationBackgroundInteraction(.enabled(upThrough: .height(72)))
                    .interactiveDismissDisabled()
                }
        }
        .tint(Color.themeAccent)
        .onAppear {
            showAddSheet = true
        }
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

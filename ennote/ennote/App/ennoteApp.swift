import SwiftUI
import SwiftData

@main
struct ennoteApp: App {
    private let modelContainer: ModelContainer
    @State private var showStorageWarning: Bool

    init() {
        if let container = NoteStorage.makeContainer() {
            modelContainer = container
            _showStorageWarning = State(initialValue: false)
        } else if let fallback = NoteStorage.makeEphemeralContainer() {
            modelContainer = fallback
            _showStorageWarning = State(initialValue: true)
        } else {
            fatalError("Could not open any note storage")
        }
    }

    var body: some Scene {
        WindowGroup {
            ContentView()
                .alert("Storage Warning", isPresented: $showStorageWarning) {
                    Button("OK") { }
                } message: {
                    Text("Storage unavailable. Using temporary storage - your notes won't be saved.")
                }
        }
        .modelContainer(modelContainer)
    }
}

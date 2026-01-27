import SwiftUI
import SwiftData

@main
struct ennoteApp: App {
    let modelContainer: ModelContainer
    @State private var showStorageError = false
    @State private var storageErrorMessage = ""

    init() {
        var container: ModelContainer
        var hasError = false
        var errorMsg = ""
        
        do {
            // Try App Group container first, fall back to default for personal dev accounts
            if AppGroup.containerURL != nil {
                let config = ModelConfiguration(
                    groupContainer: .identifier(AppGroup.identifier)
                )
                container = try ModelContainer(
                    for: Note.self,
                    configurations: config
                )
            } else {
                container = try ModelContainer(for: Note.self)
            }
        } catch {
            // Log error but don't crash - use in-memory fallback
            print("Failed to configure SwiftData: \(error)")
            errorMsg = "Storage unavailable. Using temporary storage - your notes won't be saved."
            hasError = true
            
            // Fallback to in-memory storage
            do {
                container = try ModelContainer(
                    for: Note.self,
                    configurations: ModelConfiguration(isStoredInMemoryOnly: true)
                )
            } catch {
                // Last resort - this should never fail
                fatalError("Failed to create in-memory storage: \(error)")
            }
        }
        
        self.modelContainer = container
        self._showStorageError = State(initialValue: hasError)
        self._storageErrorMessage = State(initialValue: errorMsg)
    }

    var body: some Scene {
        WindowGroup {
            ContentView()
                .alert("Storage Warning", isPresented: $showStorageError) {
                    Button("OK") { }
                } message: {
                    Text(storageErrorMessage)
                }
        }
        .modelContainer(modelContainer)
    }
}

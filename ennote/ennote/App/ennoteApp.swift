import SwiftUI
import SwiftData

@main
struct ennoteApp: App {
    let modelContainer: ModelContainer

    init() {
        do {
            // Try App Group container first, fall back to default for personal dev accounts
            if AppGroup.containerURL != nil {
                let config = ModelConfiguration(
                    groupContainer: .identifier(AppGroup.identifier)
                )
                modelContainer = try ModelContainer(
                    for: Note.self,
                    configurations: config
                )
            } else {
                modelContainer = try ModelContainer(for: Note.self)
            }
        } catch {
            fatalError("Failed to configure SwiftData: \(error)")
        }
    }

    var body: some Scene {
        WindowGroup {
            ContentView()
        }
        .modelContainer(modelContainer)
    }
}

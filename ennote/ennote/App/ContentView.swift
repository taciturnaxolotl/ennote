import SwiftUI
import SwiftData

struct ContentView: View {
    @State private var selectedTab = 0
    @State private var showScanner = false
    @State private var showStackMode = false

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
}

#Preview {
    ContentView()
        .modelContainer(for: Note.self, inMemory: true)
}

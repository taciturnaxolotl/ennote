import SwiftUI
import SwiftData
import WidgetKit
import UniformTypeIdentifiers

/// The tucked-away corner: moving notes in and out of the app.
struct DrakonsSheet: View {
    let archive: NoteArchive

    @Environment(\.modelContext) private var modelContext
    @Environment(\.dismiss) private var dismiss
    @State private var exportDocument: ArchiveDocument?
    @State private var isImporting = false
    @State private var report: String?

    var body: some View {
        NavigationStack {
            List {
                Section {
                    Button {
                        exportDocument = ArchiveDocument(archive)
                    } label: {
                        Label("Export Notes", systemImage: "square.and.arrow.up")
                    }

                    Button {
                        UIPasteboard.general.string = archive.markdown
                        report = "Copied as a markdown checklist."
                    } label: {
                        Label("Copy as Markdown", systemImage: "doc.on.doc")
                    }

                    Button {
                        isImporting = true
                    } label: {
                        Label("Import Notes", systemImage: "square.and.arrow.down")
                    }
                }
            }
            .navigationTitle("here be drakons")
            .toolbarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .confirmationAction) {
                    Button("Done") { dismiss() }
                }
            }
        }
        .presentationDetents([.medium])
        .presentationDragIndicator(.visible)
        .fileExporter(
            isPresented: Binding(get: { exportDocument != nil }, set: { if !$0 { exportDocument = nil } }),
            document: exportDocument,
            contentType: .json,
            defaultFilename: archive.fileName
        ) { result in
            report = (try? result.get()) != nil ? "Saved." : "Could not save the archive."
        }
        .fileImporter(isPresented: $isImporting, allowedContentTypes: [.json]) { result in
            report = restore(from: result)
        }
        .alert(
            "enɳoté",
            isPresented: Binding(get: { report != nil }, set: { if !$0 { report = nil } }),
            presenting: report
        ) { _ in
            Button("OK") { }
        } message: { report in
            Text(report)
        }
    }

    /// The document picker writes the bytes itself, skipping the share sheet's
    /// several-second warm-up. Sharing onward is a tap away in Files.
    struct ArchiveDocument: FileDocument {
        static let readableContentTypes = [UTType.json]
        let data: Data

        init(_ archive: NoteArchive) {
            data = (try? archive.jsonData()) ?? Data()
        }

        init(configuration: ReadConfiguration) throws {
            data = configuration.file.regularFileContents ?? Data()
        }

        func fileWrapper(configuration: WriteConfiguration) throws -> FileWrapper {
            FileWrapper(regularFileWithContents: data)
        }
    }

    private func restore(from result: Result<URL, any Error>) -> String {
        do {
            let count = try NoteArchive.restore(from: result.get(), into: modelContext)
            WidgetCenter.shared.reloadAllTimelines()
            return count == 0 ? "Everything was already here." : "Restored \(count) notes."
        } catch {
            return "Could not read that file. \(error.localizedDescription)"
        }
    }
}

#Preview {
    Color.clear
        .sheet(isPresented: .constant(true)) {
            DrakonsSheet(archive: NoteArchive([]))
        }
}

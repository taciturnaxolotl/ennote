import Foundation
import SwiftData
import UniformTypeIdentifiers

/// A portable snapshot of every note.
///
/// Two builds with different bundle identifiers (the beta one and the real one)
/// get separate stores, so an archive is the bridge between them: export from
/// the old build, import into the new one. It doubles as the way notes leave
/// the phone at all, since the JSON reads fine on any desktop.
nonisolated struct NoteArchive: Codable, Sendable {
    struct Entry: Codable, Sendable {
        var id: UUID
        var content: String
        var isCompleted: Bool
        var order: Int
        var createdAt: Date
        var completedAt: Date?
    }

    /// Bumped only if the shape changes in a way an older build can't read.
    var version = 1
    var exportedAt: Date
    var notes: [Entry]

    init(version: Int = 1, exportedAt: Date = Date(), notes: [Entry]) {
        self.version = version
        self.exportedAt = exportedAt
        self.notes = notes
    }

    init(_ notes: [Note], exportedAt: Date = Date()) {
        self.init(
            exportedAt: exportedAt,
            notes: notes.map {
                Entry(
                    id: $0.id,
                    content: $0.content,
                    isCompleted: $0.isCompleted,
                    order: $0.order,
                    createdAt: $0.createdAt,
                    completedAt: $0.completedAt
                )
            }
        )
    }
}

// MARK: - Coding

nonisolated extension NoteArchive {
    private static var encoder: JSONEncoder {
        let encoder = JSONEncoder()
        encoder.outputFormatting = [.prettyPrinted, .sortedKeys]
        encoder.dateEncodingStrategy = .iso8601
        return encoder
    }

    private static var decoder: JSONDecoder {
        let decoder = JSONDecoder()
        decoder.dateDecodingStrategy = .iso8601
        return decoder
    }

    func jsonData() throws -> Data {
        try Self.encoder.encode(self)
    }

    static func decode(_ data: Data) throws -> NoteArchive {
        try decoder.decode(NoteArchive.self, from: data)
    }
}

// MARK: - Presentation

nonisolated extension NoteArchive {
    var fileName: String {
        let day = exportedAt.formatted(.iso8601.year().month().day().dateSeparator(.dash))
        return "ennote-\(day)"
    }

    /// A checklist any desktop markdown reader renders sensibly.
    var markdown: String {
        let ordered = notes.sorted {
            $0.isCompleted == $1.isCompleted ? $0.order < $1.order : !$0.isCompleted
        }
        return ordered.map { entry in
            let lines = entry.content.components(separatedBy: .newlines)
            let box = entry.isCompleted ? "- [x] " : "- [ ] "
            return ([box + (lines.first ?? "")] + lines.dropFirst().map { "      " + $0 })
                .joined(separator: "\n")
        }
        .joined(separator: "\n")
    }
}

// MARK: - Import

extension NoteArchive {
    /// Upserts by id, so importing the same archive twice is a no-op rather
    /// than a duplicate pile. Returns how many notes arrived or changed.
    @MainActor
    @discardableResult
    func restore(into context: ModelContext) throws -> Int {
        let existing = try context.fetch(FetchDescriptor<Note>())
            .reduce(into: [UUID: Note]()) { $0[$1.id] = $1 }

        var touched = 0
        for entry in notes {
            if let note = existing[entry.id] {
                guard note.content != entry.content
                        || note.isCompleted != entry.isCompleted
                        || note.order != entry.order else { continue }
                note.content = entry.content
                note.isCompleted = entry.isCompleted
                note.order = entry.order
                note.completedAt = entry.completedAt
            } else {
                context.insert(
                    Note(
                        id: entry.id,
                        content: entry.content,
                        isCompleted: entry.isCompleted,
                        order: entry.order,
                        createdAt: entry.createdAt,
                        completedAt: entry.completedAt
                    )
                )
            }
            touched += 1
        }
        try context.save()
        return touched
    }

    /// Reads a file the document picker handed back, which arrives sandboxed.
    @MainActor
    static func restore(from url: URL, into context: ModelContext) throws -> Int {
        let scoped = url.startAccessingSecurityScopedResource()
        defer { if scoped { url.stopAccessingSecurityScopedResource() } }
        return try decode(Data(contentsOf: url)).restore(into: context)
    }
}

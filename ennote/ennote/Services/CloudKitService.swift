import Foundation
import CloudKit

/// CloudKit service for syncing notes and fetching stacks
actor CloudKitService {
    static let shared = CloudKitService()

    private let container: CKContainer
    private let privateDatabase: CKDatabase
    private let publicDatabase: CKDatabase

    private init() {
        container = CKContainer(identifier: "iCloud.sh.dunkirk.ennote")
        privateDatabase = container.privateCloudDatabase
        publicDatabase = container.publicCloudDatabase
    }

    // MARK: - Stack Operations (Public DB)

    /// Fetch a stack from the public database by ID
    func fetchStack(id: String) async throws -> Stack? {
        let recordID = CKRecord.ID(recordName: id)

        do {
            let record = try await publicDatabase.record(for: recordID)
            return stackFromRecord(record)
        } catch let error as CKError where error.code == .unknownItem {
            return nil
        }
    }

    /// Mark a stack as fetched
    func markStackFetched(id: String) async throws {
        let recordID = CKRecord.ID(recordName: id)
        let record = try await publicDatabase.record(for: recordID)
        record["fetched"] = 1
        try await publicDatabase.save(record)
    }

    /// Create a stack (used by web app, included for completeness)
    func createStack(_ stack: Stack) async throws {
        let record = CKRecord(recordType: "Stack", recordID: CKRecord.ID(recordName: stack.id))
        record["notes"] = stack.notes
        record["expiresAt"] = stack.expiresAt
        record["fetched"] = stack.fetched ? 1 : 0

        try await publicDatabase.save(record)
    }

    // MARK: - Private Helpers

    private func stackFromRecord(_ record: CKRecord) -> Stack? {
        guard let notes = record["notes"] as? [String],
              let expiresAt = record["expiresAt"] as? Date else {
            return nil
        }

        let fetched = (record["fetched"] as? Int64 ?? 0) == 1

        return Stack(
            id: record.recordID.recordName,
            notes: notes,
            createdAt: record.creationDate ?? Date(),
            expiresAt: expiresAt,
            fetched: fetched
        )
    }
}

// MARK: - Note Sync (Private DB)
extension CloudKitService {
    /// Sync note to iCloud
    func syncNote(_ note: Note) async throws {
        // Note: With SwiftData + CloudKit integration via NSPersistentCloudKitContainer,
        // sync happens automatically. This method is for manual sync if needed.

        let recordID = CKRecord.ID(recordName: note.id.uuidString)
        let record = CKRecord(recordType: "Note", recordID: recordID)

        record["content"] = note.content
        record["isCompleted"] = note.isCompleted ? 1 : 0
        record["order"] = note.order
        record["createdAt"] = note.createdAt
        record["completedAt"] = note.completedAt

        try await privateDatabase.save(record)
    }

    /// Delete note from iCloud
    func deleteNote(id: UUID) async throws {
        let recordID = CKRecord.ID(recordName: id.uuidString)
        try await privateDatabase.deleteRecord(withID: recordID)
    }
}

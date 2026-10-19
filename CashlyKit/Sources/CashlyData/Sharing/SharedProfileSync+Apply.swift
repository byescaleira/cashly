import CashlyDomain
import CloudKit
import Foundation

extension SharedProfileSync {
    func applyAndConfirm(_ incoming: [(SharedRecord, CKRecord)], deleting keys: [CKRecord.ID])
        async
    {
        applying += 1
        defer { applying -= 1 }
        let deletions = keys.compactMap { SharedRecord.Key(name: $0.recordName) }
        do {
            try await store.applyShared(incoming.map(\.0), deleting: deletions)
            await confirm(incoming.map { ($0.0, $0.1.recordID, SharedZone.archive($0.1)) })
        } catch {
            CashlyMetrics.failure("applyShared", error: error)
            do { try await store.applyShared([], deleting: deletions) } catch {
                CashlyMetrics.failure("applySharedDeletions", error: error)
            }
            for (shared, record) in incoming {
                await applyOne(
                    shared, recordID: record.recordID, fields: SharedZone.archive(record))
            }
        }
        for recordID in keys {
            drop(recordID)
            unpark(recordID)
        }
        persist()
    }

    func retryParked() async {
        guard !state.parked.isEmpty else { return }
        applying += 1
        defer { applying -= 1 }
        for (key, parked) in state.parked {
            guard let zoneID = zoneID(for: parked.profileID),
                let shared = SharedRecord.Key(name: parked.name).map({
                    SharedRecord(key: $0, payload: parked.payload)
                })
            else {
                state.parked.removeValue(forKey: key)
                continue
            }
            state.parked.removeValue(forKey: key)
            await applyOne(
                shared, recordID: CKRecord.ID(recordName: parked.name, zoneID: zoneID),
                fields: parked.fields)
        }
        persist()
    }

    private func applyOne(_ shared: SharedRecord, recordID: CKRecord.ID, fields: Data) async {
        do {
            try await store.applyShared([shared], deleting: [])
            await confirm([(shared, recordID, fields)])
        } catch {
            guard let profileID = SharedZone.profileID(of: recordID.zoneID) else { return }
            fetchFailed = true
            state.parked[profileID + "/" + shared.name] = SharedSyncState.Parked(
                profileID: profileID, name: shared.name, payload: shared.payload, fields: fields)
        }
    }

    func confirm(_ applied: [(SharedRecord, CKRecord.ID, Data)]) async {
        let local = (try? await store.sharedDigests(applied.map(\.0.key))) ?? [:]
        for (shared, recordID, fields) in applied {
            guard let profileID = SharedZone.profileID(of: recordID.zoneID) else { continue }
            state.parked.removeValue(forKey: profileID + "/" + shared.name)
            let digest = local[shared.name] ?? shared.digest
            state.zones[profileID]?.records[shared.name] = SharedSyncState.Record(
                digest: digest, local: digest, fields: fields, editedAt: nil)
        }
    }

    func confirmSent(_ record: CKRecord) {
        guard let profileID = SharedZone.profileID(of: record.recordID.zoneID),
            state.zones[profileID] != nil, let shared = Self.shared(from: record)
        else { return }
        var meta = state.zones[profileID]?.records[shared.name] ?? SharedSyncState.Record()
        meta.digest = shared.digest
        meta.fields = SharedZone.archive(record)
        if meta.local == shared.digest { meta.editedAt = nil }
        state.zones[profileID]?.records[shared.name] = meta
    }

    func unpark(_ recordID: CKRecord.ID) {
        guard let profileID = SharedZone.profileID(of: recordID.zoneID) else { return }
        state.parked.removeValue(forKey: profileID + "/" + recordID.recordName)
    }

    func drop(_ recordID: CKRecord.ID) {
        guard let profileID = SharedZone.profileID(of: recordID.zoneID) else { return }
        state.zones[profileID]?.records.removeValue(forKey: recordID.recordName)
    }

    func requeue(_ recordID: CKRecord.ID, fields: Data?) {
        guard let profileID = SharedZone.profileID(of: recordID.zoneID) else { return }
        state.zones[profileID]?.records[recordID.recordName]?.fields = fields
        engine?.state.add(pendingRecordZoneChanges: [.saveRecord(recordID)])
    }

    static func shared(from record: CKRecord) -> SharedRecord? {
        guard record.recordType != CKRecord.SystemType.share,
            let key = SharedRecord.Key(name: record.recordID.recordName),
            key.kind.rawValue == record.recordType,
            let payload = record.encryptedValues[Field.payload] as? Data
        else { return nil }
        return SharedRecord(key: key, payload: payload)
    }

    static func editedAt(of record: CKRecord) -> Date {
        record.encryptedValues[Field.editedAt] as? Date ?? .distantPast
    }

    enum Field {
        static let payload = "payload"
        static let editedAt = "editedAt"
    }
}

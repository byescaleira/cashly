import CashlyDomain
import CloudKit
import Foundation

extension SharedProfileSync {
    static let coreDataZone = CKRecordZone.ID(
        zoneName: "com.apple.coredata.cloudkit.zone", ownerName: CKCurrentUserDefaultName)

    func handleEvent(_ event: CKSyncEngine.Event, syncEngine: CKSyncEngine) async {
        guard syncEngine === engine else { return }
        switch event {
        case .stateUpdate(let update):
            state.engine = update.stateSerialization
            scheduleSave()
        case .accountChange(let change):
            await handle(change)
        case .fetchedDatabaseChanges(let changes):
            await handle(changes)
        case .fetchedRecordZoneChanges(let changes):
            await apply(changes, engine: syncEngine)
        case .sentRecordZoneChanges(let sent):
            await handle(sent, engine: syncEngine)
        case .sentDatabaseChanges(let sent):
            for failure in sent.failedZoneSaves {
                sendFailed = true
                CashlyMetrics.failure("saveSharedZone", error: failure.error)
            }
        case .willFetchChanges:
            isFetching = true
            fetchFailed = false
        case .didFetchRecordZoneChanges(let fetched):
            guard let error = fetched.error else { break }
            fetchFailed = true
            CashlyMetrics.failure("fetchSharedZone", error: error)
        case .didFetchChanges:
            isFetching = false
            didFinishCycle(failed: fetchFailed)
            if !hasFetched, !fetchFailed {
                hasFetched = true
                scheduleScan(after: .zero)
            }
        case .willSendChanges:
            isSending = true
            sendFailed = false
        case .didSendChanges:
            isSending = false
            didFinishCycle(failed: sendFailed)
        default:
            break
        }
    }

    func nextFetchChangesOptions(
        _ context: CKSyncEngine.FetchChangesContext, syncEngine: CKSyncEngine
    ) async -> CKSyncEngine.FetchChangesOptions {
        guard scope == .owned, context.options.scope == .all else { return context.options }
        return CKSyncEngine.FetchChangesOptions(scope: .allExcluding([Self.coreDataZone]))
    }

    func nextRecordZoneChangeBatch(
        _ context: CKSyncEngine.SendChangesContext, syncEngine: CKSyncEngine
    ) async -> CKSyncEngine.RecordZoneChangeBatch? {
        let pending = Array(
            syncEngine.state.pendingRecordZoneChanges.filter { context.options.scope.contains($0) }
                .prefix(SharedSyncPolicy.batchSize))
        guard !pending.isEmpty else { return nil }
        var records: [CKRecord.ID: CKRecord] = [:]
        var skipped: [CKSyncEngine.PendingRecordZoneChange] = []
        for change in pending {
            guard case .saveRecord(let id) = change else { continue }
            if let record = await makeRecord(id) {
                records[id] = record
            } else {
                skipped.append(change)
            }
        }
        if !skipped.isEmpty { syncEngine.state.remove(pendingRecordZoneChanges: skipped) }
        let prepared = records
        let ready = pending.filter { !skipped.contains($0) }
        guard !ready.isEmpty else { return nil }
        return await CKSyncEngine.RecordZoneChangeBatch(pendingChanges: ready) { prepared[$0] }
    }

    private func makeRecord(_ id: CKRecord.ID) async -> CKRecord? {
        guard let profileID = SharedZone.profileID(of: id.zoneID),
            let key = SharedRecord.Key(name: id.recordName),
            let shared = try? await store.sharedRecord(key)
        else { return nil }
        let meta = state.zones[profileID]?.records[id.recordName]
        guard let editedAt = SharedSyncPolicy.outgoing(meta, currentDigest: shared.digest) else {
            return nil
        }
        let record =
            meta?.fields.flatMap(SharedZone.unarchive)
            ?? CKRecord(recordType: key.kind.rawValue, recordID: id)
        record.encryptedValues[Field.payload] = shared.payload
        record.encryptedValues[Field.editedAt] = editedAt
        return record
    }

    private func didFinishCycle(failed: Bool) {
        guard !failed else { return }
        lastSync = .now
    }

    private func handle(_ change: CKSyncEngine.Event.AccountChange) async {
        switch change.changeType {
        case .signIn: break
        case .signOut, .switchAccounts: await reset()
        @unknown default: break
        }
    }

    private func handle(_ changes: CKSyncEngine.Event.FetchedDatabaseChanges) async {
        for deletion in changes.deletions {
            guard let profileID = SharedZone.profileID(of: deletion.zoneID) else { continue }
            if scope == .owned, deletion.reason == .encryptedDataReset {
                state.zones[profileID]?.records = [:]
                engine?.state.add(pendingDatabaseChanges: [
                    .saveZone(CKRecordZone(zoneID: deletion.zoneID))
                ])
                await reconcile(only: [profileID], force: true)
            } else {
                await forget(profileID)
            }
        }
    }

    private func apply(
        _ changes: CKSyncEngine.Event.FetchedRecordZoneChanges, engine: CKSyncEngine
    ) async {
        CashlyMetrics.logger.info(
            "Sharing \(self.scope.rawValue, privacy: .public) fetched \(changes.modifications.count) changed, \(changes.deletions.count) deleted"
        )
        var incoming: [(SharedRecord, CKRecord)] = []
        for modification in changes.modifications {
            let record = modification.record
            track(record.recordID.zoneID)
            guard let profileID = SharedZone.profileID(of: record.recordID.zoneID),
                state.zones[profileID] != nil, let shared = Self.shared(from: record)
            else { continue }
            let meta = state.zones[profileID]?.records[shared.name]
            switch SharedSyncPolicy.incoming(meta, remoteEditedAt: Self.editedAt(of: record)) {
            case .keepLocal:
                requeue(record.recordID, fields: SharedZone.archive(record))
            case .apply:
                engine.state.remove(pendingRecordZoneChanges: [.saveRecord(record.recordID)])
                incoming.append((shared, record))
            }
        }
        var deleted: [CKRecord.ID] = []
        for deletion in changes.deletions {
            guard let profileID = SharedZone.profileID(of: deletion.recordID.zoneID),
                state.zones[profileID] != nil
            else { continue }
            let meta = state.zones[profileID]?.records[deletion.recordID.recordName]
            switch SharedSyncPolicy.remoteDeletion(meta) {
            case .recreate: requeue(deletion.recordID, fields: nil)
            case .deleteLocal: deleted.append(deletion.recordID)
            }
        }
        await applyAndConfirm(incoming, deleting: deleted)
    }

    private func handle(_ sent: CKSyncEngine.Event.SentRecordZoneChanges, engine: CKSyncEngine)
        async
    {
        CashlyMetrics.logger.info(
            "Sharing \(self.scope.rawValue, privacy: .public) sent \(sent.savedRecords.count) saved, \(sent.deletedRecordIDs.count) deleted, \(sent.failedRecordSaves.count) failed"
        )
        for record in sent.savedRecords { confirmSent(record) }
        for failure in sent.failedRecordSaves { await resolve(failure) }
        for recordID in sent.deletedRecordIDs { drop(recordID) }
        for (recordID, error) in sent.failedRecordDeletes where error.code == .unknownItem {
            drop(recordID)
        }
        persist()
    }

    private func resolve(_ failure: CKSyncEngine.Event.SentRecordZoneChanges.FailedRecordSave)
        async
    {
        let recordID = failure.record.recordID
        guard let profileID = SharedZone.profileID(of: recordID.zoneID),
            state.zones[profileID] != nil
        else { return }
        let meta = state.zones[profileID]?.records[recordID.recordName]
        switch failure.error.code {
        case .serverRecordChanged:
            guard let server = failure.error.serverRecord else { return }
            let shared = Self.shared(from: server)
            switch SharedSyncPolicy.conflict(
                meta, serverEditedAt: Self.editedAt(of: server), serverDigest: shared?.digest)
            {
            case .resend: requeue(recordID, fields: SharedZone.archive(server))
            case .adoptServer:
                guard let shared else { return }
                await applyAndConfirm([(shared, server)], deleting: [])
            }
        case .zoneNotFound where scope == .owned:
            engine?.state.add(pendingDatabaseChanges: [
                .saveZone(CKRecordZone(zoneID: recordID.zoneID))
            ])
            requeue(recordID, fields: nil)
        case .zoneNotFound, .userDeletedZone:
            await forget(profileID)
        case .unknownItem:
            switch SharedSyncPolicy.missingOnServer(meta) {
            case .recreate: requeue(recordID, fields: nil)
            case .deleteLocal: await applyAndConfirm([], deleting: [recordID])
            }
        case .networkFailure, .networkUnavailable, .zoneBusy, .serviceUnavailable,
            .requestRateLimited, .notAuthenticated, .accountTemporarilyUnavailable,
            .operationCancelled:
            break
        default:
            sendFailed = true
            CashlyMetrics.failure("saveSharedRecord", error: failure.error)
        }
    }
}

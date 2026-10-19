import CashlyDomain
import CloudKit
import Foundation

actor SharedProfileSync: CKSyncEngineDelegate {
    enum Scope: String, Sendable { case owned, joined }

    let scope: Scope
    let store: CashlyStore
    nonisolated let database: CKDatabase
    let stateURL: URL?
    let registry: SharedZoneRegistry
    var state: SharedSyncState
    var engine: CKSyncEngine?
    var applying = 0
    var hasFetched = false
    var isFetching = false
    var isSending = false
    var fetchFailed = false
    var sendFailed = false
    var lastSync: Date?
    private var saveTask: Task<Void, Never>?
    private var scanTask: Task<Void, Never>?

    init(
        scope: Scope, container: CKContainer, store: CashlyStore, stateURL: URL?,
        registry: SharedZoneRegistry
    ) {
        self.scope = scope
        self.store = store
        database =
            scope == .owned ? container.privateCloudDatabase : container.sharedCloudDatabase
        self.stateURL = stateURL
        self.registry = registry
        var loaded = SharedSyncState.load(from: stateURL)
        loaded.zones = loaded.zones.filter { registry.claim($0.key, for: scope) }
        state = loaded
    }

    func start() {
        guard engine == nil else { return }
        makeEngine()
        scheduleScan(after: .zero)
    }

    func stop() async {
        scanTask?.cancel()
        scanTask = nil
        guard let engine else { return }
        self.engine = nil
        await engine.cancelOperations()
        isFetching = false
        isSending = false
        persist()
    }

    func makeEngine() {
        var configuration = CKSyncEngine.Configuration(
            database: database, stateSerialization: state.engine, delegate: self)
        configuration.automaticallySync = true
        engine = CKSyncEngine(configuration)
    }

    var canReconcile: Bool { applying == 0 && (hasFetched || state.engine != nil) }

    func profileIDs() -> Set<String> { Set(state.zones.keys) }

    func zoneID(for profileID: String) -> CKRecordZone.ID? {
        state.zones[profileID].map { SharedZone.id(for: profileID, owner: $0.owner) }
    }

    func track(_ zoneID: CKRecordZone.ID) {
        guard let profileID = SharedZone.profileID(of: zoneID), state.zones[profileID] == nil,
            registry.claim(profileID, for: scope)
        else { return }
        state.zones[profileID] = SharedSyncState.Zone(owner: zoneID.ownerName)
        persist()
    }

    func create(_ profileID: String) async {
        let zoneID = SharedZone.id(for: profileID)
        track(zoneID)
        engine?.state.add(pendingDatabaseChanges: [.saveZone(CKRecordZone(zoneID: zoneID))])
        await reconcile(only: [profileID], force: true)
    }

    func deleteZone(_ profileID: String) async {
        let zoneID = SharedZone.id(for: profileID)
        await forget(profileID)
        engine?.state.add(pendingDatabaseChanges: [.deleteZone(zoneID)])
        try? await engine?.sendChanges()
    }

    func forget(_ profileID: String) async {
        if let zoneID = zoneID(for: profileID), let engine {
            let stale = engine.state.pendingRecordZoneChanges.filter {
                Self.zoneID(of: $0) == zoneID
            }
            engine.state.remove(pendingRecordZoneChanges: stale)
        }
        let wasTracked = state.zones.removeValue(forKey: profileID) != nil
        state.parked = state.parked.filter { $0.value.profileID != profileID }
        persist()
        guard wasTracked, registry.scope(of: profileID) == scope else { return }
        registry.release(profileID, from: scope)
        do { try await store.purgeShared(profileID: profileID) } catch {
            CashlyMetrics.failure("purgeShared", error: error)
        }
    }

    func fetchNow() async throws {
        try await engine?.fetchChanges()
    }

    func reconcile(only profiles: Set<String>? = nil, force: Bool = false) async {
        guard let engine else { return }
        guard force || canReconcile else {
            scheduleScan()
            return
        }
        await retryParked()
        var pending: [CKSyncEngine.PendingRecordZoneChange] = []
        var isStale = false
        for profileID in state.zones.keys where profiles?.contains(profileID) ?? true {
            guard let known = state.zones[profileID]?.known,
                let records = try? await store.sharedRecords(profileID: profileID, known: known),
                var zone = state.zones[profileID]
            else { continue }
            guard applying == 0 || force else {
                isStale = true
                continue
            }
            let current = Dictionary(
                records.map { ($0.name, $0.digest) }, uniquingKeysWith: { first, _ in first })
            let plan = SharedSyncPlan(current: current, confirmed: zone.confirmed)
            let zoneID = SharedZone.id(for: profileID, owner: zone.owner)
            for (name, digest) in current where zone.confirmed[name] == digest {
                zone.records[name]?.local = digest
                zone.records[name]?.editedAt = nil
            }
            for name in plan.saves {
                var record = zone.records[name] ?? SharedSyncState.Record()
                if record.local != current[name] {
                    record.local = current[name]
                    record.editedAt = .now
                }
                zone.records[name] = record
                pending.append(.saveRecord(CKRecord.ID(recordName: name, zoneID: zoneID)))
            }
            for name in plan.deletes {
                pending.append(.deleteRecord(CKRecord.ID(recordName: name, zoneID: zoneID)))
            }
            state.zones[profileID] = zone
        }
        if isStale { scheduleScan() }
        guard !pending.isEmpty else { return }
        engine.state.add(pendingRecordZoneChanges: pending)
        persist()
    }

    func scheduleScan(after delay: Duration = SharedSyncPolicy.scanDelay) {
        scanTask?.cancel()
        scanTask = Task { [weak self] in
            try? await Task.sleep(for: delay)
            guard !Task.isCancelled else { return }
            await self?.reconcile()
        }
    }

    func scheduleSave() {
        saveTask?.cancel()
        saveTask = Task { [weak self] in
            try? await Task.sleep(for: SharedSyncPolicy.scanDelay)
            guard !Task.isCancelled else { return }
            await self?.persist()
        }
    }

    func persist() {
        saveTask?.cancel()
        do { try state.save(to: stateURL) } catch {
            CashlyMetrics.failure("saveSharingState", error: error)
        }
    }

    func reset() async {
        for profileID in state.zones.keys {
            registry.release(profileID, from: scope)
            try? await store.purgeShared(profileID: profileID)
        }
        state = SharedSyncState()
        hasFetched = false
        persist()
        engine = nil
        makeEngine()
    }

    func status() -> SharingSyncStatus {
        let phase: SharingSyncStatus.Phase =
            isFetching || isSending ? .syncing : fetchFailed || sendFailed ? .failed : .idle
        return SharingSyncStatus(phase: phase, lastSync: lastSync)
    }

    static func zoneID(of change: CKSyncEngine.PendingRecordZoneChange) -> CKRecordZone.ID {
        switch change {
        case .saveRecord(let id), .deleteRecord(let id): id.zoneID
        @unknown default: CKRecordZone.default().zoneID
        }
    }
}

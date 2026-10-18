import Synchronization

final class SharedZoneRegistry: Sendable {
    private let scopes = Mutex<[String: SharedProfileSync.Scope]>([:])

    func claim(_ profileID: String, for scope: SharedProfileSync.Scope) -> Bool {
        scopes.withLock { values in
            if let current = values[profileID] { return current == scope }
            values[profileID] = scope
            return true
        }
    }

    func release(_ profileID: String, from scope: SharedProfileSync.Scope) {
        scopes.withLock { values in
            if values[profileID] == scope { values.removeValue(forKey: profileID) }
        }
    }

    func scope(of profileID: String) -> SharedProfileSync.Scope? {
        scopes.withLock { $0[profileID] }
    }
}

import Synchronization

public final class MemoryWebSessionStore: WebSessionStoring {
    private let storage: Mutex<[WebSession]>

    public init(_ sessions: [WebSession] = []) {
        storage = Mutex(sessions)
    }

    public func load() -> [WebSession] {
        storage.withLock { $0 }
    }

    public func save(_ sessions: [WebSession]) throws {
        storage.withLock { $0 = sessions }
    }
}

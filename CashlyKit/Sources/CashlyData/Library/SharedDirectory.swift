import Foundation
import Synchronization

final class SharedDirectory: Sendable {
    private let ids = Mutex<Set<String>>([])

    func contains(_ id: String) -> Bool { ids.withLock { $0.contains(id) } }

    func insert(_ id: String) { _ = ids.withLock { $0.insert(id) } }

    func replace(with values: [String]) { ids.withLock { $0 = Set(values) } }
}

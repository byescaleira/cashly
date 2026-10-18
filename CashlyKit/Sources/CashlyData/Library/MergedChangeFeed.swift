import CashlyDomain

struct MergedChangeFeed: StorageChangeFeed {
    let feeds: [any StorageChangeFeed]

    func changes() -> AsyncStream<StorageChange> {
        let streams = feeds.map { $0.changes() }
        return AsyncStream(bufferingPolicy: .bufferingNewest(1)) { continuation in
            let tasks = streams.map { stream in
                Task {
                    for await change in stream { continuation.yield(change) }
                }
            }
            continuation.onTermination = { _ in
                for task in tasks { task.cancel() }
            }
        }
    }
}

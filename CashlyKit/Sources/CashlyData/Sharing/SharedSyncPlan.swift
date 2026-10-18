struct SharedSyncPlan: Equatable, Sendable {
    let saves: [String]
    let deletes: [String]

    init(current: [String: String], confirmed: [String: String]) {
        saves = current.filter { confirmed[$0.key] != $0.value }.keys.sorted()
        deletes = confirmed.keys.filter { current[$0] == nil }.sorted()
    }

    var isEmpty: Bool { saves.isEmpty && deletes.isEmpty }
}

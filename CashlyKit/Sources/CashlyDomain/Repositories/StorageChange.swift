public struct StorageChange: Sendable {
    public let userID: String?
    public let isRemote: Bool

    public init(userID: String? = nil, isRemote: Bool = false) {
        self.userID = userID
        self.isRemote = isRemote
    }
}

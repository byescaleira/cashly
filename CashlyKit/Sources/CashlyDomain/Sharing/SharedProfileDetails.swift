public struct SharedProfileDetails: Hashable, Sendable {
    public let profileID: String
    public let isOwner: Bool
    public let isShared: Bool
    public let members: [ProfileMember]

    public init(profileID: String, isOwner: Bool, isShared: Bool, members: [ProfileMember]) {
        self.profileID = profileID
        self.isOwner = isOwner
        self.isShared = isShared
        self.members = members
    }

    public var owner: ProfileMember? { members.first { $0.role == .owner } }
    public var others: [ProfileMember] { members.filter { !$0.isCurrentUser } }
    public var joinedOthers: Int { others.filter { $0.status == .joined }.count }
    public var joinedCount: Int { members.filter { $0.status == .joined }.count }
    public var invitedCount: Int { members.filter { $0.status == .invited }.count }
}

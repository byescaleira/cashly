public struct ProfileMember: Identifiable, Hashable, Sendable {
    public enum Role: Sendable { case owner, member }
    public enum Status: Sendable { case invited, joined }

    public let id: String
    public let name: String
    public let contact: String?
    public let role: Role
    public let status: Status
    public let isCurrentUser: Bool

    public init(
        id: String, name: String, contact: String? = nil, role: Role, status: Status,
        isCurrentUser: Bool = false
    ) {
        self.id = id
        self.name = name
        self.contact = contact
        self.role = role
        self.status = status
        self.isCurrentUser = isCurrentUser
    }

    public var initials: String { User.initials(of: name) }
}

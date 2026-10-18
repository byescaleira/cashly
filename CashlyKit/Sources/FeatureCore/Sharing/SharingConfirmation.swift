import CashlyDomain

public enum SharingConfirmation: Identifiable, Hashable, Sendable {
    case leave(User)
    case stopSharing(User)
    case deleteForEveryone(User)
    case removeMember(ProfileMember, User)

    public var id: String {
        switch self {
        case .leave(let user): "leave." + user.id
        case .stopSharing(let user): "stop." + user.id
        case .deleteForEveryone(let user): "delete." + user.id
        case .removeMember(let member, let user): "remove." + user.id + "." + member.id
        }
    }

    public var profile: User {
        switch self {
        case .leave(let user), .stopSharing(let user), .deleteForEveryone(let user),
            .removeMember(_, let user):
            user
        }
    }
}

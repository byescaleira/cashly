public enum AvatarStyle: Int, CaseIterable, Identifiable, Sendable {
    case masculine, feminine

    public var id: Int { rawValue }

    public var title: String {
        switch self {
        case .masculine: "Masculino"
        case .feminine: "Feminino"
        }
    }

    public var photos: [String] {
        switch self {
        case .masculine: (1...50).map(String.init)
        case .feminine: (51...100).map(String.init)
        }
    }
}

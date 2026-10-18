public struct User: Identifiable, Hashable, Sendable {
    public var id: String
    public var name: String
    public var photo: ProfilePhoto
    public var isShared: Bool

    public init(id: String, name: String, photo: ProfilePhoto = .default, isShared: Bool = false) {
        self.id = id
        self.name = name
        self.photo = photo
        self.isShared = isShared
    }

    public var initials: String {
        Self.initials(of: name)
    }

    public static func initials(of name: String) -> String {
        let words = name.split(whereSeparator: \.isWhitespace)
        let picked = words.count > 1 ? [words[0], words[words.count - 1]] : words
        return picked.compactMap { word in word.first(where: \.isLetter) ?? word.first }
            .map { String($0).uppercased() }
            .joined()
    }
}

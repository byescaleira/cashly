public struct User: Identifiable, Hashable, Sendable {
    public var id: String
    public var name: String
    public var photo: String

    public init(id: String, name: String, photo: String) {
        self.id = id
        self.name = name
        self.photo = photo
    }
}

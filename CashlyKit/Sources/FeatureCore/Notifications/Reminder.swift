import Foundation

public struct Reminder: Hashable, Sendable {
    public let id: String
    public let title: String
    public let body: String
    public let components: DateComponents
    public let repeats: Bool

    public init(
        id: String, title: String, body: String, components: DateComponents, repeats: Bool = false
    ) {
        self.id = id
        self.title = title
        self.body = body
        self.components = components
        self.repeats = repeats
    }
}

import CashlyDomain

public struct CaptureActionGroup: Hashable, Sendable {
    public let suggested: CashlyDomain.Category?
    public let frequent: [CashlyDomain.Category]

    public init(suggested: CashlyDomain.Category?, frequent: [CashlyDomain.Category]) {
        self.suggested = suggested
        self.frequent = Array(frequent.filter { $0.id != suggested?.id }.prefix(2))
    }

    public var identifier: String { NotificationCategory.capture(suggesting: suggested?.id) }

    public static func groups(
        categories: [CashlyDomain.Category], frequent: [CashlyDomain.Category]
    ) -> [CaptureActionGroup] {
        [CaptureActionGroup(suggested: nil, frequent: frequent)]
            + categories.map { CaptureActionGroup(suggested: $0, frequent: frequent) }
    }
}

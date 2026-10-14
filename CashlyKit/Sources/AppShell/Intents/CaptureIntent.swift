import AppIntents
import CashlyDomain
import FeatureCore
import Foundation

public struct CaptureTransactionIntent: AppIntent {
    public static let title: LocalizedStringResource = "Capture Payment"
    public static let description = IntentDescription(
        "Saves a payment to classify later and notifies you with a category suggestion. Made for the Wallet transaction automation in Shortcuts."
    )

    @Parameter(title: "Amount")
    public var amount: Double
    @Parameter(title: "Merchant")
    public var merchant: String
    @Parameter(title: "Card")
    public var card: String?
    @Parameter(title: "Date")
    public var date: Date?
    @Parameter(
        title: "Category", description: "Suggested in the notification instead of the learned one.")
    public var category: CategoryEntity?
    @Parameter(title: "Description")
    public var summary: String?
    @Parameter(title: "Tags")
    public var tags: [TagEntity]?

    public static var parameterSummary: some ParameterSummary {
        Summary("Capture \(\.$amount) at \(\.$merchant)") {
            \.$card
            \.$date
            \.$category
            \.$summary
            \.$tags
        }
    }

    public init() {}

    @MainActor
    public func perform() async throws -> some IntentResult & ProvidesDialog {
        let (repositories, user) = try await CashlyServices.shared.workspace()
        let actions = CaptureActions(repositories: repositories, user: user)
        let result = try await actions.capture(
            amount: amount, merchant: merchant, card: card, date: date, categoryID: category?.id,
            summary: summary, tagIDs: Set((tags ?? []).map(\.id)))
        let categories = try await actions.categories()
        let notifier = CaptureNotifier()
        await notifier.register(
            categories: categories, frequent: try await actions.frequentCategories())
        if result.isNew { await notifier.notify(result.capture, categories: categories) }
        await notifier.updateBadge(pending: try await actions.pending().count)
        return .result(
            dialog:
                "\(result.capture.money.formatted) at \(result.capture.merchant) saved to classify."
        )
    }
}

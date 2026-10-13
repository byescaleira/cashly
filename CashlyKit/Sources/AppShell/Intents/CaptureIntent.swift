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

    public static var parameterSummary: some ParameterSummary {
        Summary("Capture \(\.$amount) at \(\.$merchant)") {
            \.$card
            \.$date
        }
    }

    public init() {}

    @MainActor
    public func perform() async throws -> some IntentResult & ProvidesDialog {
        let (repositories, user) = try await CashlyServices.shared.workspace()
        let actions = CaptureActions(repositories: repositories, user: user)
        let result = try await actions.capture(
            amount: amount, merchant: merchant, card: card, date: date)
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

import AppIntents
import CashlyDomain
import FeatureCore
import FeatureJourney
import Foundation

public struct AddExpenseIntent: AppIntent {
    public static let title: LocalizedStringResource = "Add Expense"
    public static let description = IntentDescription(
        "Records an expense with everything the editor has: category, description, status, date, tags, shared profiles, split and installments."
    )

    @Parameter(title: "Amount", requestValueDialog: "How much did you spend?")
    public var amount: Double
    @Parameter(title: "Category", requestValueDialog: "Which category?")
    public var category: CategoryEntity
    @Parameter(title: "Description")
    public var summary: String?
    @Parameter(title: "Status", default: .paid)
    public var status: PaymentStatusOption
    @Parameter(title: "Date")
    public var date: Date?
    @Parameter(title: "Tags")
    public var tags: [TagEntity]?
    @Parameter(title: "Shared with", optionsProvider: ParticipantOptions())
    public var participants: [ProfileEntity]?
    @Parameter(title: "Split Mode", default: .equal)
    public var splitMode: SplitModeOption
    @Parameter(
        title: "Share per Profile",
        description: "The percentage (0 to 100) or the amount each profile pays.")
    public var share: Double?
    @Parameter(title: "Installments", inclusiveRange: (1, 1200))
    public var installments: Int?
    @Parameter(
        title: "Profile", description: "Leave it empty to use the profile selected in Cashly.")
    public var profile: ProfileEntity?

    public static var parameterSummary: some ParameterSummary {
        When(\.$participants, .hasAnyValue) {
            When(\.$splitMode, .equalTo, .equal) {
                Summary(
                    "Add \(\.$amount) in \(\.$category) shared with \(\.$participants), split \(\.$splitMode)"
                ) {
                    \.$summary
                    \.$status
                    \.$date
                    \.$tags
                    \.$installments
                    \.$profile
                }
            } otherwise: {
                Summary(
                    "Add \(\.$amount) in \(\.$category) shared with \(\.$participants), split \(\.$splitMode)"
                ) {
                    \.$share
                    \.$summary
                    \.$status
                    \.$date
                    \.$tags
                    \.$installments
                    \.$profile
                }
            }
        } otherwise: {
            Summary("Add \(\.$amount) in \(\.$category)") {
                \.$summary
                \.$status
                \.$date
                \.$tags
                \.$participants
                \.$installments
                \.$profile
            }
        }
    }

    public init() {}

    @MainActor
    public func perform() async throws -> some IntentResult & ProvidesDialog {
        let request = TransactionRequest(
            kind: .expense, amount: amount, categoryID: category.id, summary: summary ?? "",
            date: date, status: status.request, tagIDs: Set((tags ?? []).map(\.id)),
            participantIDs: (participants ?? []).map(\.id), splitMode: splitMode.mode,
            share: share, installments: installments)
        if request.needsShare, splitMode == .percentage {
            throw $share.needsValueError("What percentage does each profile pay?")
        }
        if request.needsShare {
            throw $share.needsValueError("How much does each profile pay?")
        }
        let saved = try await IntentWorkspace.actions(profileID: profile?.id)
            .add(request)
        await JourneyNotifier.reviewInBackground()
        return .result(dialog: "Added \(saved.money.formatted) in \(saved.category.name).")
    }
}

public struct AddIncomeIntent: AppIntent {
    public static let title: LocalizedStringResource = "Add Income"
    public static let description = IntentDescription(
        "Records an income with category, description, status, date, tags and installments.")

    @Parameter(title: "Amount", requestValueDialog: "How much did you receive?")
    public var amount: Double
    @Parameter(title: "Category", requestValueDialog: "Which category?")
    public var category: CategoryEntity
    @Parameter(title: "Description")
    public var summary: String?
    @Parameter(title: "Status", default: .paid)
    public var status: PaymentStatusOption
    @Parameter(title: "Date")
    public var date: Date?
    @Parameter(title: "Tags")
    public var tags: [TagEntity]?
    @Parameter(title: "Installments", inclusiveRange: (1, 1200))
    public var installments: Int?
    @Parameter(
        title: "Profile", description: "Leave it empty to use the profile selected in Cashly.")
    public var profile: ProfileEntity?

    public static var parameterSummary: some ParameterSummary {
        Summary("Add income of \(\.$amount) in \(\.$category)") {
            \.$summary
            \.$status
            \.$date
            \.$tags
            \.$installments
            \.$profile
        }
    }

    public init() {}

    @MainActor
    public func perform() async throws -> some IntentResult & ProvidesDialog {
        let request = TransactionRequest(
            kind: .income, amount: amount, categoryID: category.id, summary: summary ?? "",
            date: date, status: status.request, tagIDs: Set((tags ?? []).map(\.id)),
            installments: installments)
        let saved = try await IntentWorkspace.actions(profileID: profile?.id)
            .add(request)
        await JourneyNotifier.reviewInBackground()
        return .result(
            dialog: "Added income of \(saved.money.formatted) in \(saved.category.name).")
    }
}

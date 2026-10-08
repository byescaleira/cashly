import CashlyDomain
import Foundation

public struct TransactionDraft: Hashable {
    public var categories: [CashlyDomain.Category]
    public var id: String
    public var participants: [Participant]
    public var category: CashlyDomain.Category?
    public var kind: TransactionKind
    public var amount: Double
    public var date: Date
    public var summary: String
    public var status: TransactionStatus
    public var splitMode: TransactionSplitMode?
    public var splitValue: Double?
    public var selectedTagIDs: Set<String> = []
    public var tags: [Tag]
    public var isNew: Bool
    public var installmentIsOn: Bool
    public var installmentPlan: Int

    public var canSave: Bool {
        user != nil && category != nil && (kind != .income || participants.isEmpty)
            && ((try? Money(validating: amount).minorUnits) ?? 0) > 0
            && summary.trimmingCharacters(in: .whitespacesAndNewlines).count >= 3
            && (participants.isEmpty ? true : isValidParticipants)
            && (!installmentIsOn || (1...1200).contains(installmentPlan))
    }

    public var isValidParticipants: Bool {
        guard let total = try? Money(validating: amount),
            let allocation = try? TransactionAllocation.resolve(
                total: total, participants: participants),
            let splitValue, let owner = try? Money(validating: splitValue)
        else { return false }
        return owner == allocation.owner
    }
    public var user: User? {
        category?.user
    }

    public var summaryTags: [Tag] { tags.filter { selectedTagIDs.contains($0.id) } }
    public var suggestedTags: [Tag] {
        tags.filter {
            !selectedTagIDs.contains($0.id) && TagSuggestion.matches($0.name, in: summary)
        }
    }
    private init(
        categories: [CashlyDomain.Category] = [],
        id: String = UUID().uuidString,
        participants: [Participant] = [],
        category: CashlyDomain.Category? = nil,
        kind: TransactionKind = .expense,
        amount: Double = .zero,
        date: Date = .now,
        summary: String = "",
        status: TransactionStatus = .settled,
        splitMode: TransactionSplitMode? = nil,
        splitValue: Double? = nil,
        tags: [Tag] = [],
        isNew: Bool = true,
        installmentIsOn: Bool = false,
        installmentPlan: Int = 1,
    ) {
        self.categories = categories
        self.id = id
        self.participants = participants
        self.category = category
        self.kind = kind
        self.amount = amount
        self.date = date
        self.summary = summary
        self.status = status
        self.splitMode = splitMode
        self.splitValue = splitValue
        self.tags = tags
        self.isNew = isNew
        self.installmentIsOn = installmentIsOn
        self.installmentPlan = installmentPlan
    }

    public static func new() -> TransactionDraft {
        TransactionDraft()
    }

    public static func new(category: CashlyDomain.Category, date: Date) -> TransactionDraft {
        TransactionDraft(category: category, date: date)
    }

    public static func edit(id: String) -> TransactionDraft {
        TransactionDraft(id: id, isNew: false)
    }
}

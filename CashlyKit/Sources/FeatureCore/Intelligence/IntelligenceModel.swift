import CashlyAnalytics
import CashlyAnalyticsML
import CashlyDomain
import Foundation
import Observation

@MainActor @Observable
public final class IntelligenceModel {
    private var suggestions: Suggestions?
    private var classifier: CategoryModels.Choice?
    @ObservationIgnored private var loadedUserID: String?
    @ObservationIgnored private let session: SessionModel
    @ObservationIgnored private let flags: FeatureFlags?
    @ObservationIgnored private let source: (any LedgerSource)?

    public init(
        session: SessionModel, flags: FeatureFlags? = nil, source: (any LedgerSource)? = nil
    ) {
        self.session = session
        self.flags = flags
        self.source = source
    }

    public var isEnabled: Bool {
        flags?.isOn(.intelligence) ?? FeatureFlag.intelligence.defaultValue
    }

    public var canSuggestBudget: Bool {
        isEnabled && suggestions?.canSuggestBudget == true
    }

    public var canSuggestCategory: Bool {
        isEnabled && suggestions?.canSuggestCategory == true
    }

    public struct Key: Hashable {
        let userID: String?
        let revision: String
        let isEnabled: Bool
    }

    public func key(revision: String) -> Key {
        Key(userID: session.user?.id, revision: revision, isEnabled: isEnabled)
    }

    public func load() async {
        let userID = session.user?.id
        if !isEnabled || userID != loadedUserID {
            suggestions = nil
            classifier = nil
            loadedUserID = nil
        }
        guard isEnabled, let userID else { return }
        let source = source ?? RepositoriesLedgerSource(repositories: session.repositories)
        guard let ledger = try? await source.ledger(today: .now), !Task.isCancelled else { return }
        suggestions = Suggestions(ledger: ledger)
        loadedUserID = userID
        let choice = await Self.chooseClassifier(ledger.categoryExamples)
        guard !Task.isCancelled else { return }
        classifier = choice
    }

    public func budget(categoryID: String, month: YearMonth) -> Double? {
        guard canSuggestBudget else { return nil }
        return suggestions?.budget(categoryID: categoryID, month: month).map {
            Money(minorUnits: $0).doubleValue
        }
    }

    public func category(for text: String) -> String? {
        guard canSuggestCategory else { return nil }
        return classifier?.classifier.category(for: text) ?? suggestions?.category(for: text)
    }

    @concurrent private static func chooseClassifier(_ examples: [CategoryExample]) async
        -> CategoryModels.Choice?
    {
        CategoryModels.best(for: examples)
    }
}

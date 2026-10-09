import CashlyDomain
import FeatureCore
import Foundation
import Observation

@MainActor @Observable
public final class SearchModel {
    public var text = ""
    public private(set) var transactions: [Transaction] = []
    public private(set) var isSearching = false
    public var error: CashlyError?
    @ObservationIgnored private let session: SessionModel
    @ObservationIgnored private let finance: FinanceModel

    public init(session: SessionModel, finance: FinanceModel) {
        self.session = session
        self.finance = finance
    }

    var term: String { text.trimmingCharacters(in: .whitespacesAndNewlines) }

    var categories: [CashlyDomain.Category] {
        guard !term.isEmpty else { return [] }
        return finance.allCategories.filter { $0.name.localizedStandardContains(term) }
    }

    var tags: [Tag] {
        guard !term.isEmpty else { return [] }
        return finance.allTags.filter { $0.name.localizedStandardContains(term) }
    }

    var hasResults: Bool { !transactions.isEmpty || !categories.isEmpty || !tags.isEmpty }

    var searchKey: String { (session.user?.id ?? "") + ":\(session.generation):" + term }

    public func search(debounce: Duration = .milliseconds(250)) async {
        let query = term
        guard !query.isEmpty else {
            transactions = []
            return
        }
        do { try await Task.sleep(for: debounce) } catch { return }
        isSearching = true
        defer { isSearching = false }
        do {
            let page = try await session.repositories.dashboard.page(
                query: TransactionQuery(text: query), after: nil, limit: 50)
            guard !Task.isCancelled, query == term else { return }
            transactions = page.items
        } catch is CancellationError {} catch {
            self.error = error as? CashlyError ?? .onFetch
        }
    }
}

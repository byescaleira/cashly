import CashlyDomain
import CoreSpotlight

enum CashlyIndexer {
    static func refresh(categories: [CashlyDomain.Category]) async {
        let index = CSSearchableIndex.default()
        try? await index.deleteAllSearchableItems()
        guard !categories.isEmpty else { return }
        try? await index.indexAppEntities(categories.map(CategoryEntity.init))
    }
}

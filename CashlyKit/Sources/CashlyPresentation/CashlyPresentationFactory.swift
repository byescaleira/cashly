import CashlyDomain

@MainActor
public struct CashlyPresentationFactory {
    private let dataFactory: any CashlyDataFactoryProtocol
    public init(dataFactory: any CashlyDataFactoryProtocol) { self.dataFactory = dataFactory }
    public func scoped(to userID: String?) -> Self {
        Self(dataFactory: dataFactory.scoped(to: userID))
    }
    public func makeMainViewModel(persistSelection: Bool = true) -> MainViewModel {
        MainViewModel(dataFactory: dataFactory, persistSelection: persistSelection)
    }
    public func makeCategoryViewModel(draft: CategoryDraft) -> CategoryViewModel {
        CategoryViewModel(draft: draft, dataFactory: dataFactory)
    }
    public func makeBudgetViewModel(draft: BudgetDraft) -> BudgetViewModel {
        BudgetViewModel(draft: draft, dataFactory: dataFactory)
    }
    public func makeTransactionViewModel(draft: TransactionDraft) -> TransactionViewModel {
        TransactionViewModel(draft: draft, dataFactory: dataFactory)
    }
    public func makeUserViewModel(draft: UserDraft) -> UserViewModel {
        UserViewModel(draft: draft, dataFactory: dataFactory)
    }
    public func makeTagViewModel(draft: TagDraft) -> TagViewModel {
        TagViewModel(draft: draft, dataFactory: dataFactory)
    }
}

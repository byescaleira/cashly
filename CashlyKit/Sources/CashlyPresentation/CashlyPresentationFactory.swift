import CashlyDomain

@MainActor
public struct CashlyPresentationFactory {
    private let provider: any RepositoryProvider
    private let userID: String?

    public init(provider: any RepositoryProvider, userID: String? = nil) {
        self.provider = provider
        self.userID = userID
    }

    public func scoped(to userID: String?) -> CashlyPresentationFactory {
        CashlyPresentationFactory(provider: provider, userID: userID)
    }

    private var repositories: Repositories { provider.repositories(for: userID) }

    public func makeMainViewModel(persistSelection: Bool = true) -> MainViewModel {
        MainViewModel(provider: provider, persistSelection: persistSelection)
    }

    public func makeCategoryViewModel(draft: CategoryDraft) -> CategoryViewModel {
        CategoryViewModel(draft: draft, repositories: repositories)
    }

    public func makeBudgetViewModel(draft: BudgetDraft) -> BudgetViewModel {
        BudgetViewModel(draft: draft, repositories: repositories)
    }

    public func makeTransactionViewModel(draft: TransactionDraft) -> TransactionViewModel {
        TransactionViewModel(draft: draft, repositories: repositories)
    }

    public func makeUserViewModel(draft: UserDraft) -> UserViewModel {
        UserViewModel(draft: draft, users: repositories.users)
    }

    public func makeTagViewModel(draft: TagDraft) -> TagViewModel {
        TagViewModel(draft: draft, repositories: repositories)
    }
}

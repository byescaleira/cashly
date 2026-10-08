import CashlyDomain
import Observation

@MainActor @Observable
public final class CashlySession {
    public let factory: CashlyPresentationFactory
    public let main: MainViewModel
    public let navigation: CashlyNavigation
    public let intelligence: IntelligenceViewModel
    public init(
        provider: any RepositoryProvider, intelligence: any IntelligenceService,
        persistSelection: Bool = true
    ) {
        factory = CashlyPresentationFactory(provider: provider)
        main = factory.makeMainViewModel(persistSelection: persistSelection)
        navigation = CashlyNavigation()
        self.intelligence = IntelligenceViewModel(service: intelligence)
    }
}

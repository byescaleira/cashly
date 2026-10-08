import CashlyDomain
import Observation

@MainActor @Observable
public final class CashlySession {
    public let factory: CashlyPresentationFactory
    public let main: MainViewModel
    public let navigation: CashlyNavigation
    public let intelligence: IntelligenceViewModel
    public init(
        dataFactory: any CashlyDataFactoryProtocol, intelligenceUseCase: any IntelligenceUseCase,
        persistSelection: Bool = true
    ) {
        factory = CashlyPresentationFactory(dataFactory: dataFactory)
        main = factory.makeMainViewModel(persistSelection: persistSelection)
        navigation = CashlyNavigation()
        intelligence = IntelligenceViewModel(useCase: intelligenceUseCase)
    }
}

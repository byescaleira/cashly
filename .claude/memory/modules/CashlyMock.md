# Módulo: CashlyMock

## Identidade

- **Tipo**: Mock layer — implementações in-memory dos use cases + helpers de SwiftUI Preview
- **Path**: `CashlyKit/Sources/CashlyMock/`
- **Target SPM**: `CashlyMock`
- **Arquivos Swift**: 16
- **Dependências de target**: `CashlyDomain`, `CashlyData`, `CashlyPresentation`, `CashlyResource`
- **Dependências externas**: `Ryze`
- **Linkagem inversa**: `CashlyUI` (sim, em produção condicional simulador), `CashlyTests`

## Responsabilidade aparente

- **`MockCashlyFactory`**: implementa `CashlyDataFactoryProtocol` (e provavelmente `CashlyPresentationFactoryProtocol`) com use cases mockados. Singleton via `static let shared`.
- **Mock Actors** (`Actors/`): implementações in-memory de cada `*UseCase`:
  - `MockBudgetActor`, `MockCategoryActor`, `MockTagActor`, `MockTransactionActor`, `MockUserActor`, `MockParticipantActor`, `MockAdapterActor`
- **Mock Models** (`Models/`): fixtures hard-coded em código (`MockBudget`, `MockCategory`, `MockTag`, `MockTransaction`, `MockUser`, `MockParticipant`).
- **Views** (`Views/MockModifier.swift`): `cashlyPreview()` modifier para SwiftUI previews — injeta tudo que uma view precisa para renderizar isolada.
- **Extensions**: helpers para carregar dos JSONs de `CashlyResource/Mocks/*.json`.

## Padrão de uso

```swift
struct MyScreen_Previews: PreviewProvider {
    static var previews: some View {
        MyScreen().cashlyPreview()  // injeta stores, environment, etc.
    }
}
```

E em `CashlyApp.swift:36`:
```swift
#if targetEnvironment(simulator)
.cashlyPreview()  // ← roda mock no simulator (produção)
#else
.environmentObject(...)  // ← stack real
#endif
```

## Observações / dívidas

1. **Dependência de produção em Mock**: `CashlyUI` (logo, o app em simulador) importa `CashlyMock`. É um padrão deliberado para development, mas mistura preview infra com produção.
2. **Singleton (`MockCashlyFactory.shared`)**: viola convenção-alvo "sem singletons".
3. **Mocks precisam ser mantidos em paralelo aos Actors reais**: 7 pares Actor↔MockActor, 6 pares Model↔MockModel. Drift é o risco principal.
4. **Sem `MockTests` próprios**: os mocks são exercitados indiretamente via `BudgetActorTests` e previews. Não há suite que valide que o mock se comporta como o real.

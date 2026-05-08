# Convenções de Código

## ⚠️ Convenções-alvo vs Estado atual

> Header injetado por `project-onboarder` em 2026-05-08.

Este projeto está em **migração** para as convenções abaixo. O estado atual difere
em vários pontos — ver `migration/baseline.md` (e futuro `migration/gap-analysis.md`).

Exemplos concretos de divergências hoje:

- Convenção alvo: `@Observable` + Observation framework. Estado atual: `@StateObject` + `ObservableObject` (porque `RyzeStore` é `class: ObservableObject`).
- Convenção alvo: DI por construtor, sem singletons. Estado atual: `CashlyPresentationFactory.shared` + `MockCashlyFactory.shared` em uso ativo.
- Convenção alvo: erros tipados por contexto (`NetworkError`, `RepositoryError`, ...). Estado atual: `CashlyError` único e genérico (3 cases).
- Convenção alvo: SwiftLint + swift-format + CI. Estado atual: nada disso.
- Convenção alvo: testes em todas as camadas (Domain 100%, Presentation 90%). Estado atual: 1 actor testado, 0 cobertura em Reducer/Middleware/UI.
- Convenção alvo: `String Catalog` para localização. Estado atual: strings hardcoded em inglês, `defaultLocalization: pt-BR` declarado mas não usado.

Durante a migração:
- Código **NOVO**: deve seguir 100% as convenções desta página.
- Código **EXISTENTE**: migra em ondas conforme `migration/migration-plan.md` (a ser gerado pelo `migration-planner`).
- Áreas tocadas em qualquer feature: aplicar **Boy Scout Rule** (deixar mais limpo do que achou).

---

## Nomenclatura

- Siga [Swift API Design Guidelines](https://www.swift.org/documentation/api-design-guidelines/) à risca.
- Tipos: `UpperCamelCase`. Membros: `lowerCamelCase`. Sem prefixos `_` ou `m`.
- Booleanos: `is/has/should/can` + sujeito (ex: `isEnabled`, `hasLoaded`).
- Métodos com side effect: forma imperativa (`sort()`). Sem side effect: forma com sufixo (`sorted()`).
- Protocolos: substantivo se descreve coisa (`Collection`), `-able`/`-ible` se descreve capacidade (`Equatable`).
- **Nunca** abreviar nomes (não use `mgr`, `usr`, `cfg`). Aceitos: `URL`, `ID`, `HTTP`, `UI`.

## Estrutura de Arquivo

- Um tipo público por arquivo. Tipos auxiliares privados podem coexistir.
- Nome do arquivo == nome do tipo principal.
- Ordem dentro do tipo: nested types → static → stored properties → init → computed → public methods → private methods.
- `// MARK: - Section` para separar grandes blocos.

## Formatação

- Indentação: 4 espaços. Nunca tabs.
- Largura de linha: 120 caracteres (soft), 140 (hard).
- Imports ordenados alfabeticamente, agrupados: stdlib → Apple → terceiros → internos.
- Trailing whitespace banido.

## Tipos

- **Prefira `struct` sobre `class`.** Classes apenas quando precisar de identidade,
  herança ou referência mutável compartilhada.
- **`final class` por padrão.** Herança é exceção, não regra.
- `let` sobre `var`. Imutabilidade primeiro.
- Evite `Any`/`AnyObject`. Use generics ou `some Protocol`.
- Tipos opcionais explícitos. `!` apenas em IBOutlets ou casos justificados.

## Concorrência

- `async/await` é a forma padrão. Completion handlers só em interop com APIs antigas.
- `actor` para estado mutável compartilhado.
- `@MainActor` em ViewModels, presenters e qualquer coisa que toque UI.
- `Sendable` em todos os tipos cruzando isolation boundaries.
- **Nunca** `Task { @MainActor in ... }` para "consertar warnings" sem entender.
- Use `TaskGroup` para concorrência estruturada; evite `Task.detached`.

## Erros

- Tipo `Error` por contexto, enum com cases:
  ```swift
  enum NetworkError: Error {
      case unauthorized
      case server(statusCode: Int)
      case decoding(underlying: Error)
      case offline
  }
  ```
- `throws` sobre `Result<_, Error>` em APIs novas.
- **Nunca** `try!` fora de testes (e mesmo lá, prefira `#expect(throws:)`).
- **Nunca** `try?` que engole erro silenciosamente — log no mínimo.
- Erros user-facing são separados da `Error`: tipo `UserFacingMessage` traduz internos.

## SwiftUI

- Views são **value types**, nada de heap nelas.
- `@State` apenas para estado privado da view. `@Observable` (Observation) para ViewModels.
- `@Environment` para dependências cross-cutting (themes, services).
- Evite `@StateObject`/`@ObservedObject` em código novo (use `@Observable`).
- Body deve ser idempotente e barato. Lógica pesada vai para ViewModel.
- Identidade explícita com `.id()` quando necessário, não como hack.
- Animações: `withAnimation` no trigger, não em propriedades.

## Acesso

- Default: `internal`. Promova para `public` apenas no boundary do módulo.
- `private` em tudo que não precisa ser visto fora do tipo.
- `fileprivate` raramente justificado.
- `open` apenas em frameworks com clientes externos.

## Dependency Injection

- Sempre por construtor. Nunca service locator. Nunca singleton (exceto `Logger`, `FeatureFlags`).
- Dependências expressas como **protocolos**, não tipos concretos.
- Composition root: `AppDelegate`/`@main App` ou um `Composer` dedicado.

## Testes

- **TDD quando viável**: red → green → refactor.
- Nome de teste descreve o comportamento: `test_login_withInvalidCredentials_emitsUnauthorizedError`.
  Estilo Swift Testing: `func testLogin_withInvalidCredentials_emitsUnauthorizedError()`.
- Estrutura AAA (Arrange/Act/Assert) ou Given/When/Then.
- Test doubles: Dummy / Stub / Spy / Mock / Fake.
- Cobertura mínima:
  - Domain layer: 100%
  - Data layer: 95%
  - Presentation: 90%
  - UI views: smoke tests + snapshot

## Code Review Checklist

Resposta deve ser SIM para todos:

- [ ] Cobertura de testes nova/atualizada?
- [ ] Sem `try!`, `as!`, `force unwrap` injustificado?
- [ ] Sem captura `[unowned self]` sem garantia de lifetime?
- [ ] Memory leaks possíveis foram analisados (closures, delegates)?
- [ ] Concorrência: `Sendable` correto, `@MainActor` onde precisa, sem data races?
- [ ] Erros tratados de forma significativa, não apenas `try?`?
- [ ] Acessibilidade: labels, traits, dynamic type?
- [ ] Localização: strings via String Catalog, plurais corretos?
- [ ] Performance: sem trabalho síncrono pesado em main, sem retain de imagens grandes?
- [ ] Segurança: secrets fora do código, validação de input, ATS estrito?
- [ ] Documentação DocC em APIs públicas?
- [ ] Mudança arquitetural significativa → ADR criado?
- [ ] Testes rodam em < 1s cada (unit) e < 30s suite total?

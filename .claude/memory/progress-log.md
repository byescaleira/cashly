## 2026-05-08 — Wave 0 Partial (Rede de Segurança)

**Tipo**: chore (migration)
**Módulos**: CI, infra, CashlyKit
**Resumo**: Wave 0 entregue parcialmente (commit 22f6034). CI configurada com xcodebuild, SwiftLint/swift-format/editorconfig adicionados, pre-commit hook instalado, Ryze pinado em commit 15b047569b, SWIFT_VERSION bumped de 5 para 6 no app target. Smoke tests e snapshot tests deferidos para Wave 1.
**Impacto**: Build estável em máquina limpa (Ryze pin resolve divergência upstream), CI operacional, lint baseline estabelecido. Cobertura ainda baixa — G027 bloqueia testes automatizados via SPM CLI.
**ADR**: `.claude/memory/adr/0001-adopt-apple-dev-setup.md`
**PRs**: commit 22f6034
**Aprendizados**: Upstream Ryze foi renomeado para Prism em commit c0981be — `swift test` CLI quebra em CashlyResource por falta de explicit imports de Foundation/SwiftUI e por asset catalog não-bundled em pacote SPM. Xcode mascara o problema via implicit imports. Decisão: CI usa xcodebuild; migração Ryze→Prism mantida em Wave 5. Novos gaps descobertos: G026 (Ryze upstream rename), G027 (SPM CLI broken), G028 (xcbeautify install).

## 2026-05-08 — Onboarding + Migration Plan

**Tipo**: chore
**Módulos**: configuração / memória / migration plan
**Resumo**: `project-onboarder` rodou discovery completo (122 arquivos Swift, 11.201 linhas, 6 targets SPM) e populou `.claude/memory/`. `migration-planner` produziu gap-analysis (24 gaps: 7 críticos, 11 importantes, 6 nice-to-have) e migration-plan (9 ondas, Wave 5 fatiada em 5a/5b/5c/5d).
**Impacto**: Time tem agora um baseline imutável (`migration/baseline.md`), gap analysis priorizado (`migration/gap-analysis.md`) e plano de ondas executável (`migration/migration-plan.md`). Migração Ryze→Prism está mapeada com 8 decisões humanas pendentes que bloqueiam Wave 5.
**ADR**: `.claude/memory/adr/0001-adopt-apple-dev-setup.md`
**PRs**: —
**Aprendizados**: Arquitetura real é Redux/TCA via Ryze (não MV-@Observable como diretriz-alvo). Prism local existe com mapeamento parcial — UI exigirá reescrita por call site. Domain viola Dependency Rule (importa SwiftData/SwiftUI diretamente). Cobertura de testes ~0% fora de BudgetActorTests. Zero infra de qualidade presente (sem SwiftLint, sem CI).

# Release process

Cada **onda** termina com:

1. **Build + test green**
   - `cd CashlyKit && swift build`
   - `cd CashlyKit && swift test --parallel`
   - `xcodebuild -project Cashly/Cashly.xcodeproj -scheme Production -sdk iphonesimulator build`

2. **Code review** (subagent `swift-reviewer`)
   - Roda sobre diff da onda
   - Bloqueia release se severidade **blocker**
   - Issues **major/minor** logados em `progress-log.md` para follow-up

3. **Commit** com conventional commit message
   - Tipo: `feat` / `fix` / `refactor` / `perf` / `chore` / `docs` / `test` / `i18n`
   - Escopo opcional: `feat(ui):`, `fix(data):`
   - Co-Authored-By line obrigatória

4. **Tag + release** via `./scripts/release.sh`
   - Bumpa semver baseado na natureza da onda:
     - **major** — breaking API change (raro)
     - **minor** — feature nova (`feat`)
     - **patch** — fix/refactor/perf/docs/chore
   - `gh release create` com changelog auto

5. **Progress-log entry** em `.claude/memory/progress-log.md`

## Convenção semver

- Pre-1.0 (`0.x.y`): minor=feature, patch=tudo mais
- Pos-1.0: major reservado para breaking

## Exemplos

```bash
# Patch release (fix wave)
./scripts/release.sh patch

# Minor release (feature wave)
./scripts/release.sh minor

# Dry-run preview
./scripts/release.sh --dry-run minor

# Explicit version
./scripts/release.sh 0.5.0
```

## Bypass

Emergência push sem hook:
```bash
touch .git/SKIP_PRE_PUSH
git push
rm .git/SKIP_PRE_PUSH
```

NÃO bypass review — review é gate de qualidade, não convenience.

## Quando NÃO release

- Onda apenas planning/memory (sem código)
- Onda deferida (skip)
- Multiple ondas batched no mesmo commit (raro)

## Falha de release

Se `gh release create` falhar:
1. Deletar tag local: `git tag -d vX.Y.Z`
2. Deletar tag remota: `git push origin :refs/tags/vX.Y.Z`
3. Resolver causa raiz
4. Re-rodar script

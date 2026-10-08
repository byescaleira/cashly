# Lint e formatação

Execute `scripts/lint.sh` na raiz do projeto. O comando verifica primeiro a formatação com o `swift-format` da Apple e depois executa o SwiftLint em modo estrito: qualquer violação retorna erro e bloqueia o job de compilação no CI. Para corrigir apenas a formatação, execute `scripts/format.sh`.

O escopo inclui o app em `Cashly/Cashly`, todos os módulos em `CashlyKit/Sources`, os testes em `CashlyKit/Tests` e o manifesto `CashlyKit/Package.swift`. Caches, dependências e arquivos do Xcode ficam fora dessa seleção. O lint não altera os fontes automaticamente.

`.swift-format` controla indentação, espaçamento, quebra de linhas e ordenação de imports. `.swiftlint.yml` seleciona 24 regras de segurança e uso de APIs e a regra própria `no_comments`, que proíbe comentários em código Swift (a única exceção é `// swift-tools-version` no manifesto). As regras incluem:

- Cast, `try`, unwrap e optional implicitamente forçados.
- Condições, casos de enum, imports e chaves de dicionário duplicados.
- Operandos idênticos e parâmetros/valores ignorados em closures, bindings e setters.
- Observadores de notificações descartados e uso inadequado de delegates.
- Tasks que descartam erros, chamadas indevidas de métodos de superclass e supressões amplas do próprio lint.

As regras de compatibilidade de anotações com Swift 5 não fazem parte desta configuração: o pacote utiliza Swift 6.2. As verificações de concorrência do compilador permanecem ativas.

`scripts/install-swiftlint.sh` fixa a versão 0.65.1 e o SHA-256 do arquivo `portable_swiftlint.zip` da [distribuição oficial](https://github.com/realm/SwiftLint/releases/tag/0.65.1). O download ocorre apenas na primeira instalação; o executável e o cache ficam em `.tools`, ignorado pelo Git. Não é necessário instalar SwiftLint globalmente nem alterar as dependências do app. Esse instalador é destinado ao macOS, inclusive ao runner `xcode-27` utilizado pelo CI.

Para atualizar a ferramenta, altere juntos a versão e o checksum no instalador, revise as regras disponíveis e execute o lint antes de enviar a mudança. O formato de configuração está documentado no [SwiftLint](https://github.com/realm/SwiftLint#configuration).

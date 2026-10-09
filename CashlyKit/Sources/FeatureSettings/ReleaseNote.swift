struct ReleaseNote: Identifiable {
    let symbol: String
    let title: String
    let detail: String

    var id: String { title }

    static let current = [
        ReleaseNote(
            symbol: "gearshape", title: "Ajustes",
            detail: "Tema, ícone e moeda do app em um só lugar, pelo menu do seu avatar."),
        ReleaseNote(
            symbol: "externaldrive", title: "Backup e planilha",
            detail:
                "Exporte e importe seus dados, gere uma planilha das transações e ligue o backup automático semanal."
        ),
        ReleaseNote(
            symbol: "bell", title: "Lembretes",
            detail: "Avisos no dia das contas a pagar e a receber e no início de cada mês."),
        ReleaseNote(
            symbol: "rectangle.split.2x1", title: "Telas em colunas",
            detail: "No iPad e no Mac, o Início e as categorias aproveitam a largura da tela."),
    ]
}

import FeatureCore
import SwiftUI

struct TutorialPage: Identifiable {
    let id = UUID()
    let example: TutorialExample
    let title: LocalizedStringKey
    let message: LocalizedStringKey
}

extension Guide {
    var pages: [TutorialPage] {
        switch self {
        case .tour:
            [
                TutorialPage(
                    example: .month, title: "Início",
                    message:
                        "O resumo do mês: quanto entrou, quanto saiu, a pontuação e quanto ainda dá para gastar."
                ),
                TutorialPage(
                    example: .history, title: "Histórico",
                    message:
                        "Todas as entradas e saídas, por dia. Toque em + para registrar e deslize para editar."
                ),
                TutorialPage(
                    example: .budgetPace, title: "Metas",
                    message:
                        "Orçamentos e categorias. Defina quanto quer gastar e acompanhe o ritmo do mês."
                ),
                TutorialPage(
                    example: .search, title: "Buscar",
                    message: "Encontre qualquer transação, categoria ou tag, de qualquer mês."),
            ]
        case .budgets:
            [
                TutorialPage(
                    example: .budget,
                    title: "Um orçamento por categoria",
                    message:
                        "Em Metas, toque em + e escolha a categoria, o mês e o valor."
                ),
                TutorialPage(
                    example: .budgetPace,
                    title: "Acompanhe o ritmo",
                    message:
                        "As barras mostram o uso: verde no caminho, mostarda perto do limite, ferrugem acima do planejado."
                ),
                TutorialPage(
                    example: .score, title: "Pontuação de saúde",
                    message:
                        "No Início, a pontuação vai de 200 a 1.000 e sobe quando os gastos ficam dentro do planejado."
                ),
            ]
        case .sharing:
            [
                TutorialPage(
                    example: .participants, title: "Participantes",
                    message: "Numa transação, adicione as pessoas que dividiram a conta com você."),
                TutorialPage(
                    example: .splitModes, title: "Como dividir",
                    message:
                        "Em partes iguais, por valor fixo ou por porcentagem. O Cashly calcula a parte de cada um."
                ),
                TutorialPage(
                    example: .paid, title: "Quem já pagou",
                    message:
                        "Marque cada participante como pago ou a receber para saber quem ainda deve."
                ),
            ]
        case .importSpreadsheet, .score: []
        }
    }
}

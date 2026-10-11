import CashlyResource
import FeatureCore
import SwiftUI

struct TutorialPage: Identifiable {
    enum Artwork {
        case illustration(CashlyResourceImage)
        case symbol(String)
    }

    let id = UUID()
    let artwork: Artwork
    let title: LocalizedStringKey
    let message: LocalizedStringKey
}

extension Guide {
    var pages: [TutorialPage] {
        switch self {
        case .tour:
            [
                TutorialPage(
                    artwork: .illustration(.illustrationWelcome), title: "Início",
                    message:
                        "O resumo do mês: quanto entrou, quanto saiu, a pontuação e quanto ainda dá para gastar."
                ),
                TutorialPage(
                    artwork: .illustration(.illustrationTransaction), title: "Transações",
                    message:
                        "Todas as entradas e saídas, por dia. Toque em + para registrar e deslize para editar."
                ),
                TutorialPage(
                    artwork: .illustration(.illustrationEmpty), title: "Planejamento",
                    message:
                        "Categorias e orçamentos. Defina quanto quer gastar em cada uma e acompanhe o ritmo."
                ),
                TutorialPage(
                    artwork: .illustration(.illustrationSearch), title: "Buscar",
                    message: "Encontre qualquer transação, categoria ou tag, de qualquer mês."),
            ]
        case .budgets:
            [
                TutorialPage(
                    artwork: .symbol("chart.pie.fill"), title: "Um orçamento por categoria",
                    message:
                        "No Planejamento, toque numa categoria e defina o valor do mês ou um valor que se repete."
                ),
                TutorialPage(
                    artwork: .symbol("gauge.with.dots.needle.67percent"),
                    title: "Acompanhe o ritmo",
                    message:
                        "As bolinhas mostram o uso: verde no caminho, mostarda atenção, ferrugem acima do orçamento."
                ),
                TutorialPage(
                    artwork: .symbol("star.circle.fill"), title: "Pontuação de saúde",
                    message:
                        "No Início, a pontuação vai de 200 a 1.000 e sobe quando os gastos ficam dentro do planejado."
                ),
            ]
        case .sharing:
            [
                TutorialPage(
                    artwork: .symbol("person.2.fill"), title: "Participantes",
                    message: "Numa transação, adicione as pessoas que dividiram a conta com você."),
                TutorialPage(
                    artwork: .symbol("divide.circle.fill"), title: "Como dividir",
                    message:
                        "Em partes iguais, por valor fixo ou por porcentagem. O Cashly calcula a parte de cada um."
                ),
                TutorialPage(
                    artwork: .symbol("checkmark.circle.fill"), title: "Quem já pagou",
                    message:
                        "Marque cada participante como pago ou a receber para saber quem ainda deve."
                ),
            ]
        case .importSpreadsheet, .score: []
        }
    }
}

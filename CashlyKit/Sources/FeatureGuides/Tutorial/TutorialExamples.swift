import CashlyDesignSystem
import FeatureCore
import SwiftUI

enum TutorialExample {
    case month, history, budgetPace, search, budget, score, participants, splitModes, paid
}

struct TutorialExampleView: View {
    let example: TutorialExample

    var body: some View {
        switch example {
        case .month: ExampleMonthSummary()
        case .score: ScoreCardExample(score: 920)
        default:
            GuideExample {
                switch example {
                case .history: HistoryExample()
                case .budgetPace: BudgetPaceExample()
                case .search: SearchExample()
                case .budget: BudgetExample()
                case .participants: ParticipantsExample()
                case .splitModes: SplitModesExample()
                case .paid: PaidExample()
                case .month, .score: EmptyView()
                }
            }
        }
    }
}

private struct HistoryExample: View {
    var body: some View {
        ExampleRow(
            "Compra semanal", detail: "Mercado · 10:37", value: 312.4.formatted(.appCurrency),
            symbol: "cart.fill", color: .retroOrange)
        ExampleRow(
            "Corrida", detail: "Transporte · 08:15", value: 24.9.formatted(.appCurrency),
            symbol: "car.fill", color: .retroTeal)
        ExampleRow(
            "Salário", detail: "Renda · 09:00", value: 6_500.0.formatted(.appCurrency),
            valueColor: .positive, symbol: "briefcase.fill", color: .retroOlive)
    }
}

struct BudgetPaceExample: View {
    var body: some View {
        ExampleBar("Mercado", ratio: 0.45, color: .positive)
        ExampleBar("Lazer", ratio: 0.86, color: .warning)
        ExampleBar("Transporte", ratio: 1.12, color: .negative)
    }
}

private struct BudgetExample: View {
    var body: some View {
        ExampleHeadline(
            chip: "Mercado", value: 800.0.formatted(.appCurrency),
            detail: Date.now.formatted(.dateTime.month(.wide).year()))
        ExampleBar(
            "Gasto até agora", detail: 360.0.formatted(.appCurrency), ratio: 0.45, color: .positive
        )
    }
}

private struct ParticipantsExample: View {
    @Environment(\.appTint) private var appTint

    var body: some View {
        ExampleRow(
            "Jantar", detail: "Restaurantes", value: 120.0.formatted(.appCurrency),
            symbol: "fork.knife", color: .retroRust)
        HStack(spacing: .spaceXS) {
            Chip("Você", color: appTint)
            Chip("Ana", color: .retroTeal)
            Chip("Bruno", color: .retroPlum)
        }
    }
}

private struct SplitModesExample: View {
    @Environment(\.appTint) private var appTint

    var body: some View {
        HStack(spacing: .spaceXS) {
            ForEach(["Iguais", "Valor", "%"], id: \.self) { mode in
                Text(mode)
                    .font(.footnote.weight(.semibold))
                    .foregroundStyle(mode == "Iguais" ? Color.white : .secondary)
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, .spaceXS)
                    .background(
                        mode == "Iguais" ? appTint : Color.secondary.opacity(.opacityFill),
                        in: .capsule)
            }
        }
        ForEach(["Você", "Ana", "Bruno"], id: \.self) { name in
            ExampleRow(name, value: 40.0.formatted(.appCurrency))
        }
    }
}

private struct PaidExample: View {
    var body: some View {
        HStack {
            ExampleRow("Ana", detail: 40.0.formatted(.appCurrency), value: "")
            Chip("Pago", color: .positive)
        }
        HStack {
            ExampleRow("Bruno", detail: 40.0.formatted(.appCurrency), value: "")
            Chip("A receber", color: .warning)
        }
    }
}

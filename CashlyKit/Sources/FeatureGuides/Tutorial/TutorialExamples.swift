import CashlyDesignSystem
import FeatureCore
import SwiftUI

enum TutorialExample {
    case budgetPace, splitModes, paid
}

struct TutorialExampleView: View {
    let example: TutorialExample

    var body: some View {
        GuideExample {
            switch example {
            case .budgetPace: BudgetPaceExample()
            case .splitModes: SplitModesExample()
            case .paid: PaidExample()
            }
        }
    }
}

private struct BudgetPaceExample: View {
    private let rows: [(String, Double, Color)] = [
        ("Mercado", 0.45, .positive), ("Lazer", 0.86, .warning), ("Transporte", 1.12, .negative),
    ]

    var body: some View {
        ForEach(rows, id: \.0) { name, ratio, color in
            VStack(alignment: .leading, spacing: 6) {
                HStack {
                    Text(name).font(.subheadline.weight(.semibold))
                    Spacer()
                    Text(ratio.formatted(.percent.precision(.fractionLength(0))))
                        .font(.subheadline.weight(.bold))
                        .foregroundStyle(color)
                }
                ProgressView(value: min(ratio, 1)).tint(color)
            }
        }
    }
}

private struct SplitModesExample: View {
    @Environment(\.appTint) private var appTint

    var body: some View {
        HStack {
            Text("Jantar").font(.headline)
            Spacer()
            Text(120.0.formatted(.appCurrency)).font(.headline)
        }
        HStack(spacing: 6) {
            ForEach(["Iguais", "Valor", "%"], id: \.self) { mode in
                Text(mode)
                    .font(.footnote.weight(.semibold))
                    .foregroundStyle(mode == "Iguais" ? Color.white : .secondary)
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 6)
                    .background(
                        mode == "Iguais" ? appTint : Color.secondary.opacity(0.12), in: .capsule)
            }
        }
        ForEach(["Você", "Ana", "Bruno"], id: \.self) { name in
            HStack {
                Text(name).font(.subheadline)
                Spacer()
                Text(40.0.formatted(.appCurrency)).font(.subheadline.weight(.semibold))
            }
        }
    }
}

private struct PaidExample: View {
    private let rows: [(String, Bool)] = [("Ana", true), ("Bruno", false)]

    var body: some View {
        ForEach(rows, id: \.0) { name, isPaid in
            HStack {
                VStack(alignment: .leading, spacing: 0) {
                    Text(name).font(.subheadline.weight(.semibold))
                    Text(40.0.formatted(.appCurrency)).font(.footnote).foregroundStyle(.secondary)
                }
                Spacer()
                Text(isPaid ? "Pago" : "A receber")
                    .font(.footnote.weight(.bold))
                    .foregroundStyle(isPaid ? Color.positive : .warning)
                    .padding(.horizontal, 10)
                    .padding(.vertical, 4)
                    .background((isPaid ? Color.positive : .warning).opacity(0.15), in: .capsule)
            }
        }
    }
}

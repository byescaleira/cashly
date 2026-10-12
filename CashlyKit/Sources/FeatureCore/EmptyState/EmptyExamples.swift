import CashlyDesignSystem
import SwiftUI

struct PrerequisiteExample: View {
    let prerequisite: Prerequisite

    var body: some View {
        switch prerequisite {
        case .category: CategoriesExample()
        case .transaction: TransactionsExample()
        case .tag: TagsExample()
        case .budget: BudgetsExample()
        }
    }
}

private struct CategoriesExample: View {
    private let items: [(String, String, Color)] = [
        ("Mercado", "cart.fill", .retroOrange), ("Casa", "house.fill", .retroTeal),
        ("Transporte", "car.fill", .retroDenim), ("Lazer", "gamecontroller.fill", .retroPlum),
    ]

    var body: some View {
        HStack(spacing: .spaceS) {
            ForEach(items, id: \.0) { name, symbol, color in
                VStack(spacing: .spaceXS) {
                    Image(systemName: symbol)
                        .font(.system(size: 18, weight: .semibold))
                        .foregroundStyle(color)
                        .frame(width: 44, height: 44)
                        .background(color.opacity(.opacityTint), in: .circle)
                    Text(name)
                        .font(.caption.weight(.semibold))
                        .lineLimit(1)
                        .minimumScaleFactor(0.7)
                }
                .frame(maxWidth: .infinity)
            }
        }
    }
}

private struct TransactionsExample: View {
    var body: some View {
        ExampleRow(
            "Feira", detail: "Mercado", value: 86.0.formatted(.appCurrency), symbol: "cart.fill",
            color: .retroOrange)
        ExampleRow(
            "Salário", detail: "Renda", value: 6_500.0.formatted(.appCurrency),
            valueColor: .positive, symbol: "briefcase.fill", color: .retroOlive)
    }
}

private struct BudgetsExample: View {
    var body: some View {
        ExampleBar("Mercado", ratio: 0.45, color: .positive)
        ExampleBar("Lazer", ratio: 0.86, color: .warning)
    }
}

private struct TagsExample: View {
    var body: some View {
        ExampleRow(
            "Hotel", detail: "Lazer", value: 890.0.formatted(.appCurrency),
            symbol: "bed.double.fill", color: .retroPlum)
        HStack(spacing: .spaceXS) {
            Chip("Viagem", color: .retroTeal)
            Chip("Aniversário", color: .retroRust)
            Chip("Reforma", color: .retroMustard)
        }
    }
}

public struct SearchExample: View {
    private let term: String

    public init(term: String = "mercado") {
        self.term = term
    }

    public var body: some View {
        Text(term)
            .font(.body)
            .lineLimit(1)
            .frame(maxWidth: .infinity, alignment: .leading)
            .padding(.horizontal, .spaceM)
            .padding(.vertical, .spaceM)
            .background(Color.secondary.opacity(.opacityFill), in: .capsule)
        ExampleRow(
            "Feira", detail: "Mercado", value: 86.0.formatted(.appCurrency), symbol: "cart.fill",
            color: .retroOrange)
    }
}

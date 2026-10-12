import CashlyDesignSystem
import CashlyDomain
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
        (String(appLocalized: "Groceries"), "cart.fill", .retroOrange),
        (String(appLocalized: "Housing"), "house.fill", .retroTeal),
        (String(appLocalized: "Transport"), "car.fill", .retroDenim),
        (String(appLocalized: "Leisure"), "gamecontroller.fill", .retroPlum),
    ]

    var body: some View {
        HStack(spacing: .spaceS) {
            ForEach(items, id: \.0) { name, symbol, color in
                VStack(spacing: .spaceXS) {
                    Image(systemName: symbol)
                        .font(.icon(.s, weight: .semibold))
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
            String(appLocalized: "Market"), detail: String(appLocalized: "Groceries"),
            value: 86.0.formatted(.appCurrency), symbol: "cart.fill",
            color: .retroOrange)
        ExampleRow(
            String(appLocalized: "Salary"), detail: String(appLocalized: "Earnings"),
            value: 6_500.0.formatted(.appCurrency),
            valueColor: .positive, symbol: "briefcase.fill", color: .retroOlive)
    }
}

private struct BudgetsExample: View {
    var body: some View {
        ExampleBar(String(appLocalized: "Groceries"), ratio: 0.45, color: .positive)
        ExampleBar(String(appLocalized: "Leisure"), ratio: 0.86, color: .warning)
    }
}

private struct TagsExample: View {
    var body: some View {
        ExampleRow(
            String(appLocalized: "Hotel"), detail: String(appLocalized: "Leisure"),
            value: 890.0.formatted(.appCurrency),
            symbol: "bed.double.fill", color: .retroPlum)
        HStack(spacing: .spaceXS) {
            Chip("Trip", color: .retroTeal)
            Chip("Birthday", color: .retroRust)
            Chip("Renovation", color: .retroMustard)
        }
    }
}

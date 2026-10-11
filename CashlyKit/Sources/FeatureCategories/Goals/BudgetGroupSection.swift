import CashlyDesignSystem
import FeatureCore
import SwiftUI

struct BudgetGroupSection: View {
    @Environment(GoalsModel.self) private var goals
    @Environment(\.open) private var open
    @Environment(\.navigationSection) private var section
    let group: BudgetProgress.Group
    let items: [BudgetProgress]

    var body: some View {
        Section {
            ForEach(items) { item in
                Button {
                    open(.addBudget(id: item.budget.id, categoryID: nil, date: nil), in: section)
                } label: {
                    BudgetProgressRow(item: item)
                }
                .tint(Color.primary)
                .contextMenu {
                    Button("Editar", systemImage: "square.and.pencil") {
                        open(
                            .addBudget(id: item.budget.id, categoryID: nil, date: nil), in: section)
                    }
                    Button("Ver categoria", systemImage: "folder") {
                        open(.detailCategory(id: item.budget.category.id), in: section)
                    }
                    Divider()
                    Button("Apagar", systemImage: "trash", role: .destructive) {
                        goals.deletion = .budget(item.budget)
                    }
                }
            }
        } header: {
            Label {
                Text(group.title).sectionTitle()
            } icon: {
                Image(systemName: group.symbol).foregroundStyle(group.color).font(.title3)
            }
        } footer: {
            Text(group.detail)
        }
    }
}

struct BudgetProgressRow: View {
    let item: BudgetProgress

    var body: some View {
        HStack(spacing: 14) {
            CategoryBadge(category: item.budget.category)
            VStack(alignment: .leading, spacing: 6) {
                AdaptiveStack(alignment: .firstTextBaseline) {
                    Text(item.budget.category.name)
                        .font(.callout.weight(.semibold))
                        .frame(maxWidth: .infinity, alignment: .leading)
                    Text(remainingText)
                        .font(.footnote.weight(.semibold))
                        .foregroundStyle(item.group.color)
                        .amountLine()
                }
                ProgressView(value: min(item.ratio, 1)).tint(item.group.color)
                Text(
                    "\(item.spent.formatted(.appCurrency)) de \(item.planned.formatted(.appCurrency))"
                )
                .font(.footnote)
                .foregroundStyle(.secondary)
                .amountLine()
            }
        }
        .padding(.vertical, 4)
    }

    private var remainingText: String {
        item.remaining >= 0
            ? "Sobram \(item.remaining.formatted(.appCurrency))"
            : "Passou \(abs(item.remaining).formatted(.appCurrency))"
    }
}

extension BudgetProgress.Group {
    var color: Color {
        switch self {
        case .over: .negative
        case .attention: .warning
        case .onTrack: .positive
        case .untouched: .secondary
        }
    }

    var symbol: String {
        switch self {
        case .over: "exclamationmark.octagon.fill"
        case .attention: "exclamationmark.triangle.fill"
        case .onTrack: "checkmark.circle.fill"
        case .untouched: "moon.zzz.fill"
        }
    }
}

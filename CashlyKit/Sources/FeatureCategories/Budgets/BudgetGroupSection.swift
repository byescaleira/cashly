import CashlyDesignSystem
import CashlyDomain
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
                .swipeActions {
                    Button("Delete", systemImage: "trash", role: .destructive) {
                        goals.deletion = .budget(item.budget)
                    }
                }
                .contextMenu {
                    Button("Edit", systemImage: "square.and.pencil") {
                        open(
                            .addBudget(id: item.budget.id, categoryID: nil, date: nil), in: section)
                    }
                    Divider()
                    Button("Delete", systemImage: "trash", role: .destructive) {
                        goals.deletion = .budget(item.budget)
                    }
                }
            }
        } header: {
            HStack(spacing: .spaceS) {
                Label {
                    Text(group.title).sectionTitle()
                } icon: {
                    Image(systemName: group.symbol).foregroundStyle(group.color).font(.title3)
                }
                Spacer()
                Chip(items.count.formatted(.number.locale(.app)), color: group.color)
            }
        } footer: {
            Text(group.detail)
        }
    }
}

struct BudgetProgressRow: View {
    @Environment(\.accessibilityReduceMotion) private var reduceMotion
    @State private var isFilled = false
    let item: BudgetProgress

    var body: some View {
        HStack(spacing: .spaceM) {
            SymbolBadge(item.budget.category.icon, color: Color(hex: item.budget.category.color))
            VStack(alignment: .leading, spacing: .spaceXS) {
                AdaptiveStack(alignment: .firstTextBaseline) {
                    Text(item.budget.category.name)
                        .font(.rowTitle)
                        .frame(maxWidth: .infinity, alignment: .leading)
                    Text(item.remainingTitle)
                        .font(.footnote.weight(.semibold))
                        .foregroundStyle(item.group.color)
                        .amountLine()
                }
                ProgressView(value: isFilled ? min(item.ratio, 1) : 0)
                    .tint(item.group.color)
                    .animation(reduceMotion ? nil : .smooth(duration: 1), value: isFilled)
                    .animation(reduceMotion ? nil : .smooth, value: item.ratio)
                HStack(alignment: .firstTextBaseline) {
                    Text(item.amountsTitle)
                    Spacer()
                    Text(item.usageTitle).fontWeight(.semibold)
                }
                .font(.footnote)
                .foregroundStyle(.secondary)
                .amountLine()
            }
        }
        .padding(.vertical, .space2XS)
        .task { isFilled = true }
        .accessibilityElement(children: .combine)
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

    func summary(count: Int) -> String {
        switch self {
        case .over: String(appLocalized: "\(count) over the limit")
        case .attention: String(appLocalized: "\(count) close to the limit")
        case .onTrack: String(appLocalized: "\(count) on track")
        case .untouched: String(appLocalized: "\(count) with no spending")
        }
    }
}

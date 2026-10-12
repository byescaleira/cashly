import CashlyDesignSystem
import FeatureCore
import SwiftUI

struct BudgetsOverviewSection: View {
    @Environment(GoalsModel.self) private var goals
    @Environment(SessionModel.self) private var session
    @Environment(FinanceModel.self) private var finance
    @Environment(\.open) private var open
    @Environment(\.navigationSection) private var section

    var body: some View {
        let overview = goals.overview
        if !finance.categories.isEmpty {
            Section {
                if overview.items.isEmpty {
                    Button {
                        open(
                            .addBudget(id: nil, categoryID: nil, date: session.filter.startDate),
                            in: section)
                    } label: {
                        Label("Criar orçamento", systemImage: "plus.circle.fill")
                            .font(.body.weight(.semibold))
                    }
                } else {
                    Button {
                        open(.budgets, in: section)
                    } label: {
                        BudgetsOverviewCard(overview: overview, showsLink: true)
                    }
                    .buttonStyle(.plain)
                }
            } header: {
                Text("Orçamentos").sectionTitle()
            } footer: {
                if overview.items.isEmpty {
                    Text("Defina quanto quer gastar em cada categoria neste mês.")
                }
            }
        }
    }
}

struct BudgetsOverviewCard: View {
    @Environment(\.appTint) private var appTint
    let overview: BudgetOverview
    var showsLink = false

    var body: some View {
        let color =
            overview.ratio > 1 ? Color.negative : overview.ratio >= 0.8 ? .warning : .positive
        VStack(alignment: .leading, spacing: 14) {
            HStack(alignment: .firstTextBaseline) {
                VStack(alignment: .leading, spacing: 2) {
                    Text(overview.remaining >= 0 ? "Disponível" : "Acima do planejado")
                        .font(.subheadline)
                        .foregroundStyle(.secondary)
                    Text(abs(overview.remaining).formatted(.appCurrency))
                        .font(.title.weight(.bold))
                        .foregroundStyle(overview.remaining >= 0 ? Color.primary : .negative)
                        .contentTransition(.numericText(value: overview.remaining))
                        .amountLine()
                    Text("de \(overview.planned.formatted(.appCurrency)) planejado")
                        .font(.footnote)
                        .foregroundStyle(.secondary)
                        .amountLine()
                }
                Spacer(minLength: 8)
                VStack(alignment: .trailing, spacing: 0) {
                    Text(overview.ratio.formatted(.percent.precision(.fractionLength(0))))
                        .font(.title2.weight(.bold))
                        .foregroundStyle(color)
                    Text("usado").font(.caption).foregroundStyle(.secondary)
                }
            }
            GroupBar(counts: overview.counts)
            FlowLayout(spacing: 12) {
                ForEach(overview.counts, id: \.group) { entry in
                    HStack(spacing: 6) {
                        Circle().fill(entry.group.color).frame(width: 8, height: 8)
                        Text(entry.group.summary(count: entry.count))
                    }
                    .font(.footnote)
                    .foregroundStyle(.secondary)
                }
            }
            if showsLink {
                Divider()
                HStack {
                    Text(
                        overview.items.count == 1
                            ? "Ver o orçamento" : "Ver os \(overview.items.count) orçamentos"
                    )
                    .font(.callout.weight(.semibold))
                    .foregroundStyle(appTint)
                    Spacer()
                    Image(systemName: "chevron.forward")
                        .font(.footnote.weight(.semibold))
                        .foregroundStyle(.tertiary)
                }
            }
        }
        .padding(.vertical, 6)
        .contentShape(.rect)
        .accessibilityElement(children: .combine)
    }
}

private struct GroupBar: View {
    let counts: [(group: BudgetProgress.Group, count: Int)]

    var body: some View {
        let total = max(counts.reduce(0) { $0 + $1.count }, 1)
        GeometryReader { proxy in
            let width = proxy.size.width - CGFloat(max(counts.count - 1, 0)) * 3
            HStack(spacing: 3) {
                ForEach(counts, id: \.group) { entry in
                    Capsule()
                        .fill(entry.group.color)
                        .frame(width: width * CGFloat(entry.count) / CGFloat(total))
                }
            }
        }
        .frame(height: 10)
        .accessibilityHidden(true)
    }
}

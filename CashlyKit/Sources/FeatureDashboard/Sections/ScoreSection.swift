import CashlyDesignSystem
import CashlyDomain
import FeatureCore
import SwiftUI

struct ScoreSection: View {
    @Environment(SessionModel.self) private var session
    @Environment(FinanceModel.self) private var finance
    @Environment(\.showGuide) private var showGuide

    var body: some View {
        if !session.users.isEmpty {
            let health = finance.health
            let level = health.level
            Section {
                Button {
                    showGuide?(.score)
                } label: {
                    VStack(alignment: .leading, spacing: 16) {
                        AdaptiveStack(spacing: 8) {
                            HStack(alignment: .firstTextBaseline, spacing: 4) {
                                Text(health.score.formatted()).font(.title.weight(.bold))
                                Text("de \(BudgetHealth.maximumScore)")
                                    .font(.footnote)
                                    .foregroundStyle(Color.secondary)
                            }
                            .amountLine()
                            .frame(maxWidth: .infinity, alignment: .leading)
                            Text(level.title.uppercased())
                                .font(.caption2.weight(.bold))
                                .foregroundStyle(level.color)
                                .padding(.vertical, 8)
                                .padding(.horizontal, 12)
                                .background(level.color.opacity(0.2), in: .capsule)
                        }
                        HStack(spacing: 8) {
                            ForEach(BudgetHealth.Level.allCases, id: \.self) { item in
                                ProgressView(
                                    value: item == level ? item.progress(for: health.score) : 1,
                                    total: 1
                                )
                                .tint(
                                    health.score > item.scores.upperBound || item == level
                                        ? level.color : .clear)
                            }
                        }
                        .accessibilityHidden(true)
                        Text(level.summary).font(.callout)
                    }
                    .padding(8)
                    .contentShape(.rect)
                }
                .buttonStyle(.plain)
                .accessibilityHint("Mostra como a pontuação funciona")
            } header: {
                HStack {
                    Text("Pontuação").sectionTitle()
                    Spacer()
                    if showGuide != nil {
                        Button("Como funciona", systemImage: "info.circle") { showGuide?(.score) }
                            .labelStyle(.iconOnly)
                            .font(.title3)
                    }
                }
            }
        }
    }
}

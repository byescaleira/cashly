import CashlyDesignSystem
import CashlyDomain
import FeatureCore
import SwiftUI

struct ScoreSection: View {
    @Environment(SessionModel.self) private var session
    @Environment(FinanceModel.self) private var finance

    var body: some View {
        if !session.users.isEmpty {
            let health = finance.health
            let level = health.level
            Section {
                VStack(alignment: .leading, spacing: 16) {
                    HStack(spacing: 8) {
                        Text(String(health.score)).font(.title.weight(.bold))
                        Text("/  \(BudgetHealth.maximumScore)")
                            .font(.footnote)
                            .foregroundStyle(Color.secondary)
                            .padding(.bottom, -8)
                        Spacer()
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
            } header: {
                Text("Pontuação").sectionTitle()
            }
        }
    }
}

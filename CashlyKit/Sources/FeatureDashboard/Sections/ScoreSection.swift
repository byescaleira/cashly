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
                    VStack(alignment: .leading, spacing: .spaceL) {
                        AdaptiveStack(spacing: .spaceS) {
                            HStack(alignment: .firstTextBaseline, spacing: .space2XS) {
                                Text(health.score.formatted(.number.locale(.app))).font(
                                    .amountTitle)
                                Text("of \(BudgetHealth.maximumScore)")
                                    .font(.footnote)
                                    .foregroundStyle(Color.secondary)
                            }
                            .amountLine()
                            .frame(maxWidth: .infinity, alignment: .leading)
                            Text(level.title.uppercased())
                                .font(.caption2.weight(.bold))
                                .foregroundStyle(level.color)
                                .padding(.vertical, .spaceS)
                                .padding(.horizontal, .spaceM)
                                .background(level.color.opacity(.opacityTint), in: .capsule)
                        }
                        SegmentedBar(
                            count: BudgetHealth.Level.allCases.count,
                            value: Double(BudgetHealth.Level.allCases.firstIndex(of: level) ?? 0)
                                + level.progress(for: health.score),
                            color: level.color)
                        Text(level.summary).font(.callout)
                    }
                    .padding(.spaceS)
                    .contentShape(.rect)
                }
                .buttonStyle(.plain)
                .accessibilityHint("Shows how the score works")
            } header: {
                HStack {
                    Text("Score").sectionTitle()
                    Spacer()
                    if showGuide != nil {
                        Button("How It Works", systemImage: "info.circle") { showGuide?(.score) }
                            .labelStyle(.iconOnly)
                            .font(.title3)
                    }
                }
            }
        }
    }
}

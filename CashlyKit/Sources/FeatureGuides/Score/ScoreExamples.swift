import CashlyDomain
import FeatureCore
import SwiftUI

struct ScoreScale: View {
    var score: Int?

    var body: some View {
        HStack(alignment: .top, spacing: 6) {
            ForEach(BudgetHealth.Level.allCases, id: \.self) { level in
                let isOn = score.map(level.scores.contains) ?? true
                VStack(spacing: 6) {
                    Capsule().fill(level.color.opacity(isOn ? 1 : 0.25)).frame(height: 12)
                    Text(
                        "\(level.scores.lowerBound.formatted())–\(level.scores.upperBound.formatted())"
                    )
                    .font(.caption.weight(.semibold))
                    .foregroundStyle(isOn ? level.color : .secondary)
                    .lineLimit(1)
                    .minimumScaleFactor(0.7)
                }
                .multilineTextAlignment(.center)
                .frame(maxWidth: .infinity)
            }
        }
    }
}

struct ScoreScaleExample: View {
    var body: some View {
        GuideExample { ScoreScale() }
    }
}

struct ScoreBadgeExample: View {
    @Environment(FinanceModel.self) private var finance

    var body: some View {
        let health = finance.health
        GuideExample {
            VStack(spacing: 2) {
                Text(health.score.formatted())
                    .font(.system(.largeTitle, design: .rounded, weight: .bold))
                    .foregroundStyle(health.level.color)
                Text(health.level.title)
                    .font(.headline)
                    .foregroundStyle(health.level.color)
            }
            .frame(maxWidth: .infinity)
            ScoreScale(score: health.score)
        }
    }
}

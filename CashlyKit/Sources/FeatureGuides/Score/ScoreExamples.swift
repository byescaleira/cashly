import CashlyDesignSystem
import CashlyDomain
import FeatureCore
import SwiftUI

struct ScoreScale: View {
    var score: Int?

    var body: some View {
        HStack(alignment: .top, spacing: .spaceXS) {
            ForEach(BudgetHealth.Level.allCases, id: \.self) { level in
                let isOn = score.map(level.scores.contains) ?? true
                VStack(spacing: .spaceXS) {
                    Capsule().fill(level.color.opacity(isOn ? 1 : 0.25)).frame(height: 10)
                    Text(
                        "\(level.scores.lowerBound.formatted(.number.locale(.app)))–\(level.scores.upperBound.formatted(.number.locale(.app)))"
                    )
                    .font(.caption.weight(.semibold))
                    .foregroundStyle(isOn ? level.color : .secondary)
                    .lineLimit(1)
                    .minimumScaleFactor(0.7)
                }
                .frame(maxWidth: .infinity)
            }
        }
    }
}

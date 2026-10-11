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
                    Capsule().fill(level.color.opacity(isOn ? 1 : 0.25)).frame(height: 10)
                    Text(
                        "\(level.scores.lowerBound.formatted())–\(level.scores.upperBound.formatted())"
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

struct ScoreScaleExample: View {
    var body: some View {
        GuideExample { ScoreScale() }
    }
}

struct ScoreCardExample: View {
    let score: Int

    var body: some View {
        let level = BudgetHealth.Level.allCases.first { $0.scores.contains(score) } ?? .critical
        GuideExample {
            HStack(alignment: .firstTextBaseline) {
                Text(score.formatted()).font(.system(.largeTitle, weight: .black))
                Text("de 1.000").font(.subheadline).foregroundStyle(.secondary)
                Spacer()
                ExampleChip(level.title.uppercased(), color: level.color)
            }
            ScoreScale(score: score)
        }
    }
}

struct CurrentScoreExample: View {
    @Environment(FinanceModel.self) private var finance

    var body: some View {
        ScoreCardExample(score: finance.health.score)
    }
}

struct DailyAllowanceExample: View {
    var body: some View {
        GuideExample {
            ExampleHeadline(
                value: 85.0.formatted(.appCurrency), detail: "por dia até o fim do mês")
            Divider()
            ExampleBar("Mercado", ratio: 0.62, color: .positive)
            ExampleBar("Lazer", ratio: 0.81, color: .warning)
        }
    }
}

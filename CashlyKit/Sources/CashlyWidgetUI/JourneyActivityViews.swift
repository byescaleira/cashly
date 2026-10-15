import CashlyDesignSystem
import CashlyDomain
import SwiftUI

public struct StreakRiskView<Action: View>: View {
    private let risk: JourneySnapshot.StreakRisk
    private let action: Action

    public init(risk: JourneySnapshot.StreakRisk, @ViewBuilder action: () -> Action) {
        self.risk = risk
        self.action = action()
    }

    public var body: some View {
        VStack(alignment: .leading, spacing: .spaceM) {
            HStack(alignment: .center, spacing: .spaceM) {
                StreakRiskFigure(risk: risk, size: .badgeL)
                Spacer(minLength: .spaceS)
                VStack(alignment: .trailing, spacing: .spaceHairline) {
                    WidgetLabel("Ends in")
                    JourneyCountdown(to: risk.deadline)
                        .font(.title2.weight(.bold))
                        .fontDesign(.rounded)
                        .foregroundStyle(Color.retroOrange)
                }
            }
            HStack(spacing: .spaceM) {
                FreezeNote(risk: risk)
                Spacer(minLength: 0)
                action
            }
        }
    }
}

public struct StreakRiskFigure: View {
    private let risk: JourneySnapshot.StreakRisk
    private let size: CGFloat

    public init(risk: JourneySnapshot.StreakRisk, size: CGFloat) {
        self.risk = risk
        self.size = size
    }

    public var body: some View {
        HStack(spacing: .spaceS) {
            StreakFlame(isDone: false, size: size)
            VStack(alignment: .leading, spacing: .spaceHairline) {
                Text("\(risk.current) days")
                    .font(.title3.weight(.bold))
                    .fontDesign(.rounded)
                    .lineLimit(1)
                    .minimumScaleFactor(0.7)
                Text("Streak at Risk")
                    .font(.caption.weight(.semibold))
                    .foregroundStyle(Color.retroOrange)
                    .lineLimit(1)
            }
        }
    }
}

public struct FreezeNote: View {
    private let risk: JourneySnapshot.StreakRisk

    public init(risk: JourneySnapshot.StreakRisk) {
        self.risk = risk
    }

    public var body: some View {
        let covered = risk.freezes > 0
        Label {
            Text(
                covered ? "A freeze will cover today" : "No freezes: the streak resets at midnight")
        } icon: {
            Image(systemName: covered ? "snowflake" : "exclamationmark.triangle")
        }
        .font(.caption)
        .foregroundStyle(covered ? Color.info : Color.secondary)
        .lineLimit(2)
        .minimumScaleFactor(0.8)
    }
}

public struct JourneyCountdown: View {
    private let deadline: Date

    public init(to deadline: Date) {
        self.deadline = deadline
    }

    public var body: some View {
        Countdown(to: deadline)
    }
}

public struct ChallengeDayView: View {
    private let challenge: JourneySnapshot.Challenge

    public init(challenge: JourneySnapshot.Challenge) {
        self.challenge = challenge
    }

    public var body: some View {
        HStack(alignment: .top, spacing: .spaceM) {
            SymbolBadge(
                challenge.symbol, color: challenge.tint.color, size: .badgeL, style: .filled)
            VStack(alignment: .leading, spacing: .spaceXS) {
                HStack(alignment: .firstTextBaseline, spacing: .spaceS) {
                    Text(verbatim: challenge.title)
                        .font(.headline)
                        .fontDesign(.rounded)
                        .lineLimit(1)
                        .minimumScaleFactor(0.7)
                    Spacer(minLength: 0)
                    WidgetTag("+\(challenge.xp) XP", color: challenge.tint.color)
                }
                ChallengeDayProgress(challenge: challenge)
            }
        }
    }
}

public struct ChallengeDayProgress: View {
    private let challenge: JourneySnapshot.Challenge

    public init(challenge: JourneySnapshot.Challenge) {
        self.challenge = challenge
    }

    public var body: some View {
        VStack(alignment: .leading, spacing: .spaceXS) {
            switch challenge.outcome {
            case .active:
                HStack(alignment: .firstTextBaseline, spacing: .spaceS) {
                    Text(verbatim: challenge.measure)
                        .font(.subheadline.weight(.semibold).monospacedDigit())
                        .foregroundStyle(challenge.color)
                        .lineLimit(1)
                        .minimumScaleFactor(0.7)
                    Spacer(minLength: 0)
                    Label {
                        Countdown(to: challenge.ends)
                    } icon: {
                        Image(systemName: "hourglass")
                    }
                    .font(.subheadline.weight(.bold))
                }
                UsageBar(
                    ratio: challenge.progress, height: 8, color: challenge.color,
                    marker: challenge.elapsed)
                HStack(spacing: .spaceS) {
                    WidgetLabel("Last Day")
                    PaceLabel(challenge: challenge, font: .caption)
                }
            case .completed:
                OutcomeLabel(
                    title: "Challenge Complete", symbol: "checkmark.seal.fill", color: .positive)
                UsageBar(ratio: 1, height: 8, color: .positive)
            case .failed:
                OutcomeLabel(title: "Challenge Lost", symbol: "xmark.circle", color: .negative)
                UsageBar(ratio: challenge.progress, height: 8, color: .negative)
            }
        }
    }
}

private struct OutcomeLabel: View {
    let title: LocalizedStringKey
    let symbol: String
    let color: Color

    var body: some View {
        Label {
            Text(title)
        } icon: {
            Image(systemName: symbol)
        }
        .font(.subheadline.weight(.bold))
        .foregroundStyle(color)
    }
}

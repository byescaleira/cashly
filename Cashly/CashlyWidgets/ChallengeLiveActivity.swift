#if os(iOS)
    import ActivityKit
    import CashlyDesignSystem
    import CashlyDomain
    import CashlyWidgetUI
    import SwiftUI
    import WidgetKit

    struct ChallengeLiveActivity: Widget {
        var body: some WidgetConfiguration {
            ActivityConfiguration(for: ChallengeActivityAttributes.self) { context in
                ChallengeDayView(challenge: context.state)
                    .padding(.spaceL)
                    .widgetURL(URL(string: "cashly://journey"))
            } dynamicIsland: { context in
                let challenge = context.state
                return DynamicIsland {
                    DynamicIslandExpandedRegion(.leading) {
                        SymbolBadge(
                            challenge.symbol, color: challenge.tint.color, size: .badgeM,
                            style: .filled)
                    }
                    DynamicIslandExpandedRegion(.trailing) {
                        JourneyCountdown(to: challenge.ends)
                            .font(.title3.weight(.bold))
                            .foregroundStyle(challenge.color)
                    }
                    DynamicIslandExpandedRegion(.center) {
                        Text(verbatim: challenge.title)
                            .font(.headline)
                            .fontDesign(.rounded)
                            .lineLimit(1)
                            .minimumScaleFactor(0.7)
                    }
                    DynamicIslandExpandedRegion(.bottom) {
                        ChallengeDayProgress(challenge: challenge)
                    }
                } compactLeading: {
                    Image(systemName: challenge.symbol).foregroundStyle(challenge.tint.color)
                } compactTrailing: {
                    Text(
                        verbatim: challenge.shortMeasure(
                            currencyCode: context.attributes.currencyCode)
                    )
                    .font(.caption.weight(.bold).monospacedDigit())
                    .foregroundStyle(challenge.color)
                } minimal: {
                    Image(systemName: challenge.symbol).foregroundStyle(challenge.color)
                }
                .widgetURL(URL(string: "cashly://journey"))
                .keylineTint(challenge.color)
            }
        }
    }

    #Preview("Lock Screen", as: .content, using: ChallengeActivityAttributes.preview) {
        ChallengeLiveActivity()
    } contentStates: {
        JourneySnapshot.lastDayChallenge()
        JourneySnapshot.lastDayChallenge(pace: .fast, progress: 0.97)
        JourneySnapshot.lastDayChallenge(outcome: .completed)
        JourneySnapshot.lastDayChallenge(outcome: .failed)
    }

    #Preview("Expanded", as: .dynamicIsland(.expanded), using: ChallengeActivityAttributes.preview)
    {
        ChallengeLiveActivity()
    } contentStates: {
        JourneySnapshot.lastDayChallenge()
    }

    #Preview("Compact", as: .dynamicIsland(.compact), using: ChallengeActivityAttributes.preview) {
        ChallengeLiveActivity()
    } contentStates: {
        JourneySnapshot.lastDayChallenge()
    }

    #Preview("Minimal", as: .dynamicIsland(.minimal), using: ChallengeActivityAttributes.preview) {
        ChallengeLiveActivity()
    } contentStates: {
        JourneySnapshot.lastDayChallenge()
    }

    extension ChallengeActivityAttributes {
        fileprivate static var preview: ChallengeActivityAttributes {
            ChallengeActivityAttributes(id: "preview", currencyCode: "BRL")
        }
    }

    extension JourneySnapshot {
        fileprivate static func lastDayChallenge(
            pace: Challenge.Pace = .steady, progress: Double = 0.9,
            outcome: Challenge.Outcome = .active
        ) -> Challenge {
            let sample = sampleChallenge
            let calendar = Calendar.current
            let midnight =
                calendar.date(byAdding: .day, value: 1, to: calendar.startOfDay(for: .now)) ?? .now
            return Challenge(
                id: sample.id, title: sample.title, detail: sample.detail, symbol: sample.symbol,
                tint: sample.tint, xp: sample.xp, measure: sample.measure, value: sample.value,
                target: sample.target, unit: sample.unit, progress: progress, elapsed: 1,
                pace: pace, paceTitle: sample.paceTitle,
                starts: midnight.addingTimeInterval(-30 * 86_400), ends: midnight,
                outcome: outcome)
        }
    }
#endif

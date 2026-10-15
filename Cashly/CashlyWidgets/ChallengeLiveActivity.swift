#if os(iOS)
    import ActivityKit
    import CashlyDesignSystem
    import CashlyDomain
    import SwiftUI
    import WidgetKit

    struct ChallengeLiveActivity: Widget {
        var body: some WidgetConfiguration {
            ActivityConfiguration(for: ChallengeActivityAttributes.self) { context in
                ChallengeBanner(challenge: context.state)
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
                        Countdown(to: challenge.ends)
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
                        ChallengeDayBlock(challenge: challenge)
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

    private struct ChallengeBanner: View {
        let challenge: JourneySnapshot.Challenge

        var body: some View {
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
                        JourneyTag("+\(challenge.xp) XP", color: challenge.tint.color)
                    }
                    ChallengeDayBlock(challenge: challenge)
                }
            }
        }
    }

    private struct ChallengeDayBlock: View {
        let challenge: JourneySnapshot.Challenge

        var body: some View {
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
                    JourneyBar(
                        value: challenge.progress, color: challenge.color, height: 8,
                        marker: challenge.elapsed)
                    HStack(spacing: .spaceS) {
                        JourneyLabel("Last Day")
                        if let paceTitle = challenge.paceTitle {
                            Label {
                                Text(verbatim: paceTitle)
                            } icon: {
                                Image(systemName: challenge.paceSymbol)
                            }
                            .font(.caption.weight(.semibold))
                            .foregroundStyle(challenge.color)
                            .lineLimit(1)
                        }
                    }
                case .completed:
                    OutcomeLabel(
                        title: "Challenge Complete", symbol: "checkmark.seal.fill",
                        color: .positive)
                    JourneyBar(value: 1, color: .positive, height: 8)
                case .failed:
                    OutcomeLabel(title: "Challenge Lost", symbol: "xmark.circle", color: .negative)
                    JourneyBar(value: challenge.progress, color: .negative, height: 8)
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

    #Preview("Lock Screen", as: .content, using: ChallengeActivityAttributes.preview) {
        ChallengeLiveActivity()
    } contentStates: {
        JourneySnapshot.lastDayChallenge
        JourneySnapshot.lastDayChallenge.with(
            pace: .fast, paceTitle: String(localized: "Faster than the month"), progress: 0.97)
        JourneySnapshot.lastDayChallenge.with(outcome: .completed)
        JourneySnapshot.lastDayChallenge.with(outcome: .failed)
    }

    #Preview("Expanded", as: .dynamicIsland(.expanded), using: ChallengeActivityAttributes.preview)
    {
        ChallengeLiveActivity()
    } contentStates: {
        JourneySnapshot.lastDayChallenge
    }

    #Preview("Compact", as: .dynamicIsland(.compact), using: ChallengeActivityAttributes.preview) {
        ChallengeLiveActivity()
    } contentStates: {
        JourneySnapshot.lastDayChallenge
    }

    #Preview("Minimal", as: .dynamicIsland(.minimal), using: ChallengeActivityAttributes.preview) {
        ChallengeLiveActivity()
    } contentStates: {
        JourneySnapshot.lastDayChallenge
    }

    extension ChallengeActivityAttributes {
        fileprivate static var preview: ChallengeActivityAttributes {
            ChallengeActivityAttributes(id: "preview", currencyCode: "BRL")
        }
    }

    extension JourneySnapshot {
        fileprivate static var lastDayChallenge: Challenge {
            let calendar = Calendar.current
            let midnight =
                calendar.date(byAdding: .day, value: 1, to: calendar.startOfDay(for: .now)) ?? .now
            return sampleChallenge.with(
                elapsed: 1, starts: midnight.addingTimeInterval(-30 * 86_400), ends: midnight)
        }
    }

    extension JourneySnapshot.Challenge {
        fileprivate func with(
            pace: Pace? = nil, paceTitle: String? = nil, progress: Double? = nil,
            elapsed: Double? = nil, starts: Date? = nil, ends: Date? = nil,
            outcome: Outcome = .active
        ) -> JourneySnapshot.Challenge {
            JourneySnapshot.Challenge(
                id: id, title: title, detail: detail, symbol: symbol, tint: tint, xp: xp,
                measure: measure, value: value, target: target, unit: unit,
                progress: progress ?? self.progress, elapsed: elapsed ?? self.elapsed,
                pace: pace ?? self.pace, paceTitle: paceTitle ?? self.paceTitle,
                starts: starts ?? self.starts, ends: ends ?? self.ends, outcome: outcome)
        }
    }
#endif

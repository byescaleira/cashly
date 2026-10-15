#if os(iOS)
    import ActivityKit
    import AppIntents
    import CashlyDesignSystem
    import CashlyDomain
    import SwiftUI
    import WidgetKit

    struct StreakLiveActivity: Widget {
        var body: some WidgetConfiguration {
            ActivityConfiguration(for: StreakActivityAttributes.self) { context in
                StreakBanner(risk: context.state)
                    .padding(.spaceL)
                    .widgetURL(URL(string: "cashly://journey"))
            } dynamicIsland: { context in
                let risk = context.state
                return DynamicIsland {
                    DynamicIslandExpandedRegion(.leading) {
                        StreakFigure(risk: risk, size: .badgeM)
                    }
                    DynamicIslandExpandedRegion(.trailing) {
                        Countdown(to: risk.deadline)
                            .font(.title2.weight(.bold))
                            .foregroundStyle(Color.retroOrange)
                    }
                    DynamicIslandExpandedRegion(.bottom) {
                        VStack(alignment: .leading, spacing: .spaceS) {
                            FreezeNote(risk: risk)
                            RegisterButton()
                        }
                    }
                } compactLeading: {
                    Label {
                        Text(verbatim: risk.current.formatted())
                    } icon: {
                        Image(systemName: "flame")
                    }
                    .font(.caption.weight(.bold))
                    .foregroundStyle(Color.retroOrange)
                } compactTrailing: {
                    Countdown(to: risk.deadline)
                        .font(.caption.weight(.bold))
                        .frame(maxWidth: .badgeXL)
                        .foregroundStyle(Color.retroOrange)
                } minimal: {
                    Image(systemName: "flame").foregroundStyle(Color.retroOrange)
                }
                .widgetURL(URL(string: "cashly://journey"))
                .keylineTint(.retroOrange)
            }
        }
    }

    private struct StreakBanner: View {
        let risk: JourneySnapshot.StreakRisk

        var body: some View {
            VStack(alignment: .leading, spacing: .spaceM) {
                HStack(alignment: .center, spacing: .spaceM) {
                    StreakFigure(risk: risk, size: .badgeL)
                    Spacer(minLength: .spaceS)
                    VStack(alignment: .trailing, spacing: .spaceHairline) {
                        JourneyLabel("Ends in")
                        Countdown(to: risk.deadline)
                            .font(.title2.weight(.bold))
                            .fontDesign(.rounded)
                            .foregroundStyle(Color.retroOrange)
                    }
                }
                HStack(spacing: .spaceM) {
                    FreezeNote(risk: risk)
                    Spacer(minLength: 0)
                    RegisterButton()
                }
            }
        }
    }

    private struct StreakFigure: View {
        let risk: JourneySnapshot.StreakRisk
        let size: CGFloat

        var body: some View {
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

    private struct FreezeNote: View {
        let risk: JourneySnapshot.StreakRisk

        var body: some View {
            Label {
                Text(
                    risk.freezes > 0
                        ? "A freeze will cover today" : "No freezes: the streak resets at midnight")
            } icon: {
                Image(systemName: risk.freezes > 0 ? "snowflake" : "exclamationmark.triangle")
            }
            .font(.caption)
            .foregroundStyle(risk.freezes > 0 ? Color.info : Color.secondary)
            .lineLimit(2)
            .minimumScaleFactor(0.8)
        }
    }

    private struct RegisterButton: View {
        var body: some View {
            Button(intent: NewExpenseIntent()) {
                Label("Register Expense", systemImage: "plus.circle.fill")
                    .font(.caption.weight(.bold))
                    .lineLimit(1)
            }
            .buttonStyle(.borderedProminent)
            .tint(.retroOrange)
        }
    }

    #Preview("Lock Screen", as: .content, using: StreakActivityAttributes(id: "preview")) {
        StreakLiveActivity()
    } contentStates: {
        JourneySnapshot.StreakRisk.preview(freezes: 1)
        JourneySnapshot.StreakRisk.preview(freezes: 0)
    }

    #Preview(
        "Expanded", as: .dynamicIsland(.expanded), using: StreakActivityAttributes(id: "preview")
    ) {
        StreakLiveActivity()
    } contentStates: {
        JourneySnapshot.StreakRisk.preview(freezes: 0)
    }

    #Preview(
        "Compact", as: .dynamicIsland(.compact), using: StreakActivityAttributes(id: "preview")
    ) {
        StreakLiveActivity()
    } contentStates: {
        JourneySnapshot.StreakRisk.preview(freezes: 1)
    }

    #Preview(
        "Minimal", as: .dynamicIsland(.minimal), using: StreakActivityAttributes(id: "preview")
    ) {
        StreakLiveActivity()
    } contentStates: {
        JourneySnapshot.StreakRisk.preview(freezes: 1)
    }

    extension JourneySnapshot.StreakRisk {
        fileprivate static func preview(freezes: Int) -> JourneySnapshot.StreakRisk {
            JourneySnapshot.StreakRisk(
                current: 12, freezes: freezes, deadline: .now.addingTimeInterval(3 * 3_600 + 1_260))
        }
    }
#endif

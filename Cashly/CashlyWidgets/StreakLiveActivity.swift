#if os(iOS)
    import ActivityKit
    import AppIntents
    import CashlyDesignSystem
    import CashlyDomain
    import CashlyWidgetUI
    import SwiftUI
    import WidgetKit

    struct StreakLiveActivity: Widget {
        var body: some WidgetConfiguration {
            ActivityConfiguration(for: StreakActivityAttributes.self) { context in
                StreakRiskView(risk: context.state) { RegisterButton() }
                    .padding(.spaceL)
                    .widgetURL(URL(string: "cashly://journey"))
            } dynamicIsland: { context in
                let risk = context.state
                return DynamicIsland {
                    DynamicIslandExpandedRegion(.leading) {
                        StreakRiskFigure(risk: risk, size: .badgeM)
                    }
                    DynamicIslandExpandedRegion(.trailing) {
                        JourneyCountdown(to: risk.deadline)
                            .font(.title2.weight(.bold))
                            .foregroundStyle(Color.retroOrange)
                    }
                    DynamicIslandExpandedRegion(.bottom) {
                        HStack(spacing: .spaceM) {
                            FreezeNote(risk: risk)
                            Spacer(minLength: 0)
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
                    JourneyCountdown(to: risk.deadline)
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

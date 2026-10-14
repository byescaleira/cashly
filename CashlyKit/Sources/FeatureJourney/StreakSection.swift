import CashlyDesignSystem
import CashlyGame
import FeatureCore
import SwiftUI
import TipKit

struct StreakSection: View {
    @Environment(JourneyModel.self) private var journey
    @Environment(\.shop) private var shop
    @Environment(\.pro) private var pro

    var body: some View {
        if let streak = journey.progress?.streak {
            Section {
                StreakHeroRow(streak: streak)
                WeekStrip(days: streak.week)
                StreakFiguresRow()
                MilestoneRow()
                if !streak.isTodayTracked {
                    TipView(NoSpendDayTip()).tipBackground(.clear)
                    Button("I Didn't Spend Today", systemImage: "hand.raised") {
                        pro.perform { Task { await journey.markNoSpendToday() } }
                    }
                    .font(.buttonLabel)
                }
                if streak.restorable > 0 {
                    Button(journey.restoreTitle, systemImage: "arrow.counterclockwise") {
                        shop.open(.streakRestore)
                    }
                    .font(.buttonLabel)
                }
            } header: {
                Text("Streak").sectionTitle()
            } footer: {
                Text(
                    "Record a transaction or mark a no-spend day to keep it going. A freeze covers a missed day on its own."
                )
            }
        }
    }
}

private struct StreakHeroRow: View {
    @Environment(JourneyModel.self) private var journey
    @Environment(\.accessibilityReduceMotion) private var reduceMotion
    @State private var isShown = false
    let streak: Streak

    var body: some View {
        HStack(spacing: .spaceM) {
            SymbolBadge(
                streak.isTodayTracked ? "flame.fill" : "flame", color: .retroOrange,
                size: .badgeXL, style: streak.isTodayTracked ? .filled : .tinted
            )
            .contentTransition(.symbolEffect(.replace))
            .symbolEffect(.bounce, value: isShown)
            .symbolEffect(
                .pulse, options: .repeating, isActive: streak.isTodayTracked && !reduceMotion)
            VStack(alignment: .leading, spacing: .spaceHairline) {
                Text(journey.streakTitle)
                    .font(.amountTitle)
                    .contentTransition(.numericText(value: Double(streak.current)))
                InlineLabel(
                    journey.streakStatus,
                    symbol: streak.isTodayTracked ? "checkmark.circle.fill" : "clock"
                )
                .font(.footnote.weight(.semibold))
                .foregroundStyle(streak.isTodayTracked ? Color.positive : .secondary)
            }
        }
        .padding(.vertical, .space2XS)
        .accessibilityElement(children: .combine)
        .sensoryFeedback(.success, trigger: streak.isTodayTracked) { _, isTracked in isTracked }
        .task { isShown = true }
    }
}

private struct StreakFiguresRow: View {
    @Environment(JourneyModel.self) private var journey

    var body: some View {
        HStack(spacing: .spaceS) {
            FigureCell(
                caption: "Best", value: journey.bestStreak, symbol: "trophy",
                color: .retroMustard)
            FigureCell(
                caption: "Freezes", value: journey.freezesCaption, symbol: "snowflake",
                color: .info)
        }
        .padding(.vertical, .space2XS)
    }
}

private struct MilestoneRow: View {
    @Environment(JourneyModel.self) private var journey

    var body: some View {
        HStack(spacing: .spaceM) {
            SymbolBadge("flag.checkered", color: .retroOrange, size: .badgeM)
            VStack(alignment: .leading, spacing: .spaceS) {
                HStack(alignment: .firstTextBaseline, spacing: .spaceS) {
                    Text(journey.milestoneTitle)
                        .font(.rowTitle)
                        .frame(maxWidth: .infinity, alignment: .leading)
                    Text(journey.milestoneDetail)
                        .font(.footnote)
                        .foregroundStyle(.secondary)
                        .lineLimit(1)
                }
                FillingBar(value: journey.streakMilestone?.progress ?? 1, color: .retroOrange)
            }
        }
        .accessibilityElement(children: .combine)
    }
}

private struct WeekStrip: View {
    let days: [Streak.Day]

    var body: some View {
        HStack(spacing: 0) {
            ForEach(days.enumerated(), id: \.offset) { index, day in
                VStack(spacing: .spaceXS) {
                    Text(day.date.formatted(Date.FormatStyle(locale: .app).weekday(.narrow)))
                        .font(.caption2.weight(.semibold))
                        .foregroundStyle(index == days.count - 1 ? .primary : .secondary)
                    DayMark(day: day, isToday: index == days.count - 1)
                }
                .frame(maxWidth: .infinity)
                .cascade(index)
                .accessibilityElement(children: .ignore)
                .accessibilityLabel(
                    day.date.formatted(Date.FormatStyle(locale: .app).weekday(.wide)) + ": "
                        + day.state.title)
            }
        }
        .padding(.vertical, .space2XS)
    }
}

private struct DayMark: View {
    let day: Streak.Day
    let isToday: Bool

    var body: some View {
        switch day.state {
        case .tracked:
            SymbolBadge("flame.fill", color: .retroOrange, size: .badgeS, style: .filled)
        case .covered:
            SymbolBadge("snowflake", color: .info, size: .badgeS)
        case .missed:
            Circle()
                .strokeBorder(
                    isToday ? Color.retroOrange : Color.secondary.opacity(.opacitySoft),
                    style: StrokeStyle(lineWidth: .spaceHairline, dash: isToday ? [.space2XS] : [])
                )
                .frame(width: .badgeS, height: .badgeS)
        }
    }
}

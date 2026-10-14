import CashlyDesignSystem
import CashlyGame
import SwiftUI

struct LevelSection: View {
    @Environment(JourneyModel.self) private var journey
    @Environment(\.appTint) private var appTint

    var body: some View {
        if let level = journey.progress?.level {
            Section {
                LevelBarRow(level: level)
                RankRow(level: level)
            } header: {
                VStack(spacing: .spaceS) {
                    Chip(level.title.uppercased(), color: appTint, shape: .capsule)
                    Text(journey.levelHeadline)
                        .font(.amountHero)
                        .foregroundStyle(Color.primary)
                        .contentTransition(.numericText(value: Double(level.number)))
                        .amountLine()
                    Text(journey.totalXP).font(.subheadline).foregroundStyle(.secondary)
                }
                .textCase(nil)
                .multilineTextAlignment(.center)
                .frame(maxWidth: .infinity)
                .padding(.vertical, .spaceL)
                .accessibilityElement(children: .combine)
            }
        }
    }
}

private struct LevelBarRow: View {
    @Environment(JourneyModel.self) private var journey
    @Environment(\.appTint) private var appTint
    let level: GameLevel

    var body: some View {
        VStack(alignment: .leading, spacing: .spaceS) {
            HStack(alignment: .firstTextBaseline) {
                Text(journey.xpCaption)
                    .font(.subheadline.weight(.bold))
                    .foregroundStyle(appTint)
                    .monospacedDigit()
                    .contentTransition(.numericText(value: Double(level.xpIntoLevel)))
                Spacer()
                Text(journey.levelCaption).font(.footnote).foregroundStyle(.secondary)
            }
            .lineLimit(1)
            HStack(spacing: .spaceS) {
                LevelMark(number: level.number, color: appTint)
                FillingBar(value: level.progress, color: appTint)
                if level.xpForNextLevel > 0 {
                    LevelMark(number: level.number + 1, color: .secondary)
                }
            }
        }
        .padding(.vertical, .space2XS)
        .accessibilityElement(children: .combine)
    }
}

private struct LevelMark: View {
    let number: Int
    let color: Color

    var body: some View {
        Chip(number.formatted(.number.locale(.app)), color: color)
            .monospacedDigit()
            .contentTransition(.numericText(value: Double(number)))
            .fixedSize()
    }
}

private struct RankRow: View {
    @Environment(JourneyModel.self) private var journey
    @Environment(\.appTint) private var appTint
    @Environment(\.accessibilityReduceMotion) private var reduceMotion
    @State private var isShown = false
    let level: GameLevel

    var body: some View {
        HStack(spacing: .spaceM) {
            SymbolBadge("medal.fill", color: appTint, size: .badgeM)
                .symbolEffect(.bounce, value: isShown)
            VStack(alignment: .leading, spacing: .spaceS) {
                Text(journey.nextTitleCaption).font(.rowTitle)
                SegmentedBar(
                    count: GameLevel.rankLength, value: isShown ? journey.rankSteps : 0,
                    color: appTint
                )
                .animation(reduceMotion ? nil : .smooth(duration: 1), value: isShown)
                .animation(reduceMotion ? nil : .smooth, value: journey.rankSteps)
                HStack(alignment: .firstTextBaseline) {
                    Text(level.title)
                    Spacer()
                    Text(journey.nextRankDetail)
                }
                .font(.footnote)
                .foregroundStyle(.secondary)
                .lineLimit(1)
            }
        }
        .accessibilityElement(children: .combine)
        .task { isShown = true }
    }
}

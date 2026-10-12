import CashlyDesignSystem
import CashlyGame
import SwiftUI

struct LevelSection: View {
    @Environment(JourneyModel.self) private var journey
    @Environment(\.appTint) private var appTint
    @Environment(\.accessibilityReduceMotion) private var reduceMotion
    @State private var isFilled = false

    var body: some View {
        if let level = journey.progress?.level {
            let animation: Animation? = reduceMotion ? nil : .smooth(duration: 1)
            Section {
                VStack(alignment: .leading, spacing: .spaceS) {
                    HStack(alignment: .firstTextBaseline) {
                        Text(journey.xpCaption)
                            .font(.subheadline.weight(.semibold))
                            .monospacedDigit()
                        Spacer()
                        Text(journey.totalXP).font(.footnote).foregroundStyle(.secondary)
                    }
                    .lineLimit(1)
                    ProgressView(value: isFilled ? level.progress : 0)
                        .tint(appTint)
                        .animation(animation, value: isFilled)
                        .animation(animation, value: level.progress)
                }
                .padding(.vertical, .space2XS)
                .accessibilityElement(children: .combine)
                .task { isFilled = true }
                HStack(spacing: .spaceM) {
                    SymbolBadge("medal.fill", color: appTint, size: .badgeM)
                    VStack(alignment: .leading, spacing: .spaceS) {
                        Text(journey.nextTitleCaption).font(.rowTitle)
                        SegmentedBar(
                            count: GameLevel.ranks, value: isFilled ? level.rankProgress : 0,
                            color: appTint
                        )
                        .animation(animation, value: isFilled)
                        .animation(animation, value: level.rankProgress)
                    }
                }
                .accessibilityElement(children: .combine)
            } header: {
                VStack(spacing: .spaceS) {
                    Chip(level.title.uppercased(), color: appTint, shape: .capsule)
                    Text(journey.levelHeadline)
                        .font(.amountHero)
                        .foregroundStyle(Color.primary)
                        .contentTransition(.numericText(value: Double(level.number)))
                        .amountLine()
                    Text(journey.levelCaption).font(.subheadline).foregroundStyle(.secondary)
                }
                .textCase(nil)
                .multilineTextAlignment(.center)
                .frame(maxWidth: .infinity)
                .padding(.vertical, .spaceL)
            }
        }
    }
}

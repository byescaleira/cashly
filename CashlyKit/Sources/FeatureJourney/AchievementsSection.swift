import CashlyDesignSystem
import CashlyGame
import FeatureCore
import SwiftUI

struct AchievementsSection: View {
    @Environment(JourneyModel.self) private var journey

    var body: some View {
        if let achievements = journey.progress?.achievements, !achievements.isEmpty {
            let ratio = Double(achievements.filter(\.isUnlocked).count) / Double(achievements.count)
            Section {
                VStack(alignment: .leading, spacing: .spaceXS) {
                    HStack(alignment: .firstTextBaseline) {
                        Text(journey.achievementsCaption).font(.subheadline.weight(.semibold))
                        Spacer()
                        Text(ratio.formatted(.percent.precision(.fractionLength(0)).locale(.app)))
                            .font(.subheadline.weight(.bold))
                            .foregroundStyle(Color.retroMustard)
                            .contentTransition(.numericText(value: ratio))
                    }
                    .lineLimit(1)
                    ProgressView(value: ratio).tint(.retroMustard).animation(.smooth, value: ratio)
                }
                .padding(.vertical, .space2XS)
                .accessibilityElement(children: .combine)
                ForEach(Achievement.Group.allCases, id: \.self) { group in
                    AchievementGroupRow(
                        group: group, states: achievements.filter { $0.achievement.group == group })
                }
            } header: {
                Text("Achievements").sectionTitle()
            }
        }
    }
}

private struct AchievementGroupRow: View {
    @Environment(JourneyModel.self) private var journey
    let group: Achievement.Group
    let states: [AchievementState]

    var body: some View {
        VStack(alignment: .leading, spacing: .spaceM) {
            HStack(alignment: .firstTextBaseline) {
                Text(group.title).font(.rowTitle)
                Spacer()
                Text("\(states.filter(\.isUnlocked).count)/\(states.count)")
                    .font(.footnote.weight(.semibold).monospacedDigit())
                    .foregroundStyle(.secondary)
            }
            LazyVGrid(
                columns: [GridItem(.adaptive(minimum: .badgeXL + .spaceXL), spacing: .spaceM)],
                spacing: .spaceL
            ) {
                ForEach(states) { state in
                    Button {
                        journey.selected = state
                    } label: {
                        AchievementCell(state: state)
                    }
                    .buttonStyle(.plain)
                }
            }
        }
        .padding(.vertical, .spaceS)
    }
}

private struct AchievementCell: View {
    let state: AchievementState

    var body: some View {
        VStack(spacing: .spaceXS) {
            AchievementBadge(state: state, size: .badgeXL)
            Text(state.title)
                .font(.caption2.weight(.medium))
                .foregroundStyle(state.isUnlocked ? .primary : .secondary)
                .multilineTextAlignment(.center)
                .lineLimit(2, reservesSpace: true)
        }
        .contentShape(.rect)
        .accessibilityElement(children: .combine)
        .accessibilityValue(state.isUnlocked ? Text("Unlocked") : Text("Locked"))
    }
}

struct AchievementBadge: View {
    let state: AchievementState
    let size: CGFloat

    var body: some View {
        let color = state.achievement.tier.color
        Image(systemName: state.symbol)
            .font(.system(size: size * 0.42, weight: .semibold))
            .foregroundStyle(state.isUnlocked ? Color.white : Color.secondary)
            .frame(width: size, height: size)
            .background(
                state.isUnlocked
                    ? AnyShapeStyle(color.gradient)
                    : AnyShapeStyle(Color.secondary.opacity(.opacityFill)),
                in: .circle
            )
            .overlay {
                Circle().strokeBorder(
                    state.isUnlocked ? color.opacity(.opacitySoft) : Color.clear,
                    lineWidth: .spaceHairline)
            }
            .accessibilityHidden(true)
    }
}

struct AchievementDetailScreen: View {
    @Environment(\.dismiss) private var dismiss
    @State private var isShown = false
    let state: AchievementState

    var body: some View {
        VStack(spacing: .spaceL) {
            AchievementBadge(state: state, size: .ring)
                .symbolEffect(.bounce, value: isShown)
            VStack(spacing: .spaceXS) {
                Text(state.title).font(.titleMedium)
                Text(state.detail).foregroundStyle(.secondary)
            }
            .multilineTextAlignment(.center)
            if !state.isUnlocked && state.achievement.target > 1 {
                VStack(spacing: .spaceXS) {
                    ProgressView(value: isShown ? state.progress : 0)
                        .tint(state.achievement.tier.color)
                        .animation(.smooth(duration: 1), value: isShown)
                    Text(
                        "\(min(state.value, state.achievement.target)) of \(state.achievement.target)"
                    )
                    .font(.footnote.monospacedDigit())
                    .foregroundStyle(.secondary)
                }
            }
            if !state.isHidden {
                Chip(
                    "\(state.achievement.tier.title) · \(state.achievement.xp) XP",
                    color: state.achievement.tier.color, shape: .capsule)
            }
            Button("Done") { dismiss() }
                .prominentButton()
        }
        .padding(.spaceXL)
        .frame(maxWidth: .infinity)
        .presentationDetents([.medium])
        .task { isShown = true }
    }
}

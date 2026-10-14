import CashlyDesignSystem
import CashlyGame
import FeatureCore
import SwiftUI

struct AchievementsSection: View {
    @Environment(JourneyModel.self) private var journey

    var body: some View {
        if let achievements = journey.progress?.achievements, !achievements.isEmpty {
            Section {
                AchievementsSummaryRow()
                ForEach(journey.nextAchievements) { NextAchievementRow(state: $0) }
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

private struct AchievementsSummaryRow: View {
    @Environment(JourneyModel.self) private var journey

    var body: some View {
        let ratio = journey.unlockedRatio
        VStack(alignment: .leading, spacing: .spaceS) {
            HStack(alignment: .firstTextBaseline) {
                Text(journey.achievementsCaption).font(.subheadline.weight(.semibold))
                Spacer()
                Text(ratio.formatted(.percent.precision(.fractionLength(0)).locale(.app)))
                    .font(.subheadline.weight(.bold))
                    .foregroundStyle(Color.retroMustard)
                    .contentTransition(.numericText(value: ratio))
            }
            .lineLimit(1)
            FillingBar(value: ratio, color: .retroMustard)
        }
        .padding(.vertical, .space2XS)
        .accessibilityElement(children: .combine)
    }
}

private struct NextAchievementRow: View {
    @Environment(JourneyModel.self) private var journey
    let state: AchievementState

    var body: some View {
        let color = state.achievement.tier.color
        Button {
            journey.selected = state
        } label: {
            HStack(spacing: .spaceM) {
                AchievementBadge(state: state, size: .badgeL, isPreview: true)
                VStack(alignment: .leading, spacing: .spaceXS) {
                    HStack(alignment: .firstTextBaseline, spacing: .spaceS) {
                        Text(state.title)
                            .font(.rowTitle)
                            .frame(maxWidth: .infinity, alignment: .leading)
                        Chip("+\(state.achievement.xp) XP", color: color).fixedSize()
                    }
                    HStack(spacing: .spaceS) {
                        FillingBar(value: state.progress, color: color)
                        Text(journey.valueCaption(of: state))
                            .font(.footnote.weight(.semibold).monospacedDigit())
                            .foregroundStyle(.secondary)
                    }
                }
            }
            .contentShape(.rect)
        }
        .tint(Color.primary)
        .accessibilityElement(children: .combine)
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
                ForEach(states.enumerated(), id: \.element.id) { index, state in
                    Button {
                        journey.selected = state
                    } label: {
                        AchievementCell(state: state)
                    }
                    .buttonStyle(.plain)
                    .cascade(index)
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
            AchievementBadge(state: state, size: .badgeXL, isPreview: state.isStarted)
            FillingBar(value: state.progress, color: state.achievement.tier.color)
                .frame(width: .badgeXL - .spaceL)
                .opacity(state.isStarted ? 1 : 0)
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
    var isPreview = false

    var body: some View {
        let color = state.achievement.tier.color
        Image(systemName: state.symbol)
            .font(.system(size: size * 0.42, weight: .semibold))
            .foregroundStyle(foreground(color))
            .frame(width: size, height: size)
            .background(background(color), in: .circle)
            .overlay {
                Circle().strokeBorder(
                    state.isUnlocked ? color.opacity(.opacitySoft) : Color.clear,
                    lineWidth: .spaceHairline)
            }
            .accessibilityHidden(true)
    }

    private func foreground(_ color: Color) -> Color {
        state.isUnlocked ? .white : isPreview ? color : .secondary
    }

    private func background(_ color: Color) -> AnyShapeStyle {
        if state.isUnlocked { return AnyShapeStyle(color.gradient) }
        if isPreview { return AnyShapeStyle(color.opacity(.opacityTint)) }
        return AnyShapeStyle(Color.secondary.opacity(.opacityFill))
    }
}

struct AchievementDetailScreen: View {
    @Environment(JourneyModel.self) private var journey
    @Environment(\.dismiss) private var dismiss
    @State private var isShown = false
    let state: AchievementState

    var body: some View {
        let color = state.achievement.tier.color
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
                    FillingBar(value: state.progress, color: color)
                    Text(journey.valueCaption(of: state))
                        .font(.footnote.monospacedDigit())
                        .foregroundStyle(.secondary)
                }
            }
            if !state.isHidden {
                Chip(
                    "\(state.achievement.tier.title) · \(state.achievement.xp) XP",
                    color: color, shape: .capsule)
            }
            Button("Done") { dismiss() }
                .primaryButton()
        }
        .padding(.spaceXL)
        .frame(maxWidth: .infinity)
        .presentationDetents([.medium])
        .task { isShown = true }
    }
}

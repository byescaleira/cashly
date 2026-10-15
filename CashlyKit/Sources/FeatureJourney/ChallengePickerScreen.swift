import CashlyDesignSystem
import CashlyDomain
import CashlyGame
import FeatureCore
import SwiftUI

struct ChallengePickerScreen: View {
    @Environment(JourneyModel.self) private var journey
    @Environment(\.dismiss) private var dismiss

    var body: some View {
        @Bindable var journey = journey
        NavigationStack(path: $journey.challengePath) {
            List {
                ChallengeCostSection()
                ForEach(journey.challengeThemes, id: \.self) { ChallengeThemeSection(theme: $0) }
                ChallengeRecentSection()
            }
            .readableWidth()
            .fontDesign(.rounded)
            .navigationTitle("New Challenge")
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel", systemImage: "xmark") { dismiss() }
                }
            }
            .navigationDestination(for: Challenge.Kind.self) { ChallengeSetupScreen(kind: $0) }
        }
        .sheet(isPresented: $journey.isOfferingRerolls) {
            ShopItemScreen(item: .challengeRerolls)
        }
    }
}

private struct ChallengeCostSection: View {
    @Environment(JourneyModel.self) private var journey
    @Environment(\.appTint) private var appTint

    var body: some View {
        Section {
            HStack(spacing: .spaceM) {
                SymbolBadge("flag.checkered", color: appTint, size: .badgeM, style: .filled)
                VStack(alignment: .leading, spacing: .spaceHairline) {
                    Text(journey.catalogCaption).font(.rowTitle)
                    Text(journey.costCaption).font(.rowDetail).foregroundStyle(.secondary)
                }
            }
            .accessibilityElement(children: .combine)
        } footer: {
            Text("One challenge at a time. Progress comes from your records.")
        }
    }
}

private struct ChallengeThemeSection: View {
    @Environment(JourneyModel.self) private var journey
    let theme: Challenge.Theme

    var body: some View {
        Section {
            ForEach(journey.kinds(in: theme).enumerated(), id: \.element) { index, kind in
                ChallengeKindRow(kind: kind).cascade(index)
            }
        } header: {
            HStack(spacing: .spaceXS) {
                Image(systemName: theme.symbol).foregroundStyle(theme.color)
                Text(theme.title)
            }
            .sectionTitle()
        } footer: {
            Text(theme.detail)
        }
    }
}

private struct ChallengeKindRow: View {
    @Environment(JourneyModel.self) private var journey
    let kind: Challenge.Kind

    var body: some View {
        let blocker = journey.blocker(for: kind)
        Button {
            journey.select(kind)
        } label: {
            HStack(alignment: .top, spacing: .spaceM) {
                SymbolBadge(kind.symbol, color: kind.color, size: .badgeL)
                VStack(alignment: .leading, spacing: .spaceXS) {
                    Text(kind.title).font(.rowTitle)
                    Text(kind.detail).font(.rowDetail).foregroundStyle(.secondary)
                    ChallengeChips(kind: kind)
                    if let blocker {
                        InlineLabel(blocker.title, symbol: "lock")
                            .font(.caption)
                            .foregroundStyle(.secondary)
                    }
                }
                .frame(maxWidth: .infinity, alignment: .leading)
                Image(systemName: "chevron.right")
                    .font(.icon(.s, weight: .semibold))
                    .foregroundStyle(.tertiary)
            }
            .opacity(blocker == nil ? 1 : .opacityStrong)
            .contentShape(.rect)
        }
        .tint(Color.primary)
        .accessibilityElement(children: .combine)
    }
}

struct ChallengeChips: View {
    let kind: Challenge.Kind

    var body: some View {
        FlowLayout(spacing: .spaceXS) {
            Chip(kind.length.title, color: .secondary)
            Chip(kind.difficulty.title, color: kind.difficulty.color)
            Chip("+\(kind.xp) XP", color: kind.color)
        }
    }
}

private struct ChallengeRecentSection: View {
    @Environment(JourneyModel.self) private var journey

    var body: some View {
        if !journey.recentChallenges.isEmpty {
            Section {
                ForEach(journey.recentChallenges.enumerated(), id: \.offset) { _, state in
                    ChallengeRecentRow(state: state)
                }
            } header: {
                Text("Recent").sectionTitle()
            }
        }
    }
}

private struct ChallengeRecentRow: View {
    @Environment(JourneyModel.self) private var journey
    let state: ChallengeState

    var body: some View {
        let isDone = state.status == .completed
        let color: Color = isDone ? .positive : .negative
        HStack(spacing: .spaceM) {
            SymbolBadge(isDone ? "checkmark" : "xmark", color: color, size: .badgeM)
            VStack(alignment: .leading, spacing: .spaceHairline) {
                Text(state.challenge.kind.title).font(.rowTitle)
                Text(journey.recentPeriod(of: state)).font(.rowDetail).foregroundStyle(.secondary)
            }
            .frame(maxWidth: .infinity, alignment: .leading)
            Chip(journey.recentOutcome(of: state), color: color).fixedSize()
        }
        .accessibilityElement(children: .combine)
    }
}

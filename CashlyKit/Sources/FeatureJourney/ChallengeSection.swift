import CashlyDesignSystem
import CashlyGame
import FeatureCore
import SwiftUI
import TipKit

struct ChallengeSection: View {
    @Environment(JourneyModel.self) private var journey
    @Environment(\.shop) private var shop
    @Environment(\.pro) private var pro

    var body: some View {
        @Bindable var journey = journey
        if let progress = journey.progress {
            Section {
                if let state = progress.challenge {
                    ChallengeRow(state: state)
                        .swipeActions {
                            Button("Give Up", systemImage: "xmark", role: .destructive) {
                                pro.perform { journey.isConfirmingAbandon = true }
                            }
                        }
                        .contextMenu {
                            Button("Give Up", systemImage: "xmark", role: .destructive) {
                                pro.perform { journey.isConfirmingAbandon = true }
                            }
                        }
                    Button(
                        "Change Challenge",
                        systemImage: progress.canStartChallenge
                            ? "arrow.triangle.2.circlepath" : "lock"
                    ) {
                        pro.perform {
                            if progress.canStartChallenge {
                                journey.chooseChallenge()
                            } else {
                                shop.open(.challengeRerolls)
                            }
                        }
                    }
                    .font(.buttonLabel)
                } else {
                    TipView(ChallengeTip()).tipBackground(.clear)
                    ForEach(journey.challengeSuggestions.enumerated(), id: \.element) {
                        index, kind in
                        ChallengeOption(kind: kind, isLocked: !progress.canStartChallenge)
                            .cascade(index)
                    }
                    Button("See All Challenges", systemImage: "square.grid.2x2") {
                        pro.perform { journey.chooseChallenge() }
                    }
                    .font(.buttonLabel)
                }
            } header: {
                Text("Challenge").sectionTitle()
            } footer: {
                Text(journey.challengeFooter)
            }
            .confirmationDialog(
                "Give up the challenge?", isPresented: $journey.isConfirmingAbandon,
                titleVisibility: .visible
            ) {
                Button("Give Up", role: .destructive) {
                    Task { await journey.abandonChallenge() }
                }
            }
            .onChange(of: progress.challenge == nil, initial: true) { _, isEmpty in
                ChallengeTip.hasChallenge = !isEmpty
            }
        }
    }
}

private struct ChallengeOption: View {
    @Environment(JourneyModel.self) private var journey
    @Environment(\.shop) private var shop
    @Environment(\.pro) private var pro
    let kind: Challenge.Kind
    let isLocked: Bool

    var body: some View {
        Button {
            pro.perform {
                if isLocked { shop.open(.challengeRerolls) } else { journey.chooseChallenge(kind) }
            }
        } label: {
            HStack(alignment: .top, spacing: .spaceM) {
                SymbolBadge(kind.symbol, color: kind.color, size: .badgeM)
                VStack(alignment: .leading, spacing: .spaceXS) {
                    Text(kind.title).font(.rowTitle)
                    Text(kind.detail).font(.footnote).foregroundStyle(.secondary)
                    ChallengeChips(kind: kind)
                }
                .frame(maxWidth: .infinity, alignment: .leading)
            }
            .contentShape(.rect)
        }
        .tint(Color.primary)
        .accessibilityElement(children: .combine)
    }
}

private struct ChallengeRow: View {
    @Environment(JourneyModel.self) private var journey
    @State private var isShown = false
    let state: ChallengeState

    var body: some View {
        let kind = state.challenge.kind
        HStack(alignment: .top, spacing: .spaceM) {
            SymbolBadge(kind.symbol, color: kind.color, size: .badgeL, style: .filled)
                .symbolEffect(.bounce, value: isShown)
            VStack(alignment: .leading, spacing: .spaceS) {
                VStack(alignment: .leading, spacing: .spaceHairline) {
                    HStack(alignment: .firstTextBaseline) {
                        Text(kind.title).font(.rowTitle)
                        Spacer()
                        Chip("+\(kind.xp) XP", color: kind.color).fixedSize()
                    }
                    Text(journey.detail(of: state))
                        .font(.footnote)
                        .foregroundStyle(.secondary)
                }
                if let outlook = journey.challengeOutlook {
                    ChallengeProgress(state: state, outlook: outlook)
                } else {
                    Text(journey.ending(of: state)).font(.caption).foregroundStyle(.secondary)
                }
            }
        }
        .padding(.vertical, .space2XS)
        .accessibilityElement(children: .combine)
        .task { isShown = true }
    }
}

private struct ChallengeProgress: View {
    @Environment(JourneyModel.self) private var journey
    let state: ChallengeState
    let outlook: ChallengeOutlook

    var body: some View {
        let color = outlook.pace?.color ?? state.challenge.kind.color
        VStack(alignment: .leading, spacing: .spaceXS) {
            FillingBar(value: outlook.progress, color: color, marker: outlook.elapsed)
            HStack(alignment: .firstTextBaseline) {
                Text(journey.progressCaption(of: state))
                    .font(.caption.weight(.semibold).monospacedDigit())
                    .foregroundStyle(color)
                    .contentTransition(.numericText(value: outlook.progress))
                Spacer()
                InlineLabel(journey.daysLeftCaption(outlook), symbol: "hourglass")
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }
            .lineLimit(1)
            if let pace = outlook.pace {
                InlineLabel(journey.paceTitle(pace, of: state), symbol: pace.symbol)
                    .font(.footnote.weight(.semibold))
                    .foregroundStyle(pace.color)
            }
        }
    }
}

extension ChallengeOutlook.Pace {
    var symbol: String {
        switch self {
        case .steady: "checkmark.circle"
        case .fast: "hare"
        case .over: "exclamationmark.triangle"
        }
    }

    var color: Color {
        switch self {
        case .steady: .positive
        case .fast: .warning
        case .over: .negative
        }
    }
}

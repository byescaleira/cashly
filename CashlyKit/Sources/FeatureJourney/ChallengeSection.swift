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
                }
                if progress.challenge == nil { TipView(ChallengeTip()).tipBackground(.clear) }
                Button(
                    progress.challenge == nil ? "Choose a Challenge" : "Change Challenge",
                    systemImage: progress.canStartChallenge ? "flag" : "lock"
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
                .disabled(journey.categories.isEmpty)
                .confirmationDialog(
                    "Give up the challenge?", isPresented: $journey.isConfirmingAbandon,
                    titleVisibility: .visible
                ) {
                    Button("Give Up", role: .destructive) {
                        Task { await journey.abandonChallenge() }
                    }
                }
            } header: {
                Text("Challenge").sectionTitle()
            } footer: {
                Text(journey.challengeFooter)
            }
            .onChange(of: progress.challenge == nil, initial: true) { _, isEmpty in
                ChallengeTip.hasChallenge = !isEmpty
            }
        }
    }
}

private struct ChallengeRow: View {
    @Environment(JourneyModel.self) private var journey
    @Environment(\.appTint) private var appTint
    let state: ChallengeState

    var body: some View {
        HStack(alignment: .top, spacing: .spaceM) {
            SymbolBadge(state.challenge.kind.symbol, color: appTint, size: .badgeM)
            VStack(alignment: .leading, spacing: .spaceXS) {
                HStack(alignment: .firstTextBaseline) {
                    Text(state.challenge.kind.title).font(.rowTitle)
                    Spacer()
                    Chip("\(state.challenge.kind.xp) XP", color: appTint)
                }
                Text(journey.detail(of: state.challenge))
                    .font(.footnote)
                    .foregroundStyle(.secondary)
                if case .active(let value) = state.status {
                    let progress = min(max(value, 0), 1)
                    ProgressView(value: progress).tint(appTint).animation(.smooth, value: progress)
                    HStack {
                        Text(journey.ending(of: state)).font(.caption).foregroundStyle(.tertiary)
                        Spacer()
                        Text(
                            progress.formatted(.percent.precision(.fractionLength(0)).locale(.app))
                        )
                        .font(.caption.weight(.semibold).monospacedDigit())
                        .foregroundStyle(appTint)
                        .contentTransition(.numericText(value: progress))
                    }
                } else {
                    Text(journey.ending(of: state)).font(.caption).foregroundStyle(.tertiary)
                }
            }
        }
        .accessibilityElement(children: .combine)
    }
}

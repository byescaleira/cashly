import CashlyDesignSystem
import CashlyGame
import FeatureCore
import SwiftUI

struct ChallengeSetupScreen: View {
    @Environment(JourneyModel.self) private var journey
    let kind: Challenge.Kind

    var body: some View {
        ScrollView {
            VStack(spacing: .spaceXL) {
                ChallengeSetupHero(kind: kind)
                if kind.needsCategory || kind.needsLimit { ChallengeSetupOptions(kind: kind) }
                ChallengeSetupSummary(kind: kind)
            }
            .padding(.horizontal, .spaceInset)
            .padding(.vertical, .spaceL)
        }
        .readableWidth()
        .background(.groupedBackground)
        .safeAreaInset(edge: .bottom) { ChallengeSetupBar(kind: kind) }
        .fontDesign(.rounded)
        .navigationTitle(kind.title)
        #if !os(macOS)
            .navigationBarTitleDisplayMode(.inline)
        #endif
    }
}

private struct ChallengeSetupHero: View {
    @State private var isShown = false
    let kind: Challenge.Kind

    var body: some View {
        VStack(spacing: .spaceM) {
            SymbolBadge(kind.symbol, color: kind.color, size: .badgeXL, style: .filled)
                .symbolEffect(.bounce, value: isShown)
            Text(kind.title).font(.titleLarge)
            Text(kind.detail).font(.body).foregroundStyle(.secondary)
            HStack(spacing: .spaceXS) {
                Chip(kind.theme.title, color: kind.color, shape: .capsule)
                Chip(kind.length.title, color: .secondary, shape: .capsule)
                Chip(kind.difficulty.title, color: kind.difficulty.color, shape: .capsule)
            }
        }
        .multilineTextAlignment(.center)
        .frame(maxWidth: .infinity)
        .task { isShown = true }
    }
}

private struct ChallengeSetupOptions: View {
    @Environment(JourneyModel.self) private var journey
    let kind: Challenge.Kind

    var body: some View {
        @Bindable var journey = journey
        VStack(alignment: .leading, spacing: .spaceM) {
            if kind.choosesCategory {
                LabeledContent("Category") {
                    Picker("Category", selection: $journey.draftCategoryID) {
                        ForEach(journey.categories) { category in
                            Label(category.name, systemImage: category.icon)
                                .tag(Optional(category.id))
                        }
                    }
                    .labelsHidden()
                    .pickerStyle(.menu)
                }
                .font(.rowTitle)
            } else {
                LabeledContent("Category", value: journey.draftCategoryName).font(.rowTitle)
            }
            if let caption = journey.lastMonthCaption {
                Text(caption).font(.rowDetail).foregroundStyle(.secondary)
            }
            if kind.needsLimit { ChallengeLimitField() }
        }
        .padding(.spaceL)
        .background(.groupedRow, in: .rect(cornerRadius: .radiusL))
    }
}

private struct ChallengeLimitField: View {
    @Environment(JourneyModel.self) private var journey

    var body: some View {
        @Bindable var journey = journey
        Divider()
        VStack(alignment: .leading, spacing: .spaceS) {
            Text("Limit").font(.rowTitle)
            CurrencyField(amount: $journey.draft.limit).font(.amountTitle)
            if let suggestion = journey.suggestionCaption {
                Button(suggestion, systemImage: "wand.and.sparkles") {
                    journey.useSuggestedLimit()
                }
                .font(.footnote.weight(.semibold))
                .buttonStyle(.borderless)
            }
        }
    }
}

private struct ChallengeSetupSummary: View {
    @Environment(JourneyModel.self) private var journey
    let kind: Challenge.Kind

    var body: some View {
        VStack(alignment: .leading, spacing: .spaceM) {
            if let goal = journey.draftGoal {
                ChallengeSummaryLine(goal, symbol: "target", color: kind.color)
            }
            ChallengeSummaryLine(journey.draftPeriodText, symbol: "calendar", color: kind.color)
            ChallengeSummaryLine(journey.draftReward, symbol: "star", color: kind.color)
            ChallengeSummaryLine(journey.draftCostText, symbol: "ticket", color: kind.color)
            if let warning = journey.draftWarning {
                ChallengeSummaryLine(warning, symbol: "exclamationmark.triangle", color: .warning)
            }
            if let blocker = journey.blocker(for: kind) {
                ChallengeSummaryLine(blocker.title, symbol: "lock", color: .negative)
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(.spaceL)
        .background(kind.color.opacity(.opacityFill), in: .rect(cornerRadius: .radiusL))
    }
}

private struct ChallengeSummaryLine: View {
    let text: String
    let symbol: String
    let color: Color

    init(_ text: String, symbol: String, color: Color) {
        self.text = text
        self.symbol = symbol
        self.color = color
    }

    var body: some View {
        HStack(alignment: .firstTextBaseline, spacing: .spaceS) {
            Image(systemName: symbol)
                .foregroundStyle(color)
                .frame(width: .badgeS)
            Text(text).font(.subheadline)
                .fixedSize(horizontal: false, vertical: true)
        }
    }
}

private struct ChallengeSetupBar: View {
    @Environment(JourneyModel.self) private var journey
    let kind: Challenge.Kind

    var body: some View {
        Group {
            if journey.challengeCost == .locked {
                Button("Get Rerolls") { journey.isOfferingRerolls = true }
            } else {
                Button("Start Challenge") { Task { await journey.startChallenge() } }
                    .disabled(!journey.canStartDraft)
            }
        }
        .primaryButton()
        .padding(.horizontal, .spaceInset)
        .padding(.vertical, .spaceM)
        .readableWidth()
    }
}

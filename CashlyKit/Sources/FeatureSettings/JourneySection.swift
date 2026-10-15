import CashlyDesignSystem
import FeatureCore
import SwiftUI

struct JourneySettingsScreen: View {
    @Environment(SettingsModel.self) private var settings
    @Environment(SessionModel.self) private var session: SessionModel?

    var body: some View {
        @Bindable var settings = settings
        SettingsPage("Journey") {
            JourneySummarySection()
            JourneyVisibilitySection()
            JourneyEffectsSection()
        }
        .sensoryFeedback(.selection, trigger: settings.showsJourney)
        .sheet(isPresented: $settings.isConfirmingHideJourney) { JourneyHideSheet() }
        .task(id: session?.generation) {
            guard let session else { return }
            await settings.loadJourney(session: session)
        }
    }
}

private struct JourneySummarySection: View {
    @Environment(SettingsModel.self) private var settings
    @Environment(\.appTint) private var appTint

    var body: some View {
        Section {
            if let journey = settings.journey {
                VStack(alignment: .leading, spacing: .spaceS) {
                    if let caption = settings.journeyXPCaption {
                        Text(verbatim: caption)
                            .font(.subheadline.weight(.bold))
                            .foregroundStyle(appTint)
                            .monospacedDigit()
                    }
                    SettingsBar(value: journey.levelProgress, color: appTint)
                }
                .padding(.vertical, .space2XS)
                HStack(spacing: .spaceS) {
                    JourneyFigure(
                        caption: "Streak", value: settings.journeyStreakText, symbol: "flame",
                        color: .retroOrange
                    )
                    .settingsReveal(0)
                    JourneyFigure(
                        caption: "Achievements", value: settings.journeyAchievementsText,
                        symbol: "medal", color: .retroMustard
                    )
                    .settingsReveal(1)
                    JourneyFigure(
                        caption: "Challenges", value: settings.journeyChallengesText,
                        symbol: "flag.checkered", color: .retroTeal
                    )
                    .settingsReveal(2)
                }
                .padding(.vertical, .space2XS)
            }
        } header: {
            SettingsHero {
                SymbolBadge("trophy", color: .retroMustard, size: .badgeXL)
                    .symbolEffect(.bounce, value: settings.journey?.level)
                Text(verbatim: settings.journeyHeadline)
                    .font(.amountHero)
                    .foregroundStyle(Color.primary)
                    .contentTransition(.numericText(value: Double(settings.journey?.level ?? 0)))
                    .amountLine()
                Chip(
                    settings.showsJourney ? "Visible" : "Hidden",
                    color: settings.showsJourney ? appTint : .secondary, shape: .capsule)
            }
            .animation(.smooth, value: settings.showsJourney)
        }
    }
}

private struct JourneyFigure: View {
    let caption: LocalizedStringKey
    let value: String
    let symbol: String
    let color: Color

    var body: some View {
        VStack(spacing: .space2XS) {
            Image(systemName: symbol).font(.icon(.s, weight: .semibold)).foregroundStyle(color)
            Text(verbatim: value)
                .font(.callout.weight(.semibold))
                .monospacedDigit()
                .lineLimit(1)
                .minimumScaleFactor(0.6)
            Text(caption).font(.caption).foregroundStyle(.secondary).lineLimit(1)
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, .spaceS)
        .tintedCard(color)
        .accessibilityElement(children: .combine)
    }
}

private struct JourneyVisibilitySection: View {
    @Environment(SettingsModel.self) private var settings

    var body: some View {
        @Bindable var settings = settings
        Section {
            Toggle(isOn: $settings.journeyToggle) {
                IconRow(
                    title: Text("Show Journey"), detail: Text(verbatim: settings.journeyStateText),
                    symbol: "trophy", color: .retroMustard)
            }
            .tint(.positive)
        } footer: {
            Text("Turn it back on any time. Nothing is deleted.")
        }
    }
}

private struct JourneyEffectsSection: View {
    var body: some View {
        Section {
            IconRow(
                "The Journey tab", detail: "Level, streak, missions, challenges and achievements.",
                symbol: "eye.slash", color: .secondary)
            IconRow(
                "Celebrations", detail: "Level-ups and new achievements stop popping up.",
                symbol: "party.popper", color: .secondary)
        } header: {
            Text("What Hiding Removes")
        }
        Section {
            IconRow(
                "Progress keeps counting",
                detail: "XP, level and achievements come from your records and stay up to date.",
                symbol: "chart.line.uptrend.xyaxis", color: .retroOlive)
            IconRow(
                "Streak and challenge",
                detail: "Days you record still count, and an active challenge keeps running.",
                symbol: "flame", color: .retroOrange)
            IconRow(
                "Shop items", detail: "Icons, colors and other items you own keep working.",
                symbol: "bag", color: .retroDenim)
        } header: {
            Text("What's Kept")
        }
    }
}

private struct JourneyHideSheet: View {
    @Environment(SettingsModel.self) private var settings

    var body: some View {
        GuideSheet(
            index: 0, count: 1,
            primary: GuideAction("Hide Journey") { settings.hideJourney() },
            secondary: GuideAction("Keep Showing") { settings.isConfirmingHideJourney = false }
        ) {
            GuidePage(
                title: "Hide the Journey?", message: "The tab goes away, but nothing is lost."
            ) {
                CashlyAnimationView(.journey)
            } content: {
                GuideFeatureList {
                    ForEach(settings.journeyHideNotes) {
                        GuideFeature(title: $0.title, detail: $0.detail)
                    }
                }
            }
        }
    }
}

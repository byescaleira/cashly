import CashlyDesignSystem
import FeatureCore
import SwiftUI

public struct JourneyScreen: View {
    @Environment(SessionModel.self) private var session
    @Environment(JourneyModel.self) private var journey
    @Environment(\.open) private var open
    @Environment(\.navigationSection) private var section
    @Environment(\.showGuide) private var showGuide
    @Environment(\.pro) private var pro

    public init() {}

    public var body: some View {
        @Bindable var journey = journey
        AdaptiveList {
            LevelSection()
            StreakSection()
            MissionsSection()
            ChallengeSection()
            AchievementsSection()
            ShopSection()
        }
        .fontDesign(.rounded)
        .toolbar {
            ToolbarItem(placement: .leading) { UserMenu() }
            ToolbarItem(placement: .primaryAction) {
                Button("Shop", systemImage: "bag") { open(.shop, in: section) }
                    .tint(Color.primary)
            }
        }
        .navigationTitle("Journey")
        .task(id: session.loadKey) { await journey.load() }
        .task { await CashlyTips.record(CashlyTips.journeyOpened) }
        .onChange(of: pro.isPro, initial: true) { journey.isPro = $1 }
        .refreshable { await journey.load() }
        .sheet(isPresented: $journey.isChoosingChallenge) { ChallengePickerScreen() }
        .sheet(item: $journey.selected, onDismiss: followAchievement) {
            AchievementDetailScreen(state: $0)
        }
        .sheet(item: $journey.celebration, onDismiss: followAchievement) {
            CelebrationScreen(celebration: $0)
        }
        .errorAlert($journey.error)
    }

    private func followAchievement() {
        journey.performPendingAction(
            pro: pro, open: { open($0, in: section) }, guide: { showGuide?($0) })
    }
}

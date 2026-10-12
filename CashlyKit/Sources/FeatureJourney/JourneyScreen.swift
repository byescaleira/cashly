import CashlyDesignSystem
import FeatureCore
import SwiftUI

public struct JourneyScreen: View {
    @Environment(SessionModel.self) private var session
    @Environment(JourneyModel.self) private var journey

    public init() {}

    public var body: some View {
        @Bindable var journey = journey
        AdaptiveList {
            PausedSection()
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
        }
        .navigationTitle("Journey")
        .task(id: session.loadKey) { await journey.load() }
        .task { await CashlyTips.record(CashlyTips.journeyOpened) }
        .refreshable { await journey.load() }
        .sheet(isPresented: $journey.isChoosingChallenge) { ChallengePickerScreen() }
        .sheet(isPresented: $journey.isShowingAchievement) {
            if let state = journey.selected { AchievementDetailScreen(state: state) }
        }
        .sheet(item: $journey.celebration) { CelebrationScreen(celebration: $0) }
        .errorAlert($journey.error)
    }
}

import CashlyDesignSystem
import CashlyGame
import FeatureCore
import SwiftUI

struct CelebrationScreen: View {
    @Environment(JourneyModel.self) private var journey
    @Environment(\.dismiss) private var dismiss
    @Environment(\.accessibilityReduceMotion) private var reduceMotion
    @State private var isShown = false
    let celebration: Celebration

    var body: some View {
        GuideSheet(index: 0, count: 1, primary: GuideAction("Continue") { dismiss() }) {
            GuidePage(verbatim: celebration.title, message: celebration.detail) {
                CelebrationArtwork(celebration: celebration)
            } content: {
                if let reward = journey.reward(for: celebration) {
                    Chip(reward, color: celebration.color, shape: .capsule)
                }
            }
        } backdrop: {
            if !reduceMotion { MoneyRainView() }
        }
        .sensoryFeedback(.success, trigger: isShown)
        .task { isShown = true }
    }
}

private struct CelebrationArtwork: View {
    @Environment(JourneyModel.self) private var journey
    let celebration: Celebration

    var body: some View {
        if let text = celebration.levelText {
            LevelMedallion(text: text, color: celebration.color)
        } else if case .achievement(let achievement) = celebration,
            let state = journey.state(of: achievement)
        {
            AchievementMedallion(state: state)
        }
    }
}

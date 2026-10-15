import CashlyDesignSystem
import CashlyGame
import SwiftUI

struct CelebrationScreen: View {
    @Environment(\.dismiss) private var dismiss
    @Environment(\.accessibilityReduceMotion) private var reduceMotion
    @State private var isShown = false
    let celebration: Celebration

    var body: some View {
        VStack(spacing: .spaceL) {
            Image(systemName: celebration.symbol)
                .font(.icon(.hero, weight: .semibold))
                .foregroundStyle(celebration.color.gradient)
                .symbolEffect(.bounce, value: isShown)
                .scaleEffect(isShown || reduceMotion ? 1 : 0.4)
                .animation(.bouncy, value: isShown)
                .accessibilityHidden(true)
            VStack(spacing: .spaceXS) {
                Text(celebration.title).font(.titleLarge)
                Text(celebration.detail).foregroundStyle(.secondary)
            }
            .multilineTextAlignment(.center)
            if case .achievement(let achievement) = celebration, achievement.xp > 0 {
                Chip("+\(achievement.xp) XP", color: celebration.color, shape: .capsule)
            }
            Button("Continue") { dismiss() }
                .primaryButton()
        }
        .padding(.spaceXL)
        .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .top)
        .background {
            if !reduceMotion {
                ConfettiView(colors: [
                    celebration.color, .retroMustard, .retroTeal, .retroOrange, .retroPlum,
                ])
                .ignoresSafeArea()
            }
        }
        .presentationDetents([.medium])
        .sensoryFeedback(.success, trigger: isShown)
        .task { isShown = true }
    }
}

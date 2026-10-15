import CashlyDesignSystem
import CashlyGame
import SwiftUI

struct AchievementMedallion: View {
    @Environment(\.accessibilityReduceMotion) private var reduceMotion
    @State private var isShown = false
    let state: AchievementState

    var body: some View {
        let color = state.achievement.tier.color
        VStack(spacing: .spaceL) {
            MedallionFace(state: state, isShown: isShown || reduceMotion)
                .overlay {
                    if state.isUnlocked && !reduceMotion { MedallionSparks(color: color) }
                }
            if state.showsProgressBar {
                FillingBar(value: state.progress, color: color)
                    .frame(width: .medallion)
            }
        }
        .padding(.top, .spaceS)
        .task { isShown = true }
    }
}

private struct MedallionFace: View {
    @Environment(\.accessibilityReduceMotion) private var reduceMotion
    let state: AchievementState
    let isShown: Bool

    var body: some View {
        let color = state.achievement.tier.color
        Image(systemName: state.symbol)
            .font(.icon(.xl, weight: .semibold))
            .foregroundStyle(foreground(color))
            .symbolEffect(.bounce, value: isShown)
            .symbolEffect(.breathe, isActive: state.isHidden && !reduceMotion)
            .frame(width: .medallion, height: .medallion)
            .background(background(color), in: .circle)
            .overlay {
                if state.isUnlocked && !reduceMotion { MedallionShine() }
            }
            .overlay { MedallionRim(state: state) }
            .overlay(alignment: .bottomTrailing) {
                if !state.isUnlocked && !state.isHidden { MedallionLock(isShown: isShown) }
            }
            .shadow(color: state.isUnlocked ? color.opacity(.opacitySoft) : .clear, radius: .spaceL)
            .scaleEffect(isShown ? 1 : 0.5)
            .opacity(isShown ? 1 : 0)
            .animation(.bouncy(duration: 0.6, extraBounce: 0.15), value: isShown)
            .keyframeAnimator(initialValue: 0.0, trigger: isShown && state.isUnlocked) {
                content, angle in
                content.rotationEffect(.degrees(angle))
            } keyframes: { _ in
                KeyframeTrack {
                    LinearKeyframe(0, duration: 0.25)
                    CubicKeyframe(-12, duration: 0.15)
                    SpringKeyframe(8, duration: 0.2)
                    SpringKeyframe(0, duration: 0.4)
                }
            }
    }

    private func foreground(_ color: Color) -> Color {
        state.isUnlocked ? .white : state.isStarted ? color : .secondary
    }

    private func background(_ color: Color) -> AnyShapeStyle {
        if state.isUnlocked { return AnyShapeStyle(color.gradient) }
        if state.isStarted { return AnyShapeStyle(color.opacity(.opacityTint)) }
        return AnyShapeStyle(Color.secondary.opacity(.opacityFill))
    }
}

private struct MedallionRim: View {
    let state: AchievementState

    var body: some View {
        if state.isUnlocked {
            Circle().strokeBorder(Color.white.opacity(.opacitySoft), lineWidth: .spaceXS)
        } else if state.isHidden {
            Circle().strokeBorder(
                Color.secondary.opacity(.opacitySoft),
                style: StrokeStyle(lineWidth: .spaceHairline, dash: [.spaceXS, .spaceXS]))
        }
    }
}

private struct MedallionLock: View {
    let isShown: Bool

    var body: some View {
        Image(systemName: "lock.fill")
            .font(.icon(.s, weight: .semibold))
            .foregroundStyle(.secondary)
            .symbolEffect(.wiggle, value: isShown)
            .frame(width: .badgeM, height: .badgeM)
            .background(.sheetCard, in: .circle)
    }
}

private struct MedallionShine: View {
    var body: some View {
        LinearGradient(
            colors: [.clear, .white.opacity(.opacitySoft), .clear], startPoint: .leading,
            endPoint: .trailing
        )
        .frame(width: .medallion / 3, height: .medallion * 1.5)
        .rotationEffect(.degrees(25))
        .keyframeAnimator(initialValue: -1.0, repeating: true) { content, position in
            content.offset(x: position * .medallion)
        } keyframes: { _ in
            KeyframeTrack {
                LinearKeyframe(-1.0, duration: 0.8)
                CubicKeyframe(1.0, duration: 1.0)
                LinearKeyframe(1.0, duration: 1.8)
            }
        }
        .frame(width: .medallion, height: .medallion)
        .clipShape(.circle)
        .allowsHitTesting(false)
    }
}

private struct MedallionSparks: View {
    static let count = 10
    let color: Color

    var body: some View {
        ZStack {
            ForEach(0..<Self.count, id: \.self) { index in
                MedallionSpark(index: index, color: index.isMultiple(of: 2) ? color : .retroMustard)
            }
        }
        .allowsHitTesting(false)
    }
}

private struct MedallionSpark: View {
    struct Motion {
        var distance = CGFloat.medallion * 0.45
        var opacity = 0.0
        var scale = 0.4
    }

    let index: Int
    let color: Color

    var body: some View {
        let angle = Angle.degrees(Double(index) * 360 / Double(MedallionSparks.count))
        let delay = 0.3 + Double(index % 3) * 0.25
        Image(systemName: "sparkle")
            .font(.icon(.xs, weight: .bold))
            .foregroundStyle(color)
            .keyframeAnimator(initialValue: Motion(), repeating: true) { content, motion in
                content
                    .scaleEffect(motion.scale)
                    .opacity(motion.opacity)
                    .offset(y: -motion.distance)
                    .rotationEffect(angle)
            } keyframes: { _ in
                KeyframeTrack(\.distance) {
                    LinearKeyframe(.medallion * 0.45, duration: delay)
                    CubicKeyframe(.medallion * 0.62, duration: 1.2)
                    LinearKeyframe(.medallion * 0.62, duration: 2 - delay)
                }
                KeyframeTrack(\.opacity) {
                    LinearKeyframe(0, duration: delay)
                    LinearKeyframe(1, duration: 0.3)
                    LinearKeyframe(0, duration: 0.9)
                    LinearKeyframe(0, duration: 2 - delay)
                }
                KeyframeTrack(\.scale) {
                    LinearKeyframe(0.4, duration: delay)
                    SpringKeyframe(1.2, duration: 0.4)
                    LinearKeyframe(0.6, duration: 0.8)
                    LinearKeyframe(0.4, duration: 2 - delay)
                }
            }
    }
}

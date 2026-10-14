import CashlyDesignSystem
import CashlyResource
import Lottie
import SwiftUI

public enum CashlyAnimation: String, Sendable {
    case month, history, budgetPace, journey, budget, score, participants, splitModes, paid, table
    case file, done, connect, launch, pro, paywall, shopIcons, shopColors, shopHelps, capture
    case goals
}

public struct CashlyAnimationView: View {
    @Environment(\.accessibilityReduceMotion) private var reduceMotion
    @Environment(\.appTint) private var appTint
    @Environment(\.self) private var environment
    private let animation: CashlyAnimation
    private let loops: Bool

    public init(_ animation: CashlyAnimation, loops: Bool = false) {
        self.animation = animation
        self.loops = loops
    }

    public var body: some View {
        tinted(
            LottieView(animation: loaded)
                .playbackMode(
                    reduceMotion
                        ? .paused(at: .progress(1))
                        : .playing(
                            .fromProgress(0, toProgress: 1, loopMode: loops ? .loop : .playOnce))
                )
                .resizable()
        )
        .aspectRatio(16 / 9, contentMode: .fit)
        .accessibilityHidden(true)
    }

    private var loaded: LottieAnimation? {
        AnimationStore.animation(animation)
    }

    private func tinted(_ view: LottieView<EmptyView>) -> LottieView<EmptyView> {
        var view = view
        for (name, color) in palette {
            view = view.valueProvider(
                ColorValueProvider(lottieColor(color)),
                for: AnimationKeypath(keypath: name + ".**.Color"))
        }
        return view
    }

    private var palette: [(String, Color)] {
        [
            ("tint", appTint), ("olive", .retroOlive), ("mustard", .retroMustard),
            ("rust", .retroRust), ("orange", .retroOrange), ("teal", .retroTeal),
            ("denim", .retroDenim), ("plum", .retroPlum), ("brown", .retroBrown),
            ("ink", .primary), ("paper", .sheetBackground), ("cream", .retroCream),
        ]
    }

    private func lottieColor(_ color: Color) -> LottieColor {
        let resolved = color.resolve(in: environment)
        return LottieColor(
            r: Double(resolved.red), g: Double(resolved.green), b: Double(resolved.blue),
            a: Double(resolved.opacity))
    }
}

@MainActor
private enum AnimationStore {
    private static var loaded: [CashlyAnimation: LottieAnimation] = [:]

    static func animation(_ animation: CashlyAnimation) -> LottieAnimation? {
        if let cached = loaded[animation] { return cached }
        guard let json = CashlyResourceAnimation.json(named: animation.rawValue),
            let parsed = try? LottieAnimation.from(data: Data(json.utf8))
        else { return nil }
        loaded[animation] = parsed
        return parsed
    }
}

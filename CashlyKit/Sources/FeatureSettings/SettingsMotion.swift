import CashlyDesignSystem
import SwiftUI

extension View {
    func settingsReveal(_ index: Int) -> some View {
        modifier(SettingsReveal(index: index))
    }
}

private struct SettingsReveal: ViewModifier {
    @Environment(\.accessibilityReduceMotion) private var reduceMotion
    @State private var isShown = false
    let index: Int

    func body(content: Content) -> some View {
        content
            .opacity(isShown || reduceMotion ? 1 : 0)
            .offset(y: isShown || reduceMotion ? 0 : .spaceS)
            .animation(reduceMotion ? nil : .smooth.delay(Double(index) * 0.05), value: isShown)
            .task { isShown = true }
    }
}

struct SettingsBar: View {
    @Environment(\.accessibilityReduceMotion) private var reduceMotion
    @State private var isFilled = false
    let value: Double
    let color: Color

    var body: some View {
        let animation: Animation? = reduceMotion ? nil : .smooth(duration: 1)
        ProgressView(value: isFilled ? min(max(value, 0), 1) : 0)
            .tint(color)
            .animation(animation, value: isFilled)
            .animation(animation, value: value)
            .task { isFilled = true }
            .accessibilityHidden(true)
    }
}

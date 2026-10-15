import CashlyDesignSystem
import SwiftUI

struct LevelMedallion: View {
    @Environment(\.accessibilityReduceMotion) private var reduceMotion
    @State private var isShown = false
    let text: String
    let color: Color

    var body: some View {
        Text(verbatim: text)
            .font(.amountHero)
            .dynamicTypeSize(...DynamicTypeSize.large)
            .foregroundStyle(.white)
            .frame(width: .medallion, height: .medallion)
            .background(color.gradient, in: .circle)
            .overlay {
                if !reduceMotion { MedallionShine() }
            }
            .overlay {
                Circle().strokeBorder(Color.white.opacity(.opacitySoft), lineWidth: .spaceXS)
            }
            .shadow(color: color.opacity(.opacitySoft), radius: .spaceL)
            .scaleEffect(isShown || reduceMotion ? 1 : 0.5)
            .opacity(isShown || reduceMotion ? 1 : 0)
            .animation(.bouncy(duration: 0.6, extraBounce: 0.15), value: isShown)
            .padding(.top, .spaceS)
            .task { isShown = true }
    }
}

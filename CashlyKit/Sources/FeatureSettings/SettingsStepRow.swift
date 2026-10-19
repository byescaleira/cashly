import CashlyDesignSystem
import SwiftUI

struct SettingsStepRow: View {
    @Environment(\.appTint) private var appTint
    let number: Int
    let text: String

    var body: some View {
        HStack(alignment: .firstTextBaseline, spacing: .spaceM) {
            Text(verbatim: "\(number)")
                .font(.chipLabel)
                .monospacedDigit()
                .foregroundStyle(appTint)
                .frame(width: .badgeS, height: .badgeS)
                .background(appTint.opacity(.opacityTint), in: .circle)
                .alignmentGuide(.firstTextBaseline) { $0[VerticalAlignment.center] + .space2XS }
            Text(verbatim: text)
        }
        .accessibilityElement(children: .combine)
    }
}

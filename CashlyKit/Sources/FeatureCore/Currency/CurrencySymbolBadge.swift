import CashlyDesignSystem
import SwiftUI

public struct CurrencySymbolBadge: View {
    @Environment(\.appTint) private var appTint
    let symbol: String
    let size: CGFloat

    public init(symbol: String, size: CGFloat) {
        self.symbol = symbol
        self.size = size
    }

    public var body: some View {
        Text(verbatim: symbol)
            .font(size > .badgeL ? .titleMedium : .callout.weight(.semibold))
            .lineLimit(1)
            .minimumScaleFactor(0.5)
            .padding(.horizontal, .space2XS)
            .foregroundStyle(appTint)
            .frame(width: size, height: size)
            .background(appTint.opacity(.opacityTint), in: .rect(cornerRadius: .radiusS))
            .accessibilityHidden(true)
    }
}

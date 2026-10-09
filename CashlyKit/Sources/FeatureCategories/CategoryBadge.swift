import CashlyDesignSystem
import CashlyDomain
import SwiftUI

struct CategoryBadge: View {
    let category: CashlyDomain.Category
    var diameter: CGFloat = 40
    var ring: CGFloat = 0

    var body: some View {
        let color = Color(hex: category.color)
        Image(systemName: category.icon)
            .font(.system(size: diameter * 0.45))
            .foregroundStyle(color)
            .frame(width: diameter, height: diameter)
            .background(color.opacity(0.2), in: .circle)
            .overlay {
                if ring > 0 {
                    Circle().stroke(color, lineWidth: ring)
                        .frame(width: diameter + ring * 2, height: diameter + ring * 2)
                }
            }
            .symbolEffect(
                .bounce.byLayer, options: .repeat(.continuous).speed(0.1), isActive: ring > 0
            )
            .accessibilityHidden(true)
    }
}

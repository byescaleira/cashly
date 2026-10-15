import CashlyDesignSystem
import SwiftUI

public struct LockBadge: View {
    public init() {}

    public var body: some View {
        Image(systemName: "lock.fill")
            .font(.caption2.weight(.bold))
            .foregroundStyle(.white)
            .padding(.spaceXS)
            .background(.black.opacity(.opacityStrong), in: .circle)
            .offset(x: .spaceXS, y: .spaceXS)
            .accessibilityHidden(true)
    }
}

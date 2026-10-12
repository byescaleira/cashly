import CashlyDesignSystem
import FeatureCore
import SwiftUI

public struct LaunchView: View {
    public init() {}

    public var body: some View {
        VStack(spacing: .spaceL) {
            CashlyAnimationView(.launch, loops: true)
                .frame(maxWidth: 220)
            Text("Opening Cashly")
                .font(.subheadline)
                .foregroundStyle(.secondary)
        }
        .fontDesign(.rounded)
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .background(.groupedBackground)
        .accessibilityLabel("Opening Cashly")
    }
}

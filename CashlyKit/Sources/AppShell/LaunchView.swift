import CashlyDesignSystem
import SwiftUI

public struct LaunchView: View {
    public init() {}

    public var body: some View {
        ProgressView("Abrindo Cashly")
            .frame(maxWidth: .infinity, maxHeight: .infinity)
            .background(.groupedBackground)
    }
}

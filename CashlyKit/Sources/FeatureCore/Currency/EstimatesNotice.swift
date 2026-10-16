import SwiftUI

public struct EstimatesNotice: View {
    @Environment(FinanceModel.self) private var finance

    public init() {}

    public var body: some View {
        if finance.hasEstimates {
            Label(
                "Includes amounts converted from other currencies. They're estimates for reference.",
                systemImage: "arrow.left.arrow.right"
            )
            .font(.footnote)
        }
    }
}

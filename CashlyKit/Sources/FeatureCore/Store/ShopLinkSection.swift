import CashlyDesignSystem
import SwiftUI

public struct ShopLinkSection: View {
    public init() {}

    public var body: some View {
        Section {
            DisclosureLink {
                RouteView(.shop)
            } label: {
                Label("See the Shop", systemImage: "bag")
                    .font(.buttonLabel)
                    .foregroundStyle(.tint)
            }
        } footer: {
            Text("Items are yours for good, with or without Cashly Pro.")
        }
    }
}

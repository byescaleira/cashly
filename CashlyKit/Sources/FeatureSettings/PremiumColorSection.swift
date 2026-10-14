import CashlyDesignSystem
import CashlyDomain
import FeatureCore
import SwiftUI

struct PremiumColorSection: View {
    @Environment(SettingsModel.self) private var settings
    @Environment(\.shop) private var shop
    let item: ShopItem
    let title: LocalizedStringKey

    var body: some View {
        @Bindable var settings = settings
        let access = settings.access(to: item, in: shop)
        Section {
            PremiumColorPicker(
                colors: PremiumColor.colors(of: item), hex: $settings.tint,
                isLocked: access.lockedItem != nil
            ) {
                shop.open(item)
            }
        } header: {
            HStack(alignment: .firstTextBaseline) {
                Text(title).sectionTitle()
                Spacer()
                PackAccessButton(access: access)
            }
            .textCase(nil)
        } footer: {
            if access.lockedItem != nil { Text("Available in the Journey shop.") }
        }
    }
}

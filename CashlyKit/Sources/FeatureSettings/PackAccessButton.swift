import CashlyDesignSystem
import FeatureCore
import FeatureStore
import SwiftUI

struct PackAccessButton: View {
    @Environment(\.shop) private var shop
    let access: PackAccess

    var body: some View {
        if let item = access.lockedItem {
            Button {
                shop.open(item)
            } label: {
                PackAccessChip(access: access)
            }
            .buttonStyle(.plain)
        } else {
            PackAccessChip(access: access)
        }
    }
}

struct PackAccessChip: View {
    @Environment(SettingsModel.self) private var settings
    @Environment(StoreModel.self) private var store
    @Environment(\.appTint) private var appTint
    let access: PackAccess

    var body: some View {
        if let label = settings.accessLabel(access, price: access.lockedItem.flatMap(store.price)) {
            HStack(spacing: .spaceXS) {
                if access.lockedItem != nil {
                    Image(systemName: "lock")
                        .font(.footnote.weight(.semibold))
                        .foregroundStyle(.secondary)
                }
                Chip(label, color: access == .owned ? .retroOlive : appTint)
            }
            .accessibilityElement(children: .combine)
        }
    }
}

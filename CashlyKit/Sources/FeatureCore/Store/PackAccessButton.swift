import CashlyDesignSystem
import CashlyDomain
import SwiftUI

public struct PackAccessButton: View {
    @Environment(\.shop) private var shop
    private let access: PackAccess

    public init(access: PackAccess) {
        self.access = access
    }

    public var body: some View {
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

public struct PackAccessChip: View {
    @Environment(\.shop) private var shop
    @Environment(\.appTint) private var appTint
    private let access: PackAccess

    public init(access: PackAccess) {
        self.access = access
    }

    public var body: some View {
        if let label = access.label(price: access.lockedItem.flatMap(shop.price)) {
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

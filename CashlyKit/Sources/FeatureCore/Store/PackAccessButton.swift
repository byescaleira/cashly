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
        if access.isLocked {
            Button {
                shop.unlock(access)
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
                if access.isLocked {
                    Image(systemName: "lock")
                        .font(.footnote.weight(.semibold))
                        .foregroundStyle(.secondary)
                }
                Chip(label, color: color)
            }
            .accessibilityElement(children: .combine)
            .accessibilityLabel(
                access == .pro ? Text("Requires Cashly Pro") : Text(verbatim: label))
        }
    }

    private var color: Color {
        switch access {
        case .owned: .retroOlive
        case .pro: .retroMustard
        default: appTint
        }
    }
}

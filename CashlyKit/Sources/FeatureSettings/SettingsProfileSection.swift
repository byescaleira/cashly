import CashlyDesignSystem
import CashlyDomain
import FeatureCore
import FeatureStore
import SwiftUI

struct SettingsProfileSection: View {
    @Environment(StoreModel.self) private var store: StoreModel?

    var body: some View {
        Section {
            if let store {
                if store.entitlement.isActive {
                    ProPlanRow()
                } else {
                    ProOfferRow()
                    SettingsRow(
                        "Plan and Purchases", symbol: "bag", color: .companion,
                        value: store.entitlement.title
                    ) {
                        SettingsPage("Cashly Pro") { ProSection() }
                    }
                }
            }
        } header: {
            SettingsProfileHeader()
        }
    }
}

private struct SettingsProfileHeader: View {
    @Environment(SettingsModel.self) private var settings
    @Environment(SessionModel.self) private var session: SessionModel?
    @Environment(StoreModel.self) private var store: StoreModel?
    @Environment(AppLockModel.self) private var lock: AppLockModel?

    var body: some View {
        SettingsHero {
            ProfileAvatar(session?.user, size: .badgeXL)
                .accessibilityHidden(true)
            Text(verbatim: settings.profileName(session?.user))
                .font(.titleMedium)
                .foregroundStyle(Color.primary)
                .lineLimit(1)
                .minimumScaleFactor(0.8)
            AdaptiveStack(stackedAlignment: .center, spacing: .spaceS) {
                if let store {
                    PlanChip(badge: settings.planBadge(for: store.entitlement))
                }
                Chip(
                    settings.syncBadge, color: settings.isSyncOn ? .retroDenim : .secondary,
                    shape: .capsule)
                if settings.locksApp {
                    Chip((lock?.biometry ?? .none).title, color: .retroPlum, shape: .capsule)
                }
            }
        }
    }
}

private struct PlanChip: View {
    @Environment(\.appTint) private var appTint
    let badge: PlanBadge

    var body: some View {
        Chip(badge.title, color: color, shape: .capsule)
            .contentTransition(.opacity)
    }

    private var color: Color {
        switch badge.tone {
        case .pro: .retroMustard
        case .trial: appTint
        case .free: .secondary
        }
    }
}

private struct ProPlanRow: View {
    @Environment(SettingsModel.self) private var settings
    @Environment(StoreModel.self) private var store

    var body: some View {
        SettingsRow(
            "Cashly Pro", symbol: "crown", color: .retroMustard,
            value: settings.proValue(for: store.entitlement), detail: store.entitlement.detail
        ) {
            SettingsPage("Cashly Pro") { ProSection() }
        }
    }
}

private struct ProOfferRow: View {
    @Environment(SettingsModel.self) private var settings
    @Environment(StoreModel.self) private var store
    @Environment(\.pro) private var pro
    @State private var isShown = false

    var body: some View {
        Button {
            pro.present()
        } label: {
            HStack(spacing: .spaceM) {
                SymbolBadge("crown", color: .retroMustard, size: .badgeL, style: .filled)
                    .symbolEffect(.bounce, value: isShown)
                VStack(alignment: .leading, spacing: .spaceHairline) {
                    Text(verbatim: settings.proOfferTitle(for: store.entitlement))
                        .font(.rowTitle)
                        .foregroundStyle(Color.primary)
                    Text("Unlimited recording, analysis, the Journey and backups.")
                        .font(.footnote)
                        .foregroundStyle(.secondary)
                }
                Spacer(minLength: .spaceS)
                if let days = store.trialDays {
                    Chip("\(days) days free", color: .retroMustard, shape: .capsule)
                        .fixedSize()
                }
            }
            .padding(.vertical, .space2XS)
            .contentShape(.rect)
        }
        .buttonStyle(.plain)
        .task { isShown = true }
    }
}

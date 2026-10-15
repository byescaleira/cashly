import CashlyDesignSystem
import FeatureCore
import SwiftUI

struct CloudSection: View {
    @Environment(SettingsModel.self) private var settings

    var body: some View {
        CloudHeroSection()
        CloudToggleSection()
        CloudScopeSection(title: "Synced with iCloud", items: settings.syncedItems, isSynced: true)
        CloudScopeSection(title: "Only on This Device", items: settings.localItems, isSynced: false)
    }
}

private struct CloudHeroSection: View {
    @Environment(SettingsModel.self) private var settings
    @Environment(\.accessibilityReduceMotion) private var reduceMotion

    var body: some View {
        let status = settings.cloudStatus
        Section {
            VStack(spacing: .spaceM) {
                Image(systemName: status.symbol)
                    .font(.icon(.xl, weight: .medium))
                    .foregroundStyle(status.color)
                    .frame(width: .badgeXL * 1.5, height: .badgeXL * 1.5)
                    .background(status.color.opacity(.opacityFill), in: .circle)
                    .contentTransition(.symbolEffect(.replace))
                    .symbolEffect(.breathe, isActive: status == .on && !reduceMotion)
                    .accessibilityHidden(true)
                VStack(spacing: .space2XS) {
                    Text(verbatim: status.title).font(.titleMedium)
                    TimelineView(.periodic(from: .now, by: 60)) { context in
                        Text(verbatim: settings.cloudDetail(now: context.date))
                            .font(.subheadline)
                            .foregroundStyle(.secondary)
                    }
                }
                .multilineTextAlignment(.center)
                CloudChips()
            }
            .frame(maxWidth: .infinity)
            .padding(.vertical, .spaceM)
            .animation(reduceMotion ? nil : .smooth, value: status)
            .accessibilityElement(children: .combine)
        }
    }
}

private struct CloudChips: View {
    @Environment(SettingsModel.self) private var settings

    var body: some View {
        if settings.isCloudAvailable {
            HStack(spacing: .spaceS) {
                Chip(
                    "iCloud: \(settings.cloudAccount.title)", color: settings.cloudAccount.color,
                    shape: .capsule)
                Chip(
                    settings.reachTitle,
                    color: settings.cloudStatus == .on ? .info : .secondary, shape: .capsule)
            }
        }
    }
}

private struct CloudToggleSection: View {
    @Environment(SettingsModel.self) private var settings

    var body: some View {
        @Bindable var settings = settings
        Section {
            Toggle(isOn: $settings.isSyncOn) {
                IconRow("Sync with iCloud", symbol: "icloud", color: RetroColor.sky.color)
            }
            .tint(.positive)
            .disabled(!settings.isCloudAvailable)
            if settings.needsRestart {
                IconRow(
                    "Applies on Next Launch",
                    detail: "Close and reopen Cashly to apply the change.",
                    symbol: "arrow.clockwise", color: .warning
                )
                .transition(.opacity)
            }
        } footer: {
            Text(verbatim: settings.cloudToggleFooter)
        }
        .animation(.smooth, value: settings.needsRestart)
    }
}

private struct CloudScopeSection: View {
    let title: LocalizedStringKey
    let items: [SettingsModel.CloudScopeItem]
    let isSynced: Bool

    var body: some View {
        Section {
            ForEach(items) { item in
                IconRow(
                    verbatim: item.title, detail: item.detail, symbol: item.symbol,
                    color: isSynced ? RetroColor.sky.color : .companion)
            }
        } header: {
            Text(title).sectionTitle()
        }
    }
}

extension SettingsModel.CloudStatus {
    fileprivate var color: Color {
        switch self {
        case .on: .positive
        case .pending, .attention: .warning
        case .off, .unavailable: .secondary
        }
    }
}

extension CloudAccount {
    fileprivate var color: Color {
        switch self {
        case .available: .positive
        case .checking: .secondary
        case .noAccount, .restricted, .temporarilyUnavailable, .unavailable: .warning
        }
    }
}

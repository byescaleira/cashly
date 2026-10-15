import CashlyDesignSystem
import FeatureCore
import SwiftUI

struct PrivacyScreen: View {
    @Environment(SettingsModel.self) private var settings

    var body: some View {
        SettingsPage("Privacy") {
            PrivacyLockSection()
            DiscreetSection()
            PrivacyDeviceSection()
        }
        .sensoryFeedback(.selection, trigger: settings.isDiscreet)
        .sensoryFeedback(.selection, trigger: settings.locksApp)
    }
}

private struct PrivacyLockSection: View {
    @Environment(SettingsModel.self) private var settings
    @Environment(AppLockModel.self) private var lock: AppLockModel?

    var body: some View {
        @Bindable var settings = settings
        let biometry = lock?.biometry ?? .none
        Section {
            Toggle(isOn: $settings.locksApp) {
                SettingsToggleLabel(
                    title: settings.lockTitle(biometry), detail: settings.lockDetail,
                    symbol: settings.lockSymbol(biometry), color: .retroPlum)
            }
            .tint(.positive)
        } header: {
            SettingsHero {
                SymbolBadge(
                    settings.locksApp ? settings.lockSymbol(biometry) : "lock.open",
                    color: settings.locksApp ? .retroPlum : .secondary, size: .badgeXL
                )
                .contentTransition(.symbolEffect(.replace))
                .symbolEffect(.bounce, value: settings.locksApp)
                Text(verbatim: settings.privacyHeadline(biometry))
                    .font(.titleMedium)
                    .foregroundStyle(Color.primary)
                    .contentTransition(.opacity)
                Text(verbatim: settings.privacyDetail)
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
                    .contentTransition(.opacity)
            }
            .animation(.smooth, value: settings.locksApp)
            .animation(.smooth, value: settings.isDiscreet)
        }
    }
}

private struct DiscreetSection: View {
    var body: some View {
        Section {
            HStack(alignment: .top, spacing: .spaceM) {
                DiscreetChoice(isDiscreet: false)
                DiscreetChoice(isDiscreet: true)
            }
            .padding(.vertical, .spaceS)
        } header: {
            Text("Discreet Mode").sectionTitle()
        } footer: {
            Text(
                "Discreet mode blurs every amount until you turn it off. Names and categories stay readable."
            )
        }
    }
}

private struct DiscreetChoice: View {
    @Environment(SettingsModel.self) private var settings
    @Environment(\.appTint) private var appTint
    let isDiscreet: Bool

    var body: some View {
        let isSelected = settings.isDiscreet == isDiscreet
        Button {
            settings.isDiscreet = isDiscreet
        } label: {
            VStack(spacing: .spaceS) {
                PrivacyPreviewCard(isDiscreet: isDiscreet)
                    .padding(.space2XS)
                    .overlay {
                        RoundedRectangle(cornerRadius: .radiusM + .space2XS, style: .continuous)
                            .stroke(isSelected ? appTint : .clear, lineWidth: 3)
                    }
                Text(isDiscreet ? "Discreet" : "Visible")
                    .font(.subheadline.weight(isSelected ? .semibold : .regular))
                SelectionMark(isSelected: isSelected)
            }
            .frame(maxWidth: .infinity)
            .contentShape(.rect)
        }
        .buttonStyle(.plain)
        .accessibilityAddTraits(isSelected ? .isSelected : [])
    }
}

private struct PrivacyPreviewCard: View {
    let isDiscreet: Bool

    var body: some View {
        if isDiscreet {
            PrivacyPreviewContent().redacted(reason: .privacy)
        } else {
            PrivacyPreviewContent().unredacted()
        }
    }
}

private struct PrivacyPreviewContent: View {
    @Environment(SettingsModel.self) private var settings

    var body: some View {
        VStack(alignment: .leading, spacing: .spaceS) {
            Text("Available").font(.caption).foregroundStyle(.secondary)
            Text(verbatim: settings.privacySampleBalance).font(.amountRow).amountLine()
            ForEach(settings.privacySample) { row in
                HStack(spacing: .spaceXS) {
                    SymbolBadge(row.symbol, color: row.color.color, size: .badgeS)
                    Text(verbatim: row.title).font(.caption).lineLimit(1)
                    Spacer(minLength: .space2XS)
                    Text(verbatim: row.amount).font(.caption.weight(.semibold)).amountLine()
                }
            }
        }
        .padding(.spaceM)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(.groupedBackground, in: .rect(cornerRadius: .radiusM))
        .dynamicTypeSize(...DynamicTypeSize.xxLarge)
        .accessibilityHidden(true)
    }
}

private struct PrivacyDeviceSection: View {
    var body: some View {
        Section {
            IconRow(
                "Unlocking stays with the system",
                detail:
                    "Cashly never sees your face, fingerprint or passcode, only whether unlocking worked.",
                symbol: "faceid", color: .retroPlum)
            IconRow(
                "These choices stay on this device",
                detail: "Lock and discreet mode don't sync to your other devices.",
                symbol: "slider.horizontal.3", color: .retroTeal)
            IconRow(
                "Your records are yours",
                detail:
                    "They live on this device and, with iCloud sync on, in your own iCloud account.",
                symbol: "icloud", color: .retroDenim)
        } header: {
            Text("On This Device")
        }
    }
}

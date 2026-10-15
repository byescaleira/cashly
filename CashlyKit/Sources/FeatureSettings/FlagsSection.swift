import CashlyDesignSystem
import FeatureCore
import SwiftUI

struct FlagsSection: View {
    @Environment(\.featureFlags) private var flags

    var body: some View {
        #if DEBUG
            if let flags {
                Section {
                    ForEach(FeatureFlag.allCases) { FlagRow(flag: $0) }
                    Button {
                        flags.restoreDefaults()
                    } label: {
                        IconRow(
                            "Restore Defaults", symbol: "arrow.uturn.backward",
                            color: .companion)
                    }
                    .disabled(flags.overriddenCount == 0)
                } header: {
                    HStack {
                        Text("Feature Flags").sectionTitle()
                        Spacer()
                        Chip(
                            flags.overridesSummary,
                            color: flags.overriddenCount == 0 ? .secondary : .warning)
                    }
                    .textCase(nil)
                } footer: {
                    Text("This device's rollout group: \(flags.bucket).")
                }
            }
        #endif
    }
}

private struct FlagRow: View {
    @Environment(\.featureFlags) private var flags
    let flag: FeatureFlag

    var body: some View {
        if let flags {
            Toggle(
                isOn: Binding(get: { flags.isOn(flag) }, set: { flags.override(flag, $0) })
            ) {
                VStack(alignment: .leading, spacing: .spaceHairline) {
                    Text(verbatim: flag.title)
                    Text(verbatim: flags.source(of: flag))
                        .font(.footnote)
                        .foregroundStyle(flags.isOverridden(flag) ? Color.warning : Color.secondary)
                }
            }
            .tint(.positive)
        }
    }
}

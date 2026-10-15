import CashlyDesignSystem
import FeatureCore
import SwiftUI

struct NotificationBanner: View {
    @Environment(SettingsModel.self) private var settings
    let text: ReminderText
    let actions: [String]

    var body: some View {
        VStack(alignment: .leading, spacing: .spaceS) {
            HStack(alignment: .top, spacing: .spaceM) {
                AppIconImage(icon: settings.appIcon, size: .badgeM)
                VStack(alignment: .leading, spacing: .spaceHairline) {
                    HStack(alignment: .firstTextBaseline, spacing: .spaceS) {
                        Text(verbatim: text.title)
                            .font(.subheadline.weight(.semibold))
                            .lineLimit(1)
                        Spacer(minLength: .spaceS)
                        Text("now").font(.caption).foregroundStyle(.secondary)
                    }
                    Text(verbatim: text.body)
                        .font(.subheadline)
                        .lineLimit(3)
                        .fixedSize(horizontal: false, vertical: true)
                }
            }
            .padding(.spaceM)
            .frame(maxWidth: .infinity, alignment: .leading)
            .background(.groupedRow, in: .rect(cornerRadius: .radiusL))
            .shadow(color: .black.opacity(.opacityFill), radius: 6, y: 2)
            if !actions.isEmpty {
                HStack(spacing: .spaceS) {
                    ForEach(actions, id: \.self) { action in
                        Text(verbatim: action)
                            .font(.footnote.weight(.semibold))
                            .lineLimit(1)
                            .padding(.horizontal, .spaceM)
                            .padding(.vertical, .spaceS)
                            .background(.groupedRow, in: .capsule)
                    }
                }
            }
        }
        .foregroundStyle(Color.primary)
        .textCase(nil)
        .multilineTextAlignment(.leading)
        .accessibilityElement(children: .combine)
    }
}

import CashlyDesignSystem
import FeatureCore
import SwiftUI

struct AppIconSection: View {
    @Environment(SettingsModel.self) private var settings

    var body: some View {
        Section {
            AppIconGrid(icons: settings.quickIcons)
            DisclosureLink {
                AppIconScreen()
            } label: {
                LabeledContent {
                    MoreIconsValue()
                } label: {
                    Text("More Icons")
                }
            }
        } header: {
            Text("App Icon").sectionTitle()
        }
    }
}

private struct MoreIconsValue: View {
    @Environment(SettingsModel.self) private var settings

    var body: some View {
        if settings.showsCurrentIconApart {
            HStack(spacing: .spaceS) {
                Text(settings.appIcon.title)
                AppIconImage(icon: settings.appIcon, size: .badgeS)
            }
        } else {
            HStack(spacing: -.spaceS) {
                ForEach(settings.allIconsPreview.prefix(3)) { icon in
                    AppIconImage(icon: icon, size: .badgeS)
                        .overlay {
                            RoundedRectangle(cornerRadius: .badgeS * 0.2237, style: .continuous)
                                .stroke(.groupedRow, lineWidth: 2)
                        }
                }
            }
        }
    }
}

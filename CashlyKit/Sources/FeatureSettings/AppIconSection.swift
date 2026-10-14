import CashlyDesignSystem
import FeatureCore
import SwiftUI

struct AppIconSection: View {
    @Environment(SettingsModel.self) private var settings

    var body: some View {
        DisclosureLink {
            AppIconScreen()
        } label: {
            LabeledContent {
                HStack(spacing: .spaceS) {
                    Text(settings.appIcon.title)
                    AppIconImage(icon: settings.appIcon, size: 28)
                }
            } label: {
                Text("Icon")
            }
        }
    }
}

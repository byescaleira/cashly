import CashlyDesignSystem
import CashlyResource
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
                Text("Ícone")
            }
        }
    }
}

struct AppIconImage: View {
    let icon: AppIcon
    let size: CGFloat

    var body: some View {
        CashlyResourceImage.appIcon(icon.previewName)
            .resizable()
            .scaledToFit()
            .frame(width: size, height: size)
            .clipShape(.rect(cornerRadius: size * 0.2237, style: .continuous))
            .accessibilityHidden(true)
    }
}

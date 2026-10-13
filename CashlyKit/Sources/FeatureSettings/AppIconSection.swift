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
                Text("Icon")
            }
        }
    }
}

public struct AppIconImage: View {
    private let icon: AppIcon
    private let size: CGFloat

    public init(icon: AppIcon, size: CGFloat) {
        self.icon = icon
        self.size = size
    }

    public var body: some View {
        CashlyResourceImage.appIcon(icon.previewName)
            .resizable()
            .scaledToFit()
            .frame(width: size, height: size)
            .clipShape(.rect(cornerRadius: size * 0.2237, style: .continuous))
            .accessibilityHidden(true)
    }
}

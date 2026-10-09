import CashlyDesignSystem
import CashlyResource
import SwiftUI

public struct EmptyStateCard: View {
    private let image: CashlyResourceImage
    private let title: LocalizedStringKey
    private let subtitle: LocalizedStringKey
    private let buttonTitle: LocalizedStringKey
    private let size: CGFloat
    private let action: () -> Void

    public init(
        image: CashlyResourceImage, title: LocalizedStringKey, subtitle: LocalizedStringKey,
        buttonTitle: LocalizedStringKey, size: CGFloat = 110, action: @escaping () -> Void
    ) {
        self.image = image
        self.title = title
        self.subtitle = subtitle
        self.buttonTitle = buttonTitle
        self.size = size
        self.action = action
    }

    public var body: some View {
        VStack(spacing: 24) {
            image.image
                .resizable()
                .scaledToFit()
                .frame(height: size)
                .accessibilityHidden(true)
            VStack(spacing: 8) {
                Text(title).font(.headline.weight(.bold)).foregroundStyle(.primary)
                Text(subtitle).font(.callout).foregroundStyle(.secondary)
            }
            Button(action: action) {
                Text(buttonTitle).font(.headline.weight(.bold)).frame(maxWidth: .infinity)
            }
            .prominentButton()
            .controlSize(.large)
            .tint(.accentColor)
        }
        .fontDesign(.rounded)
        .frame(maxWidth: .infinity)
        .multilineTextAlignment(.center)
    }
}

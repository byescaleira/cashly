import CashlyDesignSystem
import CashlyResource
import SwiftUI

public struct EmptyStateView: View {
    private let image: CashlyResourceImage
    private let title: LocalizedStringKey
    private let description: LocalizedStringKey
    private let actionTitle: LocalizedStringKey?
    private let action: (() -> Void)?

    public init(
        image: CashlyResourceImage, title: LocalizedStringKey, description: LocalizedStringKey,
        actionTitle: LocalizedStringKey? = nil, action: (() -> Void)? = nil
    ) {
        self.image = image
        self.title = title
        self.description = description
        self.actionTitle = actionTitle
        self.action = action
    }

    public var body: some View {
        ContentUnavailableView {
            Label {
                Text(title)
            } icon: {
                image.image
                    .resizable()
                    .scaledToFit()
                    .frame(height: 110)
                    .accessibilityHidden(true)
            }
        } description: {
            Text(description)
        } actions: {
            if let actionTitle, let action {
                Button(action: action) {
                    Text(actionTitle).font(.headline.weight(.bold)).frame(maxWidth: .infinity)
                }
                .prominentButton()
                .controlSize(.large)
                .fontDesign(.rounded)
            }
        }
    }
}

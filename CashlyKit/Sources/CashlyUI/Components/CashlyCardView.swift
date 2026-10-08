import CashlyDesignSystem
import CashlyResource
import Foundation
import SwiftUI

public struct CashlyCardView: View {
    let image: CashlyResourceImage
    let title: String
    let subtitle: String
    let buttonTitle: String
    let size: CGFloat
    let action: () -> Void

    public init(
        image: CashlyResourceImage,
        title: String,
        subtitle: String,
        buttonTitle: String,
        size: CGFloat = 110,
        action: @escaping () -> Void
    ) {
        self.image = image
        self.title = title
        self.subtitle = subtitle
        self.buttonTitle = buttonTitle
        self.size = size
        self.action = action
    }

    public var body: some View {
        CashlyVStack(spacing: .large) {
            image.image
                .resizable()
                .scaledToFit()
                .frame(height: size)

            CashlyVStack(spacing: .small) {
                CashlyText(title)
                    .cashly(font: .headline, weight: .bold)
                    .cashly(color: .text)

                CashlyText(subtitle)
                    .cashly(font: .callout)
                    .cashly(color: .textSecondary)
            }

            button
        }
        .frame(maxWidth: .infinity)
        .cashly(alignment: .center)
    }

    var button: some View {
        Button {
            action()
        } label: {
            CashlyText(buttonTitle)
                .cashly(font: .headline, weight: .bold)
                .frame(maxWidth: .infinity)
        }
        .cashlyProminentButton()
        .controlSize(.large)
        .cashly(tint: .primary)
    }

}

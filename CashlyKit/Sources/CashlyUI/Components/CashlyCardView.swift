//
//  CashlyCardView.swift
//  CashlyKit
//
//  Created by Rafael Escaleira on 02/09/25.
//

import SwiftUI
import CashlyResource

public struct CashlyCardView: CashlyView {
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
        CashlyButton {
            action()
        } label: {
            CashlyText(buttonTitle)
                .cashly(font: .headline, weight: .bold)
                .frame(maxWidth: .infinity)
        }
        .buttonStyle(.glassProminent)
        .controlSize(.large)
        .cashly(tint: .primary)
    }

    public static var mock: some View {
        CashlyCardView(
            image: .illustrationEmpty,
            title: "Empty",
            subtitle: "Empty Description",
            buttonTitle: "Open Empty"
        ) {

        }
    }
}

#Preview {
    CashlyCardView
        .mock
}

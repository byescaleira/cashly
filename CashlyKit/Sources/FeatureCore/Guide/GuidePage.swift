import CashlyDesignSystem
import SwiftUI

public struct GuidePage<Artwork: View, Content: View>: View {
    private let title: LocalizedStringKey
    private let message: LocalizedStringKey
    private let artwork: Artwork
    private let content: Content

    public init(
        title: LocalizedStringKey, message: LocalizedStringKey,
        @ViewBuilder artwork: () -> Artwork, @ViewBuilder content: () -> Content = { EmptyView() }
    ) {
        self.title = title
        self.message = message
        self.artwork = artwork()
        self.content = content()
    }

    public var body: some View {
        VStack(spacing: .spaceXL) {
            artwork
                .accessibilityHidden(true)
            VStack(spacing: .spaceS) {
                Text(title).font(.title.weight(.bold))
                Text(message).font(.body).foregroundStyle(.secondary)
            }
            .multilineTextAlignment(.center)
            content
        }
        .frame(maxWidth: .infinity)
    }
}

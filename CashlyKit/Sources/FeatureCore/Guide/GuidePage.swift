import CashlyResource
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
        VStack(spacing: 20) {
            artwork
                .frame(height: 150)
                .accessibilityHidden(true)
            VStack(spacing: 8) {
                Text(title).font(.title2.weight(.bold))
                Text(message).font(.callout).foregroundStyle(.secondary)
            }
            .multilineTextAlignment(.center)
            content
        }
        .frame(maxWidth: .infinity)
    }
}

extension GuidePage where Artwork == GuideIllustration {
    public init(
        _ image: CashlyResourceImage, title: LocalizedStringKey, message: LocalizedStringKey,
        @ViewBuilder content: () -> Content = { EmptyView() }
    ) {
        self.init(
            title: title, message: message, artwork: { GuideIllustration(image: image) },
            content: content)
    }
}

public struct GuideIllustration: View {
    let image: CashlyResourceImage

    public var body: some View {
        image.image.resizable().scaledToFit()
    }
}

public struct GuideSymbol: View {
    private let name: String

    public init(_ name: String) {
        self.name = name
    }

    public var body: some View {
        Image(systemName: name)
            .font(.system(size: 96))
            .foregroundStyle(.tint)
            .symbolEffect(.bounce, options: .nonRepeating)
    }
}

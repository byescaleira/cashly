import SwiftUI

struct StepLayout<Artwork: View, Content: View>: View {
    let title: LocalizedStringKey
    let message: LocalizedStringKey
    @ViewBuilder let artwork: Artwork
    @ViewBuilder let content: Content

    var body: some View {
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

import CashlyDesignSystem
import SwiftUI

public struct SettingsRow<Destination: View>: View {
    private let title: Text
    private let detail: Text?
    private let symbol: String
    private let color: Color
    private let value: String?
    private let destination: Destination

    public init(
        _ title: LocalizedStringKey, symbol: String, color: Color, value: String? = nil,
        detail: String? = nil, @ViewBuilder destination: () -> Destination
    ) {
        self.title = Text(title)
        self.detail = detail.map { Text(verbatim: $0) }
        self.symbol = symbol
        self.color = color
        self.value = value
        self.destination = destination()
    }

    public init(
        verbatim title: String, symbol: String, color: Color, value: String? = nil,
        detail: String? = nil, @ViewBuilder destination: () -> Destination
    ) {
        self.title = Text(verbatim: title)
        self.detail = detail.map { Text(verbatim: $0) }
        self.symbol = symbol
        self.color = color
        self.value = value
        self.destination = destination()
    }

    public var body: some View {
        DisclosureLink {
            destination
        } label: {
            IconRow(title: title, detail: detail, symbol: symbol, color: color, value: value)
                .contentTransition(.opacity)
        }
    }
}

public struct SettingsPage<Content: View>: View {
    private let title: LocalizedStringKey
    private let content: Content

    public init(_ title: LocalizedStringKey, @ViewBuilder content: () -> Content) {
        self.title = title
        self.content = content()
    }

    public var body: some View {
        Group {
            #if os(macOS)
                Form { content }.formStyle(.grouped)
            #else
                AdaptiveList { content }
            #endif
        }
        .navigationTitle(title)
        #if os(iOS)
            .navigationBarTitleDisplayMode(.inline)
        #endif
    }
}

struct SettingsHero<Content: View>: View {
    private let content: Content

    init(@ViewBuilder content: () -> Content) {
        self.content = content()
    }

    var body: some View {
        VStack(spacing: .spaceS) { content }
            .textCase(nil)
            .multilineTextAlignment(.center)
            .frame(maxWidth: .infinity)
            .padding(.vertical, .spaceL)
            .accessibilityElement(children: .combine)
    }
}

struct SettingsToggleLabel: View {
    let title: String
    let detail: String?
    let symbol: String
    let color: Color

    var body: some View {
        IconRow(
            title: Text(verbatim: title), detail: detail.map { Text(verbatim: $0) },
            symbol: symbol, color: color)
    }
}

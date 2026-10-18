import CashlyDesignSystem
import SwiftUI

public struct ProShowcaseSection: View {
    @Environment(\.pro) private var pro
    private let showcase: ProShowcase

    public init(_ showcase: ProShowcase) {
        self.showcase = showcase
    }

    public var body: some View {
        if !pro.isPro {
            Section {
                ProShowcaseHero(showcase: showcase)
                ForEach(showcase.pitches, id: \.self) { ProPitchRow(pitch: $0) }
                Button("See Cashly Pro", action: pro.present)
                    .primaryButton()
                    .padding(.vertical, .spaceS)
            } header: {
                Text("Cashly Pro").sectionTitle()
            }
        }
    }
}

private struct ProShowcaseHero: View {
    @State private var isShown = false
    let showcase: ProShowcase

    var body: some View {
        VStack(spacing: .spaceM) {
            SymbolBadge("crown.fill", color: .retroMustard, size: .badgeXL, style: .filled)
                .symbolEffect(.bounce, value: isShown)
            VStack(spacing: .spaceXS) {
                Text(showcase.title).font(.titleMedium)
                Text(showcase.message).font(.subheadline).foregroundStyle(.secondary)
            }
            .multilineTextAlignment(.center)
            .fixedSize(horizontal: false, vertical: true)
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, .spaceM)
        .accessibilityElement(children: .combine)
        .task { isShown = true }
    }
}

private struct ProPitchRow: View {
    let pitch: ProPitch

    var body: some View {
        HStack(alignment: .top, spacing: .spaceM) {
            SymbolBadge(pitch.symbol, color: .retroMustard, size: .badgeM)
            VStack(alignment: .leading, spacing: .spaceHairline) {
                Text(pitch.title).font(.rowTitle)
                Text(pitch.message).font(.footnote).foregroundStyle(.secondary)
            }
            .frame(maxWidth: .infinity, alignment: .leading)
            .fixedSize(horizontal: false, vertical: true)
        }
        .padding(.vertical, .space2XS)
        .accessibilityElement(children: .combine)
    }
}

public struct ProOnly<Content: View>: View {
    @Environment(\.pro) private var pro
    private let content: Content

    public init(@ViewBuilder content: () -> Content) {
        self.content = content()
    }

    public var body: some View {
        if pro.isPro { content }
    }
}

extension ProAccess {
    public var lockedValue: String? {
        isPro ? nil : "Pro"
    }
}

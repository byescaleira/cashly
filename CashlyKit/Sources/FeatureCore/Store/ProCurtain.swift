import CashlyDesignSystem
import SwiftUI

public struct ProCurtain<Preview: View>: View {
    @Environment(\.pro) private var pro
    @Environment(\.accessibilityReduceTransparency) private var reduceTransparency
    private let pitch: ProPitch
    private let preview: Preview

    public init(_ pitch: ProPitch, @ViewBuilder preview: () -> Preview) {
        self.pitch = pitch
        self.preview = preview()
    }

    public var body: some View {
        VStack(spacing: .spaceL) {
            ZStack {
                if !reduceTransparency {
                    preview
                        .redacted(reason: .placeholder)
                        .blur(radius: .blurCurtain)
                        .allowsHitTesting(false)
                        .accessibilityHidden(true)
                }
                SymbolBadge(pitch.symbol, color: .retroMustard, size: .badgeXL, style: .filled)
            }
            .frame(maxWidth: .infinity)
            VStack(spacing: .spaceXS) {
                Text(pitch.title).font(.rowTitle)
                Text(pitch.message).font(.rowDetail).foregroundStyle(.secondary)
            }
            .multilineTextAlignment(.center)
            .fixedSize(horizontal: false, vertical: true)
            .accessibilityElement(children: .combine)
            Button("See Cashly Pro", action: pro.present).primaryButton()
        }
        .padding(.vertical, .spaceS)
    }
}

public struct ProCurtainSection<Content: View, Preview: View>: View {
    @Environment(\.pro) private var pro
    private let pitch: ProPitch
    private let content: Content
    private let preview: Preview

    public init(
        _ pitch: ProPitch, @ViewBuilder content: () -> Content,
        @ViewBuilder preview: () -> Preview
    ) {
        self.pitch = pitch
        self.content = content()
        self.preview = preview()
    }

    public var body: some View {
        if pro.isPro {
            content
        } else {
            Section {
                ProCurtain(pitch) { preview }
            } header: {
                Text(pitch.section).sectionTitle()
            }
        }
    }
}

extension ProAccess {
    public var lockedValue: String? {
        isPro ? nil : "Pro"
    }
}

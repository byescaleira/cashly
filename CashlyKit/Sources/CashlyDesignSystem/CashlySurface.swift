import SwiftUI

extension View {
    @ViewBuilder public func cashlyDismissKeyboardOnScroll() -> some View {
        #if os(visionOS)
            self
        #else
            scrollDismissesKeyboard(.immediately)
        #endif
    }

    @ViewBuilder public func cashlyProminentButton() -> some View {
        #if os(visionOS)
            buttonStyle(.borderedProminent)
        #else
            buttonStyle(.glassProminent)
        #endif
    }

    /// A custom control surface. Apply after sizing and appearance modifiers.
    public func cashlySurface(
        tint: Color? = nil, in shape: CashlyShape, interactive: Bool = false
    ) -> some View {
        modifier(CashlyGlassSurfaceModifier(tint: tint, shape: shape, interactive: interactive))
    }

    /// A tinted background for information within content, without an optical glass layer.
    public func cashlyContentSurface(tint: Color? = nil, in shape: CashlyShape) -> some View {
        background(tint ?? .secondary.opacity(0.12), in: shape)
    }
}

private struct CashlyGlassSurfaceModifier: ViewModifier {
    @Environment(\.isEnabled) private var isEnabled
    let tint: Color?
    let shape: CashlyShape
    let interactive: Bool

    @ViewBuilder func body(content: Content) -> some View {
        #if os(visionOS)
            switch shape {
            case .circle: visionSurface(content, in: Circle())
            case .capsule: visionSurface(content, in: Capsule())
            case .rounded(let radius):
                visionSurface(content, in: RoundedRectangle(cornerRadius: radius))
            }
        #else
            content.glassEffect(
                .regular.tint(tint).interactive(interactive && isEnabled), in: shape)
        #endif
    }

    #if os(visionOS)
        private func visionSurface<S: InsettableShape>(
            _ content: Content, in shape: S
        ) -> some View {
            content.background(tint ?? .clear, in: shape).glassBackgroundEffect(in: shape)
        }
    #endif
}

public struct CashlySurfaceContainer<Content: View>: View {
    private let content: Content
    private let spacing: CGFloat

    /// Optical merging distance, independent of the content's layout spacing.
    public init(spacing: CGFloat = 0, @ViewBuilder content: () -> Content) {
        self.spacing = spacing
        self.content = content()
    }

    public var body: some View {
        #if os(visionOS)
            content
        #else
            GlassEffectContainer(spacing: spacing) { content }
        #endif
    }
}

public struct CashlyToolbarSpacer: ToolbarContent {
    public init() {}
    public var body: some ToolbarContent {
        #if os(visionOS)
            ToolbarItem { EmptyView() }
        #else
            ToolbarSpacer(.fixed)
        #endif
    }
}

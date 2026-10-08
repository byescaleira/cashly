import SwiftUI

extension View {
    public func surface(
        tint: Color? = nil, in shape: CashlyShape, interactive: Bool = false
    ) -> some View {
        modifier(GlassSurface(tint: tint, shape: shape, interactive: interactive))
    }

    public func contentSurface(tint: Color? = nil, in shape: CashlyShape) -> some View {
        background(tint ?? .subtleFill, in: shape)
    }
}

private struct GlassSurface: ViewModifier {
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

import SwiftUI

extension View {
    public func cashlyDismissKeyboardOnScroll() -> some View { dismissKeyboardOnScroll() }
    public func cashlyProminentButton() -> some View { prominentButton() }
    public func cashlySurface(
        tint: Color? = nil, in shape: CashlyShape, interactive: Bool = false
    ) -> some View {
        surface(tint: tint, in: shape, interactive: interactive)
    }
    public func cashlyContentSurface(tint: Color? = nil, in shape: CashlyShape) -> some View {
        contentSurface(tint: tint, in: shape)
    }
}

public typealias CashlySurfaceContainer<Content: View> = SurfaceContainer<Content>
public typealias CashlyToolbarSpacer = FixedToolbarSpacer

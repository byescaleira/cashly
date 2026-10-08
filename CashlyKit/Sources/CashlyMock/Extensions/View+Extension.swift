import SwiftUI

extension View {
    public func cashlyPreview(includeSampleData: Bool = true) -> some View {
        modifier(MockModifier(includeSampleData: includeSampleData))
    }
}

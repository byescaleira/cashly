import SwiftUI

extension View {
    @ViewBuilder public func prominentButton() -> some View {
        #if os(visionOS)
            buttonStyle(.borderedProminent)
        #else
            buttonStyle(.glassProminent)
        #endif
    }
}

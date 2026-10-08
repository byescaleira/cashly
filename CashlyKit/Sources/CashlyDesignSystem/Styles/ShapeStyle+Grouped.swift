import SwiftUI

#if canImport(UIKit)
    import UIKit
#elseif canImport(AppKit)
    import AppKit
#endif

extension ShapeStyle where Self == Color {
    public static var groupedBackground: Color {
        #if os(macOS)
            Color(nsColor: .windowBackgroundColor)
        #elseif os(visionOS)
            .clear
        #else
            Color(uiColor: .systemGroupedBackground)
        #endif
    }

    public static var groupedRow: Color {
        #if os(macOS)
            Color(nsColor: .controlBackgroundColor)
        #elseif os(visionOS)
            Color.secondary.opacity(0.12)
        #else
            Color(uiColor: .secondarySystemGroupedBackground)
        #endif
    }
}

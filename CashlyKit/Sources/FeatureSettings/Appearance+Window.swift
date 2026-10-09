#if canImport(UIKit)
    import UIKit
#else
    import AppKit
#endif

extension Appearance {
    @MainActor func apply() {
        #if canImport(UIKit)
            for case let scene as UIWindowScene in UIApplication.shared.connectedScenes {
                for window in scene.windows { window.overrideUserInterfaceStyle = style }
            }
        #else
            NSApp.appearance = appearance
        #endif
    }

    #if canImport(UIKit)
        private var style: UIUserInterfaceStyle {
            switch self {
            case .system: .unspecified
            case .light: .light
            case .dark: .dark
            }
        }
    #else
        private var appearance: NSAppearance? {
            switch self {
            case .system: nil
            case .light: NSAppearance(named: .aqua)
            case .dark: NSAppearance(named: .darkAqua)
            }
        }
    #endif
}

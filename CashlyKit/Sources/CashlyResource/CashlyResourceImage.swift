import SwiftUI

#if canImport(UIKit)
    import UIKit
#elseif canImport(AppKit)
    import AppKit
#endif

public enum CashlyResourceImage {
    public static func appIcon(_ name: String) -> Image {
        Image(name, bundle: .module)
    }

    public static func avatar(_ name: String) -> Image {
        Image(name, bundle: .module)
    }

    public static func contains(_ name: String) -> Bool {
        #if canImport(UIKit)
            UIImage(named: name, in: .module, with: nil) != nil
        #else
            Bundle.module.image(forResource: name) != nil
        #endif
    }
}

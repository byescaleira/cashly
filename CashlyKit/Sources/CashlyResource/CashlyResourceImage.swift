import SwiftUI

public enum CashlyResourceImage {
    public static func appIcon(_ name: String) -> Image {
        Image(name, bundle: .module)
    }
}

import SwiftUI

public enum CashlyResourceImage {
    public static func appIcon(_ name: String) -> Image {
        Image(name, bundle: .module)
    }
    public static func avatar(id: String?) -> Image {
        guard let id, (1...100).contains(Int(id) ?? 0) else {
            return Image(systemName: "person")
        }
        return Image("avatar\(id)", bundle: .module)
    }
}

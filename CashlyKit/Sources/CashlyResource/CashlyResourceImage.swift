import SwiftUI

public enum CashlyResourceImage: String {
    case illustrationEmpty, illustrationNoData, illustrationPeople, illustrationTransaction,
        illustrationTag
    public var image: Image { Image(rawValue, bundle: .module) }
    public static func avatar(id: String?) -> Image {
        guard let id, (1...100).contains(Int(id) ?? 0) else {
            return Image(systemName: "person.crop.circle")
        }
        return Image("avatar\(id)", bundle: .module)
    }
}

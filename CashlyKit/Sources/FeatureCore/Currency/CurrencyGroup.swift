import SwiftUI

public struct CurrencyGroup: Identifiable, Equatable {
    public let title: LocalizedStringKey?
    public let codes: [String]

    public var id: String { codes.first ?? "" }

    public static func == (lhs: CurrencyGroup, rhs: CurrencyGroup) -> Bool {
        lhs.codes == rhs.codes
    }
}

import CashlyDesignSystem
import SwiftUI

extension Binding where Value == String {
    public var hexColor: Binding<Color> {
        Binding<Color>(get: { Color(hex: wrappedValue) }, set: { wrappedValue = $0.hex })
    }
}

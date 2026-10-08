import CashlyDesignSystem
import CashlyDomain
import FeatureCore
import Foundation
import SwiftUI

extension Double {
    func currencyColor(reference: Double = .zero) -> CashlyColor {
        reference == .zero
            ? (self > reference ? .success : self < reference ? .error : .textSecondary)
            : (self > reference ? .error : self < reference ? .success : .warning)
    }

    var percentage: String {
        (self * 100).formatted(.number.precision(.fractionLength(0))) + "%"
    }

    var variationMessage: String {
        BudgetUsage(ratio: self).stage.title
    }

    var variationColor: Color {
        BudgetUsage(ratio: self).stage.color
    }
}

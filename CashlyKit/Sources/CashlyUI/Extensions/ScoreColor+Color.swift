import CashlyDomain
import FeatureCore
import SwiftUI

extension ScoreColor {
    public var color: Color {
        switch self {
        case .red: .red
        case .orange: .orange
        case .yellow: .yellow
        case .green: .green
        }
    }
}

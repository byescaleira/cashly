import CashlyDomain
import SwiftUI

extension EnvironmentValues {
    @Entry public var open: CashlyDestination = .init { _, _ in }
    @Entry public var navigationSection: AppSection = .home
    @Entry public var user: User?
}

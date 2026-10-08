import CashlyDomain
import SwiftUI

extension EnvironmentValues {
    @Entry public var open: CashlyDestination = .init { _, _ in }
    @Entry public var navigationSection: CashlySection = .home
    @Entry public var user: User?
}

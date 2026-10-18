import CashlyDomain
import SwiftUI

public struct ProAccess {
    public let entitlement: Entitlement
    public let isEnforced: Bool
    private let presenter: () -> Void

    public init(entitlement: Entitlement, isEnforced: Bool, present: @escaping () -> Void) {
        self.entitlement = entitlement
        self.isEnforced = isEnforced
        presenter = present
    }

    public var isPro: Bool { !isEnforced || entitlement.isActive }

    public func present() {
        presenter()
    }

    public func perform(_ action: () -> Void) {
        if isPro { action() } else { present() }
    }
}

extension EnvironmentValues {
    @Entry public var pro = ProAccess(entitlement: .none, isEnforced: false, present: {})
}

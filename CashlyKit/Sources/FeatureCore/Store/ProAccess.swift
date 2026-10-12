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

    public var canWrite: Bool { !isEnforced || entitlement.canWrite }

    public func present() {
        presenter()
    }

    public func perform(_ action: () -> Void) {
        if canWrite { action() } else { present() }
    }
}

extension EnvironmentValues {
    @Entry public var pro = ProAccess(entitlement: .none, isEnforced: false, present: {})
}

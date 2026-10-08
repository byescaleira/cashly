import Observation
import SwiftUI

@MainActor @Observable
public final class CashlyNavigation {
    public var selectedSection: CashlySection = .home
    public var paths: [CashlySection: [MainRoute]] = [:]
    public var sheet: SheetDestination?
    public var sheetPath: [MainRoute] = []
    public init() {}

    public struct SheetDestination: Identifiable {
        public let id = UUID()
        public let route: MainRoute
        public let section: CashlySection
    }
    public func path(for section: CashlySection) -> Binding<[MainRoute]> {
        Binding(get: { self.paths[section, default: []] }, set: { self.paths[section] = $0 })
    }
    public func open(_ route: MainRoute, in section: CashlySection, asSheet: Bool) {
        if sheet != nil {
            sheetPath.append(route)
            return
        }
        selectedSection = section
        if asSheet {
            sheetPath = []
            sheet = SheetDestination(route: route, section: section)
        } else {
            paths[section, default: []].append(route)
        }
    }
    public func reset() {
        paths = [:]
        sheet = nil
        sheetPath = []
    }
}

public struct CashlyDestination: Sendable {
    private let action: @MainActor @Sendable (MainRoute, CashlySection) -> Void
    public init(_ action: @escaping @MainActor @Sendable (MainRoute, CashlySection) -> Void) {
        self.action = action
    }
    @MainActor public func callAsFunction(_ route: MainRoute, in section: CashlySection) {
        action(route, section)
    }
}

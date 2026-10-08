import Observation
import SwiftUI

@MainActor @Observable
public final class CashlyNavigation {
    public var selectedSection: AppSection = .home
    public var paths: [AppSection: [Route]] = [:]
    public var sheet: SheetDestination?
    public var sheetPath: [Route] = []
    public init() {}

    public struct SheetDestination: Identifiable {
        public let id = UUID()
        public let route: Route
        public let section: AppSection
    }
    public func path(for section: AppSection) -> Binding<[Route]> {
        Binding(get: { self.paths[section, default: []] }, set: { self.paths[section] = $0 })
    }
    public func open(_ route: Route, in section: AppSection, asSheet: Bool) {
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

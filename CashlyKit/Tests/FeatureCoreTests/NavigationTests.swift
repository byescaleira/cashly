import FeatureCore
import Testing

@MainActor
struct NavigationTests {
    @Test func regularWidthOpensBesideAndNestsInsideInspector() {
        let navigation = CashlyNavigation()
        navigation.open(.addTag(id: nil), in: .home, beside: true)
        #expect(navigation.inspector?.route == .addTag(id: nil))
        #expect(navigation.isInspecting.wrappedValue)
        navigation.open(.addCategory(id: nil), in: .home, beside: true)
        #expect(navigation.inspectorPath == [.addCategory(id: nil)])
        navigation.close(in: .home, inspecting: true)
        #expect(navigation.inspectorPath.isEmpty)
        #expect(navigation.inspector != nil)
        navigation.close(in: .home, inspecting: true)
        #expect(navigation.inspector == nil)
        #expect(navigation.paths[.home, default: []].isEmpty)
    }

    @Test func compactWidthPushesAndCloses() {
        let navigation = CashlyNavigation()
        navigation.open(.addTag(id: nil), in: .planning, beside: false)
        #expect(navigation.selectedSection == .planning)
        #expect(navigation.paths[.planning] == [.addTag(id: nil)])
        #expect(navigation.inspector == nil)
        navigation.close(in: .planning, inspecting: false)
        #expect(navigation.paths[.planning] == [])
    }

    @Test func opensBesideOnlyWhenTheContentColumnAndTheInspectorFit() {
        let navigation = CashlyNavigation()
        navigation.fit(width: 834)
        navigation.open(.addTag(id: nil), in: .home)
        #expect(navigation.inspector == nil)
        #expect(navigation.paths[.home] == [.addTag(id: nil)])
        navigation.fit(width: 956)
        navigation.open(.addTag(id: nil), in: .home)
        #expect(navigation.inspector == nil)
        navigation.fit(width: 1032)
        navigation.open(.addCategory(id: nil), in: .planning)
        #expect(navigation.inspector?.route == .addCategory(id: nil))
        #expect(navigation.paths[.planning, default: []].isEmpty)
    }

    @Test func changingSectionClosesForeignInspector() {
        let navigation = CashlyNavigation()
        navigation.open(.addTag(id: nil), in: .home, beside: true)
        navigation.closeInspectorOutsideSelection()
        #expect(navigation.inspector != nil)
        navigation.selectedSection = .transaction
        navigation.closeInspectorOutsideSelection()
        #expect(navigation.inspector == nil)
    }

    @Test func proGuidesOpenThePaywallForFreeUsers() {
        let navigation = CashlyNavigation()
        navigation.show(.importSpreadsheet, isPro: false)
        #expect(navigation.isShowingPaywall)
        #expect(navigation.guide == nil)
        navigation.isShowingPaywall = false
        navigation.show(.importSpreadsheet, isPro: true)
        #expect(navigation.guide == .importSpreadsheet)
        navigation.show(.score, isPro: false)
        #expect(navigation.guide == .score)
    }
}

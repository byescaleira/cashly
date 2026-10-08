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
        navigation.open(.addTag(id: nil), in: .category, beside: false)
        #expect(navigation.selectedSection == .category)
        #expect(navigation.paths[.category] == [.addTag(id: nil)])
        #expect(navigation.inspector == nil)
        navigation.close(in: .category, inspecting: false)
        #expect(navigation.paths[.category] == [])
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
}

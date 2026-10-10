import FeatureCore
import Testing

struct SymbolCategoryTests {
    @Test(arguments: SymbolCategory.allCases)
    func categoryListsItsOwnSymbolOnce(category: SymbolCategory) {
        #expect(category.symbols.count >= 15)
        #expect(Set(category.symbols).count == category.symbols.count)
        #expect(category.symbols.contains(category.systemImage))
    }

    @Test func namesAreUniqueAndSymbolsAreFound() {
        #expect(Set(SymbolCategory.allCases.map(\.name)).count == SymbolCategory.allCases.count)
        #expect(SymbolCategory.containing("banknote.fill") == .finance)
        #expect(SymbolCategory.containing("pawprint.fill") == .family)
        #expect(SymbolCategory.containing("unknown.symbol") == nil)
    }
}

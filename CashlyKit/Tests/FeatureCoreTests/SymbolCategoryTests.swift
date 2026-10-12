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

    @Test func searchUsesKeywordsWithoutCase() {
        #expect(SymbolCategory.transport.symbols(matching: "Vehicle").contains("car.fill"))
        #expect(SymbolCategory.health.symbols(matching: "medicine").contains("pills.fill"))
        #expect(SymbolCategory.food.symbols(matching: "vehicle").isEmpty)
        #expect(SymbolCategory.transport.symbols(matching: "car").contains("car.fill"))
        #expect(
            SymbolCategory.groceries.symbols(matching: "groc") == SymbolCategory.groceries.symbols)
        #expect(SymbolCategory.travel.symbols(matching: "travel") == SymbolCategory.travel.symbols)
        #expect(SymbolCategory.travel.symbols(matching: " ") == SymbolCategory.travel.symbols)
    }

    @Test func labelIsTheFirstKeyword() {
        #expect(SymbolCategory.label(for: "car.fill") == "Car")
        #expect(SymbolCategory.label(for: "unknown.symbol") == "unknown.symbol")
    }
}

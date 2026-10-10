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

    @Test func searchUsesPortugueseWordsWithoutAccents() {
        #expect(SymbolCategory.transport.symbols(matching: "carro").contains("car.fill"))
        #expect(SymbolCategory.health.symbols(matching: "remedio").contains("pills.fill"))
        #expect(SymbolCategory.food.symbols(matching: "carro").isEmpty)
        #expect(SymbolCategory.transport.symbols(matching: "car").contains("car.fill"))
        #expect(
            SymbolCategory.groceries.symbols(matching: "merc") == SymbolCategory.groceries.symbols)
        #expect(SymbolCategory.travel.symbols(matching: "viagem") == SymbolCategory.travel.symbols)
        #expect(SymbolCategory.travel.symbols(matching: " ") == SymbolCategory.travel.symbols)
    }

    @Test func labelIsThePortugueseName() {
        #expect(SymbolCategory.label(for: "car.fill") == "Carro")
        #expect(SymbolCategory.label(for: "unknown.symbol") == "unknown.symbol")
    }
}

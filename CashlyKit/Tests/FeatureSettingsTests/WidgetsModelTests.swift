import CashlyDomain
import CashlyWidgetUI
import Foundation
import Testing

@testable import FeatureSettings

@MainActor
struct WidgetsModelTests {
    private let defaults = UserDefaults(suiteName: UUID().uuidString) ?? .standard
    private let directory = FileManager.default.temporaryDirectory.appending(
        path: "cashly-widgets-\(UUID().uuidString)")

    private func makeSettings() -> SettingsModel {
        SettingsModel(defaults: defaults, cloudContainer: nil)
    }

    private func makeStore(focus: String? = nil, name: String? = nil) throws -> WidgetSnapshotStore
    {
        try FileManager.default.createDirectory(at: directory, withIntermediateDirectories: true)
        let store = WidgetSnapshotStore(directory: directory)
        try store.write(
            WidgetSnapshot(
                userID: "owner", userName: "Ana", month: YearMonth(.now), currencyCode: "BRL",
                plannedMinorUnits: 300, spentMinorUnits: 200, incomeMinorUnits: 0,
                focusCategoryID: focus, focusCategoryName: name,
                budgets: [
                    line("rent", name: "Rent", planned: 100, spent: 40),
                    line("food", name: "Food", planned: 100, spent: 130),
                ]))
        return store
    }

    private func line(_ id: String, name: String, planned: Int64, spent: Int64)
        -> WidgetSnapshot.BudgetLine
    {
        WidgetSnapshot.BudgetLine(
            id: "budget-\(id)", categoryID: id, categoryName: name, color: "C2602A", icon: "cart",
            plannedMinorUnits: planned, spentMinorUnits: spent)
    }

    @Test func withoutSnapshotThePreviewUsesSampleDataAndOffersNoChoice() {
        let model = WidgetsModel(
            settings: makeSettings(), store: WidgetSnapshotStore(directory: directory))
        model.load()
        #expect(model.isSample)
        #expect(model.choices.isEmpty)
        #expect(model.updatedText == nil)
        #expect(!model.snapshot.budgets.isEmpty)
    }

    @Test func choicesStartWithAutomaticAndListBudgetsByName() throws {
        let model = WidgetsModel(settings: makeSettings(), store: try makeStore())
        model.load()
        #expect(model.choices.map(\.id) == [WidgetChoice.automaticID, "food", "rent"])
        #expect(model.selectedChoice.isAutomatic)
        #expect(model.snapshot.focusLine?.categoryID == "food")
    }

    @Test func choosingACategoryWritesTheSettingAndRefocusesThePreview() throws {
        let settings = makeSettings()
        let model = WidgetsModel(settings: settings, store: try makeStore())
        model.load()
        let rent = try #require(model.choices.first { $0.id == "rent" })
        model.choose(rent)
        #expect(settings.widgetCategoryID == "rent")
        #expect(model.isSelected(rent))
        #expect(model.snapshot.focusLine?.categoryID == "rent")
        model.choose(try #require(model.choices.first))
        #expect(settings.widgetCategoryID == nil)
        #expect(model.snapshot.isFocusAutomatic)
    }

    @Test func aChoiceWithoutBudgetThisMonthStaysVisible() throws {
        let settings = makeSettings()
        settings.widgetCategoryID = "travel"
        let model = WidgetsModel(
            settings: settings, store: try makeStore(focus: "travel", name: "Travel"))
        model.load()
        let selected = model.selectedChoice
        #expect(selected.id == "travel")
        #expect(selected.ratio == nil)
        #expect(model.snapshot.focusLine == nil)
        #expect(model.snapshot.focusCategoryName == "Travel")
    }

    @Test func aDeletedCategoryFallsBackToAutomatic() throws {
        let settings = makeSettings()
        settings.widgetCategoryID = "gone"
        let model = WidgetsModel(settings: settings, store: try makeStore())
        model.load()
        #expect(model.selectedChoice.isAutomatic)
    }

    @Test func overspentBudgetsSayHowMuchIsOver() throws {
        let model = WidgetsModel(settings: makeSettings(), store: try makeStore())
        model.load()
        let food = try #require(model.choices.first { $0.id == "food" })
        let rent = try #require(model.choices.first { $0.id == "rent" })
        #expect(food.detail != rent.detail)
        #expect(food.ratio == 1.3)
    }

    @Test func previewsFollowTheSizesOfEachWidget() {
        let model = WidgetsModel(settings: makeSettings(), store: nil)
        #expect(model.previews(for: .budgets) == [.home(.medium), .home(.large)])
        #expect(model.previews(for: .bills).count == 3)
        #if os(iOS)
            #expect(model.previews(for: .budget).last == .lockScreen)
            #expect(model.lockScreenSizes(for: .month) == [.circular, .rectangular, .inline])
        #else
            #expect(!model.previews(for: .budget).contains(.lockScreen))
        #endif
        #expect(model.preview(for: .budgets) == .home(.medium))
        model.show(.home(.large), for: .budgets)
        #expect(model.preview(for: .budgets) == .home(.large))
        #expect(model.preview(for: .bills) == .home(.small))
        #expect(!model.gallery.contains(.budget))
    }

    @Test func settingsRowNamesTheChosenCategory() {
        let settings = makeSettings()
        let owner = User(id: "owner", name: "Ana", photo: "1")
        let food = CashlyDomain.Category(
            id: "food", user: owner, name: "Mercado", color: "5F7A2E", icon: "cart")
        #expect(settings.widgetValue(categories: [food]) == String(appLocalized: "Automatic"))
        settings.widgetCategoryID = "food"
        #expect(settings.widgetValue(categories: [food]) == "Mercado")
        settings.widgetCategoryID = "gone"
        #expect(settings.widgetValue(categories: [food]) == String(appLocalized: "Automatic"))
    }
}

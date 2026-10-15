import CashlyDomain
import CashlyWidgetUI
import Foundation
import Observation

@MainActor @Observable
final class WidgetsModel {
    private(set) var stored: WidgetSnapshot?
    private(set) var hasLoaded = false
    private var shownPreviews: [CashlyWidget: WidgetPreview] = [:]
    @ObservationIgnored private let settings: SettingsModel
    @ObservationIgnored private let store: WidgetSnapshotStore?

    init(settings: SettingsModel, store: WidgetSnapshotStore? = .shared) {
        self.settings = settings
        self.store = store
    }

    func load() {
        stored = try? store?.read()
        hasLoaded = true
    }

    var isSample: Bool { stored == nil }

    var snapshot: WidgetSnapshot {
        guard let stored else { return .sample }
        return stored.focusing(categoryID: selectedChoice.categoryID)
    }

    var gallery: [CashlyWidget] { CashlyWidget.allCases.filter { !$0.followsChoice } }

    var choices: [WidgetChoice] {
        guard let stored else { return [] }
        let lines = stored.budgets.filter { $0.categoryID != nil }.sorted {
            $0.categoryName.localizedStandardCompare($1.categoryName) == .orderedAscending
        }
        var choices = [WidgetChoice.automatic(stored.automaticLine)]
        choices += lines.map { WidgetChoice(line: $0, snapshot: stored) }
        if let missing = missingChoice(in: stored, lines: lines) { choices.append(missing) }
        return choices
    }

    var selectedChoice: WidgetChoice {
        let choices = choices
        return choices.first { $0.categoryID != nil && $0.categoryID == settings.widgetCategoryID }
            ?? choices.first ?? .automatic(nil)
    }

    func preview(for widget: CashlyWidget) -> WidgetPreview {
        shownPreviews[widget] ?? previews(for: widget).first ?? .home(.medium)
    }

    func show(_ preview: WidgetPreview, for widget: CashlyWidget) {
        shownPreviews[widget] = preview
    }

    func isSelected(_ choice: WidgetChoice) -> Bool { selectedChoice.id == choice.id }

    func choose(_ choice: WidgetChoice) {
        settings.widgetCategoryID = choice.categoryID
    }

    private func missingChoice(
        in stored: WidgetSnapshot, lines: [WidgetSnapshot.BudgetLine]
    ) -> WidgetChoice? {
        guard let id = settings.widgetCategoryID, id == stored.focusCategoryID,
            !lines.contains(where: { $0.categoryID == id }),
            let name = stored.focusCategoryName
        else { return nil }
        return WidgetChoice(missingID: id, name: name)
    }
}

import CashlyDomain
import Foundation

extension SettingsModel {
    func widgetValue(categories: [CashlyDomain.Category]) -> String {
        categories.first { $0.id == widgetCategoryID }?.name ?? String(appLocalized: "Automatic")
    }
}

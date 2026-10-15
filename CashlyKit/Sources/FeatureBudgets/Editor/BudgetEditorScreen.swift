import CashlyDesignSystem
import FeatureCore
import SwiftUI

public struct BudgetEditorScreen: View {
    @Environment(BudgetEditorModel.self) private var model
    @Environment(FinanceModel.self) private var finance
    @Environment(IntelligenceModel.self) private var intelligence
    @Environment(\.pro) private var pro

    public init() {}

    public var body: some View {
        Form {
            BudgetAmountHeader()
            BudgetSummarySection()
            BudgetCategorySection()
            BudgetDateSection()
        }
        .fontDesign(.rounded)
        .readableWidth()
        .toolbar {
            if model.canSuggestAmount(with: intelligence) {
                ToolbarItem {
                    Button("Suggest Amount", systemImage: "bolt") {
                        pro.perform { Task { await model.suggestAmount(with: intelligence) } }
                    }
                    .accessibilityValue(
                        pro.isPro ? "" : String(appLocalized: "Requires Cashly Pro")
                    )
                    .tint(.retroMustard)
                }
            }
            EditorActions(canSave: model.canSave, canRemove: model.canRemove) {
                await model.save()
            } remove: {
                await model.remove()
            }
        }
        .editorLifecycle(model.status, reloadingOn: finance.allCategories) {
            await model.loadOrRefresh()
        }
    }
}

import CashlyDesignSystem
import FeatureCore
import SwiftUI

public struct BudgetEditorScreen: View {
    @Environment(BudgetEditorModel.self) private var model
    @Environment(FinanceModel.self) private var finance
    @Environment(IntelligenceModel.self) private var intelligence

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
                        Task { await model.suggestAmount(with: intelligence) }
                    }
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

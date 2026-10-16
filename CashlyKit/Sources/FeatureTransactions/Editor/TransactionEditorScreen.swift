import CashlyDesignSystem
import CashlyDomain
import FeatureCore
import SwiftUI
import TipKit

public struct TransactionEditorScreen: View {
    @Environment(TransactionEditorModel.self) private var model
    @Environment(SessionModel.self) private var session
    @Environment(FinanceModel.self) private var finance
    @Environment(IntelligenceModel.self) private var intelligence
    @Environment(\.pro) private var pro

    public init() {}

    public var body: some View {
        @Bindable var model = model
        Form {
            TransactionAmountHeader()
            TransactionSummarySection()
            BudgetConflictLink()
            TransactionCategorySection()
            TransactionDateSection()
            TransactionCurrencySection()
            InstallmentSection().disabled(model.isAmountLocked)
            ParticipantsSection().disabled(model.isAmountLocked)
        }
        .fontDesign(.rounded)
        .readableWidth()
        .toolbar {
            ToolbarItemGroup {
                Menu {
                    Picker("Type", selection: $model.kind) {
                        ForEach(TransactionKind.allCases) {
                            Label($0.title, systemImage: $0.icon).tag($0)
                        }
                    }
                } label: {
                    Label(model.kind.title, systemImage: model.kind.icon)
                }
                .tint(Color.primary)
                if model.canEnablePrediction(with: intelligence) {
                    Button("Suggest Category", systemImage: "bolt") {
                        pro.perform { model.enablePrediction() }
                    }
                    .accessibilityValue(
                        pro.isPro ? "" : String(appLocalized: "Requires Cashly Pro"))
                }
                if !session.otherUsers.isEmpty && model.canEditParticipants {
                    MultiSelectMenu(
                        "Shared with", systemImage: "person.2.badge.plus",
                        items: session.otherUsers, selection: $model.participantUsers,
                        showsCount: false
                    ) { Text($0.name.capitalized) }
                    .tint(Color.primary)
                    .popoverTip(SplitTip())
                }
            }
            EditorActions(canSave: model.canSave, canRemove: model.canRemove) {
                await model.save()
            } remove: {
                await model.remove()
            }
        }
        .onChange(of: pro.isPro, initial: true) { model.isPro = $1 }
        .onChange(of: model.draft.summary) { model.matchTags() }
        .onChange(of: model.draft.participants) { model.updateShares() }
        .onChange(of: model.draft.amount) { model.updateShares() }
        .onChange(of: model.draft.paidAmount) { model.convertPaidAmount() }
        .task { await model.loadPaidCurrencies() }
        .task(id: model.rateRequest) { await model.updateRate() }
        .onChange(of: model.draft.splitMode) { model.changeSplitMode() }
        .task(
            id: PredictionRequest(
                summary: model.draft.summary, isActive: model.isPredictingCategory)
        ) {
            await model.predictCategory(with: intelligence)
        }
        .editorLifecycle(
            model.status,
            reloadingOn: CatalogRequest(categories: finance.allCategories, tags: finance.allTags)
        ) {
            await model.loadOrRefresh()
        }
    }
}

private struct PredictionRequest: Hashable {
    let summary: String
    let isActive: Bool
}

private struct CatalogRequest: Hashable {
    let categories: [CashlyDomain.Category]
    let tags: [Tag]
}

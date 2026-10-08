import CashlyDesignSystem
import CashlyDomain
import CashlyPresentation
import FeatureCore
import SwiftUI

public struct IntelligenceScreen: View {
    @Environment(SessionModel.self) private var session
    @Environment(FinanceModel.self) private var finance
    @Environment(IntelligenceModel.self) private var intelligence
    public init() {}
    @ViewBuilder
    public var body: some View {
        @Bindable var intelligence = intelligence
        List {
            CashlySystemMonitorView()
            if intelligence.isStale {
                Text("O histórico mudou. Treine novamente para atualizar as sugestões.")
                    .foregroundStyle(
                        .secondary)
            }
            ForEach(CashlyIntelligence.allCases) { kind in
                Section {
                    Label(kind.name, systemImage: kind.icon).foregroundStyle(kind.color)
                    if let model = intelligence.models.first(where: { $0.kind == kind }) {
                        LabeledContent(
                            "Last Update",
                            value: model.updateDate.formatted(date: .abbreviated, time: .shortened)
                        )
                        LabeledContent("Transactions", value: model.sampleCount.formatted())
                    }
                } footer: {
                    Text(kind.summary)
                }
            }
            Section {
                Button("Train Models") {
                    Task { await intelligence.train() }
                }.disabled(
                    session.user == nil || finance.totalTransactionCount < 2
                        || finance.pendingReferences > 0 || intelligence.isTraining)
                Button("Clean Models", role: .destructive) {
                    Task { await intelligence.clean() }
                }.disabled(session.user == nil || intelligence.isTraining)
                if intelligence.isTraining { ProgressView("Training") }
            } footer: {
                Text(
                    "Estimates use recent monthly spending. Categorization learns from the descriptions of your transactions. Processing stays on this device."
                )
            }
        }
        .navigationTitle("Intelligence")
        .toolbar { ToolbarItem { UserItemView() } }
        .cashlyErrorAlert(error: $intelligence.error)
    }
}

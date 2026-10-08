import CashlyDesignSystem
import CashlyDomain
import CashlyPresentation
import SwiftUI

public struct IntelligenceScreen: View {
    @Environment(MainViewModel.self) private var main
    @Environment(IntelligenceViewModel.self) private var viewModel
    public init() {}
    @ViewBuilder
    public var body: some View {
        @Bindable var viewModel = viewModel
        List {
            CashlySystemMonitorView()
            if viewModel.isStale {
                Text("O histórico mudou. Treine novamente para atualizar as sugestões.")
                    .foregroundStyle(
                        .secondary)
            }
            ForEach(CashlyIntelligence.allCases) { kind in
                Section {
                    Label(kind.name, systemImage: kind.icon).foregroundStyle(kind.color)
                    if let model = viewModel.models.first(where: { $0.kind == kind }) {
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
                    guard let user = main.user else { return }
                    Task {
                        do {
                            let dataset = try await main.trainingData()
                            await viewModel.train(user: user, dataset: dataset)
                        } catch { viewModel.error = error as? CashlyError ?? .onFetch }
                    }
                }.disabled(
                    main.user == nil || main.totalTransactionCount < 2 || main.pendingReferences > 0
                        || viewModel.isTraining)
                Button("Clean Models", role: .destructive) {
                    guard let user = main.user else { return }
                    Task { await viewModel.clean(user: user) }
                }.disabled(main.user == nil || viewModel.isTraining)
                if viewModel.isTraining { ProgressView("Training") }
            } footer: {
                Text(
                    "Estimates use recent monthly spending. Categorization learns from the descriptions of your transactions. Processing stays on this device."
                )
            }
        }
        .navigationTitle("Intelligence")
        .toolbar { ToolbarItem { UserItemView() } }
        .cashlyErrorAlert(error: $viewModel.error)
    }
}

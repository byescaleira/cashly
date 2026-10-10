import CashlyDesignSystem
import SwiftUI

struct OnboardingActions: View {
    @Environment(OnboardingModel.self) private var model
    @Environment(\.dismiss) private var dismiss

    var body: some View {
        VStack(spacing: 12) {
            Button {
                if model.step == .done {
                    dismiss()
                } else {
                    Task { await model.advance() }
                }
            } label: {
                ZStack {
                    Text(title).opacity(model.isSaving ? 0 : 1)
                    if model.isSaving { ProgressView() }
                }
                .font(.headline.weight(.bold))
                .frame(maxWidth: .infinity)
            }
            .prominentButton()
            .controlSize(.large)
            .disabled(!model.canContinue)
            if model.step == .categories {
                Button("Pular por enquanto") { Task { await model.skipCategories() } }
                    .font(.subheadline.weight(.semibold))
                    .foregroundStyle(.secondary)
                    .disabled(model.isSaving)
            }
        }
    }

    private var title: LocalizedStringKey {
        switch model.step {
        case .welcome: "Começar"
        case .profile: "Continuar"
        case .categories:
            model.suggestions.isEmpty ? "Continuar" : "Criar \(model.suggestions.count) categorias"
        case .done: "Começar a usar"
        }
    }
}

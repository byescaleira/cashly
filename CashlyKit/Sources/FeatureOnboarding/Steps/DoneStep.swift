import SwiftUI

struct DoneStep: View {
    @Environment(OnboardingModel.self) private var model

    var body: some View {
        StepLayout(
            title: "Tudo pronto, \(model.firstName)!",
            message: "Registre a primeira transação ou defina orçamentos no Planejamento."
        ) {
            Image(systemName: "checkmark.circle.fill")
                .font(.system(size: 96))
                .foregroundStyle(.tint)
                .symbolEffect(.bounce, options: .nonRepeating)
        } content: {
            EmptyView()
        }
    }
}

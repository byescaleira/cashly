import SwiftUI

struct OnboardingTopBar: View {
    @Environment(OnboardingModel.self) private var model

    var body: some View {
        ZStack {
            HStack(spacing: 6) {
                ForEach(OnboardingStep.allCases, id: \.self) { step in
                    Capsule()
                        .fill(step == model.step ? Color.accentColor : Color.secondary.opacity(0.3))
                        .frame(width: step == model.step ? 18 : 6, height: 6)
                }
            }
            .accessibilityHidden(true)
            if model.canGoBack {
                Button("Voltar", systemImage: "chevron.left") { model.back() }
                    .labelStyle(.iconOnly)
                    .buttonBorderShape(.circle)
                    .buttonStyle(.bordered)
                    .frame(maxWidth: .infinity, alignment: .leading)
            }
        }
        .frame(height: 44)
    }
}

import CashlyDesignSystem
import CashlyResource
import SwiftUI

struct ProfileStep: View {
    @Environment(OnboardingModel.self) private var model

    var body: some View {
        @Bindable var model = model
        StepLayout(
            title: "Como podemos te chamar?",
            message: "Seu perfil separa as suas finanças das de outras pessoas da casa."
        ) {
            CashlyResourceImage.avatar(id: model.photo)
                .resizable()
                .scaledToFit()
                .frame(width: 140, height: 140)
                .background(.subtleFill, in: .circle)
                .overlay(alignment: .bottomTrailing) {
                    Button("Trocar foto", systemImage: "arrow.triangle.2.circlepath") {
                        withAnimation(.bouncy) { model.shufflePhoto() }
                    }
                    .labelStyle(.iconOnly)
                    .buttonBorderShape(.circle)
                    .buttonStyle(.borderedProminent)
                }
                .contentTransition(.opacity)
        } content: {
            TextField("Seu nome", text: $model.name)
                .textContentType(.givenName)
                .submitLabel(.next)
                .onSubmit { Task { await model.advance() } }
                .font(.title3.weight(.semibold))
                .multilineTextAlignment(.center)
                .padding(.vertical, 14)
                .background(.subtleFill, in: .capsule)
        }
    }
}

import CashlyDesignSystem
import CashlyResource
import FeatureCore
import SwiftUI

struct ProfileStep: View {
    @Environment(OnboardingModel.self) private var model

    var body: some View {
        @Bindable var model = model
        GuidePage(
            title: "What Should We Call You?",
            message: "Your profile keeps your finances separate from other people at home."
        ) {
            CashlyResourceImage.avatar(id: model.photo)
                .resizable()
                .scaledToFit()
                .frame(width: 140, height: 140)
                .background(.subtleFill, in: .circle)
                .overlay(alignment: .bottomTrailing) {
                    Button("Change Photo", systemImage: "arrow.triangle.2.circlepath") {
                        withAnimation(.bouncy) { model.shufflePhoto() }
                    }
                    .labelStyle(.iconOnly)
                    .buttonBorderShape(.circle)
                    .buttonStyle(.borderedProminent)
                }
                .contentTransition(.opacity)
        } content: {
            TextField("Your Name", text: $model.name)
                .textContentType(.givenName)
                .submitLabel(.next)
                .onSubmit { Task { await model.advance() } }
                .font(.title3.weight(.semibold))
                .multilineTextAlignment(.center)
                .padding(.vertical, .spaceM)
                .background(.subtleFill, in: .capsule)
        }
    }
}

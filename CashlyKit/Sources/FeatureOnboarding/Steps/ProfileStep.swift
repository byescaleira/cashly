import CashlyDesignSystem
import FeatureCore
import SwiftUI

struct ProfileStep: View {
    @Environment(OnboardingModel.self) private var model
    @Environment(\.accessibilityReduceMotion) private var reduceMotion

    var body: some View {
        @Bindable var model = model
        GuidePage(
            title: "What Should We Call You?",
            message:
                "Each profile keeps its own finances: a person, a business, a bank or anything else."
        ) {
            ProfileAvatar(photo: model.photo, initials: model.initials, size: .medallion)
                .overlay(alignment: .bottomTrailing) {
                    Button("Change Color", systemImage: "arrow.triangle.2.circlepath") {
                        withAnimation(reduceMotion ? nil : .bouncy) { model.changeColor() }
                    }
                    .labelStyle(.iconOnly)
                    .buttonBorderShape(.circle)
                    .prominentButton()
                }
                .sensoryFeedback(.selection, trigger: model.photo)
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

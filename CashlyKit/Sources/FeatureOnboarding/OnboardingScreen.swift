import FeatureCore
import SwiftUI

public struct OnboardingScreen: View {
    @Environment(OnboardingModel.self) private var model
    @Environment(\.dismiss) private var dismiss

    public init() {}

    public var body: some View {
        @Bindable var model = model
        GuideSheet(
            index: model.step.rawValue, count: OnboardingStep.allCases.count,
            isWorking: model.isSaving, back: back, primary: primary, secondary: secondary
        ) {
            OnboardingPage(step: model.step)
        }
        .interactiveDismissDisabled()
        .errorAlert($model.error)
    }

    private var back: (() -> Void)? {
        guard model.canGoBack else { return nil }
        return { model.back() }
    }

    private var primary: GuideAction {
        GuideAction(primaryTitle, isEnabled: model.canContinue) {
            if model.step == .done {
                dismiss()
            } else {
                Task { await model.advance() }
            }
        }
    }

    private var secondary: GuideAction? {
        guard model.step == .categories else { return nil }
        return GuideAction("Skip for Now") { Task { await model.skipCategories() } }
    }

    private var primaryTitle: LocalizedStringKey {
        switch model.step {
        case .welcome: "Get Started"
        case .profile: "Continue"
        case .categories:
            model.suggestions.isEmpty ? "Continue" : "Create \(model.suggestions.count) Categories"
        case .done: "Start Using Cashly"
        }
    }
}

private struct OnboardingPage: View {
    let step: OnboardingStep

    var body: some View {
        switch step {
        case .welcome: WelcomeStep()
        case .profile: ProfileStep()
        case .categories: CategoriesStep()
        case .done: DoneStep()
        }
    }
}

import CashlyDesignSystem
import FeatureCore
import SwiftUI

public struct OnboardingScreen: View {
    @Environment(OnboardingModel.self) private var model
    @State private var height: CGFloat = 560

    public init() {}

    public var body: some View {
        @Bindable var model = model
        VStack(spacing: 24) {
            OnboardingTopBar()
            Group {
                switch model.step {
                case .welcome: WelcomeStep()
                case .profile: ProfileStep()
                case .categories: CategoriesStep()
                case .done: DoneStep()
                }
            }
            .id(model.step)
            .transition(
                .asymmetric(insertion: .move(edge: .trailing), removal: .move(edge: .leading))
                    .combined(with: .opacity))
            OnboardingActions()
        }
        .padding([.horizontal, .bottom], 24)
        .padding(.top, 16)
        .fontDesign(.rounded)
        .animation(.smooth, value: model.step)
        .fixedSize(horizontal: false, vertical: true)
        .onGeometryChange(for: CGFloat.self) {
            $0.size.height
        } action: {
            height = $0
        }
        .presentationDetents([.height(height)])
        .presentationDragIndicator(.hidden)
        .interactiveDismissDisabled()
        .errorAlert($model.error)
    }
}

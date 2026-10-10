public enum OnboardingStep: Int, CaseIterable, Sendable {
    case welcome, profile, categories, done

    var previous: OnboardingStep? {
        switch self {
        case .profile: .welcome
        case .categories: .profile
        case .welcome, .done: nil
        }
    }
}

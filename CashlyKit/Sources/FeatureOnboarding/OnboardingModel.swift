import CashlyDomain
import FeatureCore
import Foundation
import Observation

@MainActor @Observable
public final class OnboardingModel {
    public var step = OnboardingStep.welcome
    public var name = ""
    public var photo = ProfilePhoto.initials(
        color: RetroColor.allCases.randomElement()?.hex ?? ProfilePhoto.defaultColor)
    public var suggestions = CategorySuggestion.defaults
    public private(set) var isSaving = false
    public var error: CashlyError?
    @ObservationIgnored private let session: SessionModel

    public init(session: SessionModel) {
        self.session = session
    }

    public var firstName: String {
        name.trimmingCharacters(in: .whitespacesAndNewlines).components(separatedBy: " ").first
            ?? ""
    }

    public var canContinue: Bool {
        guard !isSaving else { return false }
        return step != .profile || name.trimmingCharacters(in: .whitespacesAndNewlines).count >= 3
    }

    public var canGoBack: Bool { step.previous != nil && !isSaving }

    public var initials: String { User.initials(of: name) }

    public func changeColor() {
        let colors = RetroColor.allCases
        let current = photo.color.flatMap(RetroColor.init(hex:)).flatMap(colors.firstIndex) ?? 0
        photo = photo.recolored(colors[(current + 1) % colors.count].hex)
    }

    public func isSelected(_ suggestion: CategorySuggestion) -> Bool {
        suggestions.contains(suggestion)
    }

    public func toggle(_ suggestion: CategorySuggestion) {
        if suggestions.contains(suggestion) {
            suggestions.remove(suggestion)
        } else {
            suggestions.insert(suggestion)
        }
    }

    public func back() {
        if let previous = step.previous { step = previous }
    }

    public func advance() async {
        switch step {
        case .welcome: step = .profile
        case .profile: step = .categories
        case .categories: await create()
        case .done: break
        }
    }

    public func skipCategories() async {
        suggestions = []
        await create()
    }

    private func create() async {
        isSaving = true
        defer { isSaving = false }
        do {
            let user = User(
                id: UUID().uuidString, name: name.trimmingCharacters(in: .whitespacesAndNewlines),
                photo: photo)
            try await session.repositories.users.save(user)
            await session.selectUser(id: user.id)
            for suggestion in CategorySuggestion.allCases where suggestions.contains(suggestion) {
                try await session.repositories.categories.save(suggestion.category(for: user))
            }
            step = .done
        } catch {
            self.error = error as? CashlyError ?? .onSave
        }
    }
}

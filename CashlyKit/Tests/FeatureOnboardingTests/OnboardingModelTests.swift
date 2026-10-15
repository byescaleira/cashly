import CashlyData
import CashlyDomain
import FeatureCore
import FeatureOnboarding
import Testing

@MainActor
struct OnboardingModelTests {
    private func onboarding() async throws -> (OnboardingModel, SessionModel, CashlyDatabase) {
        let database = try CashlyDatabase.open(inMemory: true)
        let session = SessionModel(provider: database, preference: .disabled)
        await session.refreshUsers()
        return (OnboardingModel(session: session), session, database)
    }

    @Test func emptyDirectoryNeedsOnboarding() async throws {
        let (_, session, _) = try await onboarding()
        #expect(session.needsOnboarding)
    }

    @Test func profileNeedsANameBeforeContinuing() async throws {
        let (model, _, _) = try await onboarding()
        await model.advance()
        #expect(model.step == .profile)
        model.name = " Al "
        #expect(!model.canContinue)
        model.name = "Ana Souza"
        #expect(model.canContinue)
        #expect(model.firstName == "Ana")
    }

    @Test func profilePhotoShowsInitialsAndChangesColor() async throws {
        let (model, _, _) = try await onboarding()
        model.name = "ana souza"
        #expect(model.initials == "AS")
        #expect(model.photo == .suggested(for: model.userID))
        let before = model.photo
        model.changeColor()
        #expect(model.photo != before)
        #expect(model.photo == .initials(color: model.photo.color ?? ""))
        #expect(model.photo.color.flatMap(RetroColor.init(hex:)) != nil)
    }

    @Test func finishingCreatesTheUserAndChosenCategories() async throws {
        let (model, session, database) = try await onboarding()
        await model.advance()
        model.name = "Ana"
        await model.advance()
        model.suggestions = [.groceries, .pets]
        await model.advance()
        #expect(model.step == .done)
        let user = try #require(session.user)
        #expect(user.name == "Ana")
        #expect(user.photo == model.photo)
        #expect(user.id == model.userID)
        let categories = try await database.repositories(for: user.id).dashboard.snapshot(
            month: nil
        ).categories
        #expect(Set(categories.map(\.name)) == ["Groceries", "Pets"])
        #expect(categories.allSatisfy { RetroColor(hex: $0.color) != nil })
    }

    @Test func skippingCreatesOnlyTheUser() async throws {
        let (model, session, database) = try await onboarding()
        model.step = .categories
        model.name = "Ana"
        await model.skipCategories()
        let user = try #require(session.user)
        #expect(
            try await database.repositories(for: user.id).dashboard.snapshot(month: nil).categories
                .isEmpty)
        #expect(model.step == .done)
    }
}

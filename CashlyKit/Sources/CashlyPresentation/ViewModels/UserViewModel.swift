import CashlyDomain
import Foundation
import Observation

@MainActor @Observable
public final class UserViewModel {
    public var draft: UserDraft
    public private(set) var isLoading = false
    public private(set) var isSaved = false
    public var error: CashlyError?
    public var canSave: Bool { hasLoaded && draft.canSave && !isLoading && !isSaved }
    @ObservationIgnored private var hasLoaded = false
    @ObservationIgnored private let userUseCase: any UserUseCase

    public init(draft: UserDraft = .new(), dataFactory: any CashlyDataFactoryProtocol) {
        self.draft = draft
        self.userUseCase = dataFactory.makeUserUseCase()
    }

    public func load() async {
        guard !hasLoaded, !isLoading else { return }
        isLoading = true
        error = nil
        defer { isLoading = false }
        do {
            let record = try await userUseCase.getUser(id: draft.id)
            try Task.checkCancellation()
            if !draft.isNew && record == nil { throw CashlyError.missingRecord }
            if let record {
                draft.name = record.name
                draft.photo = record.photo
            }
            if draft.photo == nil { draft.photo = "1" }
            try Task.checkCancellation()
            hasLoaded = true
        } catch is CancellationError {} catch { self.error = error as? CashlyError ?? .onFetch }
    }

    public func save() async {
        guard !isLoading && !isSaved else { return }
        isLoading = true
        error = nil
        defer { isLoading = false }
        do {
            guard hasLoaded && draft.canSave else { throw CashlyError.onSave }
            guard draft.name.trimmingCharacters(in: .whitespacesAndNewlines).count >= 3,
                let photo = draft.photo,
                (1...100).contains(Int(photo) ?? 0)
            else {
                self.error = .onSave
                return
            }
            try await userUseCase.addUser(
                id: draft.id,
                name: draft.name.trimmingCharacters(in: .whitespacesAndNewlines),
                photo: photo
            )

            isSaved = true
        } catch {
            self.error = error as? CashlyError ?? .onSave
        }
    }

    public func remove() async {
        guard hasLoaded && !draft.isNew && !isLoading && !isSaved else { return }
        isLoading = true
        error = nil
        defer { isLoading = false }
        do {
            try await userUseCase.removeUser(id: draft.id)
            isSaved = true
        } catch {
            self.error = error as? CashlyError ?? .onRemove
        }
    }
}

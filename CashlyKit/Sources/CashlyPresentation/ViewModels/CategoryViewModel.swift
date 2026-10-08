import CashlyDesignSystem
import CashlyDomain
import Foundation
import Observation
import SwiftUI

@MainActor @Observable
public final class CategoryViewModel {
    public var draft: CategoryDraft
    public private(set) var isLoading = false
    public private(set) var isSaved = false
    public var error: CashlyError?
    public var canSave: Bool { hasLoaded && draft.canSave && !isLoading && !isSaved }
    @ObservationIgnored private var hasLoaded = false
    @ObservationIgnored private let contextUserID: String?
    @ObservationIgnored private let categories: any CategoryRepository
    @ObservationIgnored private let users: any UserRepository

    public init(draft: CategoryDraft = .new(), repositories: Repositories) {
        self.draft = draft
        self.contextUserID = repositories.userID
        self.categories = repositories.categories
        self.users = repositories.users
    }

    public func load() async {
        guard !hasLoaded, !isLoading else { return }
        isLoading = true
        error = nil
        defer { isLoading = false }
        do {
            let record = try await categories.category(id: draft.id)
            try Task.checkCancellation()
            if !draft.isNew && record == nil { throw CashlyError.missingRecord }
            let currentUser: User?
            if let contextUserID {
                currentUser = try await users.user(id: contextUserID)
            } else {
                currentUser = nil
            }
            try Task.checkCancellation()
            draft.user = record?.user ?? draft.user ?? currentUser
            if let record {
                draft.name = record.name
                draft.icon = record.icon
                draft.color = Color(hex: record.color)
            }
            if draft.icon.isEmpty { draft.icon = "tag.fill" }
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
                !draft.icon.isEmpty,
                let user = draft.user
            else {
                self.error = .onSave
                return
            }
            try await categories.save(
                CashlyDomain.Category(
                    id: draft.id, user: user,
                    name: draft.name.trimmingCharacters(in: .whitespacesAndNewlines),
                    color: draft.color.hex, icon: draft.icon))
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
            try await categories.delete(id: draft.id)
            isSaved = true
        } catch {
            self.error = error as? CashlyError ?? .onRemove
        }
    }
}

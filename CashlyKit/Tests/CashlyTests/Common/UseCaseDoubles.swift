//
//  UseCaseDoubles.swift
//  CashlyKit
//
//  Test doubles for Domain UseCase protocols. Each double exposes
//  programmable return values + throw flags + call-record arrays so
//  middleware tests can drive deterministic scenarios without
//  SwiftData / in-memory store roundtrips.
//

import Foundation
import CashlyDomain

// MARK: - Recorder

final class CallRecorder<Args>: @unchecked Sendable {
    private let lock = NSLock()
    private var _calls: [Args] = []

    var calls: [Args] {
        lock.lock(); defer { lock.unlock() }
        return _calls
    }

    func record(_ args: Args) {
        lock.lock(); defer { lock.unlock() }
        _calls.append(args)
    }
}

// MARK: - UserUseCaseDouble

final class UserUseCaseDouble: UserUseCase, @unchecked Sendable {
    var users: [User] = []
    var currentUser: User?
    var throwOnGet = false
    var throwOnAdd = false
    var throwOnSelect = false
    var throwOnRemove = false

    let getUserCalls = CallRecorder<String>()
    let addUserCalls = CallRecorder<(id: String, name: String, photo: String)>()
    let selectUserCalls = CallRecorder<User>()
    let removeUserCalls = CallRecorder<String>()

    func getUser(id: String) async throws -> User? {
        getUserCalls.record(id)
        if throwOnGet { throw CashlyError.onFetch }
        return users.first { $0.id == id }
    }

    func getCurrentUser() async throws -> User? {
        if throwOnGet { throw CashlyError.onFetch }
        return currentUser
    }

    func selectUser(user: User) async throws {
        selectUserCalls.record(user)
        if throwOnSelect { throw CashlyError.onSave }
        currentUser = user
    }

    func getUsers() async throws -> [User] {
        if throwOnGet { throw CashlyError.onFetch }
        return users
    }

    func removeUser(id: String) async throws {
        removeUserCalls.record(id)
        if throwOnRemove { throw CashlyError.onRemove }
        users.removeAll { $0.id == id }
    }

    func removeUsers() async throws {
        if throwOnRemove { throw CashlyError.onRemove }
        users.removeAll()
    }

    func addUser(id: String, name: String, photo: String) async throws {
        addUserCalls.record((id, name, photo))
        if throwOnAdd { throw CashlyError.onSave }
        users.append(User(id: id, name: name, photo: photo))
    }
}

// MARK: - BudgetUseCaseDouble

final class BudgetUseCaseDouble: BudgetUseCase, @unchecked Sendable {
    var budgets: [Budget] = []
    var throwOnGet = false
    var throwOnAdd = false
    var throwOnRemove = false

    func getBudget(id: String) async throws -> Budget? {
        if throwOnGet { throw CashlyError.onFetch }
        return budgets.first { $0.id == id }
    }

    func getBudgets() async throws -> [Budget] {
        if throwOnGet { throw CashlyError.onFetch }
        return budgets
    }

    func getBudgets(categories: [String]?, date: Date?) async throws -> [Budget] {
        if throwOnGet { throw CashlyError.onFetch }
        var result = budgets
        if let categories {
            result = result.filter { categories.contains($0.category.id) }
        }
        return result
    }

    func removeBudget(id: String) async throws {
        if throwOnRemove { throw CashlyError.onRemove }
        budgets.removeAll { $0.id == id }
    }

    func removeBudgets() async throws {
        if throwOnRemove { throw CashlyError.onRemove }
        budgets.removeAll()
    }

    func addBudget(id: String, amount: Double, category: CashlyDomain.Category, date: Int, summary: String) async throws {
        if throwOnAdd { throw CashlyError.onSave }
        budgets.append(Budget(id: id, amount: amount, category: category, date: date, summary: summary))
    }
}

// MARK: - CategoryUseCaseDouble

final class CategoryUseCaseDouble: CategoryUseCase, @unchecked Sendable {
    var categories: [CashlyDomain.Category] = []
    var throwOnGet = false
    var throwOnAdd = false
    var throwOnRemove = false

    func getCategory(id: String) async throws -> CashlyDomain.Category? {
        if throwOnGet { throw CashlyError.onFetch }
        return categories.first { $0.id == id }
    }

    func getCategories() async throws -> [CashlyDomain.Category] {
        if throwOnGet { throw CashlyError.onFetch }
        return categories
    }

    func getCategories(ids: [String]?, users: [String]?) async throws -> [CashlyDomain.Category] {
        if throwOnGet { throw CashlyError.onFetch }
        var out = categories
        if let ids { out = out.filter { ids.contains($0.id) } }
        if let users { out = out.filter { users.contains($0.user.id) } }
        return out
    }

    func removeCategory(id: String) async throws {
        if throwOnRemove { throw CashlyError.onRemove }
        categories.removeAll { $0.id == id }
    }

    func removeCategories() async throws {
        if throwOnRemove { throw CashlyError.onRemove }
        categories.removeAll()
    }

    func addCategory(id: String, user: String, name: String, color: String, icon: String) async throws {
        if throwOnAdd { throw CashlyError.onSave }
        // For doubles we just track the call; constructing a real User isn't
        // required for the assertions we make.
    }
}

// MARK: - TransactionUseCaseDouble

final class TransactionUseCaseDouble: TransactionUseCase, @unchecked Sendable {
    var transactions: [CashlyDomain.Transaction] = []
    var throwOnGet = false
    var throwOnAdd = false
    var throwOnRemove = false

    func getTransaction(id: String) async throws -> CashlyDomain.Transaction? {
        if throwOnGet { throw CashlyError.onFetch }
        return transactions.first { $0.id == id }
    }

    func getTransactions() async throws -> [CashlyDomain.Transaction] {
        if throwOnGet { throw CashlyError.onFetch }
        return transactions
    }

    func getTransactions(
        budgets: [String]?,
        tags: [String]?,
        statuses: [Int]?,
        participants: [String]?,
        date: Date?
    ) async throws -> [CashlyDomain.Transaction] {
        if throwOnGet { throw CashlyError.onFetch }
        return transactions
    }

    func removeTransaction(id: String) async throws {
        if throwOnRemove { throw CashlyError.onRemove }
        transactions.removeAll { $0.id == id }
    }

    func removeTransactions() async throws {
        if throwOnRemove { throw CashlyError.onRemove }
        transactions.removeAll()
    }

    func removeTransactions(ids: Set<String>) async throws {
        if throwOnRemove { throw CashlyError.onRemove }
        transactions.removeAll { ids.contains($0.id) }
    }

    func addTransaction(
        id: String,
        participants: [Participant],
        budget: Budget,
        amount: Double,
        date: TimeInterval,
        summary: String,
        status: TransactionStatus,
        splitMode: TransactionSplitMode?,
        splitValue: Double?,
        paymentsPlan: Int?
    ) async throws {
        if throwOnAdd { throw CashlyError.onSave }
    }
}

// MARK: - TagUseCaseDouble

final class TagUseCaseDouble: TagUseCase, @unchecked Sendable {
    var tags: [Tag] = []
    var throwOnGet = false
    var throwOnAdd = false
    var throwOnRemove = false

    func getTag(id: String) async throws -> Tag? {
        if throwOnGet { throw CashlyError.onFetch }
        return tags.first { $0.id == id }
    }

    func getTags() async throws -> [Tag] {
        if throwOnGet { throw CashlyError.onFetch }
        return tags
    }

    func getTags(users: [String]?) async throws -> [Tag] {
        if throwOnGet { throw CashlyError.onFetch }
        return tags
    }

    func removeTag(id: String) async throws {
        if throwOnRemove { throw CashlyError.onRemove }
        tags.removeAll { $0.id == id }
    }

    func removeTags() async throws {
        if throwOnRemove { throw CashlyError.onRemove }
        tags.removeAll()
    }

    func addTag(id: String, user: String, name: String, color: String, icon: String) async throws {
        if throwOnAdd { throw CashlyError.onSave }
    }
}

// MARK: - ParticipantUseCaseDouble

final class ParticipantUseCaseDouble: ParticipantUseCase, @unchecked Sendable {
    var participants: [Participant] = []
    var throwOnGet = false
    var throwOnAdd = false
    var throwOnRemove = false

    func getParticipant(id: String) async throws -> Participant? {
        if throwOnGet { throw CashlyError.onFetch }
        return participants.first { $0.id == id }
    }

    func getParticipants() async throws -> [Participant] {
        if throwOnGet { throw CashlyError.onFetch }
        return participants
    }

    func getParticipants(transaction: String) async throws -> [Participant] {
        if throwOnGet { throw CashlyError.onFetch }
        return participants.filter { $0.transaction == transaction }
    }

    func removeParticipant(id: String) async throws {
        if throwOnRemove { throw CashlyError.onRemove }
        participants.removeAll { $0.id == id }
    }

    func removeParticipants() async throws {
        if throwOnRemove { throw CashlyError.onRemove }
        participants.removeAll()
    }

    func addParticipant(
        id: String,
        user: User,
        splitMode: TransactionSplitMode,
        splitValue: Double,
        status: TransactionStatus,
        transaction: String
    ) async throws {
        if throwOnAdd { throw CashlyError.onSave }
    }
}

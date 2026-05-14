//
//  MockCategoryActor.swift
//  CashlyKit
//
//  Created by Rafael Escaleira on 03/09/25.
//

import CashlyDomain
import SwiftData

actor MockCategoryActor: CategoryUseCase {
    var categories = CashlyDomain.Category.mocks
    let users = User.mocks

    init() {}

    func getCategory(id: String) async throws -> CashlyDomain.Category? {
        categories.first(where: { $0.id == id })
    }

    func getCategories() async throws -> [CashlyDomain.Category] {
        categories
    }

    func getCategories(
        ids: [String]?,
        users: [String]?
    ) async throws -> [CashlyDomain.Category] {
        categories.filter {
            ids?.contains($0.id) ?? false &&
            users?.contains($0.user.id) ?? false
        }
    }

    func removeCategory(id: String) async throws {
        guard let category = try await getCategory(id: id),
              let index = categories.firstIndex(of: category)
        else { return }
        let _ = categories.remove(at: index)
    }

    func removeCategories() async throws {
        categories = []
    }

    func addCategory(
        id: String,
        user: String,
        name: String,
        color: String,
        icon: String,
        order: Int
    ) async throws {
        guard let user = users.first(where: { $0.id == user }) else { return }
        let category = Category(
            id: id,
            user: user,
            name: name,
            color: color,
            icon: icon,
            order: order
        )
        categories.append(category)
    }

    func reorderCategories(ids: [String]) async throws {
        var byId = Dictionary(uniqueKeysWithValues: categories.map { ($0.id, $0) })
        for (index, id) in ids.enumerated() {
            byId[id]?.order = index
        }
        categories = byId.values.sorted { $0.order < $1.order }
    }
}


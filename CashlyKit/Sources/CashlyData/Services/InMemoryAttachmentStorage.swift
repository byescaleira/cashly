//
//  InMemoryAttachmentStorage.swift
//  CashlyKit
//
//  Test stub. Holds attachment bytes in a dictionary keyed by the
//  returned path, so feature tests can round-trip save → load
//  without touching the filesystem.
//

import Foundation
import CashlyDomain

public actor InMemoryAttachmentStorage: AttachmentStorageUseCase {
    private var storage: [String: Data] = [:]

    public init() {}

    public func save(data: Data, suggestedExtension: String) async throws -> String {
        let path = "memory/\(UUID().uuidString).\(suggestedExtension)"
        storage[path] = data
        return path
    }

    public func load(path: String) async -> Data? {
        storage[path]
    }

    public func remove(path: String) async {
        storage.removeValue(forKey: path)
    }
}

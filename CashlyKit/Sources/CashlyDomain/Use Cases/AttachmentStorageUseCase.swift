//
//  AttachmentStorageUseCase.swift
//  CashlyKit
//
//  Stores receipt images on disk inside the app sandbox and returns
//  a stable relative path the caller persists in Transaction.
//  Reads / deletes happen by the same path. Production impl uses
//  FileManager + Documents/Attachments; tests use an in-memory map.
//

import Foundation

public protocol AttachmentStorageUseCase: Sendable {
    /// Persists `data` as a new attachment and returns the relative
    /// path the caller should store in Transaction.attachmentPath.
    func save(data: Data, suggestedExtension: String) async throws -> String
    /// Reads attachment bytes for the supplied relative path. Returns
    /// nil when the file is missing.
    func load(path: String) async -> Data?
    /// Removes the attachment at the path. No-op when absent.
    func remove(path: String) async
}

//
//  DocumentsAttachmentStorage.swift
//  CashlyKit
//
//  AttachmentStorageUseCase backed by the app sandbox's Documents
//  directory. Files live under `Documents/Attachments/` so iOS +
//  CloudKit Documents sync (when the user has the iCloud Drive
//  container enabled) ship them automatically.
//

import Foundation
import CashlyDomain

public actor DocumentsAttachmentStorage: AttachmentStorageUseCase {
    private let directoryName: String
    private let fileManager: FileManager

    public init(directoryName: String = "Attachments", fileManager: FileManager = .default) {
        self.directoryName = directoryName
        self.fileManager = fileManager
    }

    private var directoryURL: URL {
        let documents = fileManager.urls(for: .documentDirectory, in: .userDomainMask)[0]
        return documents.appending(path: directoryName)
    }

    public func save(data: Data, suggestedExtension: String) async throws -> String {
        try ensureDirectoryExists()
        let filename = "\(UUID().uuidString).\(suggestedExtension)"
        let url = directoryURL.appending(path: filename)
        try data.write(to: url, options: .atomic)
        return "\(directoryName)/\(filename)"
    }

    public func load(path: String) async -> Data? {
        let url = resolve(path: path)
        return try? Data(contentsOf: url)
    }

    public func remove(path: String) async {
        let url = resolve(path: path)
        try? fileManager.removeItem(at: url)
    }

    private func resolve(path: String) -> URL {
        let documents = fileManager.urls(for: .documentDirectory, in: .userDomainMask)[0]
        return documents.appending(path: path)
    }

    private func ensureDirectoryExists() throws {
        if !fileManager.fileExists(atPath: directoryURL.path) {
            try fileManager.createDirectory(at: directoryURL, withIntermediateDirectories: true)
        }
    }
}

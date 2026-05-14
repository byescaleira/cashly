//
//  InMemoryAttachmentStorageTests.swift
//  CashlyKit
//

import Foundation
import Testing
import CashlyDomain
import CashlyData

@Suite("InMemoryAttachmentStorage", .tags(.unit, .local))
struct InMemoryAttachmentStorageTests {

    private let payload = Data([0xDE, 0xAD, 0xBE, 0xEF])

    @Test("save returns a path that resolves to the stored data")
    func roundTrip() async throws {
        let storage = InMemoryAttachmentStorage()
        let path = try await storage.save(data: payload, suggestedExtension: "jpg")
        let loaded = await storage.load(path: path)
        #expect(loaded == payload)
        #expect(path.hasSuffix(".jpg"))
    }

    @Test("load returns nil for unknown paths")
    func missingPath() async {
        let storage = InMemoryAttachmentStorage()
        let loaded = await storage.load(path: "memory/nope.jpg")
        #expect(loaded == nil)
    }

    @Test("remove drops the file so subsequent loads return nil")
    func removal() async throws {
        let storage = InMemoryAttachmentStorage()
        let path = try await storage.save(data: payload, suggestedExtension: "png")
        await storage.remove(path: path)
        let loaded = await storage.load(path: path)
        #expect(loaded == nil)
    }
}

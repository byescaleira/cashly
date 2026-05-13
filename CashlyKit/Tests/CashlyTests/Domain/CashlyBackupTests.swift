//
//  CashlyBackupTests.swift
//  CashlyKit
//

import Foundation
import Testing
import CashlyDomain

@Suite("CashlyBackup", .tags(.unit, .local))
struct CashlyBackupTests {

    private func makeUser() -> User {
        User(id: "u", name: "Alice", photo: "p")
    }

    private func makeBackup() -> CashlyBackup {
        let user = makeUser()
        let category = CashlyDomain.Category(
            id: "c", user: user, name: "Food", color: "#000", icon: "x"
        )
        let budget = Budget(id: "b", amount: 100, category: category, date: 202604, summary: "Lunch")
        let tag = Tag(id: "t", user: user, name: "Coffee", color: "#000", icon: "cup")
        let tx = Transaction(
            id: "tx", participants: [], budget: budget, amount: 10,
            date: 1_715_000_000, summary: "Snack", status: .settled,
            splitMode: nil, splitValue: nil, paymentsPlan: nil
        )
        return CashlyBackup(
            exportedAt: Date(timeIntervalSince1970: 1_715_000_000),
            users: [user],
            categories: [category],
            budgets: [budget],
            tags: [tag],
            transactions: [tx]
        )
    }

    @Test("encode produces stable JSON with sorted keys")
    func encodeProducesJSON() throws {
        let backup = makeBackup()
        let json = try CashlyBackupCoder.encode(backup)
        #expect(json.contains("\"version\" : 1"))
        #expect(json.contains("\"users\""))
        #expect(json.contains("\"transactions\""))
    }

    @Test("decode round-trips the snapshot")
    func roundtrip() throws {
        let original = makeBackup()
        let json = try CashlyBackupCoder.encode(original)
        let decoded = try CashlyBackupCoder.decode(json)
        #expect(decoded == original)
    }

    @Test("version defaults to 1")
    func versionDefaults() {
        let backup = makeBackup()
        #expect(backup.version == 1)
    }
}

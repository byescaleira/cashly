//
//  CashlyResourceTests.swift
//  CashlyKit
//
//  Cover the public surface in CashlyResource:
//  - CashlyL10n.string(_:) typed lookup (English fallback)
//  - CashlyResourceFile data/decoded paths
//  - CashlyResourceImage rawValues + avatar fallback
//

import Foundation
import Testing
import CashlyDomain
import CashlyResource

@Suite("CashlyResource", .tags(.unit, .data, .local))
struct CashlyResourceTests {

    // MARK: - CashlyL10n

    @Test("CashlyL10n.string falls back to key when not localized")
    func l10nFallback() {
        let str = CashlyL10n.string("__not_a_real_key__")
        #expect(str == "__not_a_real_key__")
    }

    @Test("CashlyL10n.string returns a non-empty value for known keys")
    func l10nKnownKey() {
        let save = CashlyL10n.string("Save")
        let delete = CashlyL10n.string("Delete")
        #expect(!save.isEmpty)
        #expect(!delete.isEmpty)
    }

    // MARK: - CashlyResourceFile

    @Test("every CashlyResourceFile case has non-empty data")
    func filesHaveData() {
        for file in CashlyResourceFile.allCases {
            #expect(!file.data.isEmpty, "expected data for \(file.rawValue)")
        }
    }

    @Test("decoded<[User]>() returns the seeded users JSON")
    func decodeUsers() throws {
        let users: [User] = try CashlyResourceFile.users.decoded()
        #expect(!users.isEmpty)
        // Each fixture user has a non-empty name.
        for u in users { #expect(!u.name.isEmpty) }
    }

    @Test("decoded<[CashlyDomain.Category]>() returns the seeded categories")
    func decodeCategories() throws {
        let categories: [CashlyDomain.Category] = try CashlyResourceFile.categories.decoded()
        #expect(!categories.isEmpty)
    }

    // MARK: - CashlyResourceImage

    @Test("every illustration case maps to its rawValue")
    func imageRawValues() {
        let cases: [(CashlyResourceImage, String)] = [
            (.illustrationEmpty, "illustrationEmpty"),
            (.illustrationNoData, "illustrationNoData"),
            (.illustrationPeople, "illustrationPeople"),
            (.illustrationTransaction, "illustrationTransaction"),
            (.illustrationTag, "illustrationTag")
        ]
        for (image, expectedRaw) in cases {
            #expect(image.rawValue == expectedRaw)
        }
    }

    @Test("avatar(id: nil) returns the SF fallback image without crash")
    func avatarFallback() {
        _ = CashlyResourceImage.avatar(id: nil)
        // No assertion beyond "didn't crash" — Image is opaque here.
    }

    @Test("avatar(id:) returns an Image for arbitrary id")
    func avatarWithId() {
        _ = CashlyResourceImage.avatar(id: "42")
        // Same — Image equality is private; presence is enough.
    }
}

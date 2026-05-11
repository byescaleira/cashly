//
//  CashlyErrorTests.swift
//  CashlyKit
//

import Testing
import CashlyDomain

@Suite("CashlyError + nested errors", .tags(.unit, .data, .local))
struct CashlyErrorTests {

    // MARK: - .unknown

    @Test(".unknown carries the supplied message")
    func unknownCarriesMessage() {
        let error = CashlyError.unknown(message: "oops")
        #expect(error.errorDescription == "oops")
        #expect(error.recoverySuggestion?.contains("contact support") == true)
    }

    // MARK: - PersistenceError

    @Test("PersistenceError.fetchFailed surfaces underlying detail")
    func persistenceFetchFailed() {
        let pe = PersistenceError.fetchFailed(entity: "Budget", underlying: "boom")
        #expect(pe.errorDescription == "Failed to fetch Budget.")
        #expect(pe.failureReason == "boom")
        #expect(pe.recoverySuggestion == "Check your connection and try again.")
    }

    @Test("PersistenceError.notFound formats entity + id")
    func persistenceNotFound() {
        let pe = PersistenceError.notFound(entity: "Tag", id: "abc")
        #expect(pe.errorDescription == "Tag with id abc not found.")
        #expect(pe.recoverySuggestion == "Refresh the list to see the latest data.")
    }

    @Test("CashlyError.persistence forwards descriptions")
    func persistenceWrappingForwards() {
        let inner = PersistenceError.saveFailed(entity: "User", underlying: "disk full")
        let umbrella = CashlyError.persistence(inner)
        #expect(umbrella.errorDescription == "Failed to save User.")
        #expect(umbrella.failureReason == "disk full")
    }

    // MARK: - DomainError

    @Test("DomainError.invalidInput formats field + reason")
    func domainInvalidInput() {
        let de = DomainError.invalidInput(field: "name", reason: "min length is 3")
        #expect(de.errorDescription == "Invalid value for name.")
        #expect(de.failureReason == "min length is 3")
        #expect(de.recoverySuggestion?.contains("highlighted") == true)
    }

    @Test("DomainError.businessRuleViolated formats rule")
    func domainBusinessRule() {
        let de = DomainError.businessRuleViolated(rule: "cannot delete in use")
        #expect(de.errorDescription == "Business rule violated: cannot delete in use.")
    }

    @Test("CashlyError.domain forwards descriptions")
    func domainWrappingForwards() {
        let inner = DomainError.businessRuleViolated(rule: "no orphans")
        let umbrella = CashlyError.domain(inner)
        #expect(umbrella.errorDescription == "Business rule violated: no orphans.")
    }

    // MARK: - description fallback

    @Test("CashlyError.description mirrors errorDescription")
    func descriptionMirrorsErrorDescription() {
        let error: CashlyError = .persistence(.saveFailed(entity: "X", underlying: "boom"))
        #expect(error.description == error.errorDescription)
    }
}

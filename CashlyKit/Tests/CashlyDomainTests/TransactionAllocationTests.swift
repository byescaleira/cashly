import CashlyDomain
import Testing

struct TransactionAllocationTests {
    private func participant(
        _ id: String, _ mode: TransactionSplitMode, _ value: Double
    ) -> Participant {
        Participant(
            id: id, user: User(id: "user-\(id)", name: id), splitMode: mode,
            splitValue: value, status: .pendingToReceive, transaction: "t")
    }

    @Test func ownerTakesEverythingWithoutParticipants() throws {
        let result = try TransactionAllocation.resolve(
            total: Money(minorUnits: 500), participants: [])
        #expect(result.owner == Money(minorUnits: 500))
        #expect(result.participants.isEmpty)
    }

    @Test func equalSplitGivesRemainderToOwnerFirst() throws {
        let result = try TransactionAllocation.resolve(
            total: Money(minorUnits: 100),
            participants: [participant("b", .equal, 3), participant("a", .equal, 3)])
        #expect(result.owner.minorUnits == 34)
        #expect(result.participants["a"]?.minorUnits == 33)
        #expect(result.participants["b"]?.minorUnits == 33)
    }

    @Test func percentageSplitUsesLargestRemainder() throws {
        let result = try TransactionAllocation.resolve(
            total: Money(minorUnits: 100),
            participants: [
                participant("a", .percentage, 0.333), participant("b", .percentage, 0.333),
            ])
        let total =
            result.owner.minorUnits + result.participants.values.map(\.minorUnits).reduce(0, +)
        #expect(total == 100)
        #expect(result.owner.minorUnits == 34)
    }

    @Test func percentageAboveHundredFails() {
        #expect(throws: CashlyError.self) {
            try TransactionAllocation.resolve(
                total: Money(minorUnits: 100),
                participants: [
                    participant("a", .percentage, 0.6), participant("b", .percentage, 0.6),
                ])
        }
    }

    @Test func fixedAmountsLeaveRestToOwner() throws {
        let result = try TransactionAllocation.resolve(
            total: Money(minorUnits: 1000),
            participants: [participant("a", .fixedAmount, 2.5), participant("b", .payerBased, 0)])
        #expect(result.participants["a"]?.minorUnits == 250)
        #expect(result.participants["b"] == .zero)
        #expect(result.owner.minorUnits == 750)
    }

    @Test func fixedAmountsAboveTotalFail() {
        #expect(throws: CashlyError.self) {
            try TransactionAllocation.resolve(
                total: Money(minorUnits: 100), participants: [participant("a", .fixedAmount, 2)])
        }
    }

    @Test func rejectsDuplicatedParticipants() {
        #expect(throws: CashlyError.self) {
            try TransactionAllocation.resolve(
                total: Money(minorUnits: 100),
                participants: [
                    participant("a", .fixedAmount, 0.1), participant("a", .fixedAmount, 0.1),
                ])
        }
    }

    @Test func singleCentGoesToLargestRemainderInIdOrder() throws {
        let result = try TransactionAllocation.resolve(
            total: Money(minorUnits: 1),
            participants: [
                participant("p1", .percentage, 0.5), participant("p2", .percentage, 0.5),
            ])
        #expect(result.owner == .zero)
        #expect(result.participants["p1"]?.minorUnits == 1)
        #expect(result.participants["p2"] == .zero)
    }
}

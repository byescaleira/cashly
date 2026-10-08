import CashlyDomain
import Testing

struct MoneyTests {
    @Test(arguments: [
        (10.0, Int64(1000)),
        (0.1, Int64(10)),
        (0.105, Int64(11)),
        (19.99, Int64(1999)),
        (-2.5, Int64(-250)),
    ])
    func roundsToMinorUnits(amount: Double, expected: Int64) throws {
        #expect(try Money(validating: amount).minorUnits == expected)
    }

    @Test(arguments: [Double.nan, .infinity, 9_000_000_000_001])
    func rejectsInvalidAmounts(amount: Double) {
        #expect(throws: CashlyError.self) { try Money(validating: amount) }
    }

    @Test func addsAndSubtracts() throws {
        let a = Money(minorUnits: 150)
        let b = Money(minorUnits: 75)
        #expect(try a.adding(b) == Money(minorUnits: 225))
        #expect(try a.subtracting(b) == Money(minorUnits: 75))
    }

    @Test func detectsOverflow() {
        #expect(throws: CashlyError.self) {
            try Money(minorUnits: .max).adding(Money(minorUnits: 1))
        }
        #expect(throws: CashlyError.self) {
            try Money(minorUnits: .min).subtracting(Money(minorUnits: 1))
        }
    }

    @Test func dividesRemainderToFirstShares() throws {
        let shares = try Money(minorUnits: 100).divided(into: 3)
        #expect(shares.map(\.minorUnits) == [34, 33, 33])
    }

    @Test(arguments: [0, 10_001])
    func rejectsInvalidDivision(count: Int) {
        #expect(throws: CashlyError.self) { try Money(minorUnits: 100).divided(into: count) }
    }

    @Test func installmentsReconcileTotal() {
        let total = Money(minorUnits: 1001)
        let parts = (0..<3).map { total.installment(at: $0, count: 3).minorUnits }
        #expect(parts == [334, 334, 333])
        #expect(parts.reduce(0, +) == total.minorUnits)
    }

    @Test func installmentOutOfRangeIsZero() {
        let total = Money(minorUnits: 1000)
        #expect(total.installment(at: 3, count: 3) == .zero)
        #expect(total.installment(at: -1, count: 3) == .zero)
        #expect(total.installment(at: 0, count: 0) == .zero)
    }
}

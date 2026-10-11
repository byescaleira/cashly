import Foundation

public enum Installments {
    public struct Row: Equatable, Sendable {
        public let number: Int
        public let payment: Double
        public let interest: Double
        public let amortization: Double
        public let balance: Double
    }

    public static func price(principal: Double, rate: Double, periods: Int) -> [Row] {
        let payment = TimeValue.payment(principal: principal, rate: rate, periods: periods)
        var balance = principal
        return (1...max(periods, 1)).map { number in
            let interest = balance * rate
            let amortization = payment - interest
            balance -= amortization
            return Row(
                number: number, payment: payment, interest: interest, amortization: amortization,
                balance: max(balance, 0))
        }
    }

    public static func sac(principal: Double, rate: Double, periods: Int) -> [Row] {
        let amortization = principal / Double(max(periods, 1))
        var balance = principal
        return (1...max(periods, 1)).map { number in
            let interest = balance * rate
            balance -= amortization
            return Row(
                number: number, payment: amortization + interest, interest: interest,
                amortization: amortization, balance: max(balance, 0))
        }
    }

    public static func effectiveMonthlyRate(cashPrice: Double, installment: Double, count: Int)
        -> Double?
    {
        guard cashPrice > 0, installment > 0, count > 0 else { return nil }
        let flows = [cashPrice] + Array(repeating: -installment, count: count)
        return TimeValue.internalRate(cashFlows: flows)
    }
}

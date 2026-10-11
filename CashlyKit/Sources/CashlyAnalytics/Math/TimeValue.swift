import Foundation

public enum TimeValue {
    public static func futureValue(present: Double, rate: Double, periods: Int) -> Double {
        present * pow(1 + rate, Double(periods))
    }

    public static func presentValue(future: Double, rate: Double, periods: Int) -> Double {
        future / pow(1 + rate, Double(periods))
    }

    public static func payment(principal: Double, rate: Double, periods: Int) -> Double {
        guard periods > 0 else { return principal }
        guard rate != 0 else { return principal / Double(periods) }
        return principal * rate / (1 - pow(1 + rate, -Double(periods)))
    }

    public static func netPresentValue(rate: Double, cashFlows: [Double]) -> Double {
        cashFlows.enumerated().reduce(0) { $0 + $1.element / pow(1 + rate, Double($1.offset)) }
    }

    public static func internalRate(cashFlows: [Double]) -> Double? {
        guard cashFlows.contains(where: { $0 > 0 }), cashFlows.contains(where: { $0 < 0 }) else {
            return nil
        }
        var low = -0.99
        var high = 10.0
        var rate = 0.01
        for _ in 0..<100 {
            let value = netPresentValue(rate: rate, cashFlows: cashFlows)
            if abs(value) < 1e-9 { return rate }
            let slope = cashFlows.enumerated().reduce(0) {
                $0 - Double($1.offset) * $1.element / pow(1 + rate, Double($1.offset + 1))
            }
            if netPresentValue(rate: low, cashFlows: cashFlows).sign == value.sign {
                low = rate
            } else {
                high = rate
            }
            let next = slope != 0 ? rate - value / slope : .nan
            rate = next.isFinite && next > low && next < high ? next : (low + high) / 2
        }
        return abs(netPresentValue(rate: rate, cashFlows: cashFlows)) < 1e-6 ? rate : nil
    }

    public static func annualRate(monthly: Double) -> Double {
        pow(1 + monthly, 12) - 1
    }

    public static func monthlyRate(annual: Double) -> Double {
        pow(1 + annual, 1.0 / 12) - 1
    }
}

import CashlyAnalytics
import Testing

struct FinancialMathTests {
    @Test func paymentAndPriceTableAgree() {
        let rows = Installments.price(principal: 1000, rate: 0.02, periods: 12)
        let payment = TimeValue.payment(principal: 1000, rate: 0.02, periods: 12)
        #expect(abs(payment - 94.56) < 0.01)
        #expect(abs((rows.last?.balance ?? 1) - 0) < 1e-6)
        #expect(abs(rows.reduce(0) { $0 + $1.amortization } - 1000) < 1e-6)
    }

    @Test func sacRepaysPrincipalWithDecreasingPayments() {
        let rows = Installments.sac(principal: 1200, rate: 0.01, periods: 12)
        #expect(abs(rows.reduce(0) { $0 + $1.amortization } - 1200) < 1e-6)
        #expect(rows.first?.payment ?? 0 > rows.last?.payment ?? 0)
    }

    @Test func netPresentValueIsZeroAtTheInternalRate() throws {
        let flows = [-1000.0, 300, 400, 500]
        let rate = try #require(TimeValue.internalRate(cashFlows: flows))
        #expect(abs(TimeValue.netPresentValue(rate: rate, cashFlows: flows)) < 1e-6)
    }

    @Test func interestFreeInstallmentsHaveAHiddenRateWhenCashIsCheaper() throws {
        let rate = try #require(
            Installments.effectiveMonthlyRate(cashPrice: 900, installment: 100, count: 10))
        #expect(rate > 0.018 && rate < 0.02)
        #expect(
            Installments.effectiveMonthlyRate(cashPrice: 1000, installment: 100, count: 10).map {
                abs($0) < 1e-6
            } == true)
    }

    @Test func rateConversionRoundTrips() {
        let annual = TimeValue.annualRate(monthly: 0.01)
        #expect(abs(TimeValue.monthlyRate(annual: annual) - 0.01) < 1e-12)
    }

    @Test func robustStatistics() {
        #expect(Statistics.median([1, 3, 2, 100]) == 2.5)
        #expect(Statistics.quantile([10, 20, 30, 40, 50], 0.9) == 46)
        #expect((Statistics.robustZScore(100, in: [10, 11, 12, 13, 100]) ?? 0) > 3.5)
    }
}

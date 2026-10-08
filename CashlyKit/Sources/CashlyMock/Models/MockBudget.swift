import CashlyDomain
import CashlyResource
import Foundation

extension Budget {
    public static var mock: Budget {
        mocks.first
            ?? Budget(
                id: "preview-budget", money: Money(minorUnits: 50000), category: .mock,
                date: Date.now.timeIntervalSince1970.yearMonth, summary: "Orçamento de exemplo")
    }

    public static var mocks: [Budget] {
        let budgets: [Budget] = (try? CashlyResourceFile.budgets.decoded()) ?? []
        return budgets.map { $0.normalizedPreview }.sorted(by: \.date, using: >)
    }
}

extension Budget {
    var normalizedPreview: Budget {
        var result = self
        if result.date > 999912 { result.date = Double(result.date).yearMonth }
        return result
    }
}

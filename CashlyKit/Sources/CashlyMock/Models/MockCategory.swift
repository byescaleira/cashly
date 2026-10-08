import CashlyDomain
import CashlyResource
import Foundation

extension CashlyDomain.Category {
    public static var mock: CashlyDomain.Category {
        mocks.first
            ?? CashlyDomain.Category(
                id: "preview-category", user: .mock, name: "Alimentação", color: "FF9500",
                icon: "fork.knife")
    }

    public static var mocks: [CashlyDomain.Category] {
        let categories: [CashlyDomain.Category] =
            (try? CashlyResourceFile.categories.decoded()) ?? []
        return categories.sorted(by: \.name)
    }
}

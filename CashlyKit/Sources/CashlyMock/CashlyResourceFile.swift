import Foundation

public enum CashlyResourceFile: String, CaseIterable {
    case users = "MockUsers"
    case categories = "MockCategories"
    case budgets = "MockBudgets"
    case transactions = "MockTransactions"
    case tags = "MockTags"
    case participants = "MockParticipants"
    public func decoded<T: Decodable>() throws -> T {
        guard let url = Bundle.module.url(forResource: rawValue, withExtension: "json") else {
            throw CocoaError(.fileNoSuchFile)
        }
        return try JSONDecoder().decode(T.self, from: Data(contentsOf: url))
    }
}

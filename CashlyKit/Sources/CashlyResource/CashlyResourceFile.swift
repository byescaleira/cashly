//
//  CashlyResourceFile.swift
//  CashlyKit
//
//  Created by Rafael Escaleira on 03/09/25.
//

import RyzeFoundation

public enum CashlyResourceFile: String, CaseIterable {
    case users = "MockUsers"
    case categories = "MockCategories"
    case budgets = "MockBudgets"
    case transactions = "MockTransactions"
    case tags = "MockTags"
    case participants = "MockParticipants"
    
    public var data: Data {
        guard let url = Bundle.module.url(forResource: rawValue, withExtension: ".json"),
              let data = try? Data(contentsOf: url)
        else { return Data() }
        return data
    }
    
    public func decoded<T>() -> T where T: Decodable {
        do {
            return try data.entity(for: T.self)
        } catch {
            fatalError(error.localizedDescription)
        }
    }
}

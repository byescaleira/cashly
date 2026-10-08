public enum CashlyIntelligence: String, Identifiable, CaseIterable, Codable, Sendable {
    case budgetValue
    case categoryName
    case tagValue

    public var id: String { rawValue }
}

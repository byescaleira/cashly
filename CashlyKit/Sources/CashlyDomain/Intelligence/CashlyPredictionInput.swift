public enum CashlyPredictionInput: Hashable, Sendable {
    case empty
    case text(String)
    case budget(month: YearMonth, categoryID: String)
    case tag(month: YearMonth, tagID: String)
}

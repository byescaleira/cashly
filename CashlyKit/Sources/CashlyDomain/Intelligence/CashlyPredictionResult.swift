public enum CashlyPredictionResult: Equatable, Sendable {
    case empty
    case textClassification(String)
    case tabularRegression(Double)
}

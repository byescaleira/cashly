public struct ChartPoint: Identifiable, Equatable {
    public let id: String
    public let label: String
    public let amount: Double
}

public struct ComparisonPoint: Identifiable, Equatable {
    public let id: String
    public let label: String
    public let planned: Double
    public let spent: Double
}

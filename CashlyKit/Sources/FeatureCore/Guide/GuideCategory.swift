import Foundation

public enum GuideCategory: String, CaseIterable, Identifiable, Sendable {
    case start, recording, planning, analysis, journey, automation, data

    public var id: String { rawValue }

    public var title: String {
        switch self {
        case .start: String(appLocalized: "Start Here")
        case .recording: String(appLocalized: "Recording")
        case .planning: String(appLocalized: "Budgets and Goals")
        case .analysis: String(appLocalized: "Analysis")
        case .journey: String(appLocalized: "Journey")
        case .automation: String(appLocalized: "Automation")
        case .data: String(appLocalized: "Data and Privacy")
        }
    }

    public var guides: [Guide] {
        Guide.allCases.filter { $0.category == self }
    }
}
